#!/usr/bin/env ruby
#encoding: UTF-8


require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'json'

start_url = "http://www.visualisingdata.com/index.php"

output_filename = "visualisingdata.json"

months = ["2012/01", "2012/02", "2012/03", "2012/04", "2012/05",
          "2012/06", "2012/07", "2012/08", "2012/09", "2012/10",
          "2012/11", "2012/12"]

# months = ["2012/06"]

@agent = Mechanize.new

pages = Array.new

def get_posts root_page
  data = []
  parser = root_page.parser
  links = parser.css(".post ul li a")
  links.each do |link|
    data << get_post(link)
  end

  puts links.size

  data
end

def get_post link
  page_data = {}

  page = @agent.get(link['href'])

  fields = link['href'].split("/")
  page_data["href"] = link['href']
  page_data["title"] = page.parser.css('h1.post-title').text.strip
  page_data["meta"] =  page.parser.css('.post-info').to_html.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)
  page_data["content"] = page.parser.css('.post p').to_html.force_encoding("ISO-8859-1").encode("utf-8", replace: nil)

  date_cat = page.parser.css('.post-info').text
  # puts date_time
  date = date_cat.split("in")[0].strip

  page_data["date"] = date
  # page_data['time'] = date_time.split("T")[1]

  # puts page_data['date']

  page_data
end

months.each do |month|
  url = start_url + "/" + month
  root_page = @agent.get(url)
  pages.concat(get_posts(root_page))
  link = @agent.get(url).link_with(:text => '←Older')

  while(link)
    puts 'next_page'
    root_page = link.click()
    pages.concat(get_posts(root_page))

    link = @agent.page.link_with(:text => '←Older')
  end
end

pages = pages.sort do |a,b| 
  date_a = a['date'].split("/")
  date_b = b['date'].split('/')
  Time.new(date_a[0], date_a[1], date_a[2]) <=> Time.new(date_b[0], date_b[1], date_b[2])
end

File.open(output_filename, 'w') do |file|
  file.puts JSON.pretty_generate(JSON.parse(pages.to_json))
end

