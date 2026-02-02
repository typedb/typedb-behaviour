# TypeDB Behaviour: Bzlmod Migration Status

**Status: COMPLETE**

All 21 targets build successfully with Bazel 8.0.0 using Bzlmod.

## Build Verification

```bash
bazelisk build //...
```

**Results:**
- 21 targets analyzed
- All targets build successfully
- No exclusions required

## Repository Purpose

This repository contains BDD (Behavior-Driven Development) test specifications in Gherkin format (`.feature` files) that define the expected behavior of TypeDB drivers and the core server.

## Targets

The repository primarily contains:
- `checkstyle_test` - Code style verification
- `exports_files` - Exposes `.feature` files for consumers
- `filegroup` - CI targets

## Configuration

### MODULE.bazel

Key configurations:
- **Python**: 3.11 toolchain (required for checkstyle)
- **Kotlin**: toolchain registered (required for checkstyle)
- **Local overrides**: `typedb_dependencies` and `typedb_bazel_distribution`

### Dependencies

```
typedb_behaviour
├── typedb_dependencies (local)
│   └── typedb_bazel_distribution (local, transitive)
└── BCR modules
    ├── bazel_skylib (1.7.1)
    ├── rules_python (1.0.0)
    └── rules_kotlin (2.0.0)
```

## Files

| File | Purpose |
|------|---------|
| `MODULE.bazel` | Bzlmod configuration |
| `.bazelversion` | Bazel 8.0.0 |
| `.bazelrc` | Build flags |
| `WORKSPACE` | Deprecated, kept for backward compatibility |

## Consumers

This repository is consumed by:
- `typedb` - BDD tests for core server
- `typedb-driver` - BDD tests for drivers
- `typedb-cluster` - BDD tests for cluster
- `typedb-console` - BDD tests for console

Feature files are exported via `exports_files` and can be referenced by consumers.
