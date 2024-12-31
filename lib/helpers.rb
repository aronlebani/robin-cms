# frozen_string_literal: true

module RobinCMS
	module Helpers
		# Don't mind be being a pirate and rolling my own pluralizing function.
		# I didn't want to import a giant utility library.
		def pluralize(str)
			str = str.downcase

			if ['s', 'x', 'z', 'sh', 'ch'].any { |e| str.end_with?(e) }
				"#{str}es"
			elsif str.end_with?('ff')
				"#{str}s"
			elsif str.end_with?('f')
				"#{str[0..-2]}ves"
			elsif str.end_with?('y')
				if ['a', 'e', 'i', 'o', 'u'].include?(str[-2])
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
