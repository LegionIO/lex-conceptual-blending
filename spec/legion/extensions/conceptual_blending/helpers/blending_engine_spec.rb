# frozen_string_literal: true

RSpec.describe Legion::Extensions::ConceptualBlending::Helpers::BlendingEngine do
  subject(:engine) { described_class.new }

  let(:space_a) do
    engine.create_space(name: 'biology', domain: 'science').tap do |s|
      s.add_element(name: 'virus', properties: { type: :pathogen })
      s.add_element(name: 'host', properties: { type: :organism })
      s.add_relation(from: 'virus', to: 'host', type: :infects)
      s.add_relation(from: 'virus', to: 'host', type: :spreads)
    end
  end

  let(:space_b) do
    engine.create_space(name: 'computing', domain: 'technology').tap do |s|
      s.add_element(name: 'software', properties: { type: :program })
      s.add_element(name: 'network', properties: { type: :infrastructure })
      s.add_relation(from: 'software', to: 'network', type: :corrupts)
      s.add_relation(from: 'software', to: 'network', type: :replicates)
    end
  end

  describe '#create_space' do
    it 'returns a MentalSpace' do
      space = engine.create_space(name: 'test', domain: 'misc')
      expect(space).to be_a(Legion::Extensions::ConceptualBlending::Helpers::MentalSpace)
    end

    it 'stores space internally' do
      space = engine.create_space(name: 'test', domain: 'misc')
      expect(engine.to_h[:spaces_count]).to eq(1)
      space # suppress unused warning
    end
  end

  describe '#add_element_to_space' do
    it 'adds element to the space' do
      space = engine.create_space(name: 's', domain: 'd')
      engine.add_element_to_space(space_id: space.id, name: 'elem', properties: { key: :val })
      expect(space.elements['elem']).to eq({ key: :val })
    end

    it 'raises ArgumentError for unknown space_id' do
      expect do
        engine.add_element_to_space(space_id: 'bad-id', name: 'x', properties: {})
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#add_relation_to_space' do
    it 'adds relation to the space' do
      space = engine.create_space(name: 's', domain: 'd')
      engine.add_relation_to_space(space_id: space.id, from: 'a', to: 'b', type: :links)
      expect(space.relations.first).to eq({ from: 'a', to: 'b', type: :links })
    end

    it 'raises ArgumentError for unknown space_id' do
      expect do
        engine.add_relation_to_space(space_id: 'bad-id', from: 'a', to: 'b', type: :x)
      end.to raise_error(ArgumentError, /not found/)
    end

    it 'raises ArgumentError when MAX_MAPPINGS is reached' do
      space = engine.create_space(name: 's', domain: 'd')
      stub_const('Legion::Extensions::ConceptualBlending::Helpers::Constants::MAX_MAPPINGS', 2)
      engine.add_relation_to_space(space_id: space.id, from: 'a', to: 'b', type: :x)
      engine.add_relation_to_space(space_id: space.id, from: 'b', to: 'c', type: :y)
      expect do
        engine.add_relation_to_space(space_id: space.id, from: 'c', to: 'd', type: :z)
      end.to raise_error(ArgumentError, /Max mappings/)
    end
  end

  describe '#blend' do
    it 'creates a Blend from two spaces' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      expect(blend).to be_a(Legion::Extensions::ConceptualBlending::Helpers::Blend)
    end

    it 'sets both input space ids' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      expect(blend.input_space_ids).to contain_exactly(space_a.id, space_b.id)
    end

    it 'uses the given blend_type' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id, blend_type: :mirror)
      expect(blend.blend_type).to eq(:mirror)
    end

    it 'extracts generic space with shared relation types' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      expect(blend.generic_space).to have_key(:shared_relation_types)
    end

    it 'merges elements from both spaces' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      merged = blend.blended_elements[:merged_elements]
      expect(merged).to include('virus', 'software')
    end

    it 'generates emergent properties from cross-domain relations' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      expect(blend.blended_elements[:emergent_properties]).not_to be_empty
    end

    it 'raises ArgumentError for unknown space ids' do
      expect do
        engine.blend(space_a_id: 'bad', space_b_id: space_b.id)
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#elaborate_blend' do
    let(:blend) { engine.blend(space_a_id: space_a.id, space_b_id: space_b.id) }

    it 'adds emergent property to blend' do
      engine.elaborate_blend(blend_id: blend.id, emergent_property: 'computer_immune_system')
      expect(blend.blended_elements[:emergent_properties]).to include('computer_immune_system')
    end

    it 'raises ArgumentError for unknown blend_id' do
      expect do
        engine.elaborate_blend(blend_id: 'bad', emergent_property: 'x')
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#compress_blend' do
    let(:blend) { engine.blend(space_a_id: space_a.id, space_b_id: space_b.id) }

    it 'reduces blend strength' do
      original_strength = blend.strength
      engine.compress_blend(blend_id: blend.id, removed_element: 'virus')
      expect(blend.strength).to be < original_strength
    end

    it 'raises ArgumentError for unknown blend_id' do
      expect do
        engine.compress_blend(blend_id: 'bad', removed_element: 'x')
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#find_blends' do
    it 'finds blends involving spaces from the given domain' do
      engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      results = engine.find_blends(domain: 'science')
      expect(results).not_to be_empty
    end

    it 'returns empty array when no matching domain' do
      engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      results = engine.find_blends(domain: 'nonexistent')
      expect(results).to eq([])
    end
  end

  describe '#best_blends' do
    it 'returns array of blends ordered by quality' do
      engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      results = engine.best_blends(limit: 5)
      expect(results).to be_an(Array)
    end

    it 'respects the limit' do
      3.times { engine.blend(space_a_id: space_a.id, space_b_id: space_b.id) }
      results = engine.best_blends(limit: 2)
      expect(results.size).to be <= 2
    end
  end

  describe '#blend_quality' do
    let(:blend) { engine.blend(space_a_id: space_a.id, space_b_id: space_b.id) }

    it 'returns quality assessment hash' do
      result = engine.blend_quality(blend_id: blend.id)
      expect(result).to include(:blend_id, :quality_score, :quality_label, :strength, :use_count, :stale)
    end

    it 'raises ArgumentError for unknown blend_id' do
      expect do
        engine.blend_quality(blend_id: 'bad')
      end.to raise_error(ArgumentError, /not found/)
    end
  end

  describe '#decay_stale' do
    it 'returns count of decayed blends' do
      engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      count = engine.decay_stale
      expect(count).to be_a(Integer)
    end
  end

  describe '#prune_weak' do
    it 'returns count of pruned blends' do
      pruned = engine.prune_weak
      expect(pruned).to be_a(Integer)
    end

    it 'removes blends with strength below 0.1' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      blend.instance_variable_set(:@strength, 0.05)
      engine.prune_weak
      expect(engine.to_h[:blends_count]).to eq(0)
    end
  end

  describe '#history' do
    it 'records create_space events' do
      engine.create_space(name: 'test', domain: 'misc')
      expect(engine.history.last[:operation]).to eq(:create_space)
    end

    it 'records blend events' do
      engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      expect(engine.history.last[:operation]).to eq(:blend)
    end

    it 'records elaborate events' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      engine.elaborate_blend(blend_id: blend.id, emergent_property: 'new_prop')
      expect(engine.history.last[:operation]).to eq(:elaborate)
    end

    it 'records compress events' do
      blend = engine.blend(space_a_id: space_a.id, space_b_id: space_b.id)
      engine.compress_blend(blend_id: blend.id, removed_element: 'virus')
      expect(engine.history.last[:operation]).to eq(:compress)
    end

    it 'enforces MAX_HISTORY cap' do
      stub_const('Legion::Extensions::ConceptualBlending::Helpers::Constants::MAX_HISTORY', 3)
      5.times { |i| engine.create_space(name: "s#{i}", domain: 'd') }
      expect(engine.history.size).to eq(3)
    end

    it 'returns a copy (not the internal array)' do
      engine.create_space(name: 'test', domain: 'misc')
      expect(engine.history).not_to be(engine.instance_variable_get(:@history))
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      result = engine.to_h
      expect(result).to include(:spaces_count, :blends_count, :best_quality)
    end

    it 'reflects current state' do
      engine.create_space(name: 's', domain: 'd')
      expect(engine.to_h[:spaces_count]).to eq(1)
    end
  end
end
