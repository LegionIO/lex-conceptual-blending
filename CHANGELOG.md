# Changelog

## [0.1.1] - 2026-03-18

### Added
- Operation history tracking in `BlendingEngine` (create_space, blend, elaborate, compress events) with `MAX_HISTORY` (300) cap
- `history` accessor on `BlendingEngine` for introspection

### Fixed
- Enforce `MAX_MAPPINGS` (500) — `add_relation_to_space` now raises `ArgumentError` when total relations across all spaces reaches the cap

## [0.1.0] - 2026-03-13

### Added
- Initial release: mental spaces, blending engine, four blend types
- Quality scoring, staleness decay, weak blend pruning
- Standalone Client
