require 'sinatra'
require 'uri'
require 'pg'


configure :production do
  set :db_connection_info, {
    host: ENV['DB_HOST'],
    dbname:ENV['DB_DATABASE'],
    user:ENV['DB_USER'],
    password:ENV['DB_PASSWORD']
  }

end

configure :development do
  set :db_connection_info, {dbname: 'urls'}
end

def db_connection
  begin
    connection = PG::Connection.open(settings.db_connection_info)
    yield(connection)
  ensure
    connection.close
  end
end

def save_link(url, short_url)
  db_connection do |conn|
    conn.exec("INSERT INTO urls (long_url, short_url, clicks)
    VALUES ('#{url}', '#{short_url}', 0);")
  end
end

def add_clicks(link)
  db_connection do |conn|
  #increment clicks cell
    conn.exec("UPDATE urls SET clicks = clicks + 1 WHERE urls.short_url = '#{link}'")
  end
end

def get_all_url_stats
  db_connection do |conn|
    conn.exec("SELECT * FROM urls")
  end
end

def get_url_data(short_url)
  db_connection do |conn|
    conn.exec("SELECT * FROM urls WHERE urls.short_url = '#{short_url}'")
  end
end

def check_short_url(short_url)
  db_connection do |conn|
    results = conn.exec("SELECT short_url FROM urls WHERE urls.short_url = '#{short_url}'")
  end
end

def get_short(long_url)
  unique_url = false
  letters = (('a'..'z').to_a + ('A'..'Z').to_a)
  until unique_url == true
    short_url = letters.sample(6).join
    short_urls = check_short_url(short_url).to_a
    if short_urls.empty?
      unique_url = true
    end
  end
  short_url
end

def get_long_url(short_url)
  db_connection do |conn|
    conn.exec("SELECT long_url FROM urls WHERE urls.short_url = '#{short_url}'")
  end
end

def check_long_url(url)
  db_connection do |conn|
    conn.exec("SELECT * FROM urls WHERE urls.long_url = '#{url}'")
  end
end

def valid_url(url)
  errors = []
  if (url =~ URI::regexp) != 0
      errors << "Please enter a valid url."
  end
  errors
end

get '/' do
  @errors = []
  erb :index
end

get '/links/:short' do
  short = params[:short]
  @url_data = get_url_data(short)
  erb :'links/show'
end

get '/:short_url' do
  short_url = params[:short_url]
  if short_url == 'stats'
    @url_stats = get_all_url_stats
    erb :'stats'
  elsif short_url == 'about'
    erb :'about'
  else
    add_clicks(short_url)
    outgoing_link_data = get_long_url(short_url)
    outgoing_link = outgoing_link_data[0]["long_url"]
    redirect "#{outgoing_link}"
  end
end

post '/new' do
  url = params[:url]
  @errors = []
  @errors = valid_url(url)
  if @errors.empty?
    long_url = check_long_url(url).to_a
    if long_url.empty?
      short_url = get_short(url)
      save_link(url, short_url)
    else
      short_url = long_url[0]["short_url"]
    end
    redirect "/links/#{short_url}"
  else
    erb :index
  end
end
