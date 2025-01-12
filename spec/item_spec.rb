require 'rspec'
require 'fileutils'

require_relative '../lib/item'

include RobinCMS

describe Item do
	before(:context) do
		$cfg = ConfigurationParser.new(File.join(__dir__, 'files/item_spec.yaml'))
	end

	before(:example) do
		FileUtils.mkdir_p(File.join(__dir__, 'tmp', 'artists'))
	end

	after(:example) do
		FileUtils.rm_rf(File.join(__dir__, 'tmp'))
	end

	it 'writes the correct filetype' do
		Item.create(:song, {
			:title => 'All News Is Good News',
			:artist_name => 'Surprise Chef'
		})

		expect(File.exist?(File.join(__dir__, 'tmp', 'all-news-is-good-news.yaml'))).to be(true)
	end

	it 'writes to the correct location' do
		Item.create(:artist, {
			:title => 'Surprise Chef',
			:from => 'Melbourne, Australia'
		})

		expect(File.exist?(File.join(__dir__, 'tmp', 'artists', 'surprise-chef.yaml'))).to be(true)
	end

	it 'creates a new item with the correct filename' do
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})

		expect(File.exist?(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'))).to be(true)
	end

	it 'creates a new html item with the correct fields' do
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})

		expect(File.readlines(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), chomp: true)).to contain_exactly(
			'---',
			'---',
			'<p>This is a poem about <i>Ruby</i>.</p>',
			'title: A poem about Ruby',
			'author_name: Aron',
			'kind: poem',
			a_string_matching(/created_at: .*/),
			a_string_matching(/updated_at: .*/)
		).and start_with('---')
		 .and end_with('<p>This is a poem about <i>Ruby</i>.</p>')
	end

	it 'creates a new yaml item with the correct fields' do
		Item.create(:song, {
			:title => 'All News Is Good News',
			:artist_name => 'Surprise Chef'
		})

		expect(File.readlines(File.join(__dir__, 'tmp', 'all-news-is-good-news.yaml'), chomp: true)).to contain_exactly(
			'---',
			'title: All News Is Good News',
			'artist_name: Surprise Chef',
			'kind: song',
			a_string_matching(/created_at: .*/),
			a_string_matching(/updated_at: .*/)
		)
	end

	it 'correctly sets the timestamps' do
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})
		timestamp = Time.now.strftime('%Y-%m-%d')

		expect(File.readlines(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), chomp: true)).to include(
			"updated_at: '#{timestamp}'",
			"created_at: '#{timestamp}'"
		)
	end

	it 'complains if a file with the same name already exists' do
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})
		expect do
			Item.create(:poem, {
				:title => 'A poem about Ruby',
				:author_name => 'Aron',
				:content => '<p>This is another a poem about <i>Ruby</i>.</p>'
			})
		end.to raise_error(IOError)
	end

	it 'complains if a file with the same name of a different collection already exists' do
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})
		expect do
			Item.create(:article, {
				:title => 'A poem about Ruby',
				:author_name => 'Aron',
				:content => '<p>This is another a poem about <i>Ruby</i>.</p>'
			})
		end.to raise_error(IOError)
	end

	it 'complains if a file with the same name in a different directory already exists' do
		# Genres have location '/genres'.
		Item.create(:poem, {
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		})
		expect do
			Item.create(:genre, { :title => 'A poem about Ruby' })
		end.to raise_error(IOError)
	end

	it 'creates a subdirectory if it does not already exist' do
		# Genres have location '/genres', but the directory isn't created yet.
		expect do
			Item.create(:genre, { :title => 'Cinematic Soul' })
		end.not_to raise_error
	end

	it 'finds the item' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)

		expect(item).not_to be(nil)
	end

	it 'finds the html item with the correct fields' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)

		expect(item.id).to eq('a-poem-about-ruby')
		expect(item.collection.id).to eq(:poem)
		expect(item.fields).to include(
			:title => 'A poem about Ruby',
			:author_name => 'Aron',
			:created_at => '2024-12-23',
			:updated_at => '2024-12-23',
			:kind => :poem,
			:content => '<p>This is a poem about <i>Ruby</i>.</p>'
		)
	end

	it 'finds the yaml item with the correct fields' do
		File.write(File.join(__dir__, 'tmp', 'all-news-is-good-news.yaml'), <<~HTML)
			title: All News Is Good News
			artist_name: Surprise Chef
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: song
		HTML
		item = Item.find('all-news-is-good-news', :song)

		expect(item.id).to eq('all-news-is-good-news')
		expect(item.collection.id).to eq(:song)
		expect(item.fields).to include(
			:title => 'All News Is Good News',
			:artist_name => 'Surprise Chef',
			:created_at => '2024-12-23',
			:updated_at => '2024-12-23',
			:kind => :song
		)
	end

	it 'returns nil if item not found' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :article)

		expect(item).to be(nil)
	end

	it 'finds all items of a given collection' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-haskell.html'), <<~HTML)
			---
			title: A poem about Haskell
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Haskell</i>.</p>
		HTML
		items = Item.where(collection_id: :poem)

		expect(items.length).to eq(2)
	end

	it 'only include items from specified collection' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'an-article-about-ruby.html'), <<~HTML)
			---
			title: An article about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: article
			---
			<p>This is an article about <i>Ruby</i>.</p>
		HTML
		items = Item.where(collection_id: :poem)

		expect(items.length).to eq(1)
	end

	it 'returns an empty array if no items of a given collection are found' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		items = Item.where(collection_id: :article)

		expect(items.length).to eq(0)
	end

	it 'sorts items correctly' do
		File.write(File.join(__dir__, 'tmp', 'aaa.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2025-01-09'
			updated_at: '2025-01-12'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'bbb.html'), <<~HTML)
			---
			title: A poem about Haskell
			author_name: Aron
			created_at: '2025-01-10'
			updated_at: '2024-01-10'
			kind: poem
			---
			<p>This is a poem about <i>Haskell</i>.</p>
		HTML
		items = Item.where(collection_id: :poem, sort: '-updated_at')

		# Due to the filenames, if sort is not specified, 'aaa.html' would
		# appear before bbb.
		expect(items[0].id).to eq('bbb')
	end

	it 'filters items by draft status' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2025-01-09'
			updated_at: '2025-01-12'
			kind: poem
			status: published
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-haskell.html'), <<~HTML)
			---
			title: A poem about Haskell
			author_name: Aron
			created_at: '2025-01-10'
			updated_at: '2024-01-10'
			kind: poem
			status: draft
			---
			<p>This is a poem about <i>Haskell</i>.</p>
		HTML
		items = Item.where(collection_id: :poem, status: 'draft')

		expect(items.length).to eq(1)
		expect(items[0].fields[:status]).to eq('draft')
	end

	it 'filters items by search query' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2025-01-09'
			updated_at: '2025-01-12'
			kind: poem
			status: published
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-haskell.html'), <<~HTML)
			---
			title: A poem about Haskell
			author_name: Aron
			created_at: '2025-01-10'
			updated_at: '2024-01-10'
			kind: poem
			status: draft
			---
			<p>This is a poem about <i>Haskell</i>.</p>
		HTML
		items = Item.where(collection_id: :poem, q: 'Ruby')

		expect(items.length).to eq(1)
		expect(items[0].id).to eq('a-poem-about-ruby')
	end

	it 'ignores case in search query' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2025-01-09'
			updated_at: '2025-01-12'
			kind: poem
			status: published
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-haskell.html'), <<~HTML)
			---
			title: A poem about Haskell
			author_name: Aron
			created_at: '2025-01-10'
			updated_at: '2024-01-10'
			kind: poem
			status: draft
			---
			<p>This is a poem about <i>Haskell</i>.</p>
		HTML
		items = Item.where(collection_id: :poem, q: 'ruby')

		expect(items.length).to eq(1)
		expect(items[0].id).to eq('a-poem-about-ruby')
	end

	it 'returns everything if collection is omitted' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		File.write(File.join(__dir__, 'tmp', 'an-article-about-ruby.html'), <<~HTML)
			---
			title: An article about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: article
			---
			<p>This is an article about <i>Ruby</i>.</p>
		HTML
		items = Item.all

		expect(items.length).to eq(2)
	end

	it 'finds nested items' do
		File.write(File.join(__dir__, 'tmp', 'artists', 'surprise-chef.yaml'), <<~HTML)
			---
			title: Surprise Chef
			from: Melbourne, Australia
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: artist
		HTML
		item = Item.find('surprise-chef', :artist)

		expect(item).not_to be(nil)
	end

	it 'finds items that have been moved to a different directory' do
		File.write(File.join(__dir__, 'tmp', 'artists', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)

		expect(item).not_to be(nil)
	end

	it 'correctly updates fields when editing' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)
		item.fields[:title] = 'A poem about Haskell'
		item.fields[:content] = '<p>This is a poem about <i>Haskell</i>.</p>'
		item.update

		expect(File.readlines(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), chomp: true)).to include(
			'title: A poem about Haskell'
		).and end_with('<p>This is a poem about <i>Haskell</i>.</p>')
	end

	it 'correctly updates the timestamps' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)
		item.fields[:title] = 'Is this working?'
		item.update
		timestamp = Time.now.strftime('%Y-%m-%d')

		expect(File.readlines(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), chomp: true)).to include(
			"updated_at: '#{timestamp}'",
			"created_at: '2024-12-23'"
		)
	end

	it 'keeps the same file name if the title changes' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)
		item.fields[:title] = 'A poem about OCaml'
		item.update

		expect(File.exist?(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'))).to be(true)
	end

	it 'deletes item' do
		File.write(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'), <<~HTML)
			---
			title: A poem about Ruby
			author_name: Aron
			created_at: '2024-12-23'
			updated_at: '2024-12-23'
			kind: poem
			---
			<p>This is a poem about <i>Ruby</i>.</p>
		HTML
		item = Item.find('a-poem-about-ruby', :poem)
		item.delete

		expect(File.exist?(File.join(__dir__, 'tmp', 'a-poem-about-ruby.html'))).to be(false)
	end
end
