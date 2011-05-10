#!/usr/bin/env ruby
#
#=sdx.rb

SDX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(SDX_ROOT)

$: << SDX_ROOT+"/lib"

require 'sinatra'
require 'haml'
require 'yaml'

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "*.rb"
end

get '/index' do
  @id=nil
  @data=nil
  @id=params["id"] if File.exists?("sessions/#{params["id"]}.yml")
  unless @id.nil?
    @data=YAML::load(File.open("sessions/#{@id}.yml"))
  end
  haml :index
end

get '/email' do
  @id=nil
  @data=nil
  @link=nil
  @id=params["id"] if File.exists?("sessions/#{params["id"]}.yml")
  unless @id.nil?
    @data=YAML::load(File.open("sessions/#{@id}.yml"))
    @link="https://www.rheoli.net/sdx/index?dir=#{@data["direction"]}&id=#{@id}"
  end
  haml :email
end

get '/new' do
  haml :new
end

post '/new' do
  id=rand(999999)
  data={}
  data["email_from"]=params["email_from"]
  data["email_to"]=params["email_to"]
  data["direction"]=params["direction"]
  data["time"]=Time.now.to_i
  File.open("sessions/#{id}.yml","w") do |f|
    f.write(data.to_yaml)
  end
  redirect "/sdx/index?id=#{id}"
end

#=EOF
