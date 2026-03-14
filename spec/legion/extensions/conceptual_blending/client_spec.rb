# frozen_string_literal: true

require 'legion/extensions/conceptual_blending/client'

RSpec.describe Legion::Extensions::ConceptualBlending::Client do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a client with a default engine' do
      expect(client).to respond_to(:create_mental_space)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::ConceptualBlending::Helpers::BlendingEngine.new
      injected_client = described_class.new(engine: engine)
      expect(injected_client).to respond_to(:conceptual_blending_stats)
    end
  end

  it 'responds to all runner methods' do
    expect(client).to respond_to(:create_mental_space)
    expect(client).to respond_to(:add_space_element)
    expect(client).to respond_to(:add_space_relation)
    expect(client).to respond_to(:create_blend)
    expect(client).to respond_to(:elaborate_blend)
    expect(client).to respond_to(:compress_blend)
    expect(client).to respond_to(:best_blends)
    expect(client).to respond_to(:blend_quality)
    expect(client).to respond_to(:update_conceptual_blending)
    expect(client).to respond_to(:conceptual_blending_stats)
  end

  it 'round-trips a full blending workflow' do
    # Create two spaces
    bio_result  = client.create_mental_space(name: 'biology', domain: 'science')
    comp_result = client.create_mental_space(name: 'computing', domain: 'technology')

    bio_id  = bio_result[:space][:id]
    comp_id = comp_result[:space][:id]

    # Populate spaces
    client.add_space_element(space_id: bio_id, name: 'virus', properties: { spreads: true })
    client.add_space_element(space_id: comp_id, name: 'software', properties: { executes: true })
    client.add_space_relation(space_id: bio_id, from: 'virus', to: 'host', type: :infects)
    client.add_space_relation(space_id: comp_id, from: 'software', to: 'system', type: :corrupts)

    # Blend
    blend_result = client.create_blend(space_a_id: bio_id, space_b_id: comp_id)
    expect(blend_result[:success]).to be true
    blend_id = blend_result[:blend][:id]

    # Elaborate
    elab_result = client.elaborate_blend(blend_id: blend_id, emergent_property: 'computer_virus')
    expect(elab_result[:success]).to be true

    # Quality
    quality_result = client.blend_quality(blend_id: blend_id)
    expect(quality_result[:quality_label]).to be_a(Symbol)

    # Stats reflect both spaces
    stats = client.conceptual_blending_stats
    expect(stats[:spaces_count]).to eq(2)
    expect(stats[:blends_count]).to eq(1)
  end

  it 'maintains isolated state per client instance' do
    client_a = described_class.new
    client_b = described_class.new

    client_a.create_mental_space(name: 'space_a', domain: 'domain_a')

    stats_a = client_a.conceptual_blending_stats
    stats_b = client_b.conceptual_blending_stats

    expect(stats_a[:spaces_count]).to eq(1)
    expect(stats_b[:spaces_count]).to eq(0)
  end
end
