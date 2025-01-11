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

	class FieldParser
		include RobinCMS

		ALLOWED_TYPES = [
			'text', 'richtext', 'date', 'hidden', 'number', 'color', 'email',
			'url', 'select'
		].freeze
		REQUIRED_ATTRS = [:name, :label, :type].freeze

		attr_reader :id, :label, :type, :default, :required, :readonly, :options

		def initialize(config)
			unless ALLOWED_TYPES.include?(config[:type])
				raise ParseError, "Invalid field type #{config[:type]}."
			end

			unless REQUIRED_ATTRS.all? { |attr| config.keys.include?(attr) }
				raise ParseError, "Field missing one or more required attributes #{REQUIRED_ATTRS.join(', ')} for field #{config[:name]}."
			end

			# TODO - validate options array

			@id = config[:name].to_sym
			@label = config[:label]
			@type = config[:type]
			@default = config[:default] || ''
			@required = config[:required] || false
			@readonly = config[:readonly] || false
			@options = config[:options] || []
		end
	end

	class CollectionParser
		include RobinCMS

		ALLOWED_FILETYPES = ['html', 'yaml', nil].freeze
		REQUIRED_ATTRS = [:name, :label].freeze
		IMPLICIT_FIELDS = [
			{ :label => 'Title', :name => 'title', :type => 'text' },
			{ :label => 'Collection', :name => 'kind', :type => 'hidden' },
			{ :label => 'Published date', :name => 'created_at', :type => 'hidden' },
			{ :label => 'Last edited', :name => 'updated_at', :type => 'hidden' },
			{
				:label => 'Status',
				:name => 'status',
				:type => 'select',
				:default => 'draft',
				:options => [{
					:label => 'Draft',
					:value => 'draft'
				}, {
					:label => 'Published',
					:value => 'published'
				}]
			}
		].freeze

		attr_reader :id, :label, :label_singular, :location, :filetype,
			:description, :can_delete, :can_create, :fields

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
			@can_create = config[:can_create].nil? ? true : config[:can_create]
			@can_delete = config[:can_delete].nil? ? true : config[:can_delete]
			@fields = (config[:fields] || [])
				.concat(IMPLICIT_FIELDS)
				.uniq { |f| f[:name] }
				.map { |f| FieldParser.new(f) }
		end

		def ordered_fields
			title_field = @fields.find { |f| f.id == :title }
			status_field = @fields.find { |f| f.id == :status }
			remaining_fields = @fields.filter { |f| f.id != :title && f.id != :status }

			[title_field, status_field, *remaining_fields]
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
			@base_route = config[:base_route] || 'admin'
			@accent_color = config[:accent_color] || '#fd8a13'

			@collections = config[:collections].map { |c| CollectionParser.new(c) }
		end
	end
end
