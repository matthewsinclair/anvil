# Anvil Scripts

This directory contains utility scripts for common development tasks.

## Available Scripts

### `scripts/setup`
Initial project setup. Run this after cloning the repository.
- Installs dependencies
- Sets up the database
- Builds assets
- Runs seeds

### `scripts/server`
Starts the Phoenix development server.
```bash
scripts/server
```

### `scripts/iex`
Starts an interactive Elixir shell with the project loaded.
```bash
scripts/iex
```

### `scripts/mix`
Runs mix commands (wrapper for consistency).
```bash
scripts/mix compile
scripts/mix deps.get
```

### `scripts/test`
Runs the test suite with trace enabled.
```bash
scripts/test
scripts/test test/specific_test.exs
```

### `scripts/repl`
Starts an IEx REPL session.
```bash
scripts/repl
```

### `scripts/mcduct`
Clean rebuild - cleans, updates deps, compiles, and runs tests.
```bash
scripts/mcduct
```

## Usage

All scripts should be run from the project root directory. They will automatically handle directory changes if needed.

Make sure scripts are executable:
```bash
chmod +x scripts/*
```