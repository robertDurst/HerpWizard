require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Gatherer
  class WikipediaScraper < Scraper
    BASE_URL = 'https://en.wikipedia.org'
    ALL_SNAKES_URL = "#{BASE_URL}/wiki/List_of_snakes_by_common_name"

    def initialize
      @source_file = './data/wikipedia.json'

      Dir.mkdir('./data') unless Dir.exist?('./data')
      File.open(@source_file, 'w') unless File.exist?(@source_file)
    end

    def scrape_all
      uri = URI(ALL_SNAKES_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      return unless response.is_a?(Net::HTTPSuccess)

      doc = Nokogiri::HTML(response.body)

      all_snake_categories = doc.css('#mw-content-text').children[0].css('ul')[2..]
      all_snakes = all_snake_categories.map do |row|
        row.css('li').map do |snake|
          name = snake.text
          link = snake.css('a')[0]['href']
          {
            name: name,
            link: link
          }
        end
      end.flatten.compact

      all_snakes.each_with_index do |snake, i|
        puts "[#{i + 1}/#{all_snakes.size}] #{snake[:name]}"

        single_paged_scrape(snake[:link])
      end
    end

    def single_paged_scrape(link)
      sleep(rand(1..5))
      uri = URI("#{BASE_URL}/#{link}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      return unless response.is_a?(Net::HTTPSuccess)

      doc = Nokogiri::HTML(response.body)

      data = doc.css('#mw-content-text').text.include?('Kingdom') ? doc.css('#mw-content-text').text : nil

      return if data.nil?

      File.open(@source_file, 'a') do |f|
        f.puts({
          name: doc.css('h1').text,
          link: link,
          data: data
        }.to_json)
      end
    end
  end
end

Gatherer::WikipediaScraper.new.scrape_all
