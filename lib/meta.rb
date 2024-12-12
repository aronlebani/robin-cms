# frozen_string_literal: true

require 'yaml'

module RobinCMS
  module Meta
    def stringify(attrs, content)
      YAML.dump(attrs) << '---' << content
    end

    def parse(filename)
      attrs = YAML.load(filename)
      content = File.readlines(filename).split('---').last

      [attrs, content]
    end

    module_function :stringify, :parse
  end
end
