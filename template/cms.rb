# frozen_string_literal: true

require 'dotenv'
require 'securerandom'
require 'sinatra'
require 'robin-cms'

Dotenv.load

set :logging, true
set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(64)

use RobinCMS

get '/' do
  'Hello, world!'
end
