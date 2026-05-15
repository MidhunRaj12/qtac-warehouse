-- Type 1 course dimension.
-- Upsert pattern: safe to rerun; existing rows are updated in place.

BEGIN;

INSERT INTO warehouse.dim_course (
    course_code,
    course_name,
    institution_code,
    institution_name,
    campus,
    study_mode,
    duration_years,
    atar_cutoff,
    csp_available,
    is_active
)
SELECT
    TRIM(course_code)                                                           AS course_code,
    TRIM(course_name)                                                           AS course_name,
    TRIM(institution_code)                                                      AS institution_code,
    TRIM(institution_name)                                                      AS institution_name,
    TRIM(campus)                                                                AS campus,
    INITCAP(TRIM(study_mode))                                                   AS study_mode,
    NULLIF(TRIM(duration_years), '')::INTEGER                                   AS duration_years,
    NULLIF(TRIM(atar_cutoff), '')::NUMERIC(5,2)                                 AS atar_cutoff,
    CASE UPPER(TRIM(csp_available))
        WHEN 'Y' THEN TRUE
        WHEN 'N' THEN FALSE
        ELSE NULL
    END                                                                         AS csp_available,
    CASE TRIM(active_flag)
        WHEN '1' THEN TRUE
        WHEN '0' THEN FALSE
        ELSE NULL
    END                                                                         AS is_active
FROM raw.courses
WHERE TRIM(course_code) IS NOT NULL
ON CONFLICT (course_code) DO UPDATE SET
    course_name         = EXCLUDED.course_name,
    institution_code    = EXCLUDED.institution_code,
    institution_name    = EXCLUDED.institution_name,
    campus              = EXCLUDED.campus,
    study_mode          = EXCLUDED.study_mode,
    duration_years      = EXCLUDED.duration_years,
    atar_cutoff         = EXCLUDED.atar_cutoff,
    csp_available       = EXCLUDED.csp_available,
    is_active           = EXCLUDED.is_active,
    load_ts             = now();

COMMIT;