# frozen_string_literal: true

RSpec.describe Legion::Extensions::ConceptualBlending::Helpers::Blend do
  let(:input_ids) { [SecureRandom.uuid, SecureRandom.uuid] }
  let(:generic_space) { { shared_relation_types: [:infects], mapped_elements: [] } }
  let(:blended_elements) { { merged_elements: %w[virus software], emergent_properties: [] } }

  subject(:blend) do
    described_class.new(
      input_space_ids:  input_ids,
      generic_space:    generic_space,
      blended_elements: blended_elements,
      blend_type:       :double_scope
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(blend.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets input_space_ids' do
      expect(blend.input_space_ids).to eq(input_ids)
    end

    it 'sets blend_type' do
      expect(blend.blend_type).to eq(:double_scope)
    end

    it 'defaults strength to DEFAULT_STRENGTH' do
      expect(blend.strength).to eq(Legion::Extensions::ConceptualBlending::Helpers::Constants::DEFAULT_STRENGTH)
    end

    it 'starts with use_count 0' do
      expect(blend.use_count).to eq(0)
    end
  end

  describe '#use!' do
    it 'increments use_count' do
      blend.use!
      expect(blend.use_count).to eq(1)
    end

    it 'updates last_used_at' do
      original = blend.last_used_at
      sleep(0.01)
      blend.use!
      expect(blend.last_used_at).to be >= original
    end

    it 'returns self' do
      expect(blend.use!).to eq(blend)
    end
  end

  describe '#elaborate' do
    it 'appends to emergent_properties' do
      blend.elaborate(emergent_property: 'software_spreads_like_virus')
      expect(blend.blended_elements[:emergent_properties]).to include('software_spreads_like_virus')
    end

    it 'boosts strength by ELABORATION_BOOST' do
      original = blend.strength
      blend.elaborate(emergent_property: 'new_prop')
      expected = (original + Legion::Extensions::ConceptualBlending::Helpers::Constants::ELABORATION_BOOST)
                 .clamp(0.0, 1.0)
      expect(blend.strength).to be_within(0.001).of(expected)
    end

    it 'does not exceed strength ceiling' do
      10.times { blend.elaborate(emergent_property: 'prop') }
      expect(blend.strength).to be <= 1.0
    end

    it 'returns self' do
      expect(blend.elaborate(emergent_property: 'x')).to eq(blend)
    end
  end

  describe '#compress' do
    it 'reduces strength by COMPRESSION_PENALTY' do
      original = blend.strength
      blend.compress(removed_element: 'virus')
      expected = (original - Legion::Extensions::ConceptualBlending::Helpers::Constants::COMPRESSION_PENALTY)
                 .clamp(0.0, 1.0)
      expect(blend.strength).to be_within(0.001).of(expected)
    end

    it 'does not go below strength floor' do
      20.times { blend.compress(removed_element: 'x') }
      expect(blend.strength).to be >= 0.0
    end

    it 'returns self' do
      expect(blend.compress(removed_element: 'x')).to eq(blend)
    end
  end

  describe '#quality_score' do
    it 'returns a float between 0 and 1' do
      expect(blend.quality_score).to be_between(0.0, 1.0)
    end

    it 'increases with more emergent properties' do
      base_score = blend.quality_score
      5.times { |idx| blend.elaborate(emergent_property: "prop_#{idx}") }
      expect(blend.quality_score).to be > base_score
    end

    it 'increases with more use' do
      base_score = blend.quality_score
      10.times { blend.use! }
      expect(blend.quality_score).to be >= base_score
    end
  end

  describe '#quality_label' do
    it 'returns a symbol from QUALITY_LABELS' do
      labels = Legion::Extensions::ConceptualBlending::Helpers::Constants::QUALITY_LABELS.values
      expect(labels).to include(blend.quality_label)
    end
  end

  describe '#stale?' do
    it 'returns false for a freshly created blend' do
      expect(blend.stale?).to be false
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      result = blend.to_h
      expect(result).to include(
        :id, :input_space_ids, :generic_space, :blended_elements,
        :blend_type, :strength, :use_count, :quality_score, :quality_label,
        :stale, :created_at, :last_used_at
      )
    end
  end
end
