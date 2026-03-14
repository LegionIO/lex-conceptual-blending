# frozen_string_literal: true

module Legion
  module Extensions
    module ConceptualBlending
      module Helpers
        class MentalSpace
          attr_reader :id, :name, :domain, :elements, :relations, :created_at

          def initialize(name:, domain:)
            @id         = ::SecureRandom.uuid
            @name       = name
            @domain     = domain
            @elements   = {}
            @relations  = []
            @created_at = Time.now.utc
          end

          def add_element(name:, properties: {})
            @elements[name] = properties
            self
          end

          def add_relation(from:, to:, type:)
            @relations << { from: from, to: to, type: type }
            self
          end

          def element_names
            @elements.keys
          end

          def to_h
            {
              id:         @id,
              name:       @name,
              domain:     @domain,
              elements:   @elements,
              relations:  @relations,
              created_at: @created_at
            }
          end
        end
      end
    end
  end
end
