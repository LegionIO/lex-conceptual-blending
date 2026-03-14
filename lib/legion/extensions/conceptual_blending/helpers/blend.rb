# frozen_string_literal: true

module Legion
  module Extensions
    module ConceptualBlending
      module Helpers
        class Blend
          include Constants

          attr_reader :id, :input_space_ids, :generic_space, :blended_elements,
                      :blend_type, :strength, :use_count, :created_at, :last_used_at

          def initialize(input_space_ids:, generic_space:, blended_elements:, blend_type: :double_scope)
            @id               = ::SecureRandom.uuid
            @input_space_ids  = input_space_ids
            @generic_space    = generic_space
            @blended_elements = blended_elements
            @blend_type       = blend_type
            @strength         = DEFAULT_STRENGTH
            @use_count        = 0
            @created_at       = Time.now.utc
            @last_used_at     = Time.now.utc
          end

          def use!
            @use_count    += 1
            @last_used_at  = Time.now.utc
            self
          end

          def elaborate(emergent_property:)
            @blended_elements[:emergent_properties] ||= []
            @blended_elements[:emergent_properties] << emergent_property
            @strength = (@strength + ELABORATION_BOOST).clamp(STRENGTH_FLOOR, STRENGTH_CEILING)
            self
          end

          def compress(removed_element:)
            @blended_elements[:merged_elements]&.delete(removed_element)
            @strength = (@strength - COMPRESSION_PENALTY).clamp(STRENGTH_FLOOR, STRENGTH_CEILING)
            self
          end

          def quality_score
            element_count   = Array(@blended_elements[:merged_elements]).size
            emergent_count  = Array(@blended_elements[:emergent_properties]).size
            use_factor      = [@use_count / 10.0, 1.0].min

            raw = ((element_count / 10.0) * 0.4) +
                  ((emergent_count / 5.0) * 0.4) +
                  (use_factor * 0.2)
            raw.clamp(STRENGTH_FLOOR, STRENGTH_CEILING)
          end

          def quality_label
            score = quality_score
            QUALITY_LABELS.each do |range, label|
              return label if range.cover?(score)
            end
            :trivial
          end

          def stale?
            (Time.now.utc - @last_used_at).to_i > STALE_THRESHOLD
          end

          def to_h
            {
              id:               @id,
              input_space_ids:  @input_space_ids,
              generic_space:    @generic_space,
              blended_elements: @blended_elements,
              blend_type:       @blend_type,
              strength:         @strength,
              use_count:        @use_count,
              quality_score:    quality_score,
              quality_label:    quality_label,
              stale:            stale?,
              created_at:       @created_at,
              last_used_at:     @last_used_at
            }
          end
        end
      end
    end
  end
end
