# frozen_string_literal: true

module Legion
  module Extensions
    module ConceptualBlending
      module Helpers
        module Constants
          MAX_SPACES      = 200
          MAX_BLENDS      = 100
          MAX_MAPPINGS    = 500
          MAX_HISTORY     = 300
          DEFAULT_STRENGTH    = 0.5
          STRENGTH_FLOOR      = 0.0
          STRENGTH_CEILING    = 1.0
          ELABORATION_BOOST   = 0.15
          COMPRESSION_PENALTY = 0.1
          DECAY_RATE          = 0.02
          STALE_THRESHOLD     = 120
          BLEND_TYPES         = %i[simplex mirror single_scope double_scope].freeze
          QUALITY_LABELS      = {
            (0.8..)     => :excellent,
            (0.6...0.8) => :good,
            (0.4...0.6) => :fair,
            (0.2...0.4) => :weak,
            (..0.2)     => :trivial
          }.freeze
        end
      end
    end
  end
end
