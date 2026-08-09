# TC-CT-04 — Buff-then-consume tracks the aura removal

**Area:** Cooldown tracking | **Client:** Era | **Mandatory:** yes

> The nine buff-then-consume spells (Cold Blood, Presence of Mind, Inner Focus, Divine Favor,
> Nature's Swiftness, Elemental Mastery, Combustion, Amplify Curse) start their in-game cooldown
> when the buff **disappears**, so they track `SPELL_AURA_REMOVED`, not the cast. This case needs a
> real combat log - the injector bypasses the event path.

## Preconditions

- A duel partner who can cast one of the listed spells (rogue Cold Blood or mage Presence of Mind
  are the easiest)
- Optionally a second partner able to purge/dispel a buff

## Steps

1. Duel the partner and have them cast the buff (e.g. Presence of Mind) **without** consuming it
2. Watch the bar while the buff is up
3. Have them consume it (cast the empowered spell)
4. Repeat, but have them cancel the buff manually (right-click the buff icon)
5. If a dispeller/purger is available: repeat and have the buff purged

## Expected

- Nothing appears on the bar while the buff is still up - the cast alone does not queue anything
- The cooldown slot appears the moment the buff disappears, in all three cases (consumed, cancelled,
  purged), and counts the full cooldown from that moment
- The queued entry is the tracked cast id (no duplicate slot from a separate aura id)
- No Lua errors
