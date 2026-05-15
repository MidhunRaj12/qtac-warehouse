#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG="psql postgresql://qtac:qtac@localhost:5432/qtac"

mkdir -p "$ROOT/exports"

echo "Exporting warehouse tables..."
$PG -c "\copy warehouse.dim_applicant         TO '$ROOT/exports/dim_applicant.csv'         CSV HEADER"
$PG -c "\copy warehouse.dim_course            TO '$ROOT/exports/dim_course.csv'             CSV HEADER"
$PG -c "\copy warehouse.dim_qualification     TO '$ROOT/exports/dim_qualification.csv'      CSV HEADER"
$PG -c "\copy warehouse.fact_preference       TO '$ROOT/exports/fact_preference.csv'        CSV HEADER"
$PG -c "\copy warehouse.reject_qualifications TO '$ROOT/exports/reject_qualifications.csv'  CSV HEADER"

echo "Exporting mart..."
$PG -c "\copy mart.accepted_offers            TO '$ROOT/exports/accepted_offers.csv'        CSV HEADER"

echo "Exports written to $ROOT/exports/"