# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveEmpathy::Runners::CognitiveEmpathy do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#take_empathic_perspective' do
    it 'creates a perspective and returns success' do
      result = runner.take_empathic_perspective(
        agent_id:         :alice,
        perspective_type: :cognitive,
        predicted_state:  { valence: 0.7 },
        confidence:       0.8
      )
      expect(result[:success]).to be true
      expect(result[:perspective_id]).to be_a(Symbol)
      expect(result[:agent_id]).to eq(:alice)
    end

    it 'returns failure for invalid perspective_type' do
      result = runner.take_empathic_perspective(
        agent_id:         :alice,
        perspective_type: :invalid_type,
        predicted_state:  {},
        confidence:       0.5
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_or_invalid_type)
    end

    it 'uses default confidence when not provided' do
      result = runner.take_empathic_perspective(
        agent_id:         :bob,
        perspective_type: :affective,
        predicted_state:  {}
      )
      expect(result[:success]).to be true
    end
  end

  describe '#record_empathic_outcome' do
    it 'records actual state and returns accuracy' do
      created = runner.take_empathic_perspective(
        agent_id:         :carol,
        perspective_type: :motivational,
        predicted_state:  { drive: 0.8 },
        confidence:       0.7
      )
      perspective_id = created[:perspective_id]
      result = runner.record_empathic_outcome(
        perspective_id: perspective_id,
        actual_state:   { drive: 0.8 }
      )
      expect(result[:success]).to be true
      expect(result[:accuracy]).to be_a(Float)
      expect(result[:accurate]).to be(true).or be(false)
    end

    it 'returns failure for unknown perspective_id' do
      result = runner.record_empathic_outcome(
        perspective_id: :nonexistent_perspective,
        actual_state:   {}
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#empathic_accuracy_for' do
    it 'returns accuracy for an agent with no history' do
      result = runner.empathic_accuracy_for(agent_id: :dave)
      expect(result[:success]).to be true
      expect(result[:agent_id]).to eq(:dave)
      expect(result[:accuracy]).to be_a(Float)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns updated accuracy after recording outcome' do
      created = runner.take_empathic_perspective(
        agent_id:         :eve,
        perspective_type: :situational,
        predicted_state:  { stress: 0.3 },
        confidence:       0.6
      )
      perspective_id = created[:perspective_id]
      runner.record_empathic_outcome(
        perspective_id: perspective_id,
        actual_state:   { stress: 0.3 }
      )
      result = runner.empathic_accuracy_for(agent_id: :eve)
      expect(result[:success]).to be true
    end
  end

  describe '#overall_empathic_accuracy' do
    it 'returns success with accuracy and label' do
      result = runner.overall_empathic_accuracy
      expect(result[:success]).to be true
      expect(result[:accuracy]).to be_a(Float)
      expect(result[:label]).to be_a(Symbol)
    end
  end

  describe '#apply_emotional_contagion' do
    it 'increases contagion level and returns empathic_state' do
      result = runner.apply_emotional_contagion(emotion_valence: 0.8, intensity: 0.9)
      expect(result[:success]).to be true
      expect(result[:contagion_level]).to be > 0.0
      expect(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::EMPATHIC_STATES)
        .to include(result[:empathic_state])
    end
  end

  describe '#current_empathic_state' do
    it 'returns empathic_state and contagion_level' do
      result = runner.current_empathic_state
      expect(result[:success]).to be true
      expect(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::EMPATHIC_STATES)
        .to include(result[:empathic_state])
      expect(result[:contagion_level]).to be_a(Float)
    end
  end

  describe '#perspectives_for_agent' do
    it 'returns empty list for agent with no perspectives' do
      result = runner.perspectives_for_agent(agent_id: :nobody)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
      expect(result[:perspectives]).to be_empty
    end

    it 'returns perspectives after taking some' do
      runner.take_empathic_perspective(
        agent_id:         :frank,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      runner.take_empathic_perspective(
        agent_id:         :frank,
        perspective_type: :affective,
        predicted_state:  {},
        confidence:       0.5
      )
      result = runner.perspectives_for_agent(agent_id: :frank)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#empathic_blind_spots' do
    it 'returns nil agents when no perspectives exist' do
      result = runner.empathic_blind_spots
      expect(result[:success]).to be true
      expect(result[:least_accurate_agent]).to be_nil
      expect(result[:most_accurate_agent]).to be_nil
    end

    it 'returns blind spot info after recording outcomes' do
      p1 = runner.take_empathic_perspective(
        agent_id:         :good_agent,
        perspective_type: :cognitive,
        predicted_state:  { v: 0.5 },
        confidence:       0.9
      )
      runner.record_empathic_outcome(perspective_id: p1[:perspective_id], actual_state: { v: 0.5 })

      p2 = runner.take_empathic_perspective(
        agent_id:         :bad_agent,
        perspective_type: :cognitive,
        predicted_state:  { v: 1.0 },
        confidence:       0.9
      )
      runner.record_empathic_outcome(perspective_id: p2[:perspective_id], actual_state: { v: 0.0 })

      result = runner.empathic_blind_spots
      expect(result[:success]).to be true
      expect(result[:least_accurate_agent]).to eq(:bad_agent)
      expect(result[:most_accurate_agent]).to eq(:good_agent)
    end
  end

  describe '#update_cognitive_empathy' do
    it 'ticks and returns stats' do
      result = runner.update_cognitive_empathy
      expect(result[:success]).to be true
      expect(result).to include(:perspective_count, :empathic_state)
    end
  end

  describe '#cognitive_empathy_stats' do
    it 'returns current stats' do
      result = runner.cognitive_empathy_stats
      expect(result[:success]).to be true
      expect(result).to include(:perspective_count, :overall_accuracy, :empathic_state)
    end
  end
end
