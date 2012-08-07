# encoding: utf-8
require 'sinatra/assetpack'
require 'rack-flash'

module CBM
  class App < Sinatra::Base

    configure do
      set :session_secret, (ENV['SESSION_SECRET'] || "Vfnnp Nfvzbi jebgr gur Sbhaqngvba Frevrf juvpu vf ner zl snibevgr obbxf.")
      set :key, (ENV['CONSUMER_KEY'] || "udmw68f7t3om")
      set :secret, (ENV['CONSUMER_SECRET'] || "41OHptpc1oFOnI9n")
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload '**/*.rb'
    end

    register Sinatra::AssetPack

    use Rack::Session::Cookie , :secret => CBM::App.settings.session_secret

    use OmniAuth::Builder do
      provider :linkedin, CBM::App.settings.key, CBM::App.settings.secret
    end

    use Rack::Flash

    Dir.glob(File.dirname(__FILE__) + '/helpers/*', &method(:require))
    helpers CBM::App::Helpers

    assets {
      serve '/js/app', from: '/assets/coffee'
      serve '/css', from: '/assets/css'

      js :lib, '/js/lib.js', [
          '/js/lib/jquery.js',
          '/js/lib/jquery-ui-custom.js'
      ]

      js :app, '/js/app.js', [
          '/js/app/app.js',
          '/js/app/helpers.js',
          '/js/app/master.js'
      ]

      css :app, '/css/app.css', [
          '/css/reset.css',
          '/bootstrap/css/bootstrap.css',
          '/bootstrap/css/bootstrap-responsive.css',
          '/css/style.css',
      ]

      css :ie, '/css/ie.css', [
          '/css/ie.css'
      ]

      js_compression :uglify
    }

    before do
      if request.path_info.index("/css") == 0 || request.path_info.index("/js") == 0
        #disable session and delete all request cookies for js/css - allows proxy caching
        disable :sessions
        request.cookies.clear
      else
      end
    end

    # Homepage
    get '/' do
      if current_user.nil?
        haml :index, :layout => :layout
      else
        redirect to("/user/#{current_user.uid}/matches")
      end
    end

    # View Matches
    get '/user/:id/matches' do
      private_page!
      @user = user(params[:id])
      haml :matches
    end

    # Users
    get '/user/:id' do
      @user = user(params[:id])
      haml :'user/show'
    end

    get '/user/:id/connections' do
      @user = user(params[:id])
      haml :'user/index'
    end

    get '/user/:id/skills' do
      @user = user(params[:id])
      haml :'skill/index'
    end

    get '/user/:id/locations' do
      @user = user(params[:id])
      haml :'location/index'
    end

    get '/user/:id/location/new' do
      @user = user(params[:id])
      haml :'location/new'
    end

    post '/user/:id/location/create' do
      @user = user(params[:id])
      location = (params[:city_id] || params[:region_id] || params[:country_id])
      $neo_server.create_unique_relationship("has_location_index", "user_location", "#{@user.neo_id}-#{location}", "has_location", @user, location)
      redirect to("/user/#{params[:id]}/locations")
    end

    # Location
    get '/location/:id' do
      @location = CBM::Location.load(params[:id])
      haml :'location/show'
    end

    # Skills
    get '/skill/:id' do
      @skill = Skill.load(params[:id])
      haml :'skill/show'
    end

    # Jobs
    get '/jobs' do
      @jobs = Criteria.all
      haml :'job/index'
    end

    get '/job/new' do
      @jobs = Criteria.all
      @locations = Location.available
      @skills = Skill.available
      haml :'job/new'
    end

    post '/job/create' do
      uid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, "cb_match.heroku.com").to_s
      CBM::Criteria.create(uid, params[:name], params[:formula])
      reditect to('/jobs')
    end

    # Typeahead
    get '/typeahead/cities/?' do
      Location.cities(params[:q]).collect do |city|
        {:id => city[0], :name => city[1]}
      end.to_json
    end

    get '/typeahead/regions/?' do
      Location.regions(params[:q]).collect do |region|
        {:id => region[0], :name => region[1]}
      end.to_json
    end

    get '/typeahead/countries/?' do
      Location.countries(params[:q]).collect do |country|
        {:id => country[0], :name => country[1]}
      end.to_json
    end

    # Authentication
    ['get', 'post'].each do |method|
      send(method, "/auth/:provider/callback") do
        user = CBM::User.create_with_omniauth(env['omniauth.auth'])
        session[:uid] = user.uid.to_s

        redirect to(session[:redirect_url] || "/user/#{session[:uid]}")
        session[:redirect_url] = nil
      end
    end

    get '/auth/failure/?' do
      raise 'auth error'
    end

    get '/logout/?' do
      session.clear
      redirect to('/')
    end

    # Static Pages
    get '/welcome/?' do
      private_page!

      @start_url = session[:redirect_url] || '/matches'
      session[:redirect_url] = nil

      haml :welcome
    end

    get '/about/?' do
      haml :'static/about'
    end

    get '/contact/?' do
      haml :'static/contact'
    end

    get '/terms' do
      haml :'static/terms'
    end

    get '/privacy' do
      haml :'static/privacy'
    end

  end
end