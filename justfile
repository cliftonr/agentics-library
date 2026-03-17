set dotenv-load := true

# List available commands
default:
    @just --list

# Install the library (first-time setup)
install:
    claude --model opus "/library install"

# Add a new skill, agent, or prompt to the catalog
add prompt:
    #!/usr/bin/env bash
    set -euo pipefail
    prompt='{{prompt}}'
    claude --model opus "/library add $prompt"

# Pull a skill from the catalog (install or refresh)
use name:
    #!/usr/bin/env bash
    set -euo pipefail
    name='{{name}}'
    if [[ "$name" =~ [^a-zA-Z0-9_.:-] ]]; then
      echo "Error: name must contain only alphanumeric characters, dots, hyphens, underscores, and colons." >&2
      exit 1
    fi
    claude --model opus "/library use $name"

# Push local changes back to the source
push name:
    #!/usr/bin/env bash
    set -euo pipefail
    name='{{name}}'
    if [[ "$name" =~ [^a-zA-Z0-9_.:-] ]]; then
      echo "Error: name must contain only alphanumeric characters, dots, hyphens, underscores, and colons." >&2
      exit 1
    fi
    claude --model opus "/library push $name"

# Remove a locally installed skill
remove name:
    #!/usr/bin/env bash
    set -euo pipefail
    name='{{name}}'
    if [[ "$name" =~ [^a-zA-Z0-9_.:-] ]]; then
      echo "Error: name must contain only alphanumeric characters, dots, hyphens, underscores, and colons." >&2
      exit 1
    fi
    claude --model opus "/library remove $name"

# Sync all installed items (re-pull from source)
sync:
    claude --model opus "/library sync"

# List all entries in the catalog with install status
list:
    claude --model opus "/library list"

# Search the catalog by keyword
search keyword:
    #!/usr/bin/env bash
    set -euo pipefail
    keyword='{{keyword}}'
    if [[ "$keyword" =~ [^a-zA-Z0-9_.:\-\ ] ]]; then
      echo "Error: keyword contains invalid characters." >&2
      exit 1
    fi
    claude --model opus "/library search $keyword"
