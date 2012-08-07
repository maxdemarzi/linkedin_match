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
      register Sinatra::Reloader
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
          '/css/style.css'
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
        redirect to('/matches')
      end
    end

    # View Matches
    get '/matches/?' do
      private_page!
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

    get '/skill/:id' do
      @skill = Skill.load(params[:id])
      haml :'skill/show'
    end

    # View Jobs
    get '/jobs/?' do
      private_page!
      haml :jobs
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