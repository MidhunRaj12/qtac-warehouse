-- fact_preference integrity checks

DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT applicant_id, course_code, application_year
        FROM warehouse.fact_preference
        GROUP BY applicant_id, course_code, application_year
        HAVING COUNT(*) > 1
    ) t;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' duplicate business key(s) in fact_preference';
    RAISE NOTICE 'PASS: preference business key is unique';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.fact_preference fp
    LEFT JOIN warehouse.dim_applicant da ON da.applicant_sk = fp.applicant_sk
    WHERE da.applicant_sk IS NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' preference(s) reference a missing applicant_sk';
    RAISE NOTICE 'PASS: all applicant_sk values resolve to dim_applicant';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.fact_preference fp
    LEFT JOIN warehouse.dim_course dc ON dc.course_sk = fp.course_sk
    WHERE dc.course_sk IS NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' preference(s) reference a missing course_sk';
    RAISE NOTICE 'PASS: all course_sk values resolve to dim_course';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.fact_preference
    WHERE response = 'Accepted' AND offer_status != 'Offered';
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' Accepted response(s) without offer_status = Offered';
    RAISE NOTICE 'PASS: all Accepted responses have offer_status = Offered';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.dim_course
    WHERE course_code !~ '^[A-Z]{2,4}-[A-Z]{2,4}[0-9]{1,3}$';
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' course code(s) do not match expected format';
    RAISE NOTICE 'PASS: all course codes match expected format';
END $$;


-- Warning only: offers where applicant best ATAR is below course cutoff.
-- Known case: applicant 1008 offered QUT-DS001 (cutoff 82) with ATAR 68.
-- Possible alternative entry pathway — not a pipeline failure, flagged for review.
DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.fact_preference fp
    INNER JOIN warehouse.dim_course dc
            ON dc.course_sk = fp.course_sk
           AND dc.is_active = TRUE
           AND dc.atar_cutoff IS NOT NULL
    INNER JOIN (
        SELECT applicant_id, MAX(atar_score) AS atar_score
        FROM warehouse.dim_qualification
        WHERE atar_score IS NOT NULL
        GROUP BY applicant_id
    ) best ON best.applicant_id = fp.applicant_id
    WHERE fp.offer_status = 'Offered'
      AND best.atar_score < dc.atar_cutoff;
    IF v_count > 0 THEN
        RAISE NOTICE 'WARN: % offer(s) issued below course ATAR cutoff — see docs/data_quality.md', v_count;
    ELSE
        RAISE NOTICE 'PASS: no offers below course ATAR cutoff';
    END IF;
END $$;