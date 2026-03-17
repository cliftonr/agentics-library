# Sync All Installed Items

## Context
Refresh every locally installed skill, agent, and prompt by re-pulling from its source. A fast, lazy "make sure everything is up to date" command.

## Steps

### 1. Sync the Library Repo
Pull the latest catalog before reading:
```bash
cd <LIBRARY_SKILL_DIR>
git pull
```

### 2. Read the Catalog
- Read `library.yaml`
- Parse all entries from `library.skills`, `library.agents`, and `library.prompts`

### 3. Find All Installed Items
For each entry in the catalog:
- Determine the type (skill, agent, prompt) and corresponding directories from `default_dirs`
- Check if a directory or file matching the entry name exists in the **default** directory
- Check if a directory or file matching the entry name exists in the **global** directory
- Search recursively for name matches
- Collect every entry that is installed locally (either default or global)
- If nothing is installed, tell the user and exit

### 4. Confirm Sources

Before fetching, show the user a summary of what will be synced:

| Name | Type | Source |
|------|------|--------|
| skill-name | skill | /local/path/... |
| other-skill | skill | https://github.com/org/repo.git |

Ask: "Sync these N items from the sources listed above?"

If the user declines, abort the sync.

### 5. Re-pull Each Installed Item
For each installed entry, fetch the latest from its source:

**If source is a local path** (starts with `/` or `~`):
- Resolve `~` to the home directory
- Get the parent directory of the referenced file
- For skills: copy the entire parent directory to the target:
  ```bash
  cp -R <parent_directory>/ <target_directory>/<name>/
  ```
- For agents: copy just the agent file to the target:
  ```bash
  cp <agent_file> <target_directory>/<agent_name>.md
  ```
- For prompts: copy just the prompt file to the target:
  ```bash
  cp <prompt_file> <target_directory>/<prompt_name>.md
  ```

**If source is a GitHub URL**:
- Parse the URL to extract: `org`, `repo`, `branch`, `file_path`
  - Browser URL pattern: `https://github.com/<org>/<repo>/blob/<branch>/<path>`
  - Raw URL pattern: `https://raw.githubusercontent.com/<org>/<repo>/<branch>/<path>`
- Determine the clone URL: `https://github.com/<org>/<repo>.git`
- Determine the parent directory path within the repo (everything before the filename)
- Clone into a temporary directory:
  ```bash
  tmp_dir=$(mktemp -d)
  git clone --depth 1 --branch <branch> https://github.com/<org>/<repo>.git "$tmp_dir"
  ```

**Verify integrity for GitHub sources:**
```bash
cd "$tmp_dir"
fetched_commit=$(git rev-parse --short HEAD)
```
- If the entry has a `commit` field: compare with fetched commit. If mismatch, log a warning in the sync report and **skip this item** (do not overwrite with an unexpected version). Add to the report: `| skill | name | skipped: commit mismatch (expected X, got Y) |`
- If the entry has no `commit` field: proceed but log the fetched commit in the report for the user to review.

- Copy the parent directory of the file to the target:
  ```bash
  cp -R "$tmp_dir/<parent_path>/" <target_directory>/<name>/
  ```
- Clean up:
  ```bash
  rm -rf "$tmp_dir"
  ```

**If clone fails (private repo)**, try SSH:
  ```bash
  git clone --depth 1 --branch <branch> git@github.com:<org>/<repo>.git "$tmp_dir"
  ```

### 6. Resolve Dependencies
For each installed entry that has a `requires` field:
- Check if each dependency is also installed
- If a dependency is not installed, pull it as well
- Process dependencies before the items that require them

### 7. Report Results
Display a summary table:

```
## Sync Complete

| Type | Name | Status | Commit |
|------|------|--------|--------|
| skill | skill-name | refreshed | a1b2c3d |
| agent | agent-name | refreshed | (local) |
| skill | other-skill | skipped: commit mismatch (expected X, got Y) | |
| skill | failed-skill | failed: <reason> | |

Synced: X items
Skipped: Y items
Failed: Z items
```

If any items failed (e.g., network error, missing source), list them with the reason so the user can fix individually.
