require 'sinatra'
require './lib/link.rb'

configure :production do
  Link.establish_connection({
    host: ENV['DB_HOST'],
    dbname: ENV['DB_DATABASE'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  })
end

configure :development do
  Link.establish_connection({
    dbname: ENV['DB_DATABASE']
  })
end

get '/' do
  erb :index
end

# get '/links/:short_url' do
#   @link = Link.where(short_url: params[:short_url]).first
#   erb :show
# end

# get '/stats' do
#   @links = Link.all
#   erb :stats
# end

get '/about' do
  erb :about
end

get '/:short_url' do
  redirect "http://dankleiman.github.io/blog/2014/05/30/buying-a-mongolian-website/"
end

# get '/:short_url' do
#   pass if %w[stats about].include?(params[:short_url])

#   if link = Link.where(short_url: params[:short_url]).first
#     link.update_attributes(clicks: link.clicks + 1)
#     redirect link.long_url
#   else
#     @error = 'Invalid url.'
#     erb :index
#   end
# end
post '/new' do
  redirect "http://dankleiman.github.io/blog/2014/05/30/buying-a-mongolian-website/"
end
# post '/new' do
#   @error = (Link.valid_url?(params[:url]) ? nil : 'Please enter a valid url.')
#   if @error.nil?
#     link = Link.where(long_url: params[:url]).first
#     link ||= Link.create(long_url: params[:url], short_url: Link.generate_short, clicks: 0)
#     redirect "/links/#{link.short_url}"
#   else
#     erb :index
#   end
# end
