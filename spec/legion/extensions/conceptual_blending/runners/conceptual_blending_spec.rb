# frozen_string_literal: true

require 'legion/extensions/conceptual_blending/client'

RSpec.describe Legion::Extensions::ConceptualBlending::Runners::ConceptualBlending do
  let(:client) { Legion::Extensions::ConceptualBlending::Client.new }

  let(:space_a_id) do
    result = client.create_mental_space(name: 'biology', domain: 'science')
    result[:space][:id]
  end

  let(:space_b_id) do
    result = client.create_mental_space(name: 'computing', domain: 'technology')
    result[:space][:id]
  end

  before do
    client.add_space_element(space_id: space_a_id, name: 'virus', properties: { type: :pathogen })
    client.add_space_relation(space_id: space_a_id, from: 'virus', to: 'host', type: :infects)
    client.add_space_element(space_id: space_b_id, name: 'software', properties: { type: :program })
    client.add_space_relation(space_id: space_b_id, from: 'software', to: 'network', type: :corrupts)
  end

  describe '#create_mental_space' do
    it 'returns success with space hash' do
      result = client.create_mental_space(name: 'test', domain: 'misc')
      expect(result[:success]).to be true
      expect(result[:space]).to include(:id, :name, :domain)
    end
  end

  describe '#add_space_element' do
    it 'returns success with space_id and element name' do
      result = client.add_space_element(space_id: space_a_id, name: 'new_elem', properties: {})
      expect(result[:success]).to be true
      expect(result[:element]).to eq('new_elem')
    end

    it 'returns failure for unknown space_id' do
      result = client.add_space_element(space_id: 'bad-id', name: 'x', properties: {})
      expect(result[:success]).to be false
      expect(result[:error]).to include('not found')
    end
  end

  describe '#add_space_relation' do
    it 'returns success with relation hash' do
      result = client.add_space_relation(space_id: space_a_id, from: 'a', to: 'b', type: :links)
      expect(result[:success]).to be true
      expect(result[:relation]).to eq({ from: 'a', to: 'b', type: :links })
    end

    it 'returns failure for unknown space_id' do
      result = client.add_space_relation(space_id: 'bad', from: 'a', to: 'b', type: :x)
      expect(result[:success]).to be false
    end
  end

  describe '#create_blend' do
    it 'returns success with blend hash' do
      result = client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id)
      expect(result[:success]).to be true
      expect(result[:blend]).to include(:id, :blend_type, :strength)
    end

    it 'uses provided blend_type' do
      result = client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id, blend_type: :mirror)
      expect(result[:blend][:blend_type]).to eq(:mirror)
    end

    it 'returns failure for unknown space ids' do
      result = client.create_blend(space_a_id: 'bad', space_b_id: space_b_id)
      expect(result[:success]).to be false
    end
  end

  describe '#elaborate_blend' do
    let(:blend_id) do
      result = client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id)
      result[:blend][:id]
    end

    it 'returns success with updated blend' do
      result = client.elaborate_blend(blend_id: blend_id, emergent_property: 'antivirus_software')
      expect(result[:success]).to be true
      expect(result[:blend][:blended_elements][:emergent_properties]).to include('antivirus_software')
    end

    it 'returns failure for unknown blend_id' do
      result = client.elaborate_blend(blend_id: 'bad', emergent_property: 'x')
      expect(result[:success]).to be false
    end
  end

  describe '#compress_blend' do
    let(:blend_id) do
      result = client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id)
      result[:blend][:id]
    end

    it 'returns success with updated blend' do
      result = client.compress_blend(blend_id: blend_id, removed_element: 'virus')
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown blend_id' do
      result = client.compress_blend(blend_id: 'bad', removed_element: 'x')
      expect(result[:success]).to be false
    end
  end

  describe '#best_blends' do
    it 'returns success with blends array' do
      client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id)
      result = client.best_blends(limit: 5)
      expect(result[:success]).to be true
      expect(result[:blends]).to be_an(Array)
      expect(result[:count]).to eq(result[:blends].size)
    end

    it 'returns empty array when no blends exist' do
      fresh_client = Legion::Extensions::ConceptualBlending::Client.new
      result = fresh_client.best_blends(limit: 5)
      expect(result[:blends]).to eq([])
    end
  end

  describe '#blend_quality' do
    let(:blend_id) do
      result = client.create_blend(space_a_id: space_a_id, space_b_id: space_b_id)
      result[:blend][:id]
    end

    it 'returns quality assessment' do
      result = client.blend_quality(blend_id: blend_id)
      expect(result[:success]).to be true
      expect(result).to include(:quality_score, :quality_label, :strength)
    end

    it 'returns failure for unknown blend_id' do
      result = client.blend_quality(blend_id: 'bad')
      expect(result[:success]).to be false
    end
  end

  describe '#update_conceptual_blending' do
    it 'returns success with decay and prune counts' do
      result = client.update_conceptual_blending
      expect(result[:success]).to be true
      expect(result).to include(:decayed, :pruned)
    end
  end

  describe '#conceptual_blending_stats' do
    it 'returns success with engine stats' do
      result = client.conceptual_blending_stats
      expect(result[:success]).to be true
      expect(result).to include(:spaces_count, :blends_count)
    end
  end
end
