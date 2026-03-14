# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveEmpathy::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: take perspective, record outcome, check accuracy, stats' do
    p1 = client.take_empathic_perspective(
      agent_id:         :person_a,
      perspective_type: :cognitive,
      predicted_state:  { valence: 0.7, arousal: 0.4 },
      confidence:       0.8
    )
    expect(p1[:success]).to be true
    perspective_id = p1[:perspective_id]

    outcome = client.record_empathic_outcome(
      perspective_id: perspective_id,
      actual_state:   { valence: 0.7, arousal: 0.4 }
    )
    expect(outcome[:success]).to be true

    acc = client.empathic_accuracy_for(agent_id: :person_a)
    expect(acc[:accuracy]).to be_a(Float)

    client.apply_emotional_contagion(emotion_valence: 0.8, intensity: 0.6)
    state = client.current_empathic_state
    expect(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::EMPATHIC_STATES)
      .to include(state[:empathic_state])

    stats = client.cognitive_empathy_stats
    expect(stats[:perspective_count]).to eq(1)
    expect(stats[:resolved_count]).to eq(1)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::CognitiveEmpathy::Helpers::EmpathyEngine.new
    c = described_class.new(engine: engine)
    c.take_empathic_perspective(
      agent_id:         :bob,
      perspective_type: :affective,
      predicted_state:  {},
      confidence:       0.5
    )
    expect(engine.perspectives.size).to eq(1)
  end

  it 'blind spots returns nil agents on fresh client' do
    result = client.empathic_blind_spots
    expect(result[:success]).to be true
    expect(result[:least_accurate_agent]).to be_nil
  end

  it 'overall accuracy is at default on fresh client' do
    result = client.overall_empathic_accuracy
    expect(result[:accuracy]).to eq(Legion::Extensions::CognitiveEmpathy::Helpers::Constants::DEFAULT_ACCURACY)
  end

  it 'perspectives_for_agent returns empty list for unknown agent' do
    result = client.perspectives_for_agent(agent_id: :ghost)
    expect(result[:count]).to eq(0)
  end
end
