# lex-conceptual-blending

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-conceptual-blending`
- **Version**: 0.1.1
- **Namespace**: `Legion::Extensions::ConceptualBlending`

## Purpose

Implements Fauconnier & Turner's conceptual blending theory as a cognitive extension. Mental spaces (conceptual frames with elements and relations) are blended together to produce emergent structures that neither input space contains alone. The engine extracts a generic space (shared structure), merges elements from both inputs, and generates emergent properties from cross-domain relation type combinations. Blends gain strength through elaboration and lose strength through compression and staleness-based decay.

## Gem Info

- **Gemspec**: `lex-conceptual-blending.gemspec`
- **Require**: `lex-conceptual-blending`
- **Ruby**: >= 3.4
- **License**: MIT
- **Homepage**: https://github.com/LegionIO/lex-conceptual-blending

## File Structure

```
lib/legion/extensions/conceptual_blending/
  version.rb
  helpers/
    constants.rb         # Blend types, quality labels, decay/boost constants
    mental_space.rb      # MentalSpace class — one conceptual input frame
    blend.rb             # Blend class — result of blending two mental spaces
    blending_engine.rb   # BlendingEngine — registry of spaces and blends
  runners/
    conceptual_blending.rb  # Runner module — public API
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_SPACES` | 200 | Hard cap; `ArgumentError` on create when full |
| `MAX_BLENDS` | 100 | Hard cap; `ArgumentError` on blend when full |
| `MAX_MAPPINGS` | 500 | Total relations across all spaces; `ArgumentError` on add when full |
| `MAX_HISTORY` | 300 | Operation history cap; oldest entries evicted when full |
| `DEFAULT_STRENGTH` | 0.5 | Starting strength for new blends |
| `ELABORATION_BOOST` | 0.15 | Strength increase per `elaborate` call |
| `COMPRESSION_PENALTY` | 0.1 | Strength decrease per `compress` call |
| `DECAY_RATE` | 0.02 | Strength reduction per `decay_stale` cycle (stale blends only) |
| `STALE_THRESHOLD` | 120 | Seconds since `last_used_at` before a blend is stale |

`BLEND_TYPES`: `[:simplex, :mirror, :single_scope, :double_scope]`

Quality labels (based on `quality_score`): `0.8+` = `:excellent`, `0.6..0.8` = `:good`, `0.4..0.6` = `:fair`, `0.2..0.4` = `:weak`, `< 0.2` = `:trivial`

## Key Classes

### `Helpers::MentalSpace`

One conceptual input frame.

- `add_element(name:, properties:)` — stores element in `@elements` hash (name => properties); returns `self`
- `add_relation(from:, to:, type:)` — appends relation to `@relations` array; returns `self`
- `element_names` — returns element keys
- Fields: `id` (UUID), `name`, `domain`, `elements` (hash), `relations` (array of `{from:, to:, type:}`)

### `Helpers::Blend`

Result of blending two mental spaces.

- `use!` — increments `use_count`, updates `last_used_at`, does NOT change strength (no boost)
- `elaborate(emergent_property:)` — appends to `blended_elements[:emergent_properties]`; increases strength by `ELABORATION_BOOST`
- `compress(removed_element:)` — deletes from `blended_elements[:merged_elements]`; decreases strength by `COMPRESSION_PENALTY`
- `quality_score` — computed from element count (0.4 weight), emergent count (0.4 weight), use factor (0.2 weight); element_count/10 * 0.4 + emergent_count/5 * 0.4 + min(use_count/10,1) * 0.2
- `stale?` — `Time.now.utc - last_used_at > 120` seconds
- Fields: `id` (UUID), `input_space_ids`, `generic_space`, `blended_elements`, `blend_type`, `strength`, `use_count`

### `Helpers::BlendingEngine`

Registry of spaces and blends.

- `create_space(name:, domain:)` — raises `ArgumentError` when at `MAX_SPACES`
- `blend(space_a_id:, space_b_id:, blend_type:)` — raises `ArgumentError` if at `MAX_BLENDS` or space not found; extracts generic space (shared relation types + shared element names), merges all elements (space_b properties merge over space_a for same-name elements, returns merged keys only), generates emergent properties (up to 5 cross-domain relation type combinations)
- `elaborate_blend(blend_id:, emergent_property:)` / `compress_blend(blend_id:, removed_element:)` — raise `ArgumentError` if not found
- `find_blends(domain:)` — blends whose input spaces include the domain
- `best_blends(limit:)` — sorted by `quality_score` descending
- `decay_stale` — reduces strength by `DECAY_RATE` for all stale blends; returns count decayed
- `prune_weak` — removes blends with `strength < 0.1`; returns count removed

## Runners

Module: `Legion::Extensions::ConceptualBlending::Runners::ConceptualBlending`

| Runner | Key Args | Returns |
|---|---|---|
| `create_mental_space` | `name:`, `domain:` | `{ success:, space: }` or `{ success: false, error: }` |
| `add_space_element` | `space_id:`, `name:`, `properties:` | `{ success:, space_id:, element: }` or error |
| `add_space_relation` | `space_id:`, `from:`, `to:`, `type:` | `{ success:, space_id:, relation: }` or error |
| `create_blend` | `space_a_id:`, `space_b_id:`, `blend_type:` | `{ success:, blend: }` or error |
| `elaborate_blend` | `blend_id:`, `emergent_property:` | `{ success:, blend: }` or error |
| `compress_blend` | `blend_id:`, `removed_element:` | `{ success:, blend: }` or error |
| `best_blends` | `limit:` | `{ success:, blends:, count: }` |
| `blend_quality` | `blend_id:` | `{ success:, quality_score:, quality_label:, strength:, use_count:, stale: }` |
| `update_conceptual_blending` | — | `{ success:, decayed:, pruned: }` |
| `conceptual_blending_stats` | — | `{ success:, spaces_count:, blends_count:, best_quality: }` |

No `engine:` injection keyword. Engine is a private memoized `@engine`.

## Integration Points

- No actors defined; `update_conceptual_blending` should be called periodically for decay + prune
- `create_blend` is the synthesis operation — called when two concepts should be combined
- `elaborate_blend` adds discovered emergent properties after a blend has been used in practice
- `best_blends` surfaces the highest-quality active conceptual combinations
- All state is in-memory per `BlendingEngine` instance

## Development Notes

- `generate_emergent` only produces properties when relation types DIFFER between space_a and space_b — shared relation types are included in the generic space but do not generate emergent properties
- `merge_elements` returns only keys (names), not the merged property hashes — `blended_elements[:merged_elements]` is an array of strings/symbols
- `use!` increments use count but does NOT boost strength — strength is only increased by `elaborate`
- `decay_stale` uses `instance_variable_set(:@strength, ...)` to mutate strength directly (bypasses normal mutation methods)
- `prune_weak` threshold is 0.1 (different from `STRENGTH_FLOOR = 0.0`) — blends must be very weak to be pruned
- Blends are stored in `@blends` as a Hash keyed by UUID; spaces are also stored as a Hash keyed by UUID
