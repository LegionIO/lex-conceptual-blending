# lex-conceptual-blending

A LegionIO cognitive architecture extension implementing Fauconnier & Turner's conceptual blending theory. Mental spaces representing concepts in different domains are blended together to produce emergent structures and novel ideas that neither input contains alone.

## What It Does

Manages **mental spaces** (conceptual frames with elements and relations) and **blends** (combinations of two spaces).

When two spaces are blended, the engine:
1. Extracts a **generic space** — shared relation types and element names between the two inputs
2. **Merges elements** — combines all elements from both spaces (same-name elements are merged)
3. Generates **emergent properties** — cross-domain relation type combinations (up to 5), representing ideas only possible in the blend

Blends gain strength through elaboration (adding discovered emergent properties) and weaken through compression (removing elements) and staleness-based decay.

**Blend quality** reflects element count (40%), emergent property count (40%), and usage frequency (20%).

## Usage

```ruby
require 'lex-conceptual-blending'

client = Legion::Extensions::ConceptualBlending::Client.new

# Create two mental spaces
fire = client.create_mental_space(name: 'fire', domain: :physical)
# => { success: true, space: { id: "uuid...", name: "fire", domain: :physical, ... } }

argument = client.create_mental_space(name: 'argument', domain: :social)

# Add elements and relations to spaces
client.add_space_element(space_id: fire[:space][:id], name: :heat, properties: { intensity: :high })
client.add_space_element(space_id: fire[:space][:id], name: :fuel, properties: { type: :organic })
client.add_space_relation(space_id: fire[:space][:id], from: :fuel, to: :heat, type: :causes)

client.add_space_element(space_id: argument[:space][:id], name: :position, properties: { strength: :strong })
client.add_space_relation(space_id: argument[:space][:id], from: :position, to: :position, type: :opposes)

# Blend the two spaces (double_scope blend)
blend = client.create_blend(
  space_a_id: fire[:space][:id],
  space_b_id: argument[:space][:id],
  blend_type: :double_scope
)
# => { success: true, blend: { id: "uuid...", blend_type: :double_scope,
#      blended_elements: { merged_elements: [...], emergent_properties: ["causes_opposes_cross_domain"] },
#      strength: 0.5, quality_score: 0.08, quality_label: :trivial, ... } }

# Elaborate the blend with a discovered emergent property
client.elaborate_blend(
  blend_id: blend[:blend][:id],
  emergent_property: 'arguments can be fueled or extinguished'
)
# => { success: true, blend: { strength: 0.65, ... } }

# Find highest-quality blends
client.best_blends(limit: 5)
# => { success: true, blends: [...], count: 1 }

# Periodic maintenance (decay stale blends, prune very weak ones)
client.update_conceptual_blending
# => { success: true, decayed: 0, pruned: 0 }

# Engine stats
client.conceptual_blending_stats
# => { success: true, spaces_count: 2, blends_count: 1, best_quality: 0.14 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
