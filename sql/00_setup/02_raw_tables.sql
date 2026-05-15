CREATE TABLE IF NOT EXISTS raw.applicants (
    applicant_id    TEXT,
    first_name      TEXT,
    last_name       TEXT,
    date_of_birth   TEXT,
    email           TEXT,
    phone           TEXT,
    state           TEXT,
    postcode        TEXT,
    created_date    TEXT,
    updated_date    TEXT,
    load_ts         TIMESTAMP DEFAULT now(),
    source_file     TEXT
);

CREATE TABLE IF NOT EXISTS raw.courses (
    course_code         TEXT,
    course_name         TEXT,
    institution_code    TEXT,
    institution_name    TEXT,
    campus              TEXT,
    study_mode          TEXT,
    duration_years      TEXT,
    atar_cutoff         TEXT,
    csp_available       TEXT,
    active_flag         TEXT,
    load_ts             TIMESTAMP DEFAULT now(),
    source_file         TEXT
);

CREATE TABLE IF NOT EXISTS raw.qualifications (
    qualification_id    TEXT,
    applicant_id        TEXT,
    qualification_type  TEXT,
    institution_name    TEXT,
    year_completed      TEXT,
    gpa                 TEXT,
    atar_score          TEXT,
    verified            TEXT,
    load_ts             TIMESTAMP DEFAULT now(),
    source_file         TEXT
);

CREATE TABLE IF NOT EXISTS raw.preferences (
    preference_id       TEXT,
    applicant_id        TEXT,
    course_code         TEXT,
    preference_order    TEXT,
    application_year    TEXT,
    offer_status        TEXT,
    offer_date          TEXT,
    response            TEXT,
    response_date       TEXT,
    load_ts             TIMESTAMP DEFAULT now(),
    source_file         TEXT
);