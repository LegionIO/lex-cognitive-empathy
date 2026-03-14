# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveEmpathy
      module Runners
        module CognitiveEmpathy
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def take_empathic_perspective(agent_id:, perspective_type:, predicted_state:, confidence: 0.5, **)
            perspective = engine.take_perspective(
              agent_id:         agent_id,
              perspective_type: perspective_type,
              predicted_state:  predicted_state,
              confidence:       confidence
            )
            return { success: false, reason: :limit_or_invalid_type } unless perspective

            { success: true, perspective_id: perspective.id, agent_id: agent_id,
              perspective_type: perspective_type }
          end

          def record_empathic_outcome(perspective_id:, actual_state:, **)
            perspective = engine.record_outcome(perspective_id: perspective_id, actual_state: actual_state)
            return { success: false, reason: :not_found } unless perspective

            { success: true, perspective_id: perspective_id,
              accuracy: perspective.accuracy.round(4), accurate: perspective.accurate? }
          end

          def empathic_accuracy_for(agent_id:, **)
            accuracy = engine.empathic_accuracy(agent_id: agent_id)
            label = accuracy_label(accuracy)
            { success: true, agent_id: agent_id, accuracy: accuracy.round(4), label: label }
          end

          def overall_empathic_accuracy(**)
            accuracy = engine.overall_accuracy
            label = accuracy_label(accuracy)
            { success: true, accuracy: accuracy.round(4), label: label }
          end

          def apply_emotional_contagion(emotion_valence:, intensity:, **)
            level = engine.emotional_contagion(emotion_valence: emotion_valence, intensity: intensity)
            { success: true, contagion_level: level.round(4), empathic_state: engine.empathic_state }
          end

          def current_empathic_state(**)
            { success: true, empathic_state: engine.empathic_state,
              contagion_level: engine.contagion_level.round(4) }
          end

          def perspectives_for_agent(agent_id:, **)
            list = engine.perspectives_for(agent_id: agent_id).map(&:to_h)
            { success: true, agent_id: agent_id, perspectives: list, count: list.size }
          end

          def empathic_blind_spots(**)
            least = engine.least_accurate_agent
            most  = engine.most_accurate_agent
            { success: true, least_accurate_agent: least, most_accurate_agent: most,
              overall_accuracy: engine.overall_accuracy.round(4) }
          end

          def update_cognitive_empathy(**)
            engine.tick
            { success: true }.merge(engine.to_h)
          end

          def cognitive_empathy_stats(**)
            { success: true }.merge(engine.to_h)
          end

          private

          def engine
            @engine ||= Helpers::EmpathyEngine.new
          end

          def accuracy_label(accuracy)
            ACCURACY_LABELS.each { |range, lbl| return lbl if range.cover?(accuracy) }
            :blind
          end
        end
      end
    end
  end
end
