# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveEmpathy
      module Helpers
        module Constants
          MAX_PERSPECTIVES  = 50
          MAX_INTERACTIONS  = 200
          MAX_HISTORY       = 200

          DEFAULT_ACCURACY  = 0.5
          ACCURACY_FLOOR    = 0.1
          ACCURACY_CEILING  = 0.95
          CONTAGION_RATE    = 0.15
          CONTAGION_DECAY   = 0.05
          ACCURACY_ALPHA    = 0.1

          PERSPECTIVE_TYPES = %i[cognitive affective motivational situational].freeze
          EMPATHIC_STATES   = %i[detached observing resonating immersed].freeze

          ACCURACY_LABELS = {
            (0.8..)     => :excellent,
            (0.6...0.8) => :good,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :poor,
            (..0.2)     => :blind
          }.freeze
        end
      end
    end
  end
end
