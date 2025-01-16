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
			{ :label => 'Status', :id => 'status', :type => 'select', :default => 'draft', :options => [
				{ :label => 'Draft', :value => 'draft' },
				{ :label => 'Published', :value => 'published' }
			] }
		].freeze

		class ValidationError < StandardError; end

		class << self
			def parse(filename)
				config = YAML.load_file(filename, symbolize_names: true)

				schema_file = File.join(__dir__, 'configuration-schema.json')
				schema = JSON.parse(File.read(schema_file))
				JSON::Validator.validate!(schema, config)

				validate_custom!(config)

				config = with_default_values(config)
				config = with_implicit_fields(config)
				config = with_environment(config)
				config.freeze
			end

			private

			def with_default_values(config)
				config[:collections] = config[:collections].map do |collection|
					collection[:fields] = collection[:fields].map do |field|
						DEFAULT_FIELD_CONFIG.merge(field)
					end
					DEFAULT_COLLECTION_CONFIG.merge(collection)
				end
				DEFAULT_CONFIG.merge(config)
			end

			def with_implicit_fields(config)
				config[:collections].each do |collection|
					collection[:fields] = collection[:fields]
						.concat(IMPLICIT_FIELDS)
						.uniq { |f| f[:id] }
				end

				config
			end

			def with_environment(config)
				env_admin_password =
					ENV.has_key?('ADMIN_PASS') && ENV.fetch('ADMIN_PASS')
				env_admin_username =
					ENV.has_key?('ADMIN_PASS') && ENV.fetch('ADMIN_USER')

				config[:admin_password] ||= env_admin_password
				config[:admin_username] ||= env_admin_username

				config
			end

			# Provides custom validation which can't be expressed using the
			# Json Schema standard.
			def validate_custom!(config)
				config[:collections].each do |c|
					if c[:fields].filter { |f| f[:type] == 'richtext' }.length > 1
						raise ValidationError, 'Only one richtext field per collection allowed'
					end
				end
			end
		end
	end
end
