# frozen_string_literal: true

require 'json'
require 'json-schema'
require 'ostruct'
require 'yaml'

module RobinCMS
	module Configuration
		DEFAULT_CONFIG = {
			:site_name => 'RobinCMS',
			:content_dir => 'content',
			:admin_username => 'admin',
			:admin_password => 'admin',
			:build_command => nil,
			:accent_color => '#fd8a13'
		}.freeze

		DEFAULT_COLLECTION_CONFIG = {
			:location => '/',
			:filetype => 'html',
			:description => '',
			:can_create => true,
			:can_delete => true,
			:fields => []
		}.freeze

		DEFAULT_FIELD_CONFIG = {
			:type => 'text',
			:default => nil,
			:required => false,
			:readonly => false
		}.freeze

		IMPLICIT_FIELDS = [
			{ :label => 'Title', :id => 'title', :type => 'text' },
			{ :label => 'Collection', :id => 'kind', :type => 'hidden' },
			{ :label => 'Published date', :id => 'created_at', :type => 'hidden' },
			{ :label => 'Last edited', :id => 'updated_at', :type => 'hidden' },
			{
				:label => 'Status',
				:id => 'status',
				:type => 'select',
				:default => 'draft',
				:options => [
					{ :label => 'Draft', :value => 'draft' },
					{ :label => 'Published', :value => 'published' }
				]
			}
		].freeze

		class ValidationError < StandardError
			def initialize(message)
				super(message)
			end
		end

		def merge_default_values(config)
			config[:collections] = config[:collections].map do |collection|
				collection[:fields] = collection[:fields].map do |field|
					DEFAULT_FIELD_CONFIG.merge(field)
				end
				DEFAULT_COLLECTION_CONFIG.merge(collection)
			end
			DEFAULT_CONFIG.merge(config)
		end

		def merge_implicit_fields(config)
			config[:collections].each do |collection|
				collection[:fields] = collection[:fields]
					.concat(IMPLICIT_FIELDS)
					.uniq { |f| f[:id] }
			end

			config
		end

		def merge_environment(config)
			env_admin_password =
				ENV.has_key?('ADMIN_PASS') && ENV.fetch('ADMIN_PASS')
			env_admin_username =
				ENV.has_key?('ADMIN_PASS') && ENV.fetch('ADMIN_USER')

			config[:admin_password] ||= env_admin_password
			config[:admin_username] ||= env_admin_username

			config
		end

		def validate_custom!(config)
			config[:collections].each do |c|
				if c[:fields].filter { |f| f[:type] == 'richtext' }.length > 1
					raise ValidationError, 'Only one richtext field per collection allowed'
				end
			end
		end

		def parse(filename)
			config = YAML.load_file(filename, symbolize_names: true)

			schema_file = File.join(__dir__, 'configuration_schema.json')
			schema = JSON.parse(File.read(schema_file))
			JSON::Validator.validate!(schema, config)

			validate_custom!(config)

			config = merge_default_values(config)
			config = merge_implicit_fields(config)
			config = merge_environment(config)
			config.freeze
		end

		module_function :parse, :merge_default_values, :merge_implicit_fields,
			:merge_environment, :validate_custom!
	end
end
