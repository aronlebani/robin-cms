# frozen_string_literal: true

module RobinCMS
	module Helpers
		# Don't mind be being a pirate and rolling my own pluralizing function.
		# I didn't want to import a giant utility library.
		def pluralize(str)
			if ['s', 'x', 'z', 'sh', 'ch'].any? { |e| str.downcase.end_with?(e) }
				"#{str}es"
			elsif str.downcase.end_with?('ff')
				"#{str}s"
			elsif str.downcase.end_with?('f')
				"#{str[0..-2]}ves"
			elsif str.downcase.end_with?('y')
				if ['a', 'e', 'i', 'o', 'u'].include?(str.downcase[-2])
					"#{str}s"
				else
					"#{str}ies"
				end
			else
				"#{str}s"
			end
		end

		module_function :pluralize
	end
end
