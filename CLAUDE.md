# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Repository Purpose

Personal Claude Code hooks, skills, commands and agents, organized as a marketplace of independent plugins.

## Key Rules

- **README.md must be kept up to date** - when a plugin or component is added, renamed or removed, update README.md and `.claude-plugin/marketplace.json` in the same change.
- **No personal configuration** - scripts and configs must not contain hardcoded personal paths, editor preferences or machine-specific settings. Use environment variables (e.g. `$EDITOR`) for user-specific values.
- **Self-contained documentation** - do not reference skills, commands or configurations that exist only in a personal Claude Code setup. Refer only to what exists in this repository.

## Structure

- `.claude-plugin/marketplace.json` - marketplace catalog listing all plugins
- `plugins/<name>/` - one independent plugin per directory:
  - `.claude-plugin/plugin.json` - plugin manifest (name, description, version)
  - `skills/<skill>/SKILL.md` - skills, with optional `scripts/` and `references/` next to them
  - `commands/<command>.md` - slash commands
  - `agents/<agent>.md` - subagent definitions
  - `hooks/hooks.json` - hook definitions
- `tests/test-*.sh` - shell tests, all picked up by CI automatically
- `.github/scripts/` - CI helpers; `check-frontmatter.py` validates YAML frontmatter in every `.md` file

## Conventions

- Scripts referenced from skills, commands and hooks use `${CLAUDE_PLUGIN_ROOT}` for paths: plugins are copied to a cache location on install, so relative and absolute paths break.
- **Versioning** - each plugin has its own semver `version` in `plugins/<name>/.claude-plugin/plugin.json`, bumped independently: patch for fixes, minor for new components, major for breaking changes. Any change to shipped plugin content (skills, commands, agents, hooks, scripts, references) is a release and needs a bump.
- **Changelog** - every version bump adds an entry to `CHANGELOG.md` in the same change, headed `## <plugin> v<version> - YYYY-MM-DD`.
- **Cross-references** - refer to skills with the plugin prefix: `/<plugin>:<skill>`.

## Local Development

- Load a plugin without publishing: `claude --plugin-dir plugins/<name>`. Run `/reload-plugins` in the session to pick up file changes.

## Testing

- `python3 .github/scripts/check-frontmatter.py .` - validate frontmatter
- `python3 .github/scripts/check-frontmatter.py --test` - its own tests
- `for t in tests/test-*.sh; do bash "$t"; done` - shell tests
- `shellcheck` on every `*.sh`
