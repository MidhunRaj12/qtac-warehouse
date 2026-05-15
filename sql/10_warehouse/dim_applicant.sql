-- SCD Type 2 applicant dimension.
-- Detects changes by comparing each attribute against the current warehouse row.
-- Trusts source updated_date as the change marker for valid_from on new versions.
-- Idempotent: running against unchanged source data produces no changes.

BEGIN;

-- Stage: clean, deduplicate, and coerce types from raw.
-- DISTINCT ON handles two things: the duplicate 1002 row in the update file,
-- and multiple load events appended to raw.applicants over time.
-- Most recent updated_date wins; load_ts breaks ties.
CREATE TEMP TABLE staged_applicants ON COMMIT DROP AS
SELECT DISTINCT ON (applicant_id::INTEGER)
    applicant_id::INTEGER                       AS applicant_id,
    NULLIF(TRIM(first_name), '')                AS first_name,
    NULLIF(TRIM(last_name), '')                 AS last_name,
    NULLIF(TRIM(date_of_birth), '')::DATE       AS date_of_birth,
    LOWER(NULLIF(TRIM(email), ''))              AS email,
    NULLIF(TRIM(phone), '')                     AS phone,
    UPPER(NULLIF(TRIM(state), ''))              AS state,
    NULLIF(TRIM(postcode), '')                  AS postcode,
    NULLIF(TRIM(created_date), '')::DATE        AS created_date,
    NULLIF(TRIM(updated_date), '')::DATE        AS updated_date
FROM raw.applicants
WHERE applicant_id IS NOT NULL
ORDER BY applicant_id::INTEGER,
         updated_date::DATE DESC,
         load_ts DESC;


-- Identify rows that represent a real change against the current dim state,
-- or are new applicants not yet in the warehouse.
-- IS DISTINCT FROM handles NULL comparisons correctly —
-- a NULL phone becoming populated is treated as a change.
CREATE TEMP TABLE applicant_changes ON COMMIT DROP AS
SELECT s.*
FROM staged_applicants s
LEFT JOIN warehouse.dim_applicant d
       ON d.applicant_id = s.applicant_id
      AND d.is_current = TRUE
WHERE d.applicant_id   IS NULL
   OR d.first_name     IS DISTINCT FROM s.first_name
   OR d.last_name      IS DISTINCT FROM s.last_name
   OR d.date_of_birth  IS DISTINCT FROM s.date_of_birth
   OR d.email          IS DISTINCT FROM s.email
   OR d.phone          IS DISTINCT FROM s.phone
   OR d.state          IS DISTINCT FROM s.state
   OR d.postcode       IS DISTINCT FROM s.postcode;


-- Close out the current row for any applicant with detected changes.
UPDATE warehouse.dim_applicant d
   SET valid_to   = c.updated_date,
       is_current = FALSE
  FROM applicant_changes c
 WHERE d.applicant_id = c.applicant_id
   AND d.is_current = TRUE;


-- Insert new versions for changed applicants, and first versions for new ones.
INSERT INTO warehouse.dim_applicant (
    applicant_id,
    first_name,
    last_name,
    date_of_birth,
    email,
    phone,
    state,
    postcode,
    created_date,
    valid_from,
    valid_to,
    is_current,
    load_ts
)
SELECT
    applicant_id,
    first_name,
    last_name,
    date_of_birth,
    email,
    phone,
    state,
    postcode,
    created_date,
    updated_date    AS valid_from,
    NULL            AS valid_to,
    TRUE            AS is_current,
    now()           AS load_ts
FROM applicant_changes;

COMMIT;