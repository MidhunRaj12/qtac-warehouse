#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG="psql postgresql://qtac:qtac@localhost:5432/qtac"

# Append the update extract to raw.applicants.
# The SCD2 transform will pick up changes on the next run.
echo "Appending update extract to raw.applicants..."
$PG -c "\copy raw.applicants(applicant_id,first_name,last_name,date_of_birth,email,phone,state,postcode,created_date,updated_date) FROM '$ROOT/data/applicants_update.csv' CSV HEADER"
$PG -c "UPDATE raw.applicants SET source_file = 'applicants_update.csv' WHERE source_file IS NULL"

echo "Rebuilding warehouse layer..."
$PG -f "$ROOT/sql/10_warehouse/dim_course.sql"
$PG -f "$ROOT/sql/10_warehouse/dim_applicant.sql"  #SCD2
$PG -f "$ROOT/sql/10_warehouse/dim_qualification.sql"
$PG -f "$ROOT/sql/10_warehouse/fact_preference.sql"

echo "Rebuilding mart..."
$PG -f "$ROOT/sql/20_mart/mart_accepted_offers.sql"

echo "Update load complete."