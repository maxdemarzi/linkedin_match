# -*- encoding: utf-8 -*-
ENV['RACK_ENV'] ||= 'development'

require 'bundler'
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

require 'sinatra/config_file'
require 'sinatra/reloader' if development?
require 'sidekiq/web'
require './lib/cbm'
require './cbm_api'
require './cbm_app'

map '/' do
  run CBM::App
end

map '/api' do
  run CBM::Api
end

map '/sidekiq' do
  run Sidekiq::Web
end