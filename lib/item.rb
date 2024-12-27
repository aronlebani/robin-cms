# frozen_string_literal: true

module RobinCMS
	class Item
		attr_accessor :fields
		attr_reader :id, :collection

		def initialize(id, collection_id, fields = {})
			@id = id
			@fields = fields.to_h
			@collection = $cfg.collections.find { |c| c.id == collection_id }

			@fields['kind'] = collection_id
		end

		def save
			return if File.exist?(filename)

			timestamp = Time.now.strftime(DATETIME_FORMAT)
			@fields['created_at'] = timestamp
			@fields['updated_at'] = timestamp
			File.write(filename, serialize)
		end

		def update
			return unless File.exist?(filename)

			timestamp = Time.now.strftime(DATETIME_FORMAT)
			@fields['updated_at'] = timestamp
			File.write(filename, serialize)
		end

		def delete
			return unless File.exist?(filename)

			File.delete(filename)
		end

		class << self
			def find(id, collection_id)
				# TODO - I don't think this works for nested directories
				filename = Dir.glob(File.join($cfg.content_dir, id + '.*')).first

				return unless filename

				ext = File.extname(filename)
				content = File.read(filename)
				item = deserialize(id, ext, content)

				return unless item.fields['kind'] == collection_id

				item
			end

			def all(collection_id)
				Dir.glob(File.join($cfg.content_dir, '**/*')).map do |f|
					next unless File.file?(f)

					id = File.basename(f, '.*')
					ext = File.extname(f)
					content = File.read(f)
					item = deserialize(id, ext, content)

					next unless item.fields['kind'] == collection_id

					item
				end.compact
			end

			def create(collection_id, fields)
				id = make_stub(fields['title'])

				if find(id, collection_id)
					raise IOError 'An item with the same name already exists'
				end

				item = new(id, collection_id, fields)
				item.save
			end

			private

			def deserialize(id, ext, str)
				case ext
				when 'html'
					_, frontmatter, content = str.split('---')

					fields = YAML.load(frontmatter)
					collection_id = fields['kind']
					fields['content'] = content

					new(id, collection_id, fields)
				when 'yaml'
					fields = YAML.load(str)
					collection_id = fields['kind']

					new(id, collection_id, fields)
				end
			end

			def make_stub(str) = str.gsub(/\s/, '-').gsub(/[^\w-]/, '')
		end

		private

		def filename
			raise ArgumentError, 'Missing Item Id' unless @id && @collection.id

			filename = "#{@id}.#{@collection.filetype}"
			File.join($cfg.content_dir, @collection.location, filename)
		end

		def serialize
			frontmatter = @fields
			frontmatter.delete('id')
			frontmatter.delete('c_id')

			case @collection.filetype
			when 'html'
				content = @fields['content']
				frontmatter.delete('content')

				YAML.dump(frontmatter.to_h) << "---\n" << content
			when 'yaml'
				YAML.dump(frontmatter.to_h)
			end
		end
	end
end
