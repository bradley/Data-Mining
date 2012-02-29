require 'rubygems'
require 'rest-open-uri'


base_url = 'http://en.wikipedia.com/wiki/'
extension = 'Ayn_Rand'

full_url = base_url + extension
local_file_name = "downloaded_page-" + extension + ".html"




p "Downloading from: " + full_url

remote_data = open(full_url).read
=begin
 The read method returns the content of the given URL as a string
 NOTICE: Ruby is using the open method of the rest-open-uri gem here...
 whereas in the rest of the program Ruby is using the open method supplied by Ruby
 Thoughts: I am assuming ruby is going up the tree here and seeing
 whether or not the method is supplied by any included scripts / gems 
 AND checking if the arguments are contextually appropriate for the given method.
=end

p "Writing to: " + local_file_name




local_file = open(local_file_name, "w")
	local_file.write(remote_data)
local_file.close
