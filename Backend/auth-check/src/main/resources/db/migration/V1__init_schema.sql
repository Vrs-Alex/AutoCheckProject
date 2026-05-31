CREATE TABLE users (
    id           BIGSERIAL PRIMARY KEY,
    email        VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name    VARCHAR(255) NOT NULL,
    role         VARCHAR(20)  NOT NULL CHECK (role IN ('EXPERT', 'CANDIDATE')),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE assignments (
    id              BIGSERIAL PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    checker_weights TEXT         NOT NULL,
    created_by      BIGINT       NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE submissions (
    id               BIGSERIAL PRIMARY KEY,
    assignment_id    BIGINT      NOT NULL REFERENCES assignments(id),
    candidate_id     BIGINT      NOT NULL REFERENCES users(id),
    file_path        TEXT,
    git_url          TEXT,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                         CHECK (status IN ('PENDING','RUNNING','DONE','ERROR')),
    total_score      NUMERIC(5,2),
    verdict          VARCHAR(20) CHECK (verdict IN ('ACCEPTED','REJECTED')),
    verdict_comment  TEXT,
    ai_review        TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at     TIMESTAMPTZ
);

CREATE TABLE check_results (
    id            BIGSERIAL PRIMARY KEY,
    submission_id BIGINT      NOT NULL REFERENCES submissions(id),
    checker_type  VARCHAR(50) NOT NULL
                      CHECK (checker_type IN
                          ('STATIC_ANALYSIS','ARCHITECTURE','BUILD','TESTS','DOCUMENTATION','GIT_PRACTICES')),
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING','RUNNING','PASSED','FAILED','ERROR')),
    score         NUMERIC(5,2),
    log           TEXT,
    started_at    TIMESTAMPTZ,
    finished_at   TIMESTAMPTZ
);
