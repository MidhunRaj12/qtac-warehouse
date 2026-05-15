-- Gold layer: one row per applicant.
-- Accepted offer: the Accepted preference with the lowest preference_order.
-- Qualification type: highest level credential held (Bachelor > Diploma > Cert IV > Year 12).
-- ATAR score: best score across all qualifications, not just the primary one.
-- Applicants with no accepted offer or no qualification still appear (LEFT JOIN).

BEGIN;

TRUNCATE mart.accepted_offers;

WITH accepted_prefs AS (
    SELECT DISTINCT ON (fp.applicant_id)
        fp.applicant_id,
        fp.course_code,
        dc.course_name,
        dc.institution_name
    FROM warehouse.fact_preference fp
    INNER JOIN warehouse.dim_course dc ON dc.course_sk = fp.course_sk
    WHERE fp.response = 'Accepted'
    ORDER BY fp.applicant_id, fp.preference_order ASC
),
qualification_ranked AS (
    SELECT
        applicant_id,
        qualification_type,
        ROW_NUMBER() OVER (
            PARTITION BY applicant_id
            ORDER BY
                CASE qualification_type
                    WHEN 'Bachelor'        THEN 1
                    WHEN 'Diploma'         THEN 2
                    WHEN 'Certificate IV'  THEN 3
                    WHEN 'Certificate III' THEN 4
                    WHEN 'Year 12'         THEN 5
                    ELSE 99
                END,
                year_completed DESC
        ) AS rn
    FROM warehouse.dim_qualification
),
best_atar AS (
    SELECT applicant_id, MAX(atar_score) AS atar_score
    FROM warehouse.dim_qualification
    GROUP BY applicant_id
)
INSERT INTO mart.accepted_offers (
    applicant_id,
    full_name,
    state,
    course_code,
    course_name,
    institution_name,
    qualification_type,
    atar_score
)
SELECT
    da.applicant_id,
    da.first_name || ' ' || da.last_name   AS full_name,
    da.state,
    ap.course_code,
    ap.course_name,
    ap.institution_name,
    qr.qualification_type,
    ba.atar_score
FROM warehouse.dim_applicant da
LEFT JOIN accepted_prefs ap
       ON ap.applicant_id = da.applicant_id
LEFT JOIN qualification_ranked qr
       ON qr.applicant_id = da.applicant_id
      AND qr.rn = 1
LEFT JOIN best_atar ba
       ON ba.applicant_id = da.applicant_id
WHERE da.is_current = TRUE;

COMMIT;
