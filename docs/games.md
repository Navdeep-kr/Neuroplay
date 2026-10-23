# NEUROPLAY — Cognitive Games Specification

> **Status**: Living document · Last updated: 2026-10-23

This document specifies the rules, cognitive domains, deterministic engine mechanics, scoring equations, and accessibility standards for NEUROPLAY's core cognitive training exercises.

> [!NOTE]
> All NEUROPLAY exercises are built from foundational cognitive science paradigms (Corsi block-tapping, Wisconsin Card Sorting task-switching, visual search Go/No-Go). None copy proprietary names, artwork, level layouts, or text from commercial brain-training apps.

---

## 1. Memory Matrix (Spatial Working Memory)

- **Game ID**: `memory-matrix`
- **Cognitive Domain**: Memory (Spatial manipulation and pattern retention)
- **Engine Version**: `1.0.0`
- **Target Audience**: All ages; scales from 3×3 to 5×5 grid sizes.

### 1.1 Objective & Mechanics
1. **Memorize Phase**: The player is presented with a grid of neutral tiles. A subset of tiles illuminates with mint accents and star symbols for a brief preview duration (e.g. 1500ms).
2. **Recall Phase**: The tiles clear. The player taps or selects the grid cells where the pattern was located.
3. **Feedback & Progression**:
   - Correct tile selections illuminate with a checkmark and earn +100 points.
   - Erroneous selections highlight with an alert border and deduct points.
   - Finding all pattern tiles advances to the next round with a perfect streak bonus.
   - Max 3 mistakes allowed per trial to avoid infinite loops.

### 1.2 Difficulty Scaling

| Difficulty | Grid Dimensions | Target Tiles | Preview Duration | Total Rounds |
|---|---|---|---|---|
| **Easy** | 3×3 (9 tiles) | 3 | 2000 ms | 5 |
| **Medium** | 4×4 (16 tiles) | 4 | 1500 ms | 5 |
| **Hard** | 5×5 (25 tiles) | 5 | 1200 ms | 5 |
| **Expert** | 5×5 (25 tiles) | 6 | 1000 ms | 5 |
| **Practice** | 3×3 (9 tiles) | 3 | 2500 ms | 2 (unranked) |

### 1.3 Scoring Formula
$$\text{RawScore} = (\text{CorrectTiles} \times 100) + (\text{PerfectRounds} \times 150) - (\text{Mistakes} \times 40)$$
$$\text{AccuracyBonus} = \text{round}(\text{Accuracy} \times 400)$$
$$\text{SpeedBonus} = \max(0, (30 - \text{ActiveSeconds}) \times 10)$$
$$\text{FinalScore} = \text{max}\left(0, \text{RawScore} + 150 + \text{AccuracyBonus} + \text{SpeedBonus}\right) \times \text{DifficultyMultiplier}$$

### 1.4 Accessibility & Controls
- **Non-Color Distinction**: Highlighted tiles display distinct star icons (`★`) in addition to color.
- **Controls**: Full mouse/touch support, directional keyboard navigation, and Space/Enter selection.
- **Motion**: No strobe effects; smooth color transitions respecting `disableAnimations`.

---

## 2. Reflex Forge (Cognitive Flexibility & Speed)

- **Game ID**: `reflex-forge`
- **Cognitive Domain**: Cognitive Flexibility (Rule switching & task adaptation)
- **Engine Version**: `1.0.0`

### 2.1 Objective & Mechanics
1. **Dual Attributes**: Every symbol combines a **Geometric Shape** (Circle, Square, Triangle, Diamond) and a **Fill Pattern** (Solid, Striped, Dotted, Outline).
2. **Active Rule**: The header prominently displays the current rule:
   - `MATCH SHAPE`: Player must match the target's geometric shape.
   - `MATCH PATTERN`: Player must match the target's fill pattern.
3. **Rule Shift**: The rule automatically switches every 2–3 rounds. An alert banner notifies the player to inhibit previous habits and apply the new rule.
4. **Distractor Foils**: Options include a direct foil that matches the *inactive* attribute, rigorously testing distractor inhibition.

### 2.2 Difficulty Scaling

