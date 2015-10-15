require 'dotenv'
Dotenv.load
require 'dashing'
require 'rack-flash'
require 'warden'
require_relative 'lib/models'

configure do
  # Load configuration varaibles from .env file (if it exists)

  # The auth token used by external clients to get API access to the
  # dashing widgets.
  set :auth_token, ENV["DASHING_AUTH_TOKEN"] || "foobar"

  helpers do
    # Protects access to pages and redirects to the autentication page
    # if not already authenticated.
    def protected!
      # if not production?
      #   return
      # end

      if User.count == 0
        redirect '/auth/createuser'
      else
        env['warden'].authenticate!
      end
    end
  end

  # Store the authenticated user name in session state
  use Rack::Session::Cookie, :secret => ENV["SESSION_SECRET"]

  # Flash
  use Rack::Flash

  # Authentication with Warden
  use Warden::Manager do |config|
    config.serialize_into_session { |user| user.id }
    config.serialize_from_session { |id| User.get(id) }
    config.scope_defaults :default,
      strategies: [:password],
      action: 'auth/unauthenticated'
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env, opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['username'] and params['password']
    end

    def authenticate!
      user = User.first(username: params['username'])
      if not user.nil? and user.authenticate(params['password'])
        success!(user)
      else
        fail!("Incorrect username or password. Please try again.")
      end
    end
  end

  get '/auth/createuser' do
    if User.count > 0
      redirect '/'
    else
      erb :createuser
    end
  end

  post '/auth/createuser' do
    if User.count > 0
      redirect '/'
    end
    if not params[:username] or not params[:password]
      redirect '/auth/createuser'
    end
    user = User.create(
      :username => params[:username],
      :password => params[:password])
    redirect '/'
  end
 
  get '/auth/login' do
    if User.count <= 0
      redirect '/auth/createuser'
    end
    if env['warden'].authenticated?
      redirect '/'
    end
    erb :login
  end

  post '/auth/login' do
    env['warden'].authenticate!
    redirect '/'
  end

  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    redirect '/'
  end

  post '/auth/unauthenticated' do
    flash[:login] = env['warden'].message
    redirect '/auth/login'
  end

  # Restore the event history on load
  savedHistory = Setting.get('history')
  if savedHistory
    set :history, JSON.parse(savedHistory.value)
  end

  # Upong exiting, write the event history to persistent storage
  at_exit do
    savedHistory = Setting.first_or_create(:name => 'history')
    savedHistory.value = JSON.generate(settings.history)
    savedHistory.save
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application