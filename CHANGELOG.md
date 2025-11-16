# Changelog

All notable changes to the Tmux Orchestrator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-16

### Added
- `.gitignore` file for runtime and temporary files
- `LICENSE` file (MIT License)
- `CONTRIBUTING.md` with contribution guidelines
- `CHANGELOG.md` for tracking project changes
- `VERSION` file for version tracking
- `lib/tmux-helpers.sh` - Shared library with common functions:
  - Container detection logic
  - Template substitution functions
  - Message sending helpers
  - Pane capture utilities
- `registry/` directory structure for host agent logs
- `examples/host-tmux.conf` - Recommended tmux configuration
- Documentation sections in README.md:
  - OAuth Setup for containerized agents
  - Network Security & Firewall configuration
  - Container Features (modern CLI tools)
- Comprehensive code review and cleanup

### Changed
- Replaced hardcoded paths in `CLAUDE.md` with generic examples
- Updated all `/Users/jasonedward/Coding/` references to `~/repos/`
- Removed placeholders from `developer-briefing.txt` (now uses dynamic session detection)
- Enhanced `tmux_utils.py` with docstring and usage documentation

### Fixed
- Replaced `bc` dependency in `schedule_with_note.sh` with bash arithmetic (container compatibility)
- Improved shell script compatibility across different environments

### Documentation
- Updated README.md with three new major sections
- Added comprehensive contributor guidelines
- Created example configuration files
- Improved code documentation and comments

## [Unreleased]

### Planned
- Automated test suite for shell scripts
- Integration tests for container deployment
- Performance optimizations for large projects
- Additional agent role templates
- Enhanced monitoring and observability

---

## Version History

### Version Numbering

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backwards compatible)
- **PATCH** version: Bug fixes (backwards compatible)

### How to Update VERSION

When making changes:
1. Update the `VERSION` file
2. Add entry to this CHANGELOG.md
3. Tag the release: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tags: `git push --tags`

---

[1.0.0]: https://github.com/username/tmux-orchestrator/releases/tag/v1.0.0
