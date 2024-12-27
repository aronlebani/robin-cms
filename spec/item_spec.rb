require 'rspec'

require_relative '../lib/item'

include RobinCMS

describe Item do
	before(:context) do
		$cfg = ConfigurationParser.new(File.join(__dir__, 'files/item_spec.yaml'))
	end

	after(:example) do
		# TODO - Delete all files in tmp
	end

	it 'writes the correct filetype' do
		Item.create('song', {
			'title' => 'All News Is Good News',
			'artist_name' => 'Surprise Chef'
		})

		expect(File.exist?('all-news-is-good-news.yaml')).to be(true)
	end

	it 'writes to the correct location' do
		Item.create('artist', {
			'title' => 'Surprise Chef',
			'from' => 'Melbourne, Australia'
		})

		expect(File.exist?(File.join('artists', 'surprise-chef.yaml'))).to be(true)
	end

	it 'creates a new item with the correct filename' do
		Item.create('poem', {
			'title' => 'A poem about Ruby',
			'author_name' => 'Aron',
			'content' => 'This is a poem about <i>Ruby</i>.'
		})

		expect(File.exist?('a-poem-about-ruby.html')).to be(true)
	end

	# TODO - yaml version
	it 'creates a new html item with the correct fields' do
		Item.create('poem', {
			'title' => 'A poem about Ruby',
			'author_name' => 'Aron',
			'content' => 'This is a poem about <i>Ruby</i>.'
		})

		expect(File.readlines('a-poem-about-ruby.html').to contain_exactly(
			a_string_matching('---'),
			a_string_matching('---'),
			a_string_matching('<p>This is a poem about <i>Ruby</i>.</p>'),
			a_string_matching('title: A poem about Ruby'),
			a_string_matching('author_name: Aron'),
			a_string_matching('kind: poem'),
			a_string_matching(/created_at: .*/),
			a_string_matching(/updated_at: .*/)
		).and start_with('---')
		 .and end_with('<p>This is a poem about <i>Ruby</i>.</p>')
	end

	it 'creates a new yaml item with the correct fields' do
		Item.create('song', {
			'title' => 'All News Is Good News',
			'artist_name' => 'Surprise Chef'
		})

		expect(File.readlines('all-news-is-good-news.yaml').to contain_exactly(
			a_string_matching('title: All News Is Good News'),
			a_string_matching('artist_name: Surprise Chef'),
			a_string_matching('kind: song'),
			a_string_matching(/created_at: .*/),
			a_string_matching(/updated_at: .*/)
		)
	end

	it 'correctly sets the timestamps' do
		Item.create('poem', {
			'title' => 'A poem about Ruby',
			'author_name' => 'Aron',
			'content' => 'This is a poem about <i>Ruby</i>.'
		})
		timestamp = Time.now.strftime('%Y-%m-%d')

		expect(File.readlines('a-poem-about-ruby.html').to include(
			a_string_matching("updated_at: #{timestamp}")
			a_string_matching("created_at: #{timestamp}")
		)
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
		item = Item.find('a-poem-about-ruby', 'poem')

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
		item = Item.find('a-poem-about-ruby', 'poem')

		expect(item.id).to eq('a-poem-about-ruby')
		expect(item.collection.id).to eq('poem')
		expect(item.fields).to match(
			'title' => 'A poem about Ruby',
			'author_name' => 'Aron',
			'created_at' => '2024-12-23',
			'updated_at' => '2024-12-23',
			'kind' => 'poem',
			'content' => '<p>This is a poem about <i>Ruby</i>.</p>'
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
		item = Item.find('all-news-is-good-news', 'song')

		expect(item.id).to eq('all-news-is-good-news')
		expect(item.collection.id).to eq('song')
		expect(item.fields).to match(
			'title' => 'All News Is Good News',
			'artist_name' => 'Surprise Chef',
			'created_at' => '2024-12-23',
			'updated_at' => '2024-12-23',
			'kind' => 'song'
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
		item = Item.find('a-poem-about-ruby', 'article')

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
		items = Item.all('poem')

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
		items = Item.all('poem')

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
		items = Item.all('article')

		expect(items.length).to eq(0)
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
		item = Item.find('a-poem-about-ruby', 'poem')
		item.fields['title'] = 'A poem about Haskell',
		item.fields['content'] = 'This is a poem about <i>Haskell</i>.'
		item.update

		expect(File.readlines('a-poem-about-ruby.html').to include(
			a_string_matching('title: A poem about Haskell'),
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
		item.fields['title'] = 'Is this working?'
		item.update
		timestamp = Time.now.strftime('%Y-%m-%d')

		expect(File.readlines('update-test.html').to include(
			a_string_matching("updated_at: #{timestamp}")
			a_string_matching('created_at: 2024-12-23')
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
		item = Item.find('a-poem-about-ruby', 'poem')
		item.fields.title = 'A poem about OCaml'
		item.update

		expect(File.exist?('a-poem-about-ruby.html')).to be(true)
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
		item = Item.find('a-poem-about-ruby', 'poem')
		item.delete

		expect(File.exist?('a-poem-about-ruby.html')).to be(false)
	end
end
