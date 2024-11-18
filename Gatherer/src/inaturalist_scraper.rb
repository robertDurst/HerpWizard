require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'

def filter_anomalies(numbers, factor: 10)
  filtered = [numbers.first] # Start with the first number
  last_added = numbers.first
  numbers.each_cons(2) do |prev, curr|
    # Add the current number only if it's within the acceptable range
    if curr > prev && curr <= prev * factor && curr <= last_added * factor
      filtered << curr
      last_added = curr
    end
  end
  filtered
end

module Gatherer
  class INaturalistScraper < Scraper
    def initialize
      @source_file = './data/inaturalist.json'

      # make file if it doesnt exist
      File.open(@source_file, 'w') {} unless File.exist?(@source_file)

      # read file to get the last id
      return unless File.exist?(@source_file)

      begin
        @last_id = filter_anomalies(File.read(@source_file).split("\n").map do |line|
          JSON.parse(line)['id'].to_i
        end).max
      rescue JSON::ParserError
        @last_id = 1
      end

      puts @last_id
    end

    def scrape_all_pages
      keep_going = false

      until keep_going
        # random sleep to avoid rate limiting
        sleep(rand(5..30))
        begin
          puts "Scraping with last_id #{@last_id}"
          keep_going = analyze(single_paged_scrape)
        rescue StandardError => e
          puts e
          puts 'failed, trying again'
        end
      end
    end

    def analyze(result)
      total_results = result['total_results']

      results_count_of_this_query = result['results'].length
      page_num = result['page']
      per_page = result['per_page']

      puts "Page #{page_num} of #{(total_results / per_page.to_f).ceil} (#{results_count_of_this_query} results)"

      result['results'].each do |observation|
        @last_id = observation['id'] if observation['id'].to_i > @last_id && observation['id'].to_i < @last_id * 10
        puts "ID: #{observation['id']} | Created at: #{observation['created_at']}"

        # append to file
        File.open(@source_file, 'a') { |f| f.puts observation.to_json }
      end

      results_count_of_this_query < per_page
    end

    # Given zero to many of following parameters, returns observations matching the search criteria.
    # The large size of the observations index prevents us from supporting the page parameter when
    # retrieving records from large result sets. If you need to retrieve large numbers of records, use
    # the per_page and id_above or id_below parameters instead.
    def single_paged_scrape
      params = {
        captive: 'false',
        verifiable: 'true',
        taxon_id: '85553',
        iconic_taxa: 'Reptilia',
        per_page: '200',
        order: 'asc',
        order_by: 'created_at',
        id_above: @last_id,
        page: 1
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

Gatherer::INaturalistScraper.new.scrape_all_pages
