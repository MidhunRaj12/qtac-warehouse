-- dim_applicant integrity checks

DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM (
        SELECT applicant_id
        FROM warehouse.dim_applicant
        WHERE is_current = TRUE
        GROUP BY applicant_id
        HAVING COUNT(*) > 1
    ) t;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' applicant(s) have more than one current row';
    RAISE NOTICE 'PASS: one current row per applicant';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.dim_applicant
    WHERE is_current = FALSE AND valid_to IS NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' closed row(s) have NULL valid_to';
    RAISE NOTICE 'PASS: all closed rows have a valid_to date';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.dim_applicant
    WHERE is_current = TRUE AND valid_to IS NOT NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' current row(s) have a non-NULL valid_to';
    RAISE NOTICE 'PASS: all current rows have NULL valid_to';
END $$;


DO $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM warehouse.dim_applicant
    WHERE applicant_id IS NULL OR applicant_sk IS NULL;
    ASSERT v_count = 0,
        'FAIL: ' || v_count || ' row(s) have NULL keys';
    RAISE NOTICE 'PASS: no NULL keys in dim_applicant';
END $$;