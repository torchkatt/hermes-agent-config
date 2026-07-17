---
name: codebase-search-toolkit
description: "Four-tier codebase search: codebase-memory-mcp (semantic, fastest), graphify (architecture), terminal+grep (fallback), search_files (ripgrep). Use in this priority order."
---

# Codebase Search Toolkit

Use this hierarchy when searching codebases, tracing symbols, or understanding architecture. Don't default to `search_files` — pick the right layer.

**PRIMERO:** Verificar si `codebase-memory-mcp` ya indexó el proyecto. Si la DB existe en `~/.cache/codebase-memory-mcp/<project-slug>.db`, usar `mcporter` vía `npx mcporter call --stdio "...codebase-memory-mcp.exe\"" search_graph|search_code|trace_path`. Solo caer a grep/graphify si el proyecto no está indexado.

## Companion reference files

- `references/codebase-memory-mcp-commands.md` — full parameter reference for every codebase-memory-mcp tool (search_graph, search_code, trace_path, index_repository, etc.)
- `references/swiftdata-viewmodel-injection.md` — pattern for wiring `ModelContext` into `@Observable` ViewModels when SwiftData needs to be queried from outside a View (e.g. AuthViewModel reading UserHealthProfile). Apply when: you need `@Query`-like access in a plain class; you're injecting shared services that need to read/write SwiftData.

---

## Tier 0 — codebase-memory-mcp (semantic, fastest, Alexander's machine)

**When:** Searching for functions, classes, variables by name or natural language. **Always start here** — the projects are already indexed in SQLite-backed knowledge graphs.

**Prereq:** `npx mcporter` (auto-installs).

**Connection — never use `mcporter config import`** (it doesn't pick up `.claude/.mcp.json`). Always use ad-hoc `--stdio`:

```bash
CBM="C:/Users/ALEXANDER SANDOVAL/AppData/Local/Programs/codebase-memory-mcp/codebase-memory-mcp.exe"
npx mcporter call --stdio "\"$CBM\"" <tool> <args> --output json
```

**Key tools (see reference file for full parameter detail):**

| Tool | Purpose | Example |
|------|---------|---------|
| `search_graph` | BM25 semantic search | `project="..." query="auth login" limit=10` |
| `search_code` | Grep-like raw search | `pattern="func.*login" project="..."` |
| `trace_path` | Call graph trace | `function_name="Login" project="..." depth=3` |
| `get_code_snippet` | Full source by qualified name | `qualified_name="..." project="..."` |
| `get_architecture` | Project layer/module overview | `project="..." aspects=['layers','modules']` |
| `index_repository` | Re-index after changes | `repo_path="..." mode="fast|moderate|full"` |
| `index_status` | Check node/edge counts | `project="..."` |
| `detect_changes` | Check changed files since last index | `project="..." depth=2` |
| `list_projects` | List all indexed projects | (no args) |

**Detect changes before re-indexing** — always check what's changed first:
```bash
npx mcporter call --stdio "..." detect_changes project="C-Users-..." depth=2
```
Only re-index `full` if new files are missing from search results; fast/moderate modes may not pick up new files.

**Project slugs** — get them from `list_projects`. Common ones:
- `femcontrol-app` → `C-Users-ALEXANDER-SANDOVAL-Documents-PERSONAL-DESARROLLO-femcontrol-app`
- `HermesTorch` → `C-Users-ALEXANDER-SANDOVAL-Documents-PERSONAL-DESARROLLO-HermesTorch`
- `Torch` → `C-Users-ALEXANDER-SANDOVAL-Documents-PERSONAL-DESARROLLO-Torch`
- `YoutubeTeam` → `C-Users-ALEXANDER-SANDOVAL-Documents-PERSONAL-DESARROLLO-YoutubeTeam`
- `Antigravity IDE` → `C-Users-ALEXANDER-SANDOVAL-AppData-Local-Programs-Antigravity-IDE`
- `Codex` → `C-Program-Files-WindowsApps-OpenAI.Codex_...-app`

**Re-indexing:** After code changes, kill any stale `codebase-memory-mcp.exe` processes first (`taskkill /f /im codebase-memory-mcp.exe`), delete the `.db*` files from `~/.cache/codebase-memory-mcp/`, then re-index with `mode="full"`. `fast`/`moderate` modes may not pick up new files if the index deduplicates.

---

## Tier 1 — Graphify (architecture, relationships, big picture)

**When:** Questions about architecture, file relationships, "what uses X?", "how does X connect to Y?"

**Commands:**
```bash
graphify explain "SymbolName"         # what a node is + its neighbors
graphify path "NodeA" "NodeB"         # shortest path between two concepts
graphify /path/to/project              # build full graph (one-time per project)
```

**Note:** This install's CLI supports `explain`, `path`, `add`, `diagnose`, `clone` only. No `query` or `--update` is available. For full pipeline use the Python API.

**Output:** `graphify-out/graph.json` + `GRAPH_REPORT.md` + `graph.html`

**Prereq:** `pip install graphifyy` or `uv tool install graphifyy`

---

## Tier 2 — terminal + grep/find (when search_files fails on Windows)

**When:** `search_files` returns IO errors on Windows (common with deeply nested dirs like `Project/Project/Subproject/`).

```bash
find /path -name "*.swift" 2>/dev/null                     # files by name
grep -rn "Pattern" --include="*.swift" /path                # content search
find . -name "*.swift" -exec grep -l "Class" {} \;          # files containing pattern
```

**Why:** On Windows with MSYS2/git-bash, `search_files` (ripgrep via Hermes) sometimes can't resolve nested paths. Native terminal `grep`/`find` always works.

---

## Tier 3 — search_files (ripgrep, fastest on non-problematic paths)

**When:** Simple pattern search, file glob search, on paths that don't trigger Windows IO errors.

```
search_files(pattern="ClassName", path=".", file_glob="*.swift", output_mode="content")
search_files(pattern="*ViewModel*", target="files")       # find files by name
search_files(pattern="class.*ViewModel", file_glob="*.swift")  # regex content
```

---

## Tier 4 — pygount (LOC metrics, language breakdown)

**When:** "How big is this project?", language ratios, code vs comments.

```bash
pygount --format=summary --folders-to-skip=".git,node_modules,venv,__pycache__" .
```

---

## Pitfalls

| Problem | Root cause | Fix |
|---------|-----------|-----|
| `search_files` IO error | Windows nested path resolution bug | Use terminal+grep (Tier 2) |
| codebase-memory index returns old results | Index stale after file changes | Kill processes, delete .db files, re-index `full` |
| mcporter `config import` finds nothing | Looks for `.claude.json` not `.claude/.mcp.json` | Use `--stdio` with full exe path instead |
| Graphify `query` command missing | CLI version doesn't support it | Use `explain`/`path` instead, or Python API |
| codebase-memory-mcp DB locked | Stale processes from prior `--stdio` calls | `taskkill /f /im codebase-memory-mcp.exe` before re-index. `delete_project` may also fail with Permission denied — delete `.db*` manually from `~/.cache/codebase-memory-mcp/` |
| `graphify --update` not found | CLI doesn't implement it | Delete `graphify-out/` and rebuild with bare `graphify /path` |
