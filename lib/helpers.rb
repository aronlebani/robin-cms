# frozen_string_literal: true

require 'uri'

require_relative 'constants'

module RobinCMS
	module Helpers
		def query_params
			URI.decode_www_form(request.query_string).to_h
		end

		def current_collection
			_, base_route, collections, item = request.path_info.split('/')
			item || collections
		end

		def status_label(value)
			s = STATUS_OPTIONS.find { |o| o[:value] == value }
			s[:label]
		end

		# For generating safe id's where the id needs to be based on user
		# input. Prevents potential id collisions.
		def safe_id(id, prefix)
			id = id.to_s.gsub('-', '_').gsub(/\W+/, '')
			"__#{prefix}_#{id}"
		end
	end
end
