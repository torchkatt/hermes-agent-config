# codebase-memory-mcp — Full parameter reference

## search_graph

```
search_graph(project, query?, label?, name_pattern?, qn_pattern?, file_pattern?,
             relationship?, min_degree?, max_degree?, exclude_entry_points?, limit?)
```

- `project`: `C-Users-<SLUG>` — project slug (use `list_projects` to see all)
- `query`: BM25 full-text search (camelCase splitting, structural boosting)
- `label`: filter by node type (`Class`, `Method`, `Variable`, `Function`, `Interface`)
- `name_pattern`: regex for exact name matching (ignores `query` when set)
- `qn_pattern`: regex for qualified_name matching
- `file_pattern`: glob filter (e.g. `*.swift`)
- `relationship`: filter by edge type
- `min_degree`/`max_degree`: filter by connection count
- `exclude_entry_points`: bool, hide top-level entry points
- `limit`: default 200; set higher for full results

## search_code

```
search_code(pattern, project, file_pattern?, path_filter?, mode?, context?, regex?, limit?)
```

- `pattern`: text to find (grep-like)
- `project`: slug
- `file_pattern`: glob (e.g. `*.swift`)
- `path_filter`: regex on file path
- `mode`: `compact` (default), `full` (with context), `files` (paths only)
- `context`: lines of context (default 0)
- `regex`: bool, treat pattern as regex
- `limit`: max results

## trace_path

```
trace_path(function_name, project, direction?, depth?, mode?, parameter_name?, edge_types?, risk_labels?, include_tests?)
```

- `function_name`: full qualified name or short name (suggests if ambiguous)
- `project`: slug
- `direction`: `inbound` | `outbound` | `both` (default)
- `depth`: traversal depth (default 2)
- `mode`: `calls` | `data_flow` | `cross_service`
- `parameter_name`: filter by parameter
- `edge_types`: filter edge types
- `risk_labels`: filter by risk
- `include_tests`: bool

## get_code_snippet

```
get_code_snippet(qualified_name, project, include_neighbors?)
```

- `qualified_name`: exact qualified_name from search_graph results
- `project`: slug
- `include_neighbors`: bool, include connected nodes' code

## get_architecture

```
get_architecture(project, aspects?)
```

- `project`: slug
- `aspects`: array — `['all']` for everything, or specific: `['layers','modules','relationships','entry_points','node_labels']`

## index_repository

```
index_repository(repo_path, mode?, target_projects?, persistence?)
```

- `repo_path`: absolute path to project
- `mode`: `full` (all files + similarity edges) | `moderate` (filtered + similarity) | `fast` (filtered, no similarity) | `cross-repo-intelligence`
- `target_projects`: for cross-repo mode, `["*"]` for all
- `persistence`: bool, write `.codebase-memory/graph.db.zst`

## Other tools

- `list_projects()` — no args
- `delete_project(project)` — may fail with Permission denied
- `index_status(project)` — returns node/edge counts
- `detect_changes(project, scope?, depth?, base_branch?, since?)` — changed files
- `manage_adr(project, mode?, content?, sections?)` — Architecture Decision Records
- `ingest_traces(traces, project)` — trace data ingestion
- `get_graph_schema(project)` — graph schema
- `query_graph(query, project, max_rows?)` — raw SQL against the graph DB
