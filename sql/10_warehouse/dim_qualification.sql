-- Type 1 qualification dimension.
-- Rows whose applicant_id has no match in the warehouse are quarantined to
-- reject_qualifications and excluded from the main dimension.
-- Known case: Q017 references applicant_id 9999 which does not exist in source.

BEGIN;

-- Stage: clean and coerce types.
-- gpa and atar_score arrive as the string literal "NULL" from source.
CREATE TEMP TABLE staged_qualifications ON COMMIT DROP AS
SELECT
    TRIM(qualification_id)                                          AS qualification_id,
    NULLIF(TRIM(applicant_id), '')::INTEGER                         AS applicant_id,
    NULLIF(TRIM(qualification_type), '')                            AS qualification_type,
    NULLIF(TRIM(institution_name), '')                              AS institution_name,
    NULLIF(TRIM(year_completed), '')::INTEGER                       AS year_completed,
    CASE WHEN UPPER(TRIM(gpa))        IN ('NULL', 'NIL', 'N/A', '') THEN NULL
         ELSE TRIM(gpa)::NUMERIC(4,2)
    END                                                             AS gpa,
    CASE WHEN UPPER(TRIM(atar_score)) IN ('NULL', 'NIL', 'N/A', '') THEN NULL
         ELSE TRIM(atar_score)::NUMERIC(5,2)
    END                                                             AS atar_score,
    CASE UPPER(TRIM(verified))
        WHEN 'Y' THEN TRUE
        WHEN 'N' THEN FALSE
        ELSE NULL
    END                                                             AS verified
FROM raw.qualifications
WHERE TRIM(qualification_id) IS NOT NULL;


-- Quarantine rows with no matching applicant.
-- NOT EXISTS guard makes this safe to rerun without creating duplicate rejects.
INSERT INTO warehouse.reject_qualifications (
    qualification_id,
    applicant_id,
    qualification_type,
    institution_name,
    year_completed,
    gpa,
    atar_score,
    verified,
    reject_reason,
    source_file
)
SELECT
    s.qualification_id,
    s.applicant_id::TEXT,
    s.qualification_type,
    s.institution_name,
    s.year_completed::TEXT,
    s.gpa::TEXT,
    s.atar_score::TEXT,
    s.verified::TEXT,
    'orphan_applicant_id',
    r.source_file
FROM staged_qualifications s
LEFT JOIN warehouse.dim_applicant d
       ON d.applicant_id = s.applicant_id
      AND d.is_current = TRUE
LEFT JOIN raw.qualifications r
       ON TRIM(r.qualification_id) = s.qualification_id
WHERE d.applicant_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM warehouse.reject_qualifications rq
       WHERE rq.qualification_id = s.qualification_id
  );


-- Load valid qualifications. Inner join silently drops orphaned rows —
-- they are already in reject_qualifications above.
INSERT INTO warehouse.dim_qualification (
    qualification_id,
    applicant_id,
    qualification_type,
    institution_name,
    year_completed,
    gpa,
    atar_score,
    verified
)
SELECT
    s.qualification_id,
    s.applicant_id,
    s.qualification_type,
    s.institution_name,
    s.year_completed,
    s.gpa,
    s.atar_score,
    s.verified
FROM staged_qualifications s
INNER JOIN warehouse.dim_applicant d
        ON d.applicant_id = s.applicant_id
       AND d.is_current = TRUE
ON CONFLICT (qualification_id) DO UPDATE SET
    qualification_type  = EXCLUDED.qualification_type,
    institution_name    = EXCLUDED.institution_name,
    year_completed      = EXCLUDED.year_completed,
    gpa                 = EXCLUDED.gpa,
    atar_score          = EXCLUDED.atar_score,
    verified            = EXCLUDED.verified,
    load_ts             = now();

COMMIT;