# Worked example (illustrative)

One chat, fully wired. The chat id is a placeholder; the numbers are
realistic for a mid-life working thread.

**The chat:** `Deep Work`, id
`11111111-2222-3333-4444-555555555555`

**State file** — `~/hooks/state/chat-ticker-11111111-2222-3333-4444-555555555555.json`:

```json
{
  "base_name": "Deep Work",
  "chat_id": "11111111-2222-3333-4444-555555555555",
  "stamped_value": 98412,
  "updated_at": "2026-01-01T12:00:00Z",
  "value": 98412
}
```

`value` == `stamped_value`, so the title and the last read agree and the
loop stays silent. The chat's name in the list reads:

```
Deep Work ~98412
```

**Hook:** id `chat-ticker-11111111`, poll interval 600s, script =
`hook-script.instantiated.sh` in this folder (the template with the
chat id substituted), worker prompt = the template with
`<BASE_NAME>` = "Deep Work" and `<CHAT_ID>` = the id above.

**A drift moment, walked through:** the chat takes a heavy turn; the
agent reads `session_status` at 152,040 and writes `value: 103877` but
the turn ends before the rename lands. Title still says `~98412`,
state says `stamped_value: 98412`. Within 10 minutes the hook polls,
sees `103877 != 98412`, wakes the worker, which renames the chat to
`Deep Work ~103877`, sets `stamped_value: 103877`, verifies, and says
nothing. Total agent cost: one small run, once — instead of 144 runs a
day for a standing cron.
