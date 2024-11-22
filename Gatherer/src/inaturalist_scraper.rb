require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'

# we assume that we will never go 50 pages before finding next starting point
# a series of observations is one where
#
# StartPoint: the last end_point
# All Eligible Start Points
# All Ineligible Start Points
# EndPoint: the starting_point of the next series
# How many pages of data represented by the series

module Helper
  # assumes we start in a good state
  def self.filter(ids)
    copy_of_ids = ids.dup
    i = 0

    final = {}
    while i < ids.length - 1
      before = ids[i]
      after = ids[i + 1]
      if (before * 10) < after
        ids.delete_at(i + 1)
        final[after] = false
      elsif before > after
        ids.delete_at(i)
        final[before] = false
      else
        i += 1
        final[before] = true
      end
    end

    final[ids[-1]] = true

    final_actual = []

    copy_of_ids.each_with_index.map do |id, _i|
      final_actual << { ok: final[id], value: id }
    end

    final_actual
  end

  def self.decipher(final_list)
    eligible = []
    ineligible = []

    final_list.each do |item|
      if item[:ok]
        ineligible.each { |i| eligible << i }
        ineligible = []
        eligible << item[:value]
      else
        ineligible << item[:value]
      end
    end

    [eligible, eligible.pop]
  end
end

module Gatherer
  class INaturalistScraper < Scraper
    def initialize
      @source_file = './data/inaturalist.json'

      # make directory if it doesnt exist
      Dir.mkdir('./data') unless Dir.exist?('./data')
      # make file if it doesnt exist
      File.open(@source_file, 'w') unless File.exist?(@source_file)
      @total = 0
    end

    def scrape_all_pages
      start = 0
      page = 1

      while true
        page = 1

        puts "[#{Time.now}]: Starting at #{start} on page #{page} with #{@total} total observations"

        rand_sleep = rand(1..15)
        sleep(rand_sleep)
        puts "[#{Time.now}]: Querying #{start} on page #{page} after sleeping for #{rand_sleep} seconds"
        top = analyze_page(start, page)
        while top == start
          puts "[#{Time.now}]: No new data found, moving to next page: #{page}"

          rand_sleep = rand(1..15)
          sleep(rand_sleep)
          puts "[#{Time.now}]: Querying #{start} on page #{page} after sleeping for #{rand_sleep} seconds"

          page += 1
          top = analyze_page(start, page)
        end

        start = top
      end
    end

    def analyze_page(start, page)
      one_page = Gatherer::INaturalistScraper.new.single_paged_scrape(start, page)
      filtered = Helper.filter((start == 0 ? [] : [start]) + one_page['results'].map do |observation|
        observation['id'].to_i
      end)
      _, top = Helper.decipher(filtered)

      File.open(@source_file, 'a') do |f|
        one_page['results'].each do |observation|
          f.puts observation.to_json
          @total += 1
        end
      end
      top
    end

    # Given zero to many of following parameters, returns observations matching the search criteria.
    # The large size of the observations index prevents us from supporting the page parameter when
    # retrieving records from large result sets. If you need to retrieve large numbers of records, use
    # the per_page and id_above or id_below parameters instead.
    def single_paged_scrape(last_id, page)
      params = {
        captive: 'false',
        verifiable: 'true',
        taxon_id: '85553',
        iconic_taxa: 'Reptilia',
        per_page: '200',
        order: 'asc',
        order_by: 'created_at',
        id_above: last_id,
        page: page
      }

      uri = URI('https://api.inaturalist.org/v1/observations')

      uri.query = URI.encode_www_form(params)

      # Create the HTTP request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'

      # Send the request
      response = http.request(request)

      # Parse the response (if JSON)
      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

      raise "Error: #{response.code} #{response.message}"
    end
  end
end

gatherer = Gatherer::INaturalistScraper.new

gatherer.scrape_all_pages
