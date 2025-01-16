# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/namespace'

require_relative 'item'
require_relative 'helpers'
require_relative 'version'
require_relative 'configuration'

module RobinCMS
	class CMS < Sinatra::Base
		register Sinatra::Flash
		register Sinatra::Namespace

		configure do
			$cfg = Configuration.parse('robin.yaml')

			set :sessions, true
			set :logging, true
			set :session_secret, (ENV.has_key?('SESSION_SECRET') && ENV.fetch('SESSION_SECRET')) || SecureRandom.hex(64)
			set :views, File.join(__dir__, 'views')
			set :admin_user, $cfg[:admin_username]
			set :admin_pass, BCrypt::Password.create($cfg[:admin_password])

			# TODO: reference these directly from config instead of putting them
			# in settings.
			set :build_command, $cfg[:build_command]
			set :base_route, $cfg[:base_route]
			set :site_name, $cfg[:site_name]
			set :accent_color, $cfg[:accent_color]
		end

		helpers do
			include RobinCMS::Helpers

			def authenticated?(username, guess)
				return false unless username == settings.admin_user

				hashed = BCrypt::Password.new(settings.admin_pass)
				hashed == guess
			end
		end

		namespace "/#{settings.base_route}" do
			get '/login' do
				@auth_layout = true
				erb :login
			end

			post '/login' do
				unless authenticated?(params[:username], params[:password])
					flash[:error] = 'Incorrect username or password'
					redirect "/#{settings.base_route}/login"
				end

				session[:authenticated] = true
				redirect "/#{settings.base_route}/collections"
			end

			get '/logout' do
				session[:authenticated] = nil
				redirect "/#{settings.base_route}/login"
			end

			get '/collections' do
				@collections = $cfg[:collections]
				@all_items = Item.all

				erb :collections
			end

			get '/collections/:c_id' do
				@collections = $cfg[:collections]
				@collection = $cfg[:collections].find { |c| c[:id] == params[:c_id] }
				@items = Item.where(
					collection_id: params[:c_id],
					sort: params[:sort],
					status: params[:status],
					q: params[:q]
				)

				erb :collection
			end

			get '/collections/:c_id/item' do
				@collections = $cfg[:collections]
				@collection = $cfg[:collections].find { |c| c[:id] == params[:c_id] }

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
						flash[:error] = 'An item with the same name already exists'
						redirect "/#{settings.base_route}/collections/#{params[:c_id]}/item"
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
