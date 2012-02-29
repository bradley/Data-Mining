# NOTE: Almost everything below was taken directly from the guide here: http://blog.siyelo.com/machine-learning-in-ruby-statistic-classifica
# The exceptions being a few changes to the required gems (replaced outdated ones) and a heavy amount of annotation for my own learning purposes. :)

require 'rubygems'
require 'nokogiri'
require 'rest-open-uri'
require 'rss/1.0'
require 'rss/2.0'




class RssParser
  attr_accessor :url 

  def initialize(url) 
    @url = url
  end

  def article_urls
    RSS::Parser.parse(open(url), false).items.map{|item| item.link } 
    # The parse class method of Parser takes up to 4 args with the only required one being the first: rss
    # The second arg (which we supply above) is 'do_validate' which is true by default. 
    # I'm *unsure* of this, but I believe this method returns an array of article URLs in a given RSS feed.
  end
end





class HtmlParser
  attr_accessor :url, :selector 

  def initialize(url, selector) 
    @url = url
    @selector = selector
  end

  def content
    doc = Nokogiri::HTML(open(url)) 
    # The HTML class method of Nokogiri will parse a string into a NodeSet.
    # A NodeSet contains a list of Nokogiri::XML::Node objects.
    # Nokogiri::XML::Node may be treated similarly to a hash with regard to attributes.
    # Keys in any such hash will be the attributes of the given HTML / XML.
    # Check here for more: http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Node.html
    html_elements = doc.search(selector)
    # Search the hash keys for the given selectors.
    html_elements.map { |element| clean_whitespace(element.text) }.join(' ')
    # The map method takes an array and returns a new one with values returned by the block. 
    # After obtaining this new array, we join it's elements into a single string.
  end

  private

    def clean_whitespace(text)
      text.gsub(/\s{2,}|\t|\n/, ' ').strip
      # The gsub method takes to arguments: pattern and replacement.
      # Here our regexp is looking for several things, all to be replaced by a single whitespace:
      # \s = whitespace ({2,} = two or more)
      # \t = tabs
      # \n = newlines
    end
end






class Classifier
  attr_accessor :training_sets, :noise_words

  def initialize(data)
    @training_sets = {}
    filename = File.join(File.dirname(__FILE__), 'stop_words.txt')
    # I'm *unsure* of this, but I believe File.dirname(__FILE__) returns the current directory of this script.
    @noise_words = File.new(filename).readlines.map(&:chomp)
    # The readlines method reads every line of a given file and returns them in an array.
    # The ampersand/colon are shorthand for Ruby's to_proc method...
    # This is exactly the same is saying array.map( |x| x.chomp)
    # The chomp method returns a string with the given record separator (\n, \r, "ing", etc.), if present, removed from the end of the sting.
    # If no record separator is supplied as an argument, chomp will remove carriage return characters.
    train_data(data)
  end

  def scores(text)
    words = text.downcase.scan(/[a-z]+/)
    scores = {}
    training_sets.each_pair do |category, word_weights|
      scores[category] = score(word_weights, words)
    end

    scores
  end

  def train_data(data)
    data.each_pair do |category, text|
      # The each_pair method runs through a hash like each does to an array.
      # This is similar to PHP's foreach($array as $key => $value)
      words = text.downcase.scan(/[a-z]+/)
      word_weights = Hash.new(0)

      words.each {|word| word_weights[word] += 1 unless noise_words.index(word)}
      # Add each word to as an index of the word_weights hash and increment it's value by 1 unless the word is an element of our noise_words array.

      ratio = 1.0 / words.length
      word_weights.keys.each {|key| word_weights[key] *= ratio}
      # Assign a weight to each word in our word_weights hash.

      training_sets[category] = word_weights
    end
  end

  private
    def score(word_weights, words)
      score = words.inject(0) {|acc, word| acc + word_weights[word]}
      # The inject method is essentially an accumulator: the result of each execution is stored in the accumulator and then passed to the next execution.
      # Using 0 as our argument defaults the accumulator to 0. 
      # So here, we say for each word in words, up the accumulator to it's current count plus the weight we have determined (or not determined) for that particular word.
      # In the end, this gives us the score for this article's text in the terms of the current category being tested for.
      1000.0 * score / words.size
      # I'm *unsure* of this, but I believe we level the playing field here so that we arent unfairly comparing the scores of articles of varying lengths.
    end
end




# training data samples
economy = HtmlParser.new('http://en.wikipedia.org/wiki/Economy', '.mw-content-ltr')
sport = HtmlParser.new('http://en.wikipedia.org/wiki/Sport', '.mw-content-ltr')
health = HtmlParser.new('http://en.wikipedia.org/wiki/Health', '.mw-content-ltr')

training_data = {
  :economy => economy.content,
  :sport => sport.content,
  :health => health.content
}

classifier = Classifier.new(training_data)

results = {
  :economy => [],
  :sport => [],
  :health => []
}

rss_parser = RssParser.new('http://avusa.feedsportal.com/c/33051/f/534658/index.rss')
rss_parser.article_urls.each do |article_url|
  article = HtmlParser.new(article_url, '#article .area > h3, #article .area > p, #article > h3')
  # The selectors being given to the HtmlParser object in the second argument were determined using Firebug and are therefore specific for the case.
  scores = classifier.scores(article.content)
  category_name, score = scores.max_by{ |k,v| v }
  # The max_by method returns the maximum value of a given block. Here we are looking for the maximum value of our scores hash. The maximum value will be the category with the highest score for the given article.
  # DEBUG info
  # p "category: #{category_name}, score: #{score}, scores: #{scores}, url: #{article_url}"
  results[category_name] << article_url
  # Finally, we append this article's URL to the end of the category determined for this article. 
end

p results

