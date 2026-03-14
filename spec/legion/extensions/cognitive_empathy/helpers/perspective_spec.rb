# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveEmpathy::Helpers::Perspective do
  subject(:perspective) do
    described_class.new(
      id:               :persp_one,
      agent_id:         :agent_a,
      perspective_type: :cognitive,
      predicted_state:  { valence: 0.7, arousal: 0.5 },
      confidence:       0.8
    )
  end

  describe '#initialize' do
    it 'sets id' do
      expect(perspective.id).to eq(:persp_one)
    end

    it 'sets agent_id' do
      expect(perspective.agent_id).to eq(:agent_a)
    end

    it 'sets perspective_type' do
      expect(perspective.perspective_type).to eq(:cognitive)
    end

    it 'sets predicted_state' do
      expect(perspective.predicted_state).to eq({ valence: 0.7, arousal: 0.5 })
    end

    it 'sets confidence' do
      expect(perspective.confidence).to eq(0.8)
    end

    it 'clamps confidence to 0..1' do
      p = described_class.new(id: :x, agent_id: :a, confidence: 1.5)
      expect(p.confidence).to eq(1.0)
    end

    it 'starts with nil actual_state' do
      expect(perspective.actual_state).to be_nil
    end

    it 'starts with default accuracy' do
      expect(perspective.accuracy).to eq(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::DEFAULT_ACCURACY)
    end

    it 'is not resolved initially' do
      expect(perspective.resolved?).to be false
    end
  end

  describe '#record_actual' do
    context 'when prediction matches well' do
      it 'increases accuracy above default' do
        perspective.record_actual(actual_state: { valence: 0.7, arousal: 0.5 })
        expect(perspective.accuracy).to be > 0.5
      end
    end

    context 'when prediction is off' do
      it 'lowers accuracy below default' do
        perspective.record_actual(actual_state: { valence: 0.0, arousal: 0.0 })
        expect(perspective.accuracy).to be < 0.5
      end
    end

    it 'sets actual_state' do
      actual = { valence: 0.6, arousal: 0.4 }
      perspective.record_actual(actual_state: actual)
      expect(perspective.actual_state).to eq(actual)
    end

    it 'marks as resolved' do
      perspective.record_actual(actual_state: { valence: 0.6 })
      expect(perspective.resolved?).to be true
    end

    it 'returns self for chaining' do
      result = perspective.record_actual(actual_state: {})
      expect(result).to be(perspective)
    end

    it 'clamps accuracy to floor' do
      p = described_class.new(id: :x, agent_id: :a, predicted_state: { v: 1.0 })
      100.times { p.record_actual(actual_state: { v: 0.0 }) }
      expect(p.accuracy).to be >= Legion::Extensions::CognitiveEmpathy::Helpers::Constants::ACCURACY_FLOOR
    end

    it 'clamps accuracy to ceiling' do
      p = described_class.new(id: :x, agent_id: :a, predicted_state: { v: 0.5 })
      100.times { p.record_actual(actual_state: { v: 0.5 }) }
      expect(p.accuracy).to be <= Legion::Extensions::CognitiveEmpathy::Helpers::Constants::ACCURACY_CEILING
    end
  end

  describe '#accurate?' do
    it 'returns false at default accuracy (0.5)' do
      expect(perspective.accurate?).to be false
    end

    it 'returns true when accuracy is above 0.6 after repeated correct predictions' do
      p = described_class.new(id: :y, agent_id: :b, predicted_state: { v: 0.5 }, confidence: 0.9)
      10.times { p.record_actual(actual_state: { v: 0.5 }) }
      expect(p.accurate?).to be true
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = perspective.to_h
      expect(h).to include(
        :id, :agent_id, :perspective_type, :predicted_state, :actual_state,
        :confidence, :accuracy, :accurate, :resolved, :created_at, :resolved_at
      )
    end

    it 'rounds accuracy to 4 decimal places' do
      h = perspective.to_h
      expect(h[:accuracy].to_s).to match(/\A\d+\.\d{1,4}\z/)
    end

    it 'resolved_at is nil before recording actual' do
      expect(perspective.to_h[:resolved_at]).to be_nil
    end

    it 'resolved_at is set after recording actual' do
      perspective.record_actual(actual_state: {})
      expect(perspective.to_h[:resolved_at]).not_to be_nil
    end
  end
end
