require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Gatherer
  class FieldHerpForumScraper < Scraper
    BASE_URL = 'https://www.fieldherpforum.com/forum/'

    def initialize; end

    def scrape_all
      uri = URI("#{BASE_URL}/viewforum.php?f=2")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        doc = Nokogiri::HTML(response.body)

        doc.css('.topics').css('li').each do |topic|
          title = topic.css('.topictitle').text
          link = topic.css('.topictitle')[0]['href'].split('viewtopic.php?')[1]

          puts "\n"
          puts "=============== Title: #{title} ==============="
          puts "Link: #{link}"

          single_paged_scrape(link)

          puts "=============== End of #{title} ==============="
        end

      else
        puts "Error: #{response.code} #{response.message}"
      end
    end

    def single_paged_scrape(link)
      uri = URI("#{BASE_URL}/viewtopic.php?#{link}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        doc = Nokogiri::HTML(response.body)

        posts = doc.css('.post')

        posts.each do |post|
          content = post.css('.postbody').css('.content').text
          author = post.css('.author').css('.username').text
          time = post.css('.author').css('time').text
          puts "Author: #{author}"
          puts "Time: #{time}"
          puts "Content: #{content}"
        end

      else
        puts "Error: #{response.code} #{response.message}"
      end
    end
  end
end
