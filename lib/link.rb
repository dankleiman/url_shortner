require 'uri'

require './lib/model.rb'

# trackers shortened links
class Link < Model
  
  # set the table name
  self.table_name = 'urls'
  
  class << self
    # generates a unique shortened URL
    def generate_short
      letters = (('a'..'z').to_a + ('A'..'Z').to_a)
      short_url = ''
      loop do
        short_url = letters.sample(6).join
        break if self.where(short_url: short_url).empty?
      end
      short_url
    end
    
    # check if the url passes URI's regexp
    def valid_url?(url)
      URI::regexp === url
    end
  end
  
end
