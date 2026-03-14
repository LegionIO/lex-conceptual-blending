# frozen_string_literal: true

RSpec.describe Legion::Extensions::ConceptualBlending::Helpers::MentalSpace do
  subject(:space) { described_class.new(name: 'biology', domain: 'science') }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(space.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name and domain' do
      expect(space.name).to eq('biology')
      expect(space.domain).to eq('science')
    end

    it 'starts with empty elements and relations' do
      expect(space.elements).to eq({})
      expect(space.relations).to eq([])
    end

    it 'records created_at timestamp' do
      expect(space.created_at).to be_a(Time)
    end
  end

  describe '#add_element' do
    it 'stores element with properties' do
      space.add_element(name: 'virus', properties: { type: :pathogen })
      expect(space.elements['virus']).to eq({ type: :pathogen })
    end

    it 'returns self for chaining' do
      result = space.add_element(name: 'cell', properties: {})
      expect(result).to eq(space)
    end

    it 'stores multiple elements' do
      space.add_element(name: 'virus', properties: {})
      space.add_element(name: 'host', properties: {})
      expect(space.elements.size).to eq(2)
    end
  end

  describe '#add_relation' do
    it 'stores relation hash' do
      space.add_relation(from: 'virus', to: 'host', type: :infects)
      expect(space.relations.first).to eq({ from: 'virus', to: 'host', type: :infects })
    end

    it 'returns self for chaining' do
      result = space.add_relation(from: 'a', to: 'b', type: :links)
      expect(result).to eq(space)
    end

    it 'accumulates multiple relations' do
      space.add_relation(from: 'a', to: 'b', type: :one)
      space.add_relation(from: 'b', to: 'c', type: :two)
      expect(space.relations.size).to eq(2)
    end
  end

  describe '#element_names' do
    it 'returns array of element name keys' do
      space.add_element(name: 'alpha', properties: {})
      space.add_element(name: 'beta', properties: {})
      expect(space.element_names).to contain_exactly('alpha', 'beta')
    end

    it 'returns empty array when no elements' do
      expect(space.element_names).to eq([])
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      result = space.to_h
      expect(result).to include(:id, :name, :domain, :elements, :relations, :created_at)
    end

    it 'reflects current state' do
      space.add_element(name: 'x', properties: { val: 1 })
      expect(space.to_h[:elements]['x']).to eq({ val: 1 })
    end
  end
end
