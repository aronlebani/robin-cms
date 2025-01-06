# frozen_string_literal: true

require 'uri'

module RobinCMS
	module Helpers
		def query_params
			URI.decode_www_form(request.query_string).to_h
		end

		def current_collection
			_, base_route, collections, item = request.path_info.split('/')
			item || collections
		end

		module_function :query_params, :current_collection
	end
end
