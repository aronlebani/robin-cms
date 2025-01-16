# frozen_string_literal: true

require 'uri'

require_relative 'constants'

module RobinCMS
	module Helpers
		def query_params
			URI.decode_www_form(request.query_string).to_h
		end

		def current_collection
			_, _, collections, item = request.path_info.split('/')
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

		def ordered_fields(collection)
			fields = collection[:fields]

			title_field = fields.find { |f| f[:id] == 'title' }
			status_field = fields.find { |f| f[:id] == 'status' }
			remaining_fields = fields.filter { |f| f[:id] != 'title' && f[:id] != 'status' }

			[title_field, status_field, *remaining_fields]
		end
	end
end
