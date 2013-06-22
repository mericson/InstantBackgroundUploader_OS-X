#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'pp'

get '/' do 
  puts "Root"
  return "Hi there"
end

get '/favicon.ico' do
end

get '/signup-form' do 
  puts 'Show signup form'
  puts params.to_s  
end

get '/process-signup-form' do
  puts 'Process signup form'
  puts params.to_s  
end

post '/receive' do 
  puts "Processing the file"
  pp params
  
  key = Time.now.tv_usec
  
  File.open( "#{key}.png", "w" ) do |png|
    png.puts params['fileupload'][:tempfile].read
  end
  
  puts "<image_link>http://localhost:4567/#{key}</image_link>"
  return "<image_link>http://localhost:4567/#{key}</image_link>"

end

get '*' do
  base = request.path_info.sub( /^\//, '' )
  content_type "image/png"
  png = File.open( "#{base}.png" ).read
end



