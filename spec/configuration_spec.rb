require 'rspec'

require_relative '../lib/configuration'

include RobinCMS

describe ConfigurationParser do
	it 'correctly parses a valid configuration file' do
		cfg = ConfigurationParser.new(File.join(__dir__, 'files/valid.yaml'))

		expect(cfg.content_dir).to eq('content')
		expect(cfg.collections.length).to eq(2)
		expect(cfg.collections[0].id).to eq(:poem)
		expect(cfg.collections[0].label).to eq('Poem')
		expect(cfg.collections[0].location).to eq('/')
		expect(cfg.collections[0].filetype).to eq('html')
		expect(cfg.collections[0].fields.find { |f| f.label == 'My title' && f.id == :title && f.type == 'text' }).not_to be_nil
		expect(cfg.collections[0].fields.find { |f| f.label == 'Author' && f.id == :author_name && f.type == 'text' }).not_to be_nil
		expect(cfg.collections[0].fields.find { |f| f.label == 'Content' && f.id == :content && f.type == 'richtext' }).not_to be_nil
	end

	it 'adds the implicit fields' do
		cfg = ConfigurationParser.new(File.join(__dir__, 'files/valid.yaml'))

		expect(cfg.collections[1].fields.find { |f| f.id == :title }).not_to be_nil
		expect(cfg.collections[1].fields.find { |f| f.id == :kind }).not_to be_nil
		expect(cfg.collections[1].fields.find { |f| f.id == :created_at }).not_to be_nil
		expect(cfg.collections[1].fields.find { |f| f.id == :updated_at }).not_to be_nil
		expect(cfg.collections[1].fields.find { |f| f.id == :status }).not_to be_nil
	end

	it 'chooses explicitly added fields over implicitly added fields' do
		cfg = ConfigurationParser.new(File.join(__dir__, 'files/valid.yaml'))

		expect(cfg.collections[0].fields.filter { |f| f.id == :title }.length).to eq(1)
		expect(cfg.collections[0].fields.find { |f| f.id == :title }.label).to eq('My title')
	end

	it 'uses the default location if not explicitly set' do
		cfg = ConfigurationParser.new(File.join(__dir__, 'files/no_location.yaml'))

		expect(cfg.collections[0].location).to eq('/')
	end

	it 'uses the default filetype if not explicitly set' do
		cfg = ConfigurationParser.new(File.join(__dir__, 'files/no_filetype.yaml'))

		expect(cfg.collections[0].filetype).to eq('html')
	end

	it 'complains if no collections are given' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/no_collections.yaml'))
		end.to raise_error(ParseError)
	end

	it 'complains if an invalid field type is given' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/invalid_field_type.yaml'))
		end.to raise_error(ParseError)
	end

	it 'complains if a required field attribute is missing' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/missing_required_field_attr.yaml'))
		end.to raise_error(ParseError)
	end

	it 'complains if the filetype is invalid' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/invalid_file_type.yaml'))
		end.to raise_error(ParseError)
	end

	it 'complains if a required collection attribute is missing' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/missing_required_collection_attr.yaml'))
		end.to raise_error(ParseError)
	end

	it 'complains if multiple richtext fields are added in one collection' do
		expect do
			ConfigurationParser.new(File.join(__dir__, 'files/multiple_richtext.yaml'))
		end.to raise_error(ParseError)
	end

	it 'defaults to label if no label_singular provided' do
		# TODO
	end
end
