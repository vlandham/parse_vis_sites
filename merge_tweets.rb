#!/usr/bin/env ruby
#encoding: UTF-8

require 'json'
require 'date'
require 'open-uri'


def process_title title

  title = title.downcase
  title = title.gsub("“",'')
    .gsub("”",'')
    .gsub("\"",'')
    .gsub("’",'')
    .gsub("‘",'')
    .gsub("'",'')
    .gsub(",",'')
    .gsub(".",'')
    .gsub(":",'')
    .gsub("@",'')
    .gsub("…",'')
    .gsub("...",'')
    .gsub("?",'')
  
  # title.gsub!("\x93", '')
  # title.gsub!("\x94", '')
  title
end

json_filename = ARGV[0]
twitter_filename = ARGV[1]

output_filename = File.join(File.dirname(json_filename), File.basename(json_filename, File.extname(json_filename)) + "_with_tweets.json")

json = JSON.parse(File.open(json_filename,'r').read)
tweets = JSON.parse(File.open(twitter_filename,'r').read)


tweet_text = tweets.collect {|t| process_title(t['full_text']) }

no_title_match = []

matched = 0
json.each_with_index do |post, index|
  title = process_title(post['title'])
  title_regex = Regexp.new(".*#{title}.*")
  match = tweet_text.find_index {|t| t =~ title_regex}

  if match
    post['tweet'] = tweets[match]
    matched += 1
  else
    no_title_match << index
  end
end

no_href_match = []
no_title_match.each do |post_index|
  post = json[post_index]
  url = post['href']
  tweet = tweets.find {|t| t['urls'][0] and t['urls'][0]['expand'] and t['urls'][0]['expand'] == url}
  if tweet
    post['tweet'] = tweet
    matched += 1
  else
    no_href_match << post_index
  end
end

puts matched

no_href_match.each do |post_index|
  puts json[post_index]['title']
end

puts no_href_match.size

no_redirect_match = []

no_href_match.each do |post_index|
  post = json[post_index]
  date = Time.now
  if post['date'].split('/').size > 1
    date = Time.new(*post['date'].split('/'))
  else
    date = Time.parse(post['date'])
  end
  puts date
  tweets_on_day = tweets.find_all do |t|
    tweet_time = Time.parse(t['created_at'])
    date.year == tweet_time.year and date.month == tweet_time.month and date.day == tweet_time.day
  end

  puts post['title']
  found = false
  tweets_on_day.each do |t|
    if t['urls'] and t['urls'][0] and t['urls'][0]['expand']
      puts t['urls'][0]['expand']
      final_uri = ''
      begin
      open(t['urls'][0]['expand']) do |h|
        final_uri = h.base_uri
      end
      rescue OpenURI::HTTPError => the_error
        puts 'Problem with url'
      rescue
        puts 'something else'
      end
      puts "result: #{final_uri}"
      puts "post  : #{post['href']}"
      if final_uri.to_s == post['href']
        post['tweet'] = t
        found = true
        break
      end
      puts '---'
    end
  end

  if !found
    no_redirect_match << post_index
  end
end

puts no_redirect_match.size



File.open(output_filename, 'w') do |file|
  file.puts JSON.pretty_generate(JSON.parse(json.to_json))
end
