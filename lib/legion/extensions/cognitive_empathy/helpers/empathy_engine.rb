# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveEmpathy
      module Helpers
        class EmpathyEngine
          include Constants

          attr_reader :perspectives, :contagion_level, :history

          def initialize
            @perspectives     = {}
            @contagion_level  = 0.0
            @counter          = 0
            @history          = []
          end

          def take_perspective(agent_id:, perspective_type:, predicted_state:, confidence:)
            return nil if @perspectives.size >= MAX_PERSPECTIVES
            return nil unless PERSPECTIVE_TYPES.include?(perspective_type)

            @counter += 1
            id = :"perspective_#{@counter}"
            perspective = Perspective.new(
              id:               id,
              agent_id:         agent_id,
              perspective_type: perspective_type,
              predicted_state:  predicted_state,
              confidence:       confidence
            )
            @perspectives[id] = perspective
            record_event(:perspective_taken, id: id, agent_id: agent_id)
            perspective
          end

          def record_outcome(perspective_id:, actual_state:)
            perspective = @perspectives[perspective_id]
            return nil unless perspective

            perspective.record_actual(actual_state: actual_state)
            record_event(:outcome_recorded, id: perspective_id, accuracy: perspective.accuracy)
            perspective
          end

          def empathic_accuracy(agent_id:)
            agent_perspectives = perspectives_for(agent_id: agent_id)
            resolved = agent_perspectives.select(&:resolved?)
            return DEFAULT_ACCURACY if resolved.empty?

            resolved.sum(&:accuracy) / resolved.size
          end

          def overall_accuracy
            resolved = @perspectives.values.select(&:resolved?)
            return DEFAULT_ACCURACY if resolved.empty?

            resolved.sum(&:accuracy) / resolved.size
          end

          def emotional_contagion(emotion_valence:, intensity:)
            intensity_f = intensity.to_f.clamp(0.0, 1.0)
            absorption  = CONTAGION_RATE * intensity_f
            @contagion_level = (@contagion_level + absorption).clamp(0.0, 1.0)
            record_event(:contagion, valence: emotion_valence, intensity: intensity_f,
                                     level: @contagion_level)
            @contagion_level
          end

          def contagion_decay
            @contagion_level = [@contagion_level - CONTAGION_DECAY, 0.0].max
          end

          def empathic_state
            return :immersed   if @contagion_level >= 0.75
            return :resonating if @contagion_level >= 0.45
            return :observing  if @contagion_level >= 0.15

            :detached
          end

          def perspectives_for(agent_id:)
            @perspectives.values.select { |p| p.agent_id == agent_id }
          end

          def most_accurate_agent
            agent_accuracies = build_agent_accuracies
            return nil if agent_accuracies.empty?

            agent_accuracies.max_by { |_, acc| acc }&.first
          end

          def least_accurate_agent
            agent_accuracies = build_agent_accuracies
            return nil if agent_accuracies.empty?

            agent_accuracies.min_by { |_, acc| acc }&.first
          end

          def tick
            contagion_decay
            prune_old_perspectives
            self
          end

          def to_h
            {
              perspective_count: @perspectives.size,
              resolved_count:    @perspectives.values.count(&:resolved?),
              overall_accuracy:  overall_accuracy.round(4),
              contagion_level:   @contagion_level.round(4),
              empathic_state:    empathic_state,
              history_size:      @history.size
            }
          end

          private

          def build_agent_accuracies
            agent_ids = @perspectives.values.map(&:agent_id).uniq
            accuracies = {}
            agent_ids.each do |aid|
              resolved = perspectives_for(agent_id: aid).select(&:resolved?)
              next if resolved.empty?

              accuracies[aid] = resolved.sum(&:accuracy) / resolved.size
            end
            accuracies
          end

          def prune_old_perspectives
            resolved = @perspectives.select { |_, p| p.resolved? }
            return unless resolved.size > MAX_PERSPECTIVES / 2

            oldest_keys = resolved.keys.first(resolved.size - (MAX_PERSPECTIVES / 4))
            oldest_keys.each { |k| @perspectives.delete(k) }
          end

          def record_event(type, **details)
            @history << { type: type, at: Time.now.utc }.merge(details)
            @history.shift while @history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
