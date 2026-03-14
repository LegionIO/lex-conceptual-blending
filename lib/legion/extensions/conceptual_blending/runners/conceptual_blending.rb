# frozen_string_literal: true

module Legion
  module Extensions
    module ConceptualBlending
      module Runners
        module ConceptualBlending
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_mental_space(name:, domain:, **)
            Legion::Logging.debug "[conceptual_blending] create_space: name=#{name} domain=#{domain}"
            space = engine.create_space(name: name, domain: domain)
            { success: true, space: space.to_h }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] create_space failed: #{e.message}"
            { success: false, error: e.message }
          end

          def add_space_element(space_id:, name:, properties: {}, **)
            Legion::Logging.debug "[conceptual_blending] add_element: space=#{space_id} name=#{name}"
            engine.add_element_to_space(space_id: space_id, name: name, properties: properties)
            { success: true, space_id: space_id, element: name }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] add_element failed: #{e.message}"
            { success: false, error: e.message }
          end

          def add_space_relation(space_id:, from:, to:, type:, **)
            Legion::Logging.debug "[conceptual_blending] add_relation: space=#{space_id} #{from}->#{to} type=#{type}"
            engine.add_relation_to_space(space_id: space_id, from: from, to: to, type: type)
            { success: true, space_id: space_id, relation: { from: from, to: to, type: type } }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] add_relation failed: #{e.message}"
            { success: false, error: e.message }
          end

          def create_blend(space_a_id:, space_b_id:, blend_type: :double_scope, **)
            Legion::Logging.debug "[conceptual_blending] blend: a=#{space_a_id} b=#{space_b_id} type=#{blend_type}"
            blend = engine.blend(space_a_id: space_a_id, space_b_id: space_b_id, blend_type: blend_type)
            { success: true, blend: blend.to_h }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] blend failed: #{e.message}"
            { success: false, error: e.message }
          end

          def elaborate_blend(blend_id:, emergent_property:, **)
            Legion::Logging.debug "[conceptual_blending] elaborate: blend=#{blend_id} property=#{emergent_property}"
            blend = engine.elaborate_blend(blend_id: blend_id, emergent_property: emergent_property)
            { success: true, blend: blend.to_h }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] elaborate failed: #{e.message}"
            { success: false, error: e.message }
          end

          def compress_blend(blend_id:, removed_element:, **)
            Legion::Logging.debug "[conceptual_blending] compress: blend=#{blend_id} remove=#{removed_element}"
            blend = engine.compress_blend(blend_id: blend_id, removed_element: removed_element)
            { success: true, blend: blend.to_h }
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] compress failed: #{e.message}"
            { success: false, error: e.message }
          end

          def best_blends(limit: 5, **)
            Legion::Logging.debug "[conceptual_blending] best_blends: limit=#{limit}"
            blends = engine.best_blends(limit: limit)
            { success: true, blends: blends.map(&:to_h), count: blends.size }
          end

          def blend_quality(blend_id:, **)
            Legion::Logging.debug "[conceptual_blending] blend_quality: blend=#{blend_id}"
            quality = engine.blend_quality(blend_id: blend_id)
            { success: true }.merge(quality)
          rescue ArgumentError => e
            Legion::Logging.debug "[conceptual_blending] blend_quality failed: #{e.message}"
            { success: false, error: e.message }
          end

          def update_conceptual_blending(**)
            Legion::Logging.debug '[conceptual_blending] update: decay + prune cycle'
            decayed = engine.decay_stale
            pruned  = engine.prune_weak
            { success: true, decayed: decayed, pruned: pruned }
          end

          def conceptual_blending_stats(**)
            Legion::Logging.debug '[conceptual_blending] stats'
            stats = engine.to_h
            { success: true }.merge(stats)
          end

          private

          def engine
            @engine ||= Helpers::BlendingEngine.new
          end
        end
      end
    end
  end
end
