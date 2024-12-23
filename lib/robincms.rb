# frozen_string_literal: true

require 'sinatra/base'

require_relative 'version'
require_relative 'collection'

module RobinCMS
	class CMS < Sinatra::Base
		set :sessions, true
		set :views, File.join(__dir__, 'views')

		get '/login' do
			erb :login
		end

		post '/login' do
			unless authenticated?(ENV['ADMIN_PASS'], params['password'])
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
			erb :collections
		end

		get '/collections/:c_id' do
			@collection = $cfg.collections.find { |c| c.id == params['c_id'] }
			erb :collection
		end

		get '/collections/:c_id/item' do
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

				@item.fields = params
				@item.update
			else
				# TODO - figure out how to name file. Title field is not required.
				id = make_stub(params['title'])

				if Item.find(id, params['c_id'])
					@error = 'An item with the same name already exists'
					erb :error
				end

				Item.create(id, params['c_id'], fields)
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
