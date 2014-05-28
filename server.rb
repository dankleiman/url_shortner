require 'sinatra'
require 'uri'
require 'redis'


def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def save_link(url, short_url)
  redis = get_connection
  redis.hmset("short:url:#{short_url}", "url", url, "clicks", 0)
  redis.sadd("links", "short:url:#{short_url}")
end

def add_clicks(link)
  redis = get_connection
  redis.hincrby("short:url:#{link}", "clicks", 1)
end

def valid_url(url)
  errors = []
  if (url =~ URI::regexp) != 0
      errors << "Please enter a valid url."
  end
  errors
end

def get_short(long_url)
  letters = (('a'..'z').to_a + ('A'..'Z').to_a)
  short_url = letters.sample(6).join
  redis = get_connection
  until !redis.sismember("links", "short:url:#{short_url}")
    short_url = letters.sample(6).join
  end
  short_url
end

#stats page to show all links, long and short, plus clicks
#on post submit long link to shorten, clicks += 1 before redirect

get '/' do
  @errors = []
  erb :index
end

get '/links/:short' do
  @short = params[:short]
  redis = get_connection
  @long_url = redis.hget("short:url:#{@short}", "url")
  @clicks = redis.hget("short:url:#{@short}", "clicks")
  erb :'links/show'
end

get '/:short_url' do
  short_url = params[:short_url]
  add_clicks(short_url)
  redis = get_connection
  outgoing_link = redis.hget("short:url:#{short_url}", "url")
  redirect "#{outgoing_link}"
end

post '/new' do
  url = params[:url]
  @errors = []
  @errors = valid_url(url)
  if @errors.empty?
    short = get_short(url)
  # short_url = 'http://' + 'this_app_domain.com/'+ short
    save_link(url, short)
    redirect "/links/#{short}"
  else
    erb :index
  end
end
