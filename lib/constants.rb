# frozen_string_literal: true

module RobinCMS
	DATETIME_FORMAT = '%Y-%m-%d'

	SORT_OPTIONS = [
		{ :label => 'Name (a-z)', :value => 'id' },
		{ :label => 'Name (z-a)', :value => '-id' },
		{ :label => 'Created date (newest - oldest)', :value => 'created_at' },
		{ :label => 'Created date (oldest - newest)', :value => '-created_at' },
		{ :label => 'Updated date (newest - oldest)', :value => 'updated_at' },
		{ :label => 'Updated date (oldest - newest)', :value => '-updated_at' }
	].freeze

	STATUS_OPTIONS = [
		{ :label => 'Any', :value => '' },
		{ :label => 'Draft', :value => 'draft' },
		{ :label => 'Published', :value => 'published' }
	].freeze
end
