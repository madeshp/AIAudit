#!/usr/bin/env bash
# ============================================================================
# create_project.sh
#
# Scaffolds a full project around ai_audit_agents.py, following the
# repository layout in Appendix A of the AI Audit Agents implementation
# guide. Run this once to turn the single file into an installable,
# runnable project with a virtualenv, config, Docker, and test scaffolding.
#
# Usage:
#   ./create_project.sh [project_dir]
#
#   project_dir   defaults to ./ai-audit-agents
#
# Requires: python3 (3.11+ recommended), pip. Everything else is optional —
# the app itself degrades gracefully if e.g. Azure/Jira/GitLab/Datadog
# credentials aren't configured (see .env.example).
# ============================================================================
set -euo pipefail

SOURCE_FILE="ai_audit_agents.py"
PROJECT_DIR="${1:-ai-audit-agents}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERROR: $SOURCE_FILE not found in the current directory." >&2
  echo "Place this script next to ai_audit_agents.py and re-run." >&2
  exit 1
fi

echo "==> Creating project at ./$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"

# ---------------------------------------------------------------------------
# 1. Directory layout (Appendix A)
# ---------------------------------------------------------------------------
mkdir -p "$PROJECT_DIR"/{src,tests/unit,tests/integration,tests/fixtures,infra,config/prompts}

# The reference implementation ships as one importable module (src/app.py).
# It already contains every layer named in Appendix A (api/orchestrator/
# agents/connectors/llm/guardrails/aggregator/persistence/schemas) as
# clearly-commented sections. Splitting it into one-file-per-package is a
# mechanical follow-up refactor once the team is ready — the app runs
# correctly as shipped.
cp "$SOURCE_FILE" "$PROJECT_DIR/src/app.py"

echo "==> Copied $SOURCE_FILE -> $PROJECT_DIR/src/app.py"

# ---------------------------------------------------------------------------
# 2. requirements.yaml (Section 2 routing table, machine-readable)
# ---------------------------------------------------------------------------
cat > "$PROJECT_DIR/config/requirements.yaml" << 'YAML'
# Requirement-to-agent routing map (Section 2 of the implementation guide).
# Edit this file to change routing/requirement text without redeploying code.
# app.py reads this automatically via REQUIREMENTS_CONFIG_PATH
# (defaults to "config/requirements.yaml" relative to the working directory).

- id: 1
  category: "Audit Logging"
  agent: log_evidence
  text: >
    Provide sample audit-log entry proving logs capture inputs, outputs,
    prompts, timestamps, session metadata, model info, sources.
  automatable: "Y"

- id: 2
  category: "Validation Controls"
  agent: document
  text: >
    Document each validation control (UI, format, middleware,
    identifier-existence) and where it lives.
  automatable: "Partial"

- id: 3
  category: "Output Validation"
  agent: document
  text: >
    Evidence of output-validation controls: template adherence,
    completeness, accuracy, exception handling.
  automatable: "Partial"

- id: 4
  category: "Compliance Approvals"
  agent: compliance_registry
  text: "PRISM / AI Governance / BCIQ / ISS approval artifacts."
  automatable: "Y"

- id: 5
  category: "Design Documentation"
  agent: document
  text: "AI Use Case Whitepaper, Confluence docs, SD3/TDD."
  automatable: "Y"

- id: 6
  category: "SDLC & Change Mgmt"
  agent: jira_gitlab
  text: >
    All Jira projects/stories + ClearPath IDs related to the use case.
  automatable: "Y"

- id: 7
  category: "User Feedback"
  agent: jira_gitlab
  text: >
    Pilot feedback that led to an enhancement/config/prompt change.
  automatable: "Y"

- id: 8
  category: "AI Guardrails"
  agent: document
  text: >
    Decision record for guardrail tooling (e.g., Lumenova) applicability.
  automatable: "Partial"

- id: 9
  category: "Kill-Switch / Rollback"
  agent: jira_gitlab
  text: >
    Kill-switch implementation & test evidence, before/after config.
  automatable: "Y"

- id: 10
  category: "Human-in-the-Loop"
  agent: document
  text: >
    User guidance/training describing review responsibilities.
  automatable: "Y"

- id: 11
  category: "Access Mgmt — EU Users"
  agent: access
  text: "Confirm whether EU-based users use the system."
  automatable: "Y"

