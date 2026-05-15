#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG="psql postgresql://qtac:qtac@localhost:5432/qtac"

echo "Running tests..."
echo ""

echo "--- dim_applicant ---"
$PG -f "$ROOT/sql/30_tests/test_dim_applicant.sql"

echo ""
echo "--- fact_preference ---"
$PG -f "$ROOT/sql/30_tests/test_fact_preference.sql"

echo ""
echo "--- mart ---"
$PG -f "$ROOT/sql/30_tests/test_mart.sql"

echo ""
echo "All tests passed."