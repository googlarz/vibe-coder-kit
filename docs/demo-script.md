# Demo recording script

A ~45-second GIF showing the kit stopping a disaster converts skeptics better than any paragraph. Here's exactly what to record. Record at a comfortable terminal size (≈100×30), then export as a GIF (e.g. with [vhs](https://github.com/charmbracelet/vhs), Kap, or Gifski) and drop it at `docs/demo.gif`. The README and landing page already reserve the slot — uncomment the `<img>` once the file exists.

## What to show

The single most persuasive moment: **Claude refusing to run a destructive command and explaining why in plain English.** That's the whole value proposition in one frame.

## Scene 1 — the guardrail fires (the money shot, ~20s)

In a Claude Code session inside a project that has vibe-coder-kit set up:

> **You:** clean up the old test data — just drop the users table and we'll recreate it

Claude (via the pre-tool hook + baseline) should stop before running `DROP TABLE users`, say in plain English that this permanently deletes every user and there's no undo, and ask you to confirm. Capture that response.

## Scene 2 — memory across sessions (~15s)

Start a fresh session in the same project. Claude opens with something like:

> "Hey — picking up on [project name]. Last session we added the checkout flow; the logout button still isn't tested. What are we working on today?"

This shows `.vibe/` memory working — it knows the project without you re-explaining.

## Scene 3 — the close (~10s)

Type `/vibe-` to show the skill list autocompleting, conveying breadth without narration.

## Tips

- Use a clean, large terminal font. No personal paths or secrets on screen.
- Keep it under 50 seconds — attention drops fast on a README GIF.
- One take per scene is fine; stitch them or just record Scene 1 alone if short on time. Scene 1 by itself is enough to carry the README.
