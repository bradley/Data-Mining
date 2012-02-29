require 'rubygems'
require 'rest-open-uri'



class GetPagesByYear
	def initialize(base, start_year, end_year)
		@base_url = base
		@start_year = start_year
		@end_year = end_year
		@base_home = "downloaded_page-"
	end

	def get_pages
		@range = (@start_year .. @end_year)
		@range.each do |year|
			year = year.to_s
			full_url = @base_url + year

			p "Downloading from: " + full_url

			remote_data = open(full_url).read

			store_data(year, remote_data)

			sleep 1
			# We sleep for 1 second just to give wikipedia's servers a break. This isnt required for the code to run.
		end
	end

	def store_data(year, remote_data)
		local_file_name = @base_home + year + ".html"

		p "Writing to: " + local_file_name

		local_file = open(local_file_name, "w")
			local_file.write(remote_data)
		local_file.close
	end
end


base = "http://en.wikipedia.com/wiki/"
start_year = 2003
end_year = 2009

pages = GetPagesByYear.new(base, start_year, end_year)
pages.get_pages
