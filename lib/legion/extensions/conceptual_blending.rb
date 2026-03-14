# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/conceptual_blending/version'
require 'legion/extensions/conceptual_blending/helpers/constants'
require 'legion/extensions/conceptual_blending/helpers/mental_space'
require 'legion/extensions/conceptual_blending/helpers/blend'
require 'legion/extensions/conceptual_blending/helpers/blending_engine'
require 'legion/extensions/conceptual_blending/runners/conceptual_blending'

module Legion
  module Extensions
    module ConceptualBlending
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