- id: 12
  category: "Access Mgmt — Service Accounts"
  agent: access
  text: "Confirm existence of non-human/service accounts."
  automatable: "Y"

- id: 13
  category: "Access Mgmt — Account Review"
  agent: access
  text: "Owner + review process for any service accounts."
  automatable: "Y"
YAML

echo "==> Wrote config/requirements.yaml"

# ---------------------------------------------------------------------------
# 3. requirements.txt / pyproject.toml
# ---------------------------------------------------------------------------
cat > "$PROJECT_DIR/requirements.txt" << 'REQS'
fastapi>=0.111
uvicorn[standard]>=0.30
pydantic>=2.7
httpx>=0.27
PyYAML>=6.0
openai>=1.30
python-docx>=1.1
pypdf>=4.2
pytest>=8.2
pytest-asyncio>=0.23
REQS

cat > "$PROJECT_DIR/pyproject.toml" << 'TOML'
[project]
name = "ai-audit-agents"
version = "0.1.0"
description = "Multi-agent backend evaluating evidence against the AI Audit Requirements Checklist"
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.111",
  "uvicorn[standard]>=0.30",
  "pydantic>=2.7",
  "httpx>=0.27",
  "PyYAML>=6.0",
  "openai>=1.30",
  "python-docx>=1.1",
  "pypdf>=4.2",
]

[project.optional-dependencies]
dev = ["pytest>=8.2", "pytest-asyncio>=0.23", "ruff>=0.5", "black>=24.4"]

[tool.ruff]
line-length = 100

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"
TOML

echo "==> Wrote requirements.txt and pyproject.toml"

# ---------------------------------------------------------------------------
# 4. .env.example (never commit real secrets)
# ---------------------------------------------------------------------------
cat > "$PROJECT_DIR/.env.example" << 'ENV'
# Copy to .env and fill in real values for a live deployment.
# Every integration below is OPTIONAL — anything left unset degrades to a
# mock/manual connector or the offline LLM stub rather than crashing.

# --- Azure OpenAI -----------------------------------------------------
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_API_KEY=
AZURE_OPENAI_API_VERSION=2024-06-01
AZURE_OPENAI_DEPLOYMENT=
AZURE_OPENAI_TEMPERATURE=0.1
AZURE_OPENAI_MAX_TOKENS=800

# --- Jira ---------------------------------------------------------------
JIRA_BASE_URL=
JIRA_EMAIL=
JIRA_API_TOKEN=

# --- GitLab ---------------------------------------------------------------
GITLAB_BASE_URL=
GITLAB_API_TOKEN=

# --- Datadog ---------------------------------------------------------------
DATADOG_API_KEY=
DATADOG_APP_KEY=
DATADOG_SITE=datadoghq.com

# --- Confluence / doc store ------------------------------------------------
CONFLUENCE_BASE_URL=
CONFLUENCE_API_TOKEN=

# --- IAM (leave unset to use the manual-input adapter) ----------------------
IAM_API_BASE_URL=
IAM_API_TOKEN=

# --- App behavior ------------------------------------------------------
# No database: the app is stateless — every /audit/evaluate call is
# computed purely from the request payload and returned in the response.
REQUIREMENTS_CONFIG_PATH=config/requirements.yaml
CONFIDENCE_THRESHOLD=0.7
AGENT_TIMEOUT_SECONDS=30
LOG_LEVEL=INFO
ENV

echo "==> Wrote .env.example"

# ---------------------------------------------------------------------------
# 5. Dockerfile + .gitignore + README
# ---------------------------------------------------------------------------
cat > "$PROJECT_DIR/infra/Dockerfile" << 'DOCKER'
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ src/
COPY config/ config/

ENV REQUIREMENTS_CONFIG_PATH=config/requirements.yaml

EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app:app", "--app-dir", "src", "--host", "0.0.0.0", "--port", "8000"]
DOCKER

cat > "$PROJECT_DIR/.gitignore" << 'GI'
.venv/
__pycache__/
*.pyc
.env
*.db
.pytest_cache/
.ruff_cache/
GI

cat > "$PROJECT_DIR/README.md" << 'MD'
# AI Audit Evaluation Agents

Reference implementation of the multi-agent audit-evidence evaluator
described in the implementation guide (Sections 5-10, Appendix A).

## Layout

