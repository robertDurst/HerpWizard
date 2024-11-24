require_relative 'scraper'

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

module Gatherer
  class FieldHerpForumScraper < Scraper
    BASE_URL = 'https://www.fieldherpforum.com/forum/'

    def initialize
      @source_file = './data/field_herp_forum.json'

      # make directory if it doesnt exist
      Dir.mkdir('./data') unless Dir.exist?('./data')
      # make file if it doesnt exist
      File.open(@source_file, 'w') unless File.exist?(@source_file)
      @total = 0
    end

    def scrape_all
      num_results = 0
      page = 0
      page_results = 50

      while page_results == 50
        sleep(rand(1..10))
        page_results = 0
        uri = URI("#{BASE_URL}/viewforum.php?f=2&start=#{50 * page}")
        puts "[#{Time.now}] Scraping page #{page}. Thus far, #{num_results} results."
        page_results = 0
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          doc = Nokogiri::HTML(response.body)

          doc.css('.topics').css('li').each do |topic|
            title = topic.css('.topictitle')&.text
            link = topic.css('.topictitle')[0] ? topic.css('.topictitle')[0]['href']&.split('viewtopic.php?')&.[](1) : nil

            next if link.nil? || title.nil? || title.empty?

            # on the first page, the first topic is 'How to Register'
            next if title.include? 'How to Register'

            num_results += 1
            page_results += 1

            puts "\t[#{num_results}] Title: #{title} ==============="

            comments = single_paged_scrape(link)

            File.open(@source_file, 'a') do |f|
              f.puts({
                title: title,
                link: link,
                comments: comments
              }.to_json)
            end
          end

        else
          puts "Error: #{response.code} #{response.message}"
        end

        page += 1
      end
    end

    def single_paged_scrape(link)
      num_results = 0
      page_results = 50
      page = 0
      all_comments_for_page = []
      last_first_result = ''
      while page_results == 50
        page_results = 0
        sleep(rand(1..10))
        results = foobar(link, page)
        results.each do |result|
          num_results += 1
          page_results += 1
          all_comments_for_page << result
        end

        page += 1
        last_first_result_new = "#{results.to_json}"
        break if last_first_result == last_first_result_new

        last_first_result = last_first_result_new
      end
      all_comments_for_page
    end

    def foobar(link, page)
      uri = URI("#{BASE_URL}/viewtopic.php?#{link}&start=#{page * 50}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        doc = Nokogiri::HTML(response.body)

        posts = doc.css('.post')

        posts.map do |post|
          {
            content: post.css('.postbody').css('.content').text,
            author: post.css('.author').css('.username').text,
            time: post.css('.author').css('time').text
          }
        end

      else
        puts "Error: #{response.code} #{response.message}"
      end
    end
  end
end

# https://www.fieldherpforum.com/forum/viewtopic.php?t=5074
# Gatherer::FieldHerpForumScraper.new.single_paged_scrape('t=5074')

Gatherer::FieldHerpForumScraper.new.scrape_all
