# frozen_string_literal: true

require 'sinatra'

require_relative '../lib/robincms'

set :logging, true
set :session_secret, 'secret'

use RobinCMS

get '/' do
  'Hello, world!'
end

run Sinatra::Application
