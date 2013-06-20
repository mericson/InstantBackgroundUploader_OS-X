#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'pp'

get '/' do 
  puts "Root"
  return "Hi there"
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
#   params.each do |k,v|
#     puts "---------"
#     puts k
#     puts " #{v}"
#     puts ""
#   end
end

get '*' do

end



