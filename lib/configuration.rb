# frozen_string_literal: true

require 'yaml'

module RobinCMS
	class Collection
		ALLOWED_FILETYPES = ['html', 'yaml'].freeze
		IMPLICIT_FIELDS = [
			{ 'label' => 'Title', 'name' => 'title', 'type' => 'input' },
			{ 'label' => 'Collection', 'name' => 'kind', 'type' => 'input', 'hidden' => true },
			{ 'label' => 'Published date', 'name' => 'created_at', 'type' => 'date', 'hidden' => true },
			{ 'label' => 'Last edited', 'name' => 'updated_at', 'type' => 'date', 'hidden' => true }
		].freeze

		attr_reader :id, :label, :location, :filetype, :fields

		def initialize(config)
			@id = config['name'] || ''
			@label = config['label'] || ''
			@location = config['location'] || '/'
			@filetype = config['filetype'] || 'html'
			@fields = config['fields']
				.concat(IMPLICIT_FIELDS)
				.uniq { |f| f['name'] }
				.map { |f| Field.new(f) }

			unless ALLOWED_FILETYPES.include?(@filetype)
				raise TypeError "Invalid filetype #{@filetype}"
			end
		end
	end

	class Field
		ALLOWED_TYPES = ['input', 'richtext', 'date'].freeze

		attr_reader :id, :label, :type, :default, :required, :hidden, :readonly

		def initialize(config)
			@id = config['name'] || ''
			@label = config['label'] || ''
			@type = config['type'] || 'input'
			@default = config['default'] || ''
			@required = config['required'] || false
			@hidden = config['hidden'] || false
			@readonly = config['readonly'] || false

			unless ALLOWED_TYPES.include?(@type)
				raise TypeError "Invalid type #{@type}"
			end
		end
	end

	class Configuration
		FILENAME = 'robin.yaml'.freeze

		attr_reader :content_dir, :collections

		def initialize
			config = YAML.load_file(FILENAME)

			@content_dir = config['content_dir'] || 'content'
			@collections = config['collections']&.map { |c| Collection.new(c) } || []
		end
	end
end
