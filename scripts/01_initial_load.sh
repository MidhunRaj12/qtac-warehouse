#!/bin/bash
set -e

cd "$(dirname "$0")/.."

PG="psql postgresql://qtac:qtac@localhost:5432/qtac"

echo "Creating schemas and tables..."
$PG -f sql/00_setup/01_schemas.sql
$PG -f sql/00_setup/02_raw_tables.sql
$PG -f sql/00_setup/03_warehouse_tables.sql
$PG -f sql/00_setup/04_mart_tables.sql

echo "Loading raw data..."
$PG -c "\copy raw.applicants(applicant_id,first_name,last_name,date_of_birth,email,phone,state,postcode,created_date,updated_date) FROM 'data/applicants.csv' CSV HEADER"
$PG -c "UPDATE raw.applicants SET source_file = 'applicants.csv' WHERE source_file IS NULL"

$PG -c "\copy raw.courses(course_code,course_name,institution_code,institution_name,campus,study_mode,duration_years,atar_cutoff,csp_available,active_flag) FROM 'data/courses.csv' CSV HEADER"
$PG -c "UPDATE raw.courses SET source_file = 'courses.csv' WHERE source_file IS NULL"

$PG -c "\copy raw.qualifications(qualification_id,applicant_id,qualification_type,institution_name,year_completed,gpa,atar_score,verified) FROM 'data/qualifications.csv' CSV HEADER"
$PG -c "UPDATE raw.qualifications SET source_file = 'qualifications.csv' WHERE source_file IS NULL"

$PG -c "\copy raw.preferences(preference_id,applicant_id,course_code,preference_order,application_year,offer_status,offer_date,response,response_date) FROM 'data/preferences.csv' CSV HEADER"
$PG -c "UPDATE raw.preferences SET source_file = 'preferences.csv' WHERE source_file IS NULL"

echo "Building warehouse layer..."
$PG -f sql/10_warehouse/dim_course.sql
$PG -f sql/10_warehouse/dim_applicant.sql  #SCD2

echo "Initial load complete."