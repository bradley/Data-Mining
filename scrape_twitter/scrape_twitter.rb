require 'rubygems'
require 'crack'
require 'rest-open-uri'

class GetTweets
	def initialize(base, user, page_count)
		@base_url = base
		@user = user
		@page_count = page_count
		@base_home = "downloaded_page-"
		@tweets = {}
	end

	def get_tweets
		@range = (1 .. @page_count)
		@range.each do |page|
			page = page.to_s
			full_url = @base_url + @user + "&page=" + page

			p "Downloading from: " + full_url

			remote_data = open(full_url).read

			parsed_xml = Crack::XML.parse(remote_data)
			parsed_tweets = parsed_xml["statuses"]

			parsed_tweets.each do |tweet_xml|
				@tweets[tweet_xml["id"]] = tweet_xml["text"] 
			end

			sleep 5
			# We sleep for 5 second just to give Twitter's servers a break so that we dont get throttled. 
			# This may not be required for the code to run but certainly doesn't hurt.
		end
	end

	def store_data
		local_file_name = @base_home + @user + ".txt"

		p "Writing to: " + local_file_name

		local_file = open(local_file_name, "w")

		@tweets.each_pair do |tweet_id, tweet_text|
			local_file.write("#{tweet_id} \n \t #{tweet_text} \n --- \n")
		end

		local_file.close
	end
end


base = "http://api.twitter.com/1/statuses/user_timeline.xml?screen_name="
user = "bradleygriffith"
page_count = 3

tweets = GetTweets.new(base, user, page_count)
tweets.get_tweets
tweets.store_data