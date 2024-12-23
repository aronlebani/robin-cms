# frozen_string_literal: true

module RobinCMS
	def id_to_filename(id, collection_id)
		collection = $cfg.collections.find { |c| c.id == collection_id }
		filename = "#{id}.#{collection.filetype}"

		File.join($cfg.content_dir, collection.location, filename)
	end

	def filename_to_id(filename, collection_id)
		collection = $cfg.collections.find { |c| c.id == collection_id }
		extension = ".#{collection.filetype}"

		File.basename(filename, extension)
	end

	class Item
		include RobinCMS

		attr_accessor :fields
		attr_reader :id

		def initialize(id, collection_id, fields = {})
			@id = id
			@collection_id = collection_id
			@fields = fields.to_h

			@fields['kind'] = collection_id
		end

		def filename
			raise ArgumentError 'Missing Item Id' unless @id && @collection_id

			id_to_filename(@id, @collection_id)
		end

		def action
			if @id
				"/collections/#{@collection_id}/item?id=#{@id}"
			else
				"/collections/#{@collection_id}/item"
			end
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
			include RobinCMS

			def find(id, collection_id)
				filename = id_to_filename(id, collection_id)

				return unless File.exist?(filename)

				item = deserialize(id, File.read(filename))

				return unless item.fields['kind'] == collection_id

				item
			end

			def all(collection_id)
				Dir.glob(File.join($cfg.content_dir, '**/*')).map do |f|
					next unless File.file?(f)

					id = filename_to_id(f, collection_id)
					item = deserialize(id, File.read(f))

					next unless item.fields['kind'] == collection_id

					item
				end.compact
			end

			def create(id, collection_id, fields)
				item = new(id, collection_id, fields)
				item.save
			end

			private

			def deserialize(id, str)
				_, frontmatter, content = str.split('---')

				fields = YAML.load(frontmatter)
				collection_id = fields['kind']
				fields['content'] = content

				new(id, collection_id, fields)
			end
		end

		private

		def serialize
			content = @fields['content']

			frontmatter = @fields
			frontmatter.delete('content')
			frontmatter.delete('id')
			frontmatter.delete('c_id')

			YAML.dump(frontmatter.to_h) << "---\n" << content
		end
	end
end
