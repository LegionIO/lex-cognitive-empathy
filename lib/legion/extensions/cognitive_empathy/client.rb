# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveEmpathy
      class Client
        include Runners::CognitiveEmpathy

        def initialize(engine: nil)
          @engine = engine || Helpers::EmpathyEngine.new
        end
      end
    end
  end
end
