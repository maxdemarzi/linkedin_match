module CBM
  class Api < Sinatra::Base

    configure do
      set :session_secret, (ENV['SESSION_SECRET'] || "Vfnnp Nfvzbi jebgr gur Sbhaqngvba Frevrf juvpu vf ner zl snibevgr obbxf.")
      set :key, (ENV['CONSUMER_KEY'] || "udmw68f7t3om")
      set :secret, (ENV['CONSUMER_SECRET'] || "41OHptpc1oFOnI9n")
      set :redis_url, (ENV['REDISTOGO_URL'] || "redis://127.0.0.1:6379/" )
      set :neo, Neography::Rest.new
    end

    configure :development do
      register Sinatra::Reloader
    end

    before do
      content_type :json
      headers \
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS, HEAD",
        "Access-Control-Allow-Headers" => "Content-Type"
    end
    set :environment, :production

    error do
      e = env['sinatra.error']
      message = e.message.nil? ? "Oh oh... something went wrong." : e.message

      status case e.class
               when CBM::Error::User::OmniAuthHashRequired,
                   CBM::Error::User::OmniAuthInvalidProvider,
                   CBM::Error::User::OmniAuthHashCredentialsRequired,
                   CBM::Error::User::OmniAuthHashInfoRequired,
                   CBM::Error::User::OmniAuthHashInfoEmailRequired,
                   CBM::Error::User::OmniAuthHashUIDRequired,
                   CBM::Error::User::TokenRequired,
                   CBM::Error::User::TokenInvalid

                 401
               when CBM::Error::User::AuthenticationError,
                   CBM::Error::User::UnauthorizedToAddAccountError
                 403
               when CBM::Error::User::NotFoundError
                 404
               else
                 400
             end
      Airbrake.notify(e) unless (development? || test?)
      {:error => message, :type => e.class.name}.to_json
    end

    options '*' do

    end

    def current_user
      token = params[:t] || params[:token]
      raise CBM::Error::User::TokenRequired if token.nil?
      user = CBM::User.where(:token => token).first
      raise CBM::Error::User::TokenInvalid if user.nil?

      user
    end

    def page
      (params[:p] || params[:page] || 1).to_i
    end

    get '/' do
      'CBM API'
    end

    get '/user/:id/values' do
      CBM::User.find_by_uid(params[:id]).values.to_json
    end

    get '/friends/:id' do
      CBM::User.find_by_uid(params[:id]).connections.to_json
    end

    get '/wipe' do
      cypher = "START n=node(*)
                MATCH n-[r?]-()
                WHERE ID(n) <> 0
                DELETE n,r"
      CBM::Api.settings.neo.execute_query(cypher)
      'Database wiped!'
    end

  end
end