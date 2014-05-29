require 'sinatra'
require 'uri'
require 'pg'

def db_connection
  begin
    connection = PG::Connection.open(dbname: 'urls')

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

def get_short(long_url)
  letters = (('a'..'z').to_a + ('A'..'Z').to_a)
  short_url = letters.sample(6).join
  #check if it exists already, return current version
  # db_connection do |conn|
  #   conn.exec(sql)
  # end
  short_url
end

def get_long_url(short_url)
  db_connection do |conn|
    conn.exec("SELECT long_url FROM urls WHERE urls.short_url = '#{short_url}'")
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
  @url_data = get_url_data(short).to_a
  erb :'links/show'
end

get '/:short_url' do
  short_url = params[:short_url]
  if short_url == 'stats'
    @url_stats = get_all_url_stats.to_a
    erb :'stats'
  elsif short_url == 'about'
    erb :'about'
  else
    add_clicks(short_url)
    outgoing_link_data = get_long_url(short_url).to_a
    outgoing_link = outgoing_link_data[0]["long_url"]
    redirect "#{outgoing_link}"
  end
end

post '/new' do
  url = params[:url]
  @errors = []
  @errors = valid_url(url)
  if @errors.empty?
    short_url = get_short(url)
    save_link(url, short_url)
    redirect "/links/#{short_url}"
  else
    erb :index
  end
end