| Difficulty | Options Count | Shift Frequency | Speed Target | Total Rounds |
|---|---|---|---|---|
| **Easy** | 3 | Every 3 rounds | 1800 ms | 6 |
| **Medium** | 3 | Every 3 rounds | 1300 ms | 8 |
| **Hard** | 3 | Every 2 rounds | 1000 ms | 10 |
| **Expert** | 3 | Every 2 rounds | 800 ms | 12 |
| **Practice** | 3 | Every 2 rounds | 2500 ms | 3 (unranked) |

### 2.3 Scoring Formula
$$\text{RawScore} = \max(0, (\text{CorrectMatches} \times 120) - (\text{Errors} \times 50))$$
$$\text{AccuracyBonus} = \text{round}(\text{Accuracy} \times 350)$$
$$\text{SpeedBonus} = \sum \max(0, (\text{TargetMs} - \text{ReactionMs}) \times 0.1)$$
$$\text{FinalScore} = \text{max}\left(0, \text{RawScore} + 150 + \text{AccuracyBonus} + \text{StreakBonus} + \text{SpeedBonus}\right) \times \text{DifficultyMultiplier}$$

### 2.4 Accessibility & Controls
- **Non-Color Distinction**: Uses geometric outlines and fill patterns rather than hue alone.
- **Keyboard Shortcuts**: Number keys `[1]`, `[2]`, `[3]` for immediate keyboard response.
- **Accessible Feedback**: Correct matches flash a subtle check indicator; rule shift errors display distinct guidance.

---

## 3. Focus Reactor (Selective Attention & Distractor Suppression)

- **Game ID**: `focus-reactor`
- **Cognitive Domain**: Focus & Attention (Visual search, vigilance, Go/No-Go)
- **Engine Version**: `1.0.0`

### 3.1 Objective & Mechanics
1. **Target Specification**: Header displays a designated target (e.g. `SEEK TARGET: Star`).
2. **Visual Array**: An array of 4 to 6 items appears containing distractors sharing similar geometric attributes.
3. **Presence vs Absence**:
   - In ~75% of trials, the target is present in one of the slots. The player taps the matching slot (`[1]`–`[4]`).
   - In ~25% of trials, the target is absent. The player must declare absence by tapping `"Target Absent"` or pressing `[Space]`.
4. **Outcomes**:
   - **Hit**: Correct target slot selected (+100 pts + speed bonus).
   - **Correct Rejection**: Target absence correctly declared (+120 pts).
   - **False Alarm**: Distractor tapped or slot tapped when target was absent (-60 pts penalty).
   - **Miss**: Absent declared when target was present (-40 pts penalty).

### 3.2 Difficulty Scaling

| Difficulty | Displayed Slots | Target Presence | Speed Target | Total Rounds |
|---|---|---|---|---|
| **Easy** | 3 | 80% | 1800 ms | 6 |
| **Medium** | 4 | 75% | 1400 ms | 8 |
| **Hard** | 6 | 70% | 1100 ms | 10 |
| **Expert** | 6 | 65% | 900 ms | 12 |
| **Practice** | 3 | 75% | 2500 ms | 3 (unranked) |

### 3.3 Scoring Formula
$$\text{RawScore} = \max(0, (\text{Hits} \times 100) + (\text{CorrectRejections} \times 120) - (\text{FalseAlarms} \times 60) - (\text{Misses} \times 40))$$
$$\text{AccuracyBonus} = \text{round}(\text{Accuracy} \times 350)$$
$$\text{FinalScore} = \text{max}\left(0, \text{RawScore} + 150 + \text{AccuracyBonus} + \text{StreakBonus} + \text{SpeedBonus}\right) \times \text{DifficultyMultiplier}$$

### 3.4 Accessibility & Controls
- **Non-Color Distinction**: Uses 6 distinct geometric shapes (`Star`, `Hexagon`, `Cross`, `Pentagon`, `Diamond`, `Circle`) and optional markers (`•`, `○`, `≡`).
- **Keyboard Shortcuts**: Number keys `[1]`–`[4]` for slot selection, `[Space]` for absence declaration, and `[Esc]` for pause.
