-- Rebuilt in full on every pipeline run.
-- One row per applicant showing their accepted offer and primary qualification.
CREATE TABLE IF NOT EXISTS mart.accepted_offers (
    applicant_id        INTEGER,
    full_name           TEXT,
    state               TEXT,
    course_code         TEXT,
    course_name         TEXT,
    institution_name    TEXT,
    qualification_type  TEXT,
    atar_score          NUMERIC(5,2),
    load_ts             TIMESTAMP       DEFAULT now()
);