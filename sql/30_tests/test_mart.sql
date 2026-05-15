-- mart.accepted_offers integrity checks

DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT applicant_id
        FROM mart.accepted_offers
        GROUP BY applicant_id
        HAVING COUNT(*) > 1
    ) t;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' applicant(s) appear more than once in accepted_offers';
    RAISE NOTICE 'PASS: one row per applicant in mart';
END $$;


DO $$
DECLARE v_mart INTEGER; v_dim INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_mart FROM mart.accepted_offers;
    SELECT COUNT(*) INTO v_dim  FROM warehouse.dim_applicant WHERE is_current = TRUE;
    ASSERT v_mart = v_dim,
        'FAIL: mart has ' || v_mart || ' rows but dim_applicant has ' || v_dim || ' current applicants';
    RAISE NOTICE 'PASS: mart row count matches current applicant count (%)', v_mart;
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.fact_preference fp
    LEFT JOIN mart.accepted_offers mo ON mo.applicant_id = fp.applicant_id
    WHERE fp.response = 'Accepted'
      AND mo.course_code IS NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' applicant(s) with Accepted preference have no course in mart';
    RAISE NOTICE 'PASS: all applicants with an Accepted preference have a course in mart';
END $$;