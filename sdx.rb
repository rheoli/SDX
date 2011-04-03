#!/usr/bin/env ruby
#
#=sdx.rb

SDX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(SDX_ROOT)

$: << SDX_ROOT+"/lib"

require 'sinatra'
require 'haml'

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "*.rb"
end

get '/' do
  haml :index
end

get '/new' do
  haml :new
end

#=EOF
