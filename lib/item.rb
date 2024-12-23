# frozen_string_literal: true

module RobinCMS
	class Item
		attr_accessor :fields
		attr_reader :id

		def initialize(id, collection_id, fields = {})
			@id = id
			@collection_id = collection_id
			@fields = fields
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

			@fields['created_at'] = Time.now
			File.write(filename, serialize)
		end

		def update
			return unless File.exist?(filename)

			@fields['updated_at'] = Time.now
			File.write(filename, serialize)
		end

		def delete
			return unless File.exist?(filename)

			File.delete(filename)
		end

		class << self
			def find(id, collection_id)
				filename = id_to_filename(id, collection_id)

				return unless File.exist?(filename)

				item = deserialize(id, File.read(filename))

				return unless item.collectionId == collection_id

				item
			end

			def all(collection_id)
				Dir.glob(File.join(__dir__, $cfg.content_dir, '**/*')).map do |f|
					next unless File.file?(f)

					find(filename_to_id(f, collection_id))
				end.compact
			end

			def create(id, collection_id, fields)
				item = new(id, collection_id, fields)
				item.save
			end

			private

			def deserialize(id, str)
				fields = YAML.load(str)
				content = str.split('---').last
				collection_id = fields['kind']
				fields['content'] = content
				fields.delete('kind')

				new(id, collection_id, fields)
			end
		end

		private

		def serialize
			content = @fields['content']
			attrs = @fields
			attrs.delete('content')
			attrs['kind'] = @collection_id

			YAML.dump(attrs) << '---' << content
		end
	end

	def id_to_filename(id, collection_id)
		collection = $cfg.collections.find { |c| c.id == collection_id }
		filename = "#{id}.#{collection.filetype}"

		File.join(__dir__, $cfg.content_dir, collection.location, filename)
	end

	def filename_to_id(filename, collection_id)
		collection = $cfg.collections.find { |c| c.id == collection_id }
		extension = ".#{collection.filetype}"

		File.basename(filename, extension)
	end
end
