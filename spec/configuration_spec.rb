require 'rspec'

require_relative '../lib/configuration'

describe ConfigurationParser do
	it 'correctly parses a valid configuration file' do
		cfg = ConfigurationParser.new('files/valid.yaml')

		expect(cfg['content_dir']).to eq('content')
		expect(cfg['collections'].length).to eq(2)
		expect(cfg['collections'][0]['name']).to eq('poem')
		expect(cfg['collections'][0]['label']).to eq('Poem')
		expect(cfg['collections'][0]['location']).to eq('/')
		expect(cfg['collections'][0]['filetype']).to eq('html')
		expect(cfg['collections'][0]['fields']).to include({ 'label' => 'Title', 'name' => 'title', 'type' => 'input' })
		expect(cfg['collections'][0]['fields']).to include({ 'label' => 'Author', 'name' => 'author_name', 'type' => 'input' })
		expect(cfg['collections'][0]['fields']).to include({ 'label' => 'Content', 'name' => 'content', 'type' => 'richtext' })
	end

	it 'adds the implicit fields' do
		cfg = ConfigurationParser.new('files/valid.yaml')

		expect(cfg['collections'][1]['fields'].keys).to include('title')
		expect(cfg['collections'][1]['fields'].keys).to include('kind')
		expect(cfg['collections'][1]['fields'].keys).to include('created_at')
		expect(cfg['collections'][1]['fields'].keys).to include('updated_at')
	end

	it 'doesn\'t duplicate implicit fields if explicitly added' do
		cfg = ConfigurationParser.new('files/valid.yaml')

		expect(cfg['collections'][0]['fields'].keys.filter { |key| key == 'title' }.length).to eq(1)
	end

	it 'complains if no collections are given' do
		expect do
			ConfigurationParser.new('files/no_collections.yaml')
		end.to raise_error(TypeError)
	end

	it 'complains if an invalid field type is given' do
		expect do
			ConfigurationParser.new('files/invalid_field_type.yaml')
		end.to raise_error(TypeError)
	end

	it 'complains if a required field attribute is missing' do
		expect do
			ConfigurationParser.new('files/missing_required_field_attr.yaml')
		end.to raise_error(TypeError)
	end

	it 'complains if the filetype is invalid' do
		expect do
			ConfigurationParser.new('files/invalid_file_type.yaml')
		end.to raise_error(TypeError)
	end

	it 'complains if a required collection attribute is missing' do
		expect do
			ConfigurationParser.new('files/missing_required_collection_attr.yaml')
		end.to raise_error(TypeError)
	end
end
