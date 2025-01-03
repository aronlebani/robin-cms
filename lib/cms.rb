# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/namespace'

require_relative 'item'
require_relative 'version'
require_relative 'configuration'

module RobinCMS
	class CMS < Sinatra::Base
		register Sinatra::Flash
		register Sinatra::Namespace

		configure do
			$cfg = ConfigurationParser.new('robin.yaml').freeze

			set :sessions, true
			set :logging, true
			set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(64)
			set :views, File.join(__dir__, 'views')
			set :admin_user, $cfg.admin_username
			set :admin_pass, BCrypt::Password.create($cfg.admin_password)
			set :build_command, $cfg.build_command
			set :base_route, $cfg.base_route
			set :site_name, $cfg.site_name
			set :accent_color, $cfg.accent_color
		end

		namespace "/#{settings.base_route}" do
			helpers do
				def authenticated?(username, guess)
					return false unless username == settings.admin_user

					hashed = BCrypt::Password.new(settings.admin_pass)
					hashed == guess
				end
			end

			get '/login' do
				@auth_layout = true
				erb :login
			end

			post '/login' do
				unless authenticated?(params[:username], params[:password])
					@error = 'Incorrect username or password'
					@auth_layout = true
					return erb :login
				end

				session[:authenticated] = true
				redirect "/#{settings.base_route}/collections"
			end

			get '/logout' do
				session[:authenticated] = nil
				redirect "/#{settings.base_route}/login"
			end

			get '/collections' do
				@collections = $cfg.collections
				@all_items = Item.all

				erb :collections
			end

			get '/collections/:c_id' do
				@collections = $cfg.collections
				@collection = $cfg.collections.find { |c| c.id.to_s == params[:c_id] }
				@items = Item.all(params[:c_id])

				erb :collection
			end

			get '/collections/:c_id/item' do
				@collections = $cfg.collections
				@collection = $cfg.collections.find { |c| c.id.to_s == params[:c_id] }

				if params[:id]
					@item = Item.find(params[:id], params[:c_id])

					return 404 unless @item
				else
					@item = Item.new(nil, params[:c_id])
				end

				erb :collection_item
			end

			post '/collections/:c_id/item' do
				if params[:id]
					@item = Item.find(params[:id], params[:c_id])

					return 404 unless @item

					@item.fields = params
					@item.update
				else
					begin
						Item.create(params[:c_id], params)
					rescue IOError
						@error = 'An item with the same name already exists'
						erb :error
					end
				end

				redirect "/#{settings.base_route}/collections"
			end

			post '/collections/:c_id/item/delete' do
				if params[:id]
					@item = Item.find(params[:id], params[:c_id])

					return 404 unless @item

					@item.delete
				else
					return 404
				end

				redirect "/#{settings.base_route}/collections/#{params[:c_id]}"
			end

			post '/publish' do
				res = system(settings.build_command)

				return 500 unless res

				flash[:success] = true
				redirect "/#{settings.base_route}/collections"
			end

			before /\/collections.*/ do
				unless session[:authenticated]
					redirect "/#{settings.base_route}/login"
				end
			end

			error 404 do
				'Not found.'
			end

			error do
				[500, 'Oops, something went wrong...']
			end
		end
	end
end
