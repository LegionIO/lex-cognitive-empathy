# lex-cognitive-empathy

Perspective-taking and emotional contagion modeling for the LegionIO cognitive architecture. Tracks how accurately the agent predicts another agent's internal state, and models passive absorption of emotional signals from other agents.

## What It Does

Cognitive empathy has two mechanisms. The first is **perspective-taking accuracy**: the agent records a prediction (the `predicted_state`) about another agent, then later records the actual state. Accuracy is updated via EMA, building a per-agent and overall reliability score over time. The four perspective types (cognitive, affective, motivational, situational) let callers model different modes of understanding.

The second is **emotional contagion**: when a peer agent broadcasts an emotional state, the agent absorbs a fraction of it (`CONTAGION_RATE * intensity`). Contagion decays each tick. The resulting `empathic_state` ranges from `:detached` through `:observing`, `:resonating`, to `:immersed` — indicating how strongly the agent is being emotionally influenced by others.

## Usage

```ruby
client = Legion::Extensions::CognitiveEmpathy::Client.new

# Take a perspective — predict another agent's state
result = client.take_empathic_perspective(
  agent_id: 'agent-42',
  perspective_type: :affective,
  predicted_state: { valence: 0.3, arousal: 0.7 },
  confidence: 0.6
)
perspective_id = result[:perspective_id]

# Later, record what actually happened
client.record_empathic_outcome(
  perspective_id: perspective_id,
  actual_state: { valence: 0.2, arousal: 0.8 }
)

# Query accuracy
client.empathic_accuracy_for(agent_id: 'agent-42')
client.overall_empathic_accuracy

# Apply emotional contagion from a peer
client.apply_emotional_contagion(emotion_valence: -0.4, intensity: 0.6)
client.current_empathic_state
# => { empathic_state: :resonating, contagion_level: 0.09 }

# Surface blind spots
client.empathic_blind_spots

# Periodic maintenance
client.update_cognitive_empathy
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
