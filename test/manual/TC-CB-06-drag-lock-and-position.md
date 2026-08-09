# TC-CB-06 — Drag, lock and position persistence

**Area:** TargetCooldownBar | **Client:** Era | **Mandatory:** yes

## Preconditions

- Any character; start with the bar unlocked (default)

## Steps

1. `/rgcw conf enable` to show the example bar so there is something to grab
2. Drag the bar to a new position, e.g. the lower left corner
3. `/reload`
4. Open `/rgcw opt` → Options and check "Lock Targetcooldownbar"
5. Try to drag the bar again
6. `/reload`, then uncheck the lock and drag the bar back to center
7. Drag the bar against a screen edge and past it
8. `/rgcw conf disable`

## Expected

- While unlocked the bar shows its dialog backdrop and drags freely
- The dropped position survives the reload (stored under `frames.CW_TargetCooldownBarFrame`)
- Checking the lock removes the backdrop and makes the bar immovable - mouse down/up does nothing
- The lock state itself survives the reload
- The bar is clamped to the screen: it cannot be dragged (partly) off-screen
- Hiding the preview leaves the bar at the configured position
- No Lua errors
