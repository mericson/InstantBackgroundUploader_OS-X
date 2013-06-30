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
  if params['text_upload'] 
    File.open( "/tmp/#{key}.html", "w" ) do |html|
      html.puts params['textupload']
    end    
  elsif params['file_upload']    
    File.open( "/tmp/#{key}.png", "w" ) do |png|
      png.puts params['file_upload'][:tempfile].read
    end
  end
  
  puts "<share_link>http://localhost:4567/#{key}</share_link>"
  return "<share_link>http://localhost:4567/#{key}</share_link>"

end

get '*' do
  base = request.path_info.sub( /^\//, '' )
  if File.exist? "/tmp/#{base}.html" 
    return File.open( "/tmp/#{base}.html" ).read
  elsif File.exist? "/tmp/#{base}.png"
    content_type "image/png"
    return File.open( "/tmp/#{base}.png" ).read
  else
    return "Unable to find share"
  end
end



