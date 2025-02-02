# frozen_string_literal: true

require_relative 'constants'

module RobinCMS
	class Item
		attr_reader :id, :collection, :attributes

		def initialize(id, collection_id, attributes = {})
			@id = id
			@attributes = attributes
			@collection = $cfg[:collections].find { |c| c[:id] == collection_id }

			@attributes[:kind] = collection_id
		end

		def attributes=(attributes)
			@attributes = attributes.to_h.transform_keys(&:to_sym)
		end

		def save
			raise IOError, 'An item with the same name already exists' if exist?

			FileUtils.mkdir_p(File.join($cfg[:content_dir], @collection[:location]))

			timestamp = Time.now.strftime(DATETIME_FORMAT)
			@attributes[:created_at] = timestamp
			@attributes[:updated_at] = timestamp
			File.write(filename, serialize)
		end

		def update
			raise IOError, 'File not found' unless File.exist?(filename)

			timestamp = Time.now.strftime(DATETIME_FORMAT)
			@attributes[:updated_at] = timestamp
			File.write(filename, serialize)
		end

		def delete
			raise IOError, 'File not found' unless File.exist?(filename)

			File.delete(filename)
		end

		class << self
			def find(id, collection_id)
				pattern = File.join($cfg[:content_dir], '**', id + '.*')
				filename = Dir.glob(pattern).first

				return unless filename

				ext = File.extname(filename)
				content = File.read(filename)
				item = deserialize(id, ext, content)

				return unless item.attributes[:kind] == collection_id

				item
			end

			def all
				pattern = File.join($cfg[:content_dir], '**/*')
				Dir.glob(pattern).map do |f|
					next unless File.file?(f)

					id = File.basename(f, '.*')
					ext = File.extname(f)
					content = File.read(f)
					deserialize(id, ext, content)
				end.compact
			end

			def where(collection_id: nil, sort: 'id', status: nil, q: '')
				by_collection = lambda do |i|
					return true if collection_id.nil?

					i.attributes[:kind] == collection_id
				end

				by_status = lambda do |i|
					return true if status.nil? || status == ''

					i.attributes[:status] == status
				end

				by_search = lambda do |i|
					return true if q.nil?

					re = Regexp.new(q, 'i')
					i.attributes[:title].match?(re)
				end

				by_field = lambda do |a, b|
					return 0 if sort.nil?

					sort_by = sort.sub('-', '').to_sym
					sort_direction = sort.start_with?('-') ? -1 : 1

					case sort_by
					when :id
						a.id <=> b.id
					when :created_at, :updated_at
						b.attributes[sort_by] <=> a.attributes[sort_by]
					end * sort_direction
				end

				all.filter(&by_collection)
				   .filter(&by_search)
				   .filter(&by_status)
				   .sort(&by_field)
			end

			def create(collection_id, attributes)
				id = make_stub(attributes[:title])
				item = new(id, collection_id, attributes)
				item.save
			end

			private

			def deserialize(id, ext, str)
				case ext
				when '.html'
					_, frontmatter, content = str.split('---')

					attributes = YAML.load(frontmatter, symbolize_names: true)
					collection_id = attributes[:kind]
					attributes[:content] = content.strip

					new(id, collection_id, attributes)
				when '.yaml'
					attributes = YAML.load(str, symbolize_names: true)
					collection_id = attributes[:kind]

					new(id, collection_id, attributes)
				end
			end

			def make_stub(str)
				str.gsub(/\s/, '-').gsub(/[^\w-]/, '').downcase
			end
		end

		private

		def filename
			raise ArgumentError, 'Missing Item Id' unless @id && @collection[:id]

			filename = "#{@id}.#{@collection[:filetype]}"
			File.join($cfg[:content_dir], @collection[:location], filename)
		end

		def exist?
			pattern = File.join($cfg[:content_dir], '**', @id + '.*')
			Dir.glob(pattern).length >= 1
		end

		def serialize
			frontmatter = @attributes
			frontmatter.delete(:id)
			frontmatter.delete(:c_id)
			frontmatter[:kind] = frontmatter[:kind]

			# The Psych module (for which YAML is an alias) has a
			# stringify_names option which does exactly this. However it was
			# only introduced in Ruby 3.4. Using transform_keys is a workaround
			# to support earlier versions of Ruby.
			frontmatter = frontmatter.to_h.transform_keys(&:to_s)

			case @collection[:filetype]
			when 'html'
				content = frontmatter['content']
				frontmatter.delete('content')

				YAML.dump(frontmatter, stringify_names: true) << "---\n" << content
			when 'yaml'
				YAML.dump(frontmatter, stringify_names: true)
			end
		end
	end
end
