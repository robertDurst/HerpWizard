require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'

module Gatherer
  class INaturalistScraper < Scraper
    def initialize
      params = {
        captive: 'false',
        verifiable: 'true',
        taxon_id: '85553',
        iconic_taxa: 'Reptilia',
        per_page: '2',
        order: 'desc',
        order_by: 'created_at'
      }

      uri = URI('https://api.inaturalist.org/v1/observations')

      uri.query = URI.encode_www_form(params)

      @uri = uri
    end

    def single_paged_scrape
      # Create the HTTP request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'

      # Send the request
      response = http.request(request)

      # Parse the response (if JSON)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        puts data
      else
        puts "Error: #{response.code} #{response.message}"
      end
    end

    private

    attr_accessor :uri
  end
end
