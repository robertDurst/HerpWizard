require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Gatherer
  class FieldHerpForumScraper < Scraper
    ALL_SNAKES_URL = 'https://en.wikipedia.org/wiki/List_of_snakes_by_common_name'

    def initialize; end

    def scrape_all
      uri = URI(ALL_SNAKES_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      return unless response.is_a?(Net::HTTPSuccess)

      doc = Nokogiri::HTML(response.body)

      doc.css('#mw-content-text').children[0].css('ul').each do |row|
        row.css('li').each do |snake|
          name = snake.text
          link = snake.css('a')[0]['href']
          puts "#{name} - #{link}"
        end
      end
    end
  end
end

Gatherer::FieldHerpForumScraper.new.scrape_all