```
src/app.py              Full application: schemas, connectors, Azure OpenAI
                         wrapper, 5 agents, orchestrator, guardrails,
                         aggregator, FastAPI app (see file header for a
                         section-by-section map back to the guide's phases)
config/requirements.yaml Requirement -> agent routing map (config-as-data)
infra/Dockerfile          Container build
tests/                    Add unit/integration/fixtures here (Phase 11)
.env.example              All optional environment configuration
```

**Stateless by design:** this app has no database and persists nothing.
`POST /audit/evaluate` computes the full audit check from the request
payload alone and returns the result in the same response; nothing about
the request or its verdicts is stored server-side afterwards. If you need
an audit trail again later, see the `on_verdict` hook documented at the
top of `src/app.py`.

## Quickstart

```bash
python -m venv .venv && source .venv/bin/activate   # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env        # fill in real values later; safe to leave blank

# Offline demo — no external services required:
python src/app.py demo

# Run the API:
python src/app.py serve
# or: uvicorn app:app --app-dir src --reload
```

Then:

```bash
curl -s http://localhost:8000/health
curl -s -X POST localhost:8000/audit/evaluate \
  -H 'content-type: application/json' \
  -d '{"requirement_ids":[1,11],"submitted_by":"me","user_input":"EU users: yes"}'
```

## What's mocked vs. live

Every external integration (Azure OpenAI, Jira, GitLab, Datadog, Confluence,
IAM) is optional. Leave its env vars unset and the corresponding connector
returns a clearly-labeled `[MOCK ...]` response instead of failing, and the
LLM wrapper falls back to a deterministic offline stub — so `demo` and
`serve` both work with zero credentials configured. Fill in `.env` to
switch each integration to live data independently.

## Next steps (per the guide's phased roadmap)

- Split `src/app.py` into the full Appendix-A module layout once the team
  is ready (api/, orchestrator/, agents/, connectors/, llm/, guardrails/,
  aggregator/, persistence/, schemas/) — the current single-module layout
  is functionally complete but not yet split for team-scale ownership.
- Move persistence from SQLite to PostgreSQL/Cosmos DB (Phase 2).
- Add the Phase 11 test suite (unit + integration + golden-dataset fixtures
  from the checklist's "Existing Response / Notes" column).
- Phase 12/13: security review, CI/CD, kill-switch runbook.
MD

echo "==> Wrote Dockerfile, .gitignore, README.md"

# ---------------------------------------------------------------------------
# 6. Minimal starter test (Phase 11 seed)
# ---------------------------------------------------------------------------
cat > "$PROJECT_DIR/tests/unit/test_smoke.py" << 'PYTEST'
"""Smoke tests proving the pipeline runs end-to-end offline (no external
services). Expand with per-connector and per-agent fixtures per Phase 11."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src"))

import asyncio
from app import EvidenceBundle, route_and_evaluate, build_audit_report


def test_end_to_end_offline():
    bundle = EvidenceBundle(requirement_ids=[1, 11], submitted_by="pytest",
                             user_input="EU users: yes")
    verdicts = asyncio.run(route_and_evaluate(bundle))
    assert len(verdicts) == 2
    report = build_audit_report(bundle.session_id, verdicts)
    assert report.session_id == bundle.session_id
    assert 0 <= report.overall_readiness_pct <= 100
PYTEST

echo "==> Wrote tests/unit/test_smoke.py"

# ---------------------------------------------------------------------------
# 7. Virtualenv + install + smoke test
# ---------------------------------------------------------------------------
echo "==> Creating virtualenv and installing dependencies (this may take a minute)"
(
  cd "$PROJECT_DIR"
  "$PYTHON_BIN" -m venv .venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install --quiet --upgrade pip
  pip install --quiet -r requirements.txt pytest pytest-asyncio

  echo "==> Running offline demo as a smoke test"
  (cd src && REQUIREMENTS_CONFIG_PATH="../config/requirements.yaml" python app.py demo) | tail -20

  echo "==> Running pytest smoke test"
  PYTHONPATH="src" pytest -q tests/unit/test_smoke.py || \
    echo "NOTE: smoke test failed — check the output above."
)

echo
echo "============================================================"
echo " Project ready at: ./$PROJECT_DIR"
echo "   cd $PROJECT_DIR && source .venv/bin/activate"
echo "   python src/app.py serve      # start the API on :8000"
echo "   python src/app.py demo       # offline end-to-end demo"
echo "============================================================"
