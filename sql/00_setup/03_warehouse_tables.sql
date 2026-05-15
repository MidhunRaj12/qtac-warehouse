-- SCD Type 2 applicant dimension.
-- applicant_sk is the surrogate key. applicant_id is the natural key from source.
-- valid_to NULL means the row is current.
CREATE TABLE IF NOT EXISTS warehouse.dim_applicant (
    applicant_sk    SERIAL          PRIMARY KEY,
    applicant_id    INTEGER         NOT NULL,
    first_name      TEXT,
    last_name       TEXT,
    date_of_birth   DATE,
    email           TEXT,
    phone           TEXT,
    state           TEXT,
    postcode        TEXT,
    created_date    DATE,
    valid_from      DATE            NOT NULL,
    valid_to        DATE,
    is_current      BOOLEAN         NOT NULL DEFAULT TRUE,
    load_ts         TIMESTAMP       DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dim_applicant_natural
    ON warehouse.dim_applicant (applicant_id, is_current);


-- Type 1 course dimension. No versioning needed — course attributes
-- are stable within an application cycle.
CREATE TABLE IF NOT EXISTS warehouse.dim_course (
    course_sk           SERIAL          PRIMARY KEY,
    course_code         TEXT            NOT NULL UNIQUE,
    course_name         TEXT,
    institution_code    TEXT,
    institution_name    TEXT,
    campus              TEXT,
    study_mode          TEXT,
    duration_years      INTEGER,
    atar_cutoff         NUMERIC(5,2),
    csp_available       BOOLEAN,
    is_active           BOOLEAN,
    load_ts             TIMESTAMP       DEFAULT now()
);


CREATE TABLE IF NOT EXISTS warehouse.dim_qualification (
    qualification_sk    SERIAL          PRIMARY KEY,
    qualification_id    TEXT            NOT NULL UNIQUE,
    applicant_id        INTEGER         NOT NULL,
    qualification_type  TEXT,
    institution_name    TEXT,
    year_completed      INTEGER,
    gpa                 NUMERIC(4,2),
    atar_score          NUMERIC(5,2),
    verified            BOOLEAN,
    load_ts             TIMESTAMP       DEFAULT now()
);


CREATE TABLE IF NOT EXISTS warehouse.fact_preference (
    preference_id       TEXT            PRIMARY KEY,
    applicant_id        INTEGER         NOT NULL,
    applicant_sk        INTEGER         NOT NULL REFERENCES warehouse.dim_applicant (applicant_sk),
    course_code         TEXT            NOT NULL,
    course_sk           INTEGER         NOT NULL REFERENCES warehouse.dim_course (course_sk),
    preference_order    INTEGER,
    application_year    INTEGER,
    offer_status        TEXT,
    offer_date          DATE,
    response            TEXT,
    response_date       DATE,
    load_ts             TIMESTAMP       DEFAULT now()
);


-- Rows quarantined here failed referential integrity checks during load.
-- They are not in any warehouse table but are kept for audit and reprocessing.
CREATE TABLE IF NOT EXISTS warehouse.reject_qualifications (
    qualification_id    TEXT,
    applicant_id        TEXT,
    qualification_type  TEXT,
    institution_name    TEXT,
    year_completed      TEXT,
    gpa                 TEXT,
    atar_score          TEXT,
    verified            TEXT,
    reject_reason       TEXT            NOT NULL,
    reject_ts           TIMESTAMP       DEFAULT now(),
    source_file         TEXT
);