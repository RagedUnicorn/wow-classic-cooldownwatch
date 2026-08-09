# TC-VB-01 — Version broadcast and update notification

**Area:** Version broadcast | **Client:** Era | **Mandatory:** no (conditional)

> The running version is broadcast over GUILD/RAID/PARTY under the `RGCW_VER` addon-message prefix
> on `PLAYER_ENTERING_WORLD` and `GROUP_ROSTER_UPDATE` only, throttled by a 10s cooldown. A
> strictly newer version received from another player prints the update notice **once per session**;
> the announced version persists in `lastNotifiedVersion` so relogs are not re-nagged.
>
> Run this case when a second account/client (or a cooperative guild/party member) is available, or
> whenever `code/Comm.lua` changed.

## Preconditions

- Two clients/accounts in the same party or guild, one running the current dev checkout
- On the "older" client: temporarily lower the `## Version` line in `CooldownWatch.toc` (revert
  afterwards) so one side is genuinely behind

## Steps

1. Log both clients in and party up
2. On the older client, watch chat for the update notice
3. `/reload` on the older client - the versions are exchanged again
4. Log the older client out and back in
5. Have members join/leave the party a few times in quick succession
6. On the **newer** client, confirm nothing is announced

## Expected

- The older client prints the "new version is available" notice naming the newer version, exactly
  once
- The notice does not repeat on `/reload` or relog (the announced version is remembered)
- Rapid roster changes do not spam the notice and do not trip WoW's addon-message throttle (the
  broadcast is rate-limited)
- The newer client never announces anything about the older one
- Raising the older client's version above the other side's stops the notice entirely
- No Lua errors on either client
