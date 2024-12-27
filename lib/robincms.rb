# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra/base'

require_relative 'item'
require_relative 'version'
require_relative 'configuration'

module RobinCMS
	class CMS < Sinatra::Base
		helpers do
			def authenticated?(hash, guess)
				hashed = BCrypt::Password.new(hash)
				hashed == guess
			end
		end

		configure do
			set :sessions, true
			set :logging, true
			set :session_secret, SecureRandom.hex(64) # TODO - make this configurable
			set :views, File.join(__dir__, 'views')
			set :admin_pass, BCrypt::Password.create('admin') # TODO - make this configurable
			# TODO - configurable base route
			# TODO - handle duplicate filenames

			$cfg = ConfigurationParser.new('robin.yaml').freeze # TODO - make this configurable
		end

		get '/login' do
			erb :login, layout: false
		end

		post '/login' do
			unless authenticated?(settings.admin_pass, params['password'])
				@error = 'Incorrect username or password'
				erb :login
			end

			session['authenticated'] = true
			redirect '/collections'
		end

		get '/logout' do
			session['authenticated'] = nil
			redirect '/login'
		end

		get '/collections' do
			@collections = $cfg.collections

			erb :collections
		end

		get '/collections/:c_id' do
			@collections = $cfg.collections
			@collection = $cfg.collections.find { |c| c.id == params['c_id'] }
			@items = Item.all(params['c_id'])

			erb :collection
		end

		get '/collections/:c_id/item' do
			@collections = $cfg.collections
			@collection = $cfg.collections.find { |c| c.id == params['c_id'] }

			if params['id']
				@item = Item.find(params['id'], params['c_id'])

				return 404 unless @item
			else
				@item = Item.new(nil, params['c_id'])
			end

			erb :collection_item
		end

		post '/collections/:c_id/item' do
			if params['id']
				@item = Item.find(params['id'], params['c_id'])

				return 404 unless @item

				@item.fields = params.to_h
				@item.update
			else
				begin
					Item.create(params['c_id'], params)
				rescue IOError
					@error = 'An item with the same name already exists'
					erb :error
				end
			end

			redirect '/collections'
		end

		post '/collections/:c_id/delete' do
			if params['id']
				@item = Item.find(params['id'], params['collection_id'])

				return 404 unless @item

				@item.delete
			else
				return 404
			end

			redirect '/collections'
		end

		post '/publish' do
			# TODO - make build command configurable
			res = system('nanoc compile')

			return 500 unless res
		end

		before /\/collections/ do
			redirect '/login' unless session['authenticated']
		end

		error 404 do
			'Not found.'
		end

		error do
			[500, 'Oops, something went wrong...']
		end
	end
end
