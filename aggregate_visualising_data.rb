#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'
require 'date'

wdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
dst_start = Time.new(2012,03,25, 2,0,0)
dst_end = Time.new(2012,10,28,3,0,0)

input_filename = "visualisingdata_with_tweets.json"
output_filename ="visualisingdata.csv"

output_data = []

header = ['source','title', 'url', 'category', 'dotw', 'year', 'month', 'day', 'words', 'links', 'imgs', 'tweet_time','retweets']

output_data << header
posts = JSON.parse(File.open(input_filename).read)

puts posts.size

posts.each_with_index do |post, index|
  # break if index > 4

  data = []
  date = post['date']
  month = Date._strptime(date.split[0], "%B")
  year = date.split(",")[1].strip
  if !(date =~ /^\w+\s(\d+)\w+,\s\d+$/)
    puts "ERROR messed up"
    puts date
  end
  day = $1
  time = Time.new(year, month[:mon], day)
  # cat_section = Nokogiri::HTML(post["meta"]).css("a")[0]
  cat_section = Nokogiri::HTML(post["meta"]).css("a")[0]
  if cat_section
    category = cat_section.text
  else
    category = "None"
  end
  
  data << 'visualisingdata'
  data << "\"" + post['title'] + "\""
  data << post['href']
  data << category
  data << wdays[time.wday]
  data << time.strftime("%Y")
  data << time.strftime("%m")
  data << time.strftime("%d")

  html = Nokogiri::HTML(post['content'])
  word_count = html.text.split.length
  data << word_count

  links = html.css('a')
  data << links.size

  images = html.css('img')
  data << images.size
  if post['tweet']
    ttime = Time.parse(post['tweet']['created_at'])
    offset = '+00:00'
    off_hours = '0'
    if ttime > dst_start and ttime < dst_end
      puts 'dst' + ttime.to_s
      offset = '+01:00'
      off_hours = '1'
    end
    local_time = ttime.getlocal(offset)
    data << post['tweet']['created_at']
    data << post['tweet']['retweet_count']
    data << local_time
    data << off_hours
  else
    data << ''
    data << ''
    data << ''
    data << ''
  end

  output_data << data
end

File.open(output_filename, 'w') do |file|
  output_data.each do |data|
    file.puts data.join(",")
  end
end
