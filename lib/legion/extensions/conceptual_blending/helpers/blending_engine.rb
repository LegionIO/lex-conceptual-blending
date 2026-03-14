# frozen_string_literal: true

module Legion
  module Extensions
    module ConceptualBlending
      module Helpers
        class BlendingEngine
          include Constants

          def initialize
            @spaces  = {}
            @blends  = {}
          end

          def create_space(name:, domain:)
            raise ArgumentError, "Max spaces (#{MAX_SPACES}) reached" if @spaces.size >= MAX_SPACES

            space = MentalSpace.new(name: name, domain: domain)
            @spaces[space.id] = space
            space
          end

          def add_element_to_space(space_id:, name:, properties: {})
            space = @spaces.fetch(space_id) { raise ArgumentError, "Space #{space_id} not found" }
            space.add_element(name: name, properties: properties)
          end

          def add_relation_to_space(space_id:, from:, to:, type:)
            space = @spaces.fetch(space_id) { raise ArgumentError, "Space #{space_id} not found" }
            space.add_relation(from: from, to: to, type: type)
          end

          def blend(space_a_id:, space_b_id:, blend_type: :double_scope)
            raise ArgumentError, "Max blends (#{MAX_BLENDS}) reached" if @blends.size >= MAX_BLENDS

            space_a = @spaces.fetch(space_a_id) { raise ArgumentError, "Space #{space_a_id} not found" }
            space_b = @spaces.fetch(space_b_id) { raise ArgumentError, "Space #{space_b_id} not found" }

            generic_space = extract_generic_space(space_a, space_b)
            merged        = merge_elements(space_a, space_b)
            emergent      = generate_emergent(space_a, space_b)

            blended_elements = {
              merged_elements:     merged,
              emergent_properties: emergent
            }

            b = Blend.new(
              input_space_ids:  [space_a_id, space_b_id],
              generic_space:    generic_space,
              blended_elements: blended_elements,
              blend_type:       blend_type
            )
            @blends[b.id] = b
            b
          end

          def elaborate_blend(blend_id:, emergent_property:)
            blend = @blends.fetch(blend_id) { raise ArgumentError, "Blend #{blend_id} not found" }
            blend.elaborate(emergent_property: emergent_property)
          end

          def compress_blend(blend_id:, removed_element:)
            blend = @blends.fetch(blend_id) { raise ArgumentError, "Blend #{blend_id} not found" }
            blend.compress(removed_element: removed_element)
          end

          def find_blends(domain:)
            @blends.values.select do |b|
              b.input_space_ids.any? do |sid|
                @spaces[sid]&.domain == domain
              end
            end
          end

          def best_blends(limit: 5)
            @blends.values.sort_by { |b| -b.quality_score }.first(limit)
          end

          def blend_quality(blend_id:)
            blend = @blends.fetch(blend_id) { raise ArgumentError, "Blend #{blend_id} not found" }
            {
              blend_id:      blend_id,
              quality_score: blend.quality_score,
              quality_label: blend.quality_label,
              strength:      blend.strength,
              use_count:     blend.use_count,
              stale:         blend.stale?
            }
          end

          def decay_stale
            count = 0
            @blends.each_value do |b|
              next unless b.stale?

              new_strength = (b.strength - DECAY_RATE).clamp(STRENGTH_FLOOR, STRENGTH_CEILING)
              b.instance_variable_set(:@strength, new_strength)
              count += 1
            end
            count
          end

          def prune_weak
            before = @blends.size
            @blends.delete_if { |_id, b| b.strength < 0.1 }
            before - @blends.size
          end

          def to_h
            {
              spaces_count: @spaces.size,
              blends_count: @blends.size,
              best_quality: @blends.values.map(&:quality_score).max || 0.0
            }
          end

          private

          def extract_generic_space(space_a, space_b)
            types_a = space_a.relations.to_set { |r| r[:type] }
            types_b = space_b.relations.to_set { |r| r[:type] }
            shared_types = types_a & types_b

            {
              shared_relation_types: shared_types.to_a,
              mapped_elements:       shared_element_mappings(space_a, space_b)
            }
          end

          def shared_element_mappings(space_a, space_b)
            names_a = space_a.element_names.to_set(&:to_s)
            names_b = space_b.element_names.to_set(&:to_s)
            (names_a & names_b).to_a
          end

          def merge_elements(space_a, space_b)
            merged = {}
            space_a.elements.each do |name, props|
              merged[name] = props.dup
            end
            space_b.elements.each do |name, props|
              merged[name] = if merged.key?(name)
                               merged[name].merge(props)
                             else
                               props.dup
                             end
            end
            merged.keys
          end

          def generate_emergent(space_a, space_b)
            emergent = []
            space_a.relations.each do |rel_a|
              space_b.relations.each do |rel_b|
                next if rel_a[:type] == rel_b[:type]

                emergent << "#{rel_a[:type]}_#{rel_b[:type]}_cross_domain"
              end
            end
            emergent.uniq.first(5)
          end
        end
      end
    end
  end
end
