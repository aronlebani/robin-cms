# frozen_string_literal: true

require 'yaml'

module RobinCMS
	class ParseError < StandardError
		DEFAULT_MSG = 'Error parsing configuration.'

		def initialize(msg = nil)
			msg = if msg then "#{DEFAULT_MSG} #{msg}" else DEFUALT_MSG end
			super(msg)
		end
	end

	class CollectionParser
		include RobinCMS

		ALLOWED_FILETYPES = ['html', 'yaml', nil].freeze
		REQUIRED_ATTRS = [:name, :label].freeze
		IMPLICIT_FIELDS = [
			{ :label => 'Title', :name => 'title', :type => 'input' },
			{ :label => 'Collection', :name => 'kind', :type => 'input', :hidden => true },
			{ :label => 'Published date', :name => 'created_at', :type => 'date', :hidden => true },
			{ :label => 'Last edited', :name => 'updated_at', :type => 'date', :hidden => true }
		].freeze

		attr_reader :id, :label, :label_singular, :location, :filetype,
			:description, :fields

		def initialize(config)
			unless ALLOWED_FILETYPES.include?(config[:filetype])
				raise ParseError, "Invalid filetype #{config[:filetype]}."
			end

			unless REQUIRED_ATTRS.all? { |attr| config.keys.include?(attr) }
				raise ParseError, "Collection missing one or more required attributes #{REQUIRED_ATTRS.join(', ')} for collection #{config[:name]}."
			end

			if config[:fields].filter { |f| f[:type] == 'richtext' }.length > 1
				raise ParseError, 'Only one richtext field per collection is permitted.'
			end

			@id = config[:name].to_sym
			@label = config[:label]
			@label_singular = config[:label_singular] || config[:label]
			@location = config[:location] || '/'
			@filetype = config[:filetype] || 'html'
			@description = config[:description]
			@fields = (config[:fields] || [])
				.concat(IMPLICIT_FIELDS)
				.uniq { |f| f[:name] }
				.sort { |fa, fb| fa[:name] == 'title' ? -1 : fb[:name] == 'title' ? 1 : 0 }
				.map { |f| FieldParser.new(f) }
		end
	end

	class FieldParser
		include RobinCMS

		ALLOWED_TYPES = ['input', 'richtext', 'date'].freeze
		REQUIRED_ATTRS = [:name, :label, :type].freeze

		attr_reader :id, :label, :type, :default, :required, :hidden, :readonly

		def initialize(config)
			unless ALLOWED_TYPES.include?(config[:type])
				raise ParseError, "Invalid field type #{config[:type]}."
			end

			unless REQUIRED_ATTRS.all? { |attr| config.keys.include?(attr) }
				raise ParseError, "Field missing one or more required attributes #{REQUIRED_ATTRS.join(', ')} for field #{config[:name]}."
			end

			@id = config[:name].to_sym
			@label = config[:label]
			@type = config[:type]
			@default = config[:default] || ''
			@required = config[:required] || false
			@hidden = config[:hidden] || false
			@readonly = config[:readonly] || false
		end
	end

	class ConfigurationParser
		include RobinCMS

		attr_reader :site_name, :content_dir, :admin_username, :admin_password,
			:build_command, :base_route, :accent_color, :collections

		def initialize(filename)
			config = YAML.load_file(filename, symbolize_names: true)

			if !config[:collections] || config[:collections].length == 0
				raise ParseError, "At least one collection is required."
			end

			@site_name = config[:site_name] || 'RobinCMS'
			@content_dir = config[:content_dir] || 'content'
			@admin_username = ENV['ADMIN_USER'] || config[:admin_username] || 'admin'
			@admin_password = ENV['ADMIN_PASS'] || config[:admin_password] || 'admin'
			@build_command = config[:build_command] || nil
			@base_route = config[:base_route] || 'cms'
			@accent_color = config[:accent_color] || '#4493f8'

			@collections = config[:collections].map { |c| CollectionParser.new(c) }
		end
	end
end
