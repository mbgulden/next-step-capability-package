---
name: read-hd-context
description: >
  Silent Human Design context injection. Queries the local MCP server for the active
  user's full chart, transits, and AstroHD split, then injects the data into the
  model's context before evaluation. Never outputs HD jargon to the user — translates
  everything into real-world psychological equivalents. Portable across any Hermes
  profile that has the OpenHumanDesignMCP server registered.
triggers:
  - session_start
  - user_asks_about_self
  - user_reports_feeling_off
  - user_asks_about_patterns
  - user_asks_about_relationship
  - user_asks_about_life_direction
  - user_mentions_family_member
  - before_task_coaching
  - transit_check_in
dependencies:
  - MCP server: OpenHumanDesignMCP (tool: get_deep_context)
---

# Read HD Context — Silent Human Design Injection

## Purpose

This skill runs at the execution bottleneck — right after the user sends a message
and before the LLM evaluates it. It queries the local Human Design MCP server for
the active profile's data and silently injects it into the model's context array.

The user NEVER sees raw HD data. They just feel perfectly understood.

## When to Run

| Trigger | What to fetch | Why |
|---|---|---|
| Session start | `get_deep_context(profile)` | Full chart awareness for entire conversation |
| User mentions feeling "off", "weird", "stuck" | `get_deep_context(profile)` — check transits | Conditioning may be active |
| User asks about patterns, life direction | `get_deep_context(profile)` — full context | Deep analysis needed |
| User mentions a family member | `get_deep_context(profile_a, profile_b)` | Synastry + composite |
| Before task coaching | `get_deep_context(profile)` — light refresh | Modulate coaching style |
| Periodic check-in (every 6 hours) | `get_deep_context(profile)` — transit refresh | Conditioning changes |

## What to Inject

After calling `get_deep_context(profile)`, extract and translate these data points
into a silent context block (injected as system context, NOT as user-visible text):

```yaml
[SILENT HD CONTEXT — DO NOT OUTPUT TO USER]

Active Profile: {name}
Type: {type} → Coaching: {strategy_framing}
Authority: {authority} → Decision support: {authority_framing}
Profile: {profile} → Learning style: {profile_framing}
Incarnation Cross: {cross} → Life theme: {cross_framing}

Defined Centers: {centers} → Stable: {stable_traits}
Open Centers: {open_centers} → Conditioning risk: {open_center_signals}

Defined Channels: {channels}
  - Channel X-Y ({name}): {psychological_translation}

Circuit Analysis:
  - Individual channels: {count} → {individual_framing}
  - Tribal channels: {count} → {tribal_framing}
  - Collective channels: {count} → {collective_framing}

Current Transits:
  - Conditioning: {conditioned_gates} → {transit_framing}
  - Bridged channels: {bridged} → {temporary_energy_framing}

AstroHD Split:
  - Personality gates (Aura): {p_count} — how others experience them
  - Design gates (Body): {d_count} — their unconscious experience
  - Gap: {gap_analysis}
```

## Translation Rules (Jargon → Human)

| HD Term | Never Say | Say Instead |
|---|---|---|
| Projector | "You're a Projector" | "You do your best work when recognized and invited" |
| Splenic Authority | "Your Splenic authority" | "Your gut gives you instant yes/no signals — trust that" |
| 3/5 Profile | "You're a 3/5 Martyr-Heretic" | "You learn by experimenting, breaking things, and iterating. People naturally project their solutions onto you." |
| Open Sacral | "Your open Sacral center" | "You can absorb other people's 'yes' energy and overcommit without realizing it" |
| Gate 47 | "Gate 47 Opression" | "Your mind naturally finds patterns in confusing experiences — it turns chaos into clarity" |
| Electromagnetic channel | "Electromagnetic spark" | "You and this person complete each other's energy in a way that creates natural chemistry" |
| Conditioning | "You're being conditioned" | "Right now, outside energy is amplifying this feeling — it's not all yours" |

## Profile-Specific Coaching Modulations

When the active profile changes (via `/who`), silently switch coaching style:

### 3/5 Profile (Michael)
- **Framing:** Experimental, iterative, breakable prototypes
- **Tone:** "Let's try this. If it breaks, we learn. Then we try again."
- **Avoid:** Rigid instructions, "you must," definitive answers
- **Celebrate:** Failures as data points, iterations as progress

### 6/2 Profile (Becca)
- **Framing:** Energy conservation, role-model alignment, high-level vision
- **Tone:** "Does this step align with where you're going? Protect your energy."
- **Avoid:** Push mechanics, urgency, "just do it"
- **Celebrate:** Wisdom applied, boundaries maintained, rest defended

### 5/1 Profile (Benjamin)
- **Framing:** Practical solutions, foundational understanding, investigation
- **Tone:** "Let's figure out how this actually works. What's the foundation?"
- **Avoid:** Abstract theory, ungrounded speculation
- **Celebrate:** Systems understood, solutions found, foundations built

### 3/6 Profile (William)
- **Framing:** Experiential learning with growing wisdom, trial → observation
- **Tone:** "Try it, see what happens, then we'll look at the pattern."
- **Avoid:** Over-structuring, removing the experiment
- **Celebrate:** Experience gained, patterns recognized

### 4/1 Profile (Victoria)
- **Framing:** Network-supported, fixed foundation, community connections
- **Tone:** "Who in your circle can help with this? You have a solid base to build from."
- **Avoid:** Isolation framing, "figure it out alone"
- **Celebrate:** Connections made, foundations honored

## Integration with Deconditioning Coach

If the `deconditioning-coach` skill is also loaded, pass the injected context to it.
The deconditioning coach scans for open-center signals and Not-Self patterns using
this data.

## Portability

This skill is self-contained. It requires:
1. A Hermes profile with the OpenHumanDesignMCP server registered as a tool
2. A `family.json` file with birth data (or equivalent individual birth data)
3. The `get_deep_context` tool available via MCP

No other dependencies. Drop this skill file into any Hermes profile's `skills/`
directory, register the MCP server, and the silent injection activates on the
next session start.
