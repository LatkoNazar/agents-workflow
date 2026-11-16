{
  "$schema": "https://raw.githubusercontent.com/LatkoNazar/agents-workflow/main/schema/workflow.schema.json",
  "project": {
    "name": "{{PROJECT_NAME}}",
    "stack": ["{{PRIMARY_BACKEND}}", "{{PRIMARY_FRONTEND}}"],
    "defaultBranch": "main"
  },
  "kanban": {
    "provider": "local",
    "specsDir": ".agents/specs",
    "ticketsDir": ".agents/tickets",
    "externalConfig": {
      "githubRepo": "",
      "trelloBoardId": "",
      "linearTeamKey": ""
    },
    "labels": {
      "readyForAgent": "ready-for-agent",
      "afk": "afk",
      "hitl": "hitl",
      "inProgress": "in-progress",
      "inReview": "in-review",
      "done": "done"
    }
  },
  "architecture": {
    "slicingPolicy": "vertical-tracer-bullets",
    "moduleStyle": "deep-modules",
    "verticalRoots": [
      "backend/src/modules",
      "frontend/src/features"
    ],
    "publicEntrypoints": [
      "facade.py",
      "facade.ts",
      "index.ts"
    ],
    "forbidCrossInternalImports": true,
    "contractSync": {
      "enabled": true,
      "schemaPath": "contracts/openapi.json",
      "syncCommand": "./.agents/scripts/verify.sh --contracts-only"
    },
    "uiLinter": {
      "enabled": true,
      "styleSystem": "tailwind-cva",
      "command": "./.agents/scripts/lint-ui.sh"
    }
  },
  "sandbox": {
    "worktreesDir": ".worktrees",
    "branchPrefix": "feat/",
    "portOffsetStep": 100,
    "devComposeProject": "{{DEV_COMPOSE_PROJECT}}",
    "devComposeFile": "docker-compose.yml",
    "cloneState": {
      "postgres": {
        "enabled": true,
        "container": "{{POSTGRES_CONTAINER}}",
        "user": "postgres",
        "sourceDb": "{{POSTGRES_DEV_DB}}",
        "mode": "template-or-dump"
      },
      "mongodb": {
        "enabled": false,
        "container": "{{MONGO_CONTAINER}}",
        "sourceDb": "{{MONGO_DEV_DB}}"
      },
      "redis": {
        "enabled": false,
        "container": "{{REDIS_CONTAINER}}"
      },
      "dockerVolumes": [
        "{{DEV_VOLUME_1}}"
      ],
      "copyPaths": [
        ".env",
        "storage/profiles",
        "storage/uploads"
      ],
      "symlinkPaths": [
        "node_modules",
        "frontend/node_modules",
        ".venv"
      ]
    }
  },
  "orchestration": {
    "defaultTemplate": "parallel-dag-with-review",
    "availableTemplates": [
      "single-ticket",
      "sequential-with-review",
      "parallel-dag-with-review"
    ],
    "maxParallelWorktrees": 3,
    "maxReviewIterations": 3,
    "smartZoneLimitTokens": 100000,
    "mergeStrategy": "auto-merge",
    "verifyCommand": "./.agents/scripts/verify.sh",
    "serialVerifyMutex": false,
    "roles": {
      "explorer": {
        "provider": "claude",
        "model": "claude-haiku-4-5",
        "agentFile": ".agents/agents/explorer.md"
      },
      "planner": {
        "provider": "claude",
        "model": "claude-opus-4-6",
        "agentFile": ""
      },
      "implementer": {
        "provider": "claude",
        "model": "claude-sonnet-4-6",
        "agentFile": ".agents/agents/implementer.md"
      },
      "tester": {
        "provider": "claude",
        "model": "claude-sonnet-4-6",
        "agentFile": ".agents/agents/tester.md"
      },
      "reviewer": {
        "provider": "claude",
        "model": "claude-opus-4-6",
        "agentFile": ".agents/agents/reviewer.md"
      },
      "merger": {
        "provider": "claude",
        "model": "claude-sonnet-4-6",
        "agentFile": ".agents/agents/merger.md"
      }
    }
  }
}
