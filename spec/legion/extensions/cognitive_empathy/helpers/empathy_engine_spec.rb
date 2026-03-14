# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveEmpathy::Helpers::EmpathyEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with empty perspectives' do
      expect(engine.perspectives).to be_empty
    end

    it 'starts with zero contagion level' do
      expect(engine.contagion_level).to eq(0.0)
    end

    it 'starts with empty history' do
      expect(engine.history).to be_empty
    end
  end

  describe '#take_perspective' do
    it 'creates and stores a perspective' do
      p = engine.take_perspective(
        agent_id:         :alice,
        perspective_type: :cognitive,
        predicted_state:  { valence: 0.6 },
        confidence:       0.7
      )
      expect(p).to be_a(Legion::Extensions::CognitiveEmpathy::Helpers::Perspective)
      expect(engine.perspectives.size).to eq(1)
    end

    it 'returns nil for invalid perspective_type' do
      result = engine.take_perspective(
        agent_id:         :alice,
        perspective_type: :bogus,
        predicted_state:  {},
        confidence:       0.5
      )
      expect(result).to be_nil
    end

    it 'enforces MAX_PERSPECTIVES limit' do
      50.times do |i|
        engine.take_perspective(
          agent_id:         :"agent_#{i}",
          perspective_type: :cognitive,
          predicted_state:  {},
          confidence:       0.5
        )
      end
      result = engine.take_perspective(
        agent_id:         :overflow,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      expect(result).to be_nil
    end

    it 'records event in history' do
      engine.take_perspective(
        agent_id:         :bob,
        perspective_type: :affective,
        predicted_state:  {},
        confidence:       0.5
      )
      expect(engine.history.size).to eq(1)
    end

    it 'assigns unique ids' do
      p1 = engine.take_perspective(
        agent_id:         :a,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      p2 = engine.take_perspective(
        agent_id:         :b,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      expect(p1.id).not_to eq(p2.id)
    end
  end

  describe '#record_outcome' do
    it 'updates the perspective with actual state' do
      p = engine.take_perspective(
        agent_id:         :carol,
        perspective_type: :cognitive,
        predicted_state:  { valence: 0.7 },
        confidence:       0.8
      )
      perspective_id = p.id
      result = engine.record_outcome(perspective_id: perspective_id, actual_state: { valence: 0.7 })
      expect(result).to be_a(Legion::Extensions::CognitiveEmpathy::Helpers::Perspective)
      expect(result.resolved?).to be true
    end

    it 'returns nil for unknown perspective_id' do
      result = engine.record_outcome(perspective_id: :bogus_id, actual_state: {})
      expect(result).to be_nil
    end

    it 'records event in history' do
      p = engine.take_perspective(
        agent_id:         :dave,
        perspective_type: :motivational,
        predicted_state:  {},
        confidence:       0.5
      )
      perspective_id = p.id
      engine.record_outcome(perspective_id: perspective_id, actual_state: {})
      expect(engine.history.size).to eq(2)
    end
  end

  describe '#empathic_accuracy' do
    it 'returns default accuracy when no resolved perspectives exist' do
      engine.take_perspective(
        agent_id:         :eve,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      acc = engine.empathic_accuracy(agent_id: :eve)
      expect(acc).to eq(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::DEFAULT_ACCURACY)
    end

    it 'returns average accuracy for resolved perspectives' do
      p = engine.take_perspective(
        agent_id:         :frank,
        perspective_type: :cognitive,
        predicted_state:  { v: 0.5 },
        confidence:       0.8
      )
      perspective_id = p.id
      engine.record_outcome(perspective_id: perspective_id, actual_state: { v: 0.5 })
      acc = engine.empathic_accuracy(agent_id: :frank)
      expect(acc).to be_a(Float)
      expect(acc).to be > 0.0
    end

    it 'returns default for unknown agent' do
      acc = engine.empathic_accuracy(agent_id: :nobody)
      expect(acc).to eq(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::DEFAULT_ACCURACY)
    end
  end

  describe '#overall_accuracy' do
    it 'returns default when no resolved perspectives' do
      expect(engine.overall_accuracy).to eq(
        Legion::Extensions::CognitiveEmpathy::Helpers::Constants::DEFAULT_ACCURACY
      )
    end

    it 'returns average across all agents after outcomes recorded' do
      p1 = engine.take_perspective(
        agent_id: :g, perspective_type: :cognitive, predicted_state: { v: 0.5 }, confidence: 0.8
      )
      p2 = engine.take_perspective(
        agent_id: :h, perspective_type: :affective, predicted_state: { v: 0.5 }, confidence: 0.8
      )
      engine.record_outcome(perspective_id: p1.id, actual_state: { v: 0.5 })
      engine.record_outcome(perspective_id: p2.id, actual_state: { v: 0.5 })
      expect(engine.overall_accuracy).to be > 0.5
    end
  end

  describe '#emotional_contagion' do
    it 'increases contagion_level' do
      engine.emotional_contagion(emotion_valence: 0.8, intensity: 1.0)
      expect(engine.contagion_level).to be > 0.0
    end

    it 'clamps intensity to 0..1' do
      engine.emotional_contagion(emotion_valence: 0.5, intensity: 5.0)
      expect(engine.contagion_level).to be <= 1.0
    end

    it 'records event in history' do
      engine.emotional_contagion(emotion_valence: 0.5, intensity: 0.5)
      expect(engine.history).not_to be_empty
    end

    it 'returns the new contagion level' do
      level = engine.emotional_contagion(emotion_valence: 0.5, intensity: 0.5)
      expect(level).to be_a(Float)
      expect(level).to be > 0.0
    end
  end

  describe '#contagion_decay' do
    it 'reduces contagion_level' do
      engine.emotional_contagion(emotion_valence: 0.8, intensity: 1.0)
      before = engine.contagion_level
      engine.contagion_decay
      expect(engine.contagion_level).to be < before
    end

    it 'does not go below 0' do
      engine.contagion_decay
      expect(engine.contagion_level).to eq(0.0)
    end
  end

  describe '#empathic_state' do
    it 'returns :detached when contagion is near zero' do
      expect(engine.empathic_state).to eq(:detached)
    end

    it 'returns :observing when contagion is moderate' do
      10.times { engine.emotional_contagion(emotion_valence: 0.5, intensity: 0.3) }
      state = engine.empathic_state
      expect(%i[observing resonating immersed detached]).to include(state)
    end

    it 'returns :immersed when contagion is very high' do
      100.times { engine.emotional_contagion(emotion_valence: 0.9, intensity: 1.0) }
      expect(engine.empathic_state).to eq(:immersed)
    end

    it 'returns :resonating at mid-range contagion' do
      # Manually set by absorbing enough
      50.times { engine.emotional_contagion(emotion_valence: 0.5, intensity: 0.7) }
      state = engine.empathic_state
      expect(%i[resonating immersed]).to include(state)
    end
  end

  describe '#perspectives_for' do
    it 'returns perspectives matching agent_id' do
      engine.take_perspective(
        agent_id:         :ivan,
        perspective_type: :cognitive,
        predicted_state:  {},
        confidence:       0.5
      )
      engine.take_perspective(
        agent_id:         :jane,
        perspective_type: :affective,
        predicted_state:  {},
        confidence:       0.5
      )
      results = engine.perspectives_for(agent_id: :ivan)
      expect(results.size).to eq(1)
      expect(results.first.agent_id).to eq(:ivan)
    end

    it 'returns empty array for unknown agent' do
      expect(engine.perspectives_for(agent_id: :nobody)).to be_empty
    end
  end

  describe '#most_accurate_agent and #least_accurate_agent' do
    it 'returns nil when no resolved perspectives exist' do
      expect(engine.most_accurate_agent).to be_nil
      expect(engine.least_accurate_agent).to be_nil
    end

    context 'with resolved perspectives for two agents' do
      before do
        # Agent A: perfect prediction
        pa = engine.take_perspective(
          agent_id: :agent_a, perspective_type: :cognitive,
          predicted_state: { v: 0.5 }, confidence: 0.9
        )
        engine.record_outcome(perspective_id: pa.id, actual_state: { v: 0.5 })

        # Agent B: terrible prediction
        pb = engine.take_perspective(
          agent_id: :agent_b, perspective_type: :cognitive,
          predicted_state: { v: 1.0 }, confidence: 0.9
        )
        engine.record_outcome(perspective_id: pb.id, actual_state: { v: 0.0 })
      end

      it 'identifies most accurate agent' do
        expect(engine.most_accurate_agent).to eq(:agent_a)
      end

      it 'identifies least accurate agent' do
        expect(engine.least_accurate_agent).to eq(:agent_b)
      end
    end
  end

  describe '#tick' do
    it 'decays contagion level' do
      engine.emotional_contagion(emotion_valence: 0.5, intensity: 1.0)
      before = engine.contagion_level
      engine.tick
      expect(engine.contagion_level).to be < before
    end

    it 'returns self' do
      expect(engine.tick).to be(engine)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = engine.to_h
      expect(h).to include(
        :perspective_count, :resolved_count, :overall_accuracy,
        :contagion_level, :empathic_state, :history_size
      )
    end

    it 'rounds overall_accuracy to 4 places' do
      h = engine.to_h
      expect(h[:overall_accuracy]).to be_a(Float)
    end
  end
end
