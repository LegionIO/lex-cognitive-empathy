# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveEmpathy
      module Helpers
        class Perspective
          include Constants

          attr_reader :id, :agent_id, :perspective_type, :predicted_state, :actual_state,
                      :confidence, :accuracy

          def initialize(id:, agent_id:, perspective_type: :cognitive, predicted_state: {}, confidence: 0.5)
            @id               = id
            @agent_id         = agent_id
            @perspective_type = perspective_type
            @predicted_state  = predicted_state
            @confidence       = confidence.to_f.clamp(0.0, 1.0)
            @actual_state     = nil
            @accuracy         = DEFAULT_ACCURACY
            @created_at       = Time.now.utc
            @resolved_at      = nil
          end

          def record_actual(actual_state:)
            @actual_state = actual_state
            @resolved_at  = Time.now.utc
            error = compute_error(predicted_state, actual_state)
            observed_accuracy = (1.0 - error).clamp(ACCURACY_FLOOR, ACCURACY_CEILING)
            @accuracy = ((1.0 - ACCURACY_ALPHA) * @accuracy) + (ACCURACY_ALPHA * observed_accuracy)
            @accuracy = @accuracy.clamp(ACCURACY_FLOOR, ACCURACY_CEILING)
            self
          end

          def accurate?
            @accuracy > 0.6
          end

          def resolved?
            !@actual_state.nil?
          end

          def to_h
            {
              id:               @id,
              agent_id:         @agent_id,
              perspective_type: @perspective_type,
              predicted_state:  @predicted_state,
              actual_state:     @actual_state,
              confidence:       @confidence.round(4),
              accuracy:         @accuracy.round(4),
              accurate:         accurate?,
              resolved:         resolved?,
              created_at:       @created_at,
              resolved_at:      @resolved_at
            }
          end

          private

          def compute_error(predicted, actual)
            return 0.0 if predicted.empty? && actual.empty?
            return 1.0 if predicted.empty? || actual.empty?

            keys = (predicted.keys | actual.keys)
            return 1.0 if keys.empty?

            total_error = keys.sum do |k|
              p_val = numeric_value(predicted[k])
              a_val = numeric_value(actual[k])
              (p_val - a_val).abs
            end

            (total_error / keys.size).clamp(0.0, 1.0)
          end

          def numeric_value(val)
            return val.to_f if val.is_a?(Numeric)
            return 1.0 if val == true
            return 0.0 if val == false || val.nil?

            0.5
          end
        end
      end
    end
  end
end
