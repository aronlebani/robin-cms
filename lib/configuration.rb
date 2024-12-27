# frozen_string_literal: true

require 'yaml'

module RobinCMS
	class ParseError < StandardError
		def initialize(msg = 'Error parsing configuration')
			super(msg)
		end
	end

	class CollectionParser
		include RobinCMS

		ALLOWED_FILETYPES = ['html', 'yaml'].freeze
		REQUIRED_ATTRS = ['name', 'label'].freeze
		IMPLICIT_FIELDS = [
			{ 'label' => 'Title', 'name' => 'title', 'type' => 'input' },
			{ 'label' => 'Collection', 'name' => 'kind', 'type' => 'input', 'hidden' => true },
			{ 'label' => 'Published date', 'name' => 'created_at', 'type' => 'date', 'hidden' => true },
			{ 'label' => 'Last edited', 'name' => 'updated_at', 'type' => 'date', 'hidden' => true }
		].freeze

		attr_reader :id, :label, :location, :filetype, :fields

		def initialize(config)
			unless ALLOWED_FILETYPES.include?(config['filetype'])
				raise ParseError, "Invalid filetype #{config['filetype']}"
			end

			unless REQUIRED_ATTRS.all? { |attr| config.keys.include?(attr) }
				raise ParseError, "Missing one or more required attributes #{REQUIRED_ATTRS.join(', ')} for collection #{config['name']}"
			end

			@id = config['name']
			@label = config['label']
			@location = config['location'] || '/'
			@filetype = config['filetype'] || 'html'
			@fields = (config['fields'] || [])
				.concat(IMPLICIT_FIELDS)
				.uniq { |f| f['name'] }
				.map { |f| FieldParser.new(f) }
		end
	end

	class FieldParser
		include RobinCMS

		ALLOWED_TYPES = ['input', 'richtext', 'date'].freeze
		REQUIRED_ATTRS = ['name', 'label', 'type'].freeze

		attr_reader :id, :label, :type, :default, :required, :hidden, :readonly

		def initialize(config)
			unless ALLOWED_TYPES.include?(config['type'])
				raise ParseError, "Invalid type #{config['type']}"
			end

			unless REQUIRED_ATTRS.all? { |attr| config.keys.include?(attr) }
				raise ParseError, "Missing one or more required attributes #{REQUIRED_ATTRS.join(', ')} for field #{config['name']}"
			end

			@id = config['name'] || ''
			@label = config['label'] || ''
			@type = config['type'] || 'input'
			@default = config['default'] || ''
			@required = config['required'] || false
			@hidden = config['hidden'] || false
			@readonly = config['readonly'] || false
		end
	end

	class ConfigurationParser
		include RobinCMS

		attr_reader :content_dir, :collections

		def initialize(filename)
			config = YAML.load_file(filename)

			if !config['collections'] || config['collections'].length == 0
				raise ParseError, "At least one collection is required"
			end

			@content_dir = config['content_dir'] || 'content'
			@collections = config['collections'].map { |c| CollectionParser.new(c) }
		end
	end
end
