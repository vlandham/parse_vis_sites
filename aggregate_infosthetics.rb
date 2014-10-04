#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'

wdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

# different in EU
dst_start = Time.new(2012,03,25, 2,0,0)
dst_end = Time.new(2012,10,28,3,0,0)

input_filename = "infosthetics_with_tweets.json"
output_filename ="infosthetics.csv"

output_data = []

header = ['source','title', 'url', 'category', 'dotw', 'year', 'month', 'day', 'words', 'links', 'imgs', 'tweet_time','retweets','local_tweet_time', 'offset_hours']

output_data << header
posts = JSON.parse(File.open(input_filename).read)

puts posts.size

posts.each_with_index do |post, index|
  # break if index > 4

  data = []
  date = post['date'].split("/")
  time = Time.new(*date)
  # cat_section = Nokogiri::HTML(post["meta"]).css("a")[0]
  cat_section = Nokogiri::HTML(post["meta"]).css("#bylinetable")[1].css("#bylinecontent a")[0]
  if cat_section
    category = cat_section.text
  else
    category = "None"
  end

  data << 'infosthetics'
  data << "\"" + post['title'] + "\""
  data << post['href']
  data << category
  data << wdays[time.wday]
  data << date[0]
  data << date[1]
  data << date[2]

  html = Nokogiri::HTML(post['content'])
  word_count = html.text.split.length
  data << word_count

  links = html.css('a')
  data << links.size

  images = html.css('img')
  data << images.size

  if post['tweet']
    ttime = Time.parse(post['tweet']['created_at'])
    offset = '+01:00'
    off_hours = '1'
    if ttime > dst_start and ttime < dst_end
      puts 'dst' + ttime.to_s
      offset = '+02:00'
      off_hours = '2'
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
