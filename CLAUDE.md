# lex-cognitive-empathy

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Models the capacity to predict and track another agent's internal state. Four perspective types (cognitive, affective, motivational, situational) allow different modes of perspective-taking. Predictions are recorded, then outcomes are compared against them; accuracy is updated via EMA. Emotional contagion models the passive absorption of another agent's emotional state, tracked as a continuous `contagion_level` that decays each tick.

## Gem Info

- **Gem name**: `lex-cognitive-empathy`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveEmpathy`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_empathy/
  cognitive_empathy.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    empathy_engine.rb
    perspective.rb
  runners/
    cognitive_empathy.rb
```

## Key Constants

From `helpers/constants.rb`:

- `PERSPECTIVE_TYPES` — `%i[cognitive affective motivational situational]`
- `EMPATHIC_STATES` — `%i[detached observing resonating immersed]`
- `MAX_PERSPECTIVES` = `50`, `MAX_INTERACTIONS` = `200`, `MAX_HISTORY` = `200`
- `DEFAULT_ACCURACY` = `0.5`, `ACCURACY_FLOOR` = `0.1`, `ACCURACY_CEILING` = `0.95`
- `CONTAGION_RATE` = `0.15` (absorption rate per emotional contagion event)
- `CONTAGION_DECAY` = `0.05` (applied per `tick`)
- `ACCURACY_ALPHA` = `0.1` (EMA alpha for perspective accuracy updates)
- `ACCURACY_LABELS` — range hash: `0.8+` = `:excellent`, `0.6` = `:good`, `0.4` = `:moderate`, `0.2` = `:poor`, below = `:blind`

## Runners

All methods in `Runners::CognitiveEmpathy`:

- `take_empathic_perspective(agent_id:, perspective_type:, predicted_state:, confidence: 0.5)` — records a prediction about another agent's state; returns `perspective_id`; fails if `perspective_type` is invalid or limit reached
- `record_empathic_outcome(perspective_id:, actual_state:)` — compares the actual state against the prediction; updates EMA accuracy; marks perspective as resolved
- `empathic_accuracy_for(agent_id:)` — mean accuracy across all resolved perspectives for a given agent
- `overall_empathic_accuracy` — mean accuracy across all resolved perspectives globally
- `apply_emotional_contagion(emotion_valence:, intensity:)` — absorbs emotional state at `CONTAGION_RATE * intensity`; returns updated contagion_level and current empathic_state
- `current_empathic_state` — returns current `empathic_state` symbol and contagion_level
- `perspectives_for_agent(agent_id:)` — all perspectives recorded for a given agent
- `empathic_blind_spots` — returns the least and most accurate agents by resolved perspective accuracy
- `update_cognitive_empathy` — maintenance tick: applies contagion decay, prunes old resolved perspectives; call periodically
- `cognitive_empathy_stats` — full state dump: perspective count, resolved count, overall accuracy, contagion level, empathic state, history size

## Helpers

- `EmpathyEngine` — manages `@perspectives` hash and `@contagion_level`. `tick` applies `CONTAGION_DECAY` and prunes resolved perspectives when they exceed half of `MAX_PERSPECTIVES`. `empathic_state` returns the current state symbol based on contagion_level thresholds: `:immersed` (>= 0.75), `:resonating` (>= 0.45), `:observing` (>= 0.15), `:detached` (below).
- `Perspective` — prediction record with `predicted_state` (Hash), `actual_state` (Hash), `accuracy` (EMA). `record_actual(actual_state:)` computes per-key numeric error, derives `observed_accuracy = 1.0 - error`, then applies EMA: `accuracy = (1 - ALPHA) * accuracy + ALPHA * observed_accuracy`. `accurate?` returns true if accuracy > 0.6. `resolved?` returns true if actual_state is set.

## Integration Points

- `perspectives_for_agent` and `empathic_accuracy_for` can be queried from `lex-trust` to weight trust adjustments by empathic accuracy — agents whose behavior we predict accurately warrant higher trust reliability scores.
- `apply_emotional_contagion` can be driven from `lex-emotion`'s valence output during multi-agent interactions via `lex-mesh` — when a peer agent broadcasts emotional state, this extension absorbs it.
- `empathic_blind_spots` surfaces the agents we understand least — useful input to `lex-cognitive-blindspot` for registering interpersonal blind spots.
- `update_cognitive_empathy` is the natural periodic decay runner for `lex-tick`'s maintenance phase.

## Development Notes

- Accuracy uses EMA with `ACCURACY_ALPHA = 0.1` — new outcomes have low weight, making accuracy stable and slow-to-update. This is intentional for robustness.
- `compute_error` in `Perspective` uses key-union across predicted and actual hashes, treating missing keys as 0.0. Numeric values are used directly; booleans map to 1.0/0.0; other values map to 0.5. Total error is the mean absolute deviation across all keys.
- `ACCURACY_CEILING = 0.95` prevents accuracy from reaching 1.0 — models the irreducible uncertainty in predicting another agent's internal state.
- Pruning in `prune_old_perspectives` only removes resolved perspectives (unresolved remain indefinitely until `MAX_PERSPECTIVES` is hit). Pruning fires when resolved count exceeds `MAX_PERSPECTIVES / 2`.
- `contagion_level` is a global property of the engine, not per-agent — the agent has one empathic state at a time, reflecting the dominant emotional absorption level.
- `empathic_state` thresholds (0.15, 0.45, 0.75) are not stored as named constants — they are hardcoded in `EmpathyEngine#empathic_state`.
