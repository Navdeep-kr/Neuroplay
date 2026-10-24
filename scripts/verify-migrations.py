#!/usr/bin/env python3
"""
NEUROPLAY Migration Verification Script.
Validates migration file naming conventions, ordering, and syntax basics.
"""
import os
import re
import sys
from pathlib import Path

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "supabase" / "migrations"

def verify_migrations():
    print(f"Checking migrations in: {MIGRATIONS_DIR}")
    if not MIGRATIONS_DIR.exists():
        print("ERROR: Migrations directory does not exist.")
        sys.exit(1)

    sql_files = sorted([f for f in MIGRATIONS_DIR.glob("*.sql")])
    if not sql_files:
        print("WARNING: No SQL migration files found.")
        return

    pattern = re.compile(r"^(\d{14})_[a-zA-Z0-9_]+\.sql$")
    last_timestamp = ""
    errors = []

    for sql_file in sql_files:
        filename = sql_file.name
        match = pattern.match(filename)
        if not match:
            errors.append(f"Invalid migration filename format: {filename}. Expected YYYYMMDDHHMMSS_<name>.sql")
            continue

        timestamp = match.group(1)
        if timestamp <= last_timestamp:
            errors.append(f"Migration timestamp not strictly sequential: {filename} (previous: {last_timestamp})")
        last_timestamp = timestamp

        content = sql_file.read_text(encoding="utf-8")
        if not content.strip():
            errors.append(f"Empty migration file: {filename}")

        # Check for open unbalanced block comments
        if content.count("/*") != content.count("*/"):
            errors.append(f"Unbalanced multi-line comments in: {filename}")

        # Basic check for plain-text hardcoded secret keys
        if "service_role_key" in content and "placeholder" not in content and "SECURITY DEFINER" not in content:
            errors.append(f"Suspicious hardcoded service role token in: {filename}")

    if errors:
        print("\nMigration Verification Failed:")
        for err in errors:
            print(f"  - {err}")
        sys.exit(1)

    print(f"SUCCESS: {len(sql_files)} migration files verified with valid timestamp sequence and syntax integrity.")

if __name__ == "__main__":
    verify_migrations()
