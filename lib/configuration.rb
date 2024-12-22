# frozen_string_literal: true

require 'yaml'

module RobinCMS
  class Collection
    ALLOWED_FILETYPES = ['html', 'yaml']

    attr_reader :id, :label, :location, :filetype, :fields

    def initialize(config)
      @id = config['name'] || ''
      @label = config['label'] || ''
      @location = config['location'] || '/'
      @filetype = config['filetype'] || 'html'
      @fields = config['fields']&.map { |f| Field.new(f) } || []

      unless ALLOWED_FILETYPES.include?(@filetype)
        raise TypeError "Invalid filetype #{@filetype}"
      end
    end
  end

  class Field
    ALLOWED_TYPES = ['input', 'richtext', 'date']

    attr_reader :id, :label, :type, :default, :required, :hidden

    def initialize(config)
      @id = config['name'] || ''
      @label = config['label'] || ''
      @type = config['type'] || 'input'
      @default = config['default'] || ''
      @required = config['required'] || false
      @hidden = config['hidden'] || false

      unless ALLOWED_TYPES.include?(@type)
        raise TypeError "Invalid type #{@type}"
      end
    end
  end

  class Configuration
    FILENAME = 'robin.yaml'

    attr_reader :content_dir, :collections

    def initialize
      config = YAML.load_file(FILENAME)

      @content_dir = config['content_dir'] || 'content'
      @collections = config['collections']&.map { |c| Collection.new(c) } || []
    end
  end

  $cfg = Configuration.new.freeze
end
