-- Preference fact table. Full rebuild on each run.
-- Deduplicates on business key (applicant_id, course_code, application_year),
-- keeping the row with the lowest preference_id.
-- Known duplicate: P022 is identical to P004 and is dropped by the dedup logic.

BEGIN;

TRUNCATE warehouse.fact_preference;

INSERT INTO warehouse.fact_preference (
    preference_id,
    applicant_id,
    applicant_sk,
    course_code,
    course_sk,
    preference_order,
    application_year,
    offer_status,
    offer_date,
    response,
    response_date
)
SELECT
    p.preference_id,
    p.applicant_id,
    d.applicant_sk,
    p.course_code,
    c.course_sk,
    p.preference_order,
    p.application_year,
    NULLIF(TRIM(p.offer_status), '')                                AS offer_status,
    CASE WHEN UPPER(TRIM(p.offer_date))     IN ('NULL', '')
         THEN NULL ELSE TRIM(p.offer_date)::DATE
    END                                                             AS offer_date,
    CASE WHEN UPPER(TRIM(p.response))       IN ('NULL', '')
         THEN NULL ELSE NULLIF(TRIM(p.response), '')
    END                                                             AS response,
    CASE WHEN UPPER(TRIM(p.response_date))  IN ('NULL', '')
         THEN NULL ELSE TRIM(p.response_date)::DATE
    END                                                             AS response_date
FROM (
    -- Dedup: one row per applicant + course + year. Lowest preference_id wins.
    SELECT DISTINCT ON (applicant_id::INTEGER, course_code, application_year::INTEGER)
        preference_id,
        applicant_id::INTEGER       AS applicant_id,
        TRIM(course_code)           AS course_code,
        preference_order::INTEGER   AS preference_order,
        application_year::INTEGER   AS application_year,
        offer_status,
        offer_date,
        response,
        response_date
    FROM raw.preferences
    WHERE preference_id IS NOT NULL
    ORDER BY applicant_id::INTEGER,
             course_code,
             application_year::INTEGER,
             preference_id ASC
) p
INNER JOIN warehouse.dim_applicant d
        ON d.applicant_id = p.applicant_id
       AND d.is_current = TRUE
INNER JOIN warehouse.dim_course c
        ON c.course_code = p.course_code;

COMMIT;