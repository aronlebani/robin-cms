# frozen_string_literal: true

module RobinCMS
  class Article
    attr_accessor :content
    attr_reader :meta, :id

    def initialize(id = nil, content = nil, meta = {})
      @id = id
      @content = content
      @meta = meta
    end

    def filename
      raise ArgumentError 'Missing Article Id' unless @id

      File.join(__dir__, 'content', @id + '.html')
    end

    def link_to
      "#{ENV['APP_HOST']}/#{@id}"
    end

    def action
      if @id
        "/admin/article?id=#{id}"
      else
        "/admin/article"
      end
    end

    def meta=(attrs)
      @meta = attrs.reject do |key|
        key == 'content' || key == 'id'
      end
    end

    def save
      return if File.exist?(filename)

      File.write(filename, Meta.stringify(@meta, @content))
    end

    def update
      return unless File.exist?(filename)

      File.write(filename, Meta.stringify(@meta, @content))
    end

    def delete
      return unless File.exist?(filename)

      File.delete(filename)
    end

    class << self
      def find(id)
        return unless File.exist?(filename)

        meta, content = Meta.parse(filename)

        new(id, content, meta)
      end

      def all
        Dir.glob(File.join(__dir__, 'content', '**/*')) do |f|
          next unless File.file?(f)

          find(extract_stub(f))
        end
      end

      def create(id, content, meta)
        article = new(id, content, meta)
        article.save
      end
    end
  end
end
