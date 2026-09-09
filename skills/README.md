# Inlay Agent Skills

Agent skills for integrating [inlay](https://github.com/leancodepl/inlay) into add-to-app
projects, maintained by the inlay team. A skill is a folder of focused instructions in the open
[Agent Skills](https://agentskills.io/) format (`SKILL.md`) that teaches an AI coding agent *how*
to perform a specific task following best practices — reducing mistakes and making the agent
reliably complete the work.

These skills are for **users of inlay** embedding Flutter in their own native iOS and Android
apps.

## Installation

Install the skills into your project with the [`skills`](https://github.com/vercel-labs/skills)
CLI, targeting the agent(s) you use. Claude Code reads `.claude/skills/`, while Cursor, Codex,
GitHub Copilot, Antigravity, Gemini CLI and most others share `.agents/skills/` (the `universal`
target):

```bash
# Claude Code
npx skills add leancodepl/inlay/skills -s '*' -a claude-code -y

# Cursor, Codex, GitHub Copilot, Antigravity, Gemini CLI, … (the "universal" location)
npx skills add leancodepl/inlay/skills -s '*' -a universal -y

# …or cover both at once
npx skills add leancodepl/inlay/skills -s '*' -a claude-code universal -y
```

To update later:

```bash
npx skills update
```

> **Claude Code:** `npx skills update` can write to `.agents/skills` instead of `.claude/skills`
> (where Claude Code reads them), due to
> [vercel-labs/skills#744](https://github.com/vercel-labs/skills/issues/744). If your skills stop
> being picked up, regenerate them with
> `npx skills add leancodepl/inlay/skills -s '*' -a claude-code -y`.

## Available skills

| Skill | Description | Example prompt |
|---|---|---|
| [inlay-setup](inlay-setup/SKILL.md) | Set up inlay in an add-to-app project for the first time — Flutter module dependencies, the `inlay.yaml` codegen config, the companion native plugin, and native host wiring on both iOS and Android. | Set up inlay so my iOS and Android apps can open Flutter screens |
| [inlay-add-route](inlay-add-route/SKILL.md) | Add or change inlay routes, dialogs, and shared stores — edit the annotated schema, regenerate Dart/Kotlin/Swift, and wire both the Flutter and native sides. | Add a Flutter settings screen that native code can open with a user id |
| [inlay-testing](inlay-testing/SKILL.md) | Write widget tests for screens that use `InlayNavigator` or `KeyValueStorage`, using the in-memory fakes from `package:inlay/testing.dart`. | Write a widget test for a screen that navigates and reads a shared store |
