# encoding: utf-8
cbm_dir = File.expand_path('../cbm', __FILE__)
$:.unshift(cbm_dir) unless $:.include? cbm_dir

require 'sidekiq/middleware/server/unique_jobs'
require 'sidekiq/middleware/client/unique_jobs'

Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] }
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::UniqueJobs
  end
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] }
  config.client_middleware do |chain|
    chain.add Sidekiq::Middleware::Client::UniqueJobs
  end
end

LinkedIn.configure do |config|
  config.token = ENV['CONSUMER_KEY']
  config.secret = ENV['CONSUMER_SECRET']
  config.default_profile_fields = ['id', 'first-name', 'last-name', 'educations', 'positions', 'skills']
end


require 'models/user'
require 'jobs/import_linkedin_profile'
