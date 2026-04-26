-- Caridad Culinary Training Program — Dropout Risk Database
-- Program: 10-week cohort, Mon–Fri 8:30AM–3:30PM, 845 N Main Ave Tucson AZ
--
-- Relation schema decisions:
--   - participants ON DELETE RESTRICT (preserve historical records)
--   - risk_events  ON DELETE RESTRICT (preserve intervention audit trail)
--   - weekly_checkins: UNIQUE (participant_id, week_number) — one per week
--   - risk_scores:     UNIQUE (participant_id, week_number) — one per week
--   - baseline_assessments: 1:N — participant can re-enroll across cohorts
--   - interventions.risk_event_id: NOT NULL — must be triggered by a risk event
--   - coordinators table replaces free-text coordinator_name

-- ─────────────────────────────────────────────
-- COHORTS
-- ─────────────────────────────────────────────
CREATE TABLE cohorts (
    cohort_id      SERIAL PRIMARY KEY,
    cohort_number  INTEGER NOT NULL UNIQUE,       -- e.g. 43 for "Class 43"
    start_date     DATE NOT NULL,
    end_date       DATE NOT NULL,                 -- typically start_date + 10 weeks
    max_capacity   INTEGER NOT NULL DEFAULT 20,
    status         TEXT NOT NULL DEFAULT 'upcoming'
                       CHECK (status IN ('upcoming', 'active', 'completed')),
    notes          TEXT,
    CONSTRAINT cohort_dates_valid CHECK (end_date > start_date)
);

-- ─────────────────────────────────────────────
-- COORDINATORS
-- ─────────────────────────────────────────────
CREATE TABLE coordinators (
    coordinator_id SERIAL PRIMARY KEY,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    email          TEXT NOT NULL UNIQUE,
    phone          TEXT,
    role           TEXT NOT NULL DEFAULT 'coordinator'
                       CHECK (role IN ('coordinator', 'supervisor', 'admin')),
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- PARTICIPANTS
-- ─────────────────────────────────────────────
CREATE TABLE participants (
    participant_id  SERIAL PRIMARY KEY,
    cohort_id       INTEGER NOT NULL
                        REFERENCES cohorts(cohort_id)
                        ON DELETE RESTRICT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    phone           TEXT,                         -- used for SMS check-ins
    email           TEXT,
    date_of_birth   DATE,
    enrollment_date DATE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'graduated', 'dropped', 'on_leave')),
    withdrawal_date   DATE,
    withdrawal_reason TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT withdrawal_requires_date
        CHECK (status != 'dropped' OR withdrawal_date IS NOT NULL)
);

-- ─────────────────────────────────────────────
-- BASELINE ASSESSMENTS
-- 1:N — one per participant per cohort enrollment
-- 8 onboarding questions covering all 7 barrier categories + goal anchor
-- ─────────────────────────────────────────────
CREATE TABLE baseline_assessments (
    assessment_id  SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    cohort_id      INTEGER NOT NULL
                       REFERENCES cohorts(cohort_id)
                       ON DELETE RESTRICT,
    submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Q1: Primary employment barrier
    primary_barrier        TEXT NOT NULL
                               CHECK (primary_barrier IN (
                                   'unemployment', 'reentry', 'long_term_absence',
                                   'disability', 'language', 'other'
                               )),
    -- Q2: Housing stability
    housing_status         TEXT NOT NULL
                               CHECK (housing_status IN (
                                   'stable', 'unstable', 'transitional', 'homeless'
                               )),
    -- Q3: Transportation
    has_reliable_transport BOOLEAN NOT NULL,
    transport_mode         TEXT    NOT NULL
                               CHECK (transport_mode IN (
                                   'own_vehicle', 'public_transit', 'ride_share',
                                   'walking', 'none'
                               )),
    -- Q4: Childcare / dependents
    has_dependents         BOOLEAN NOT NULL,
    dependent_ages         TEXT,                  -- free text, e.g. "3, 7"
    childcare_arranged     BOOLEAN,               -- NULL when has_dependents = FALSE

    -- Q5: Financial stress level (1–5, 5 = most stressed)
    financial_stress_score INTEGER NOT NULL
                               CHECK (financial_stress_score BETWEEN 1 AND 5),

    -- Q6: Stated goal — used as anchor text in personalised SMS nudges
    stated_goal            TEXT NOT NULL,

    -- Q7: Prior food service experience
    prior_food_service       BOOLEAN NOT NULL,
    prior_food_service_years INTEGER,             -- NULL when prior_food_service = FALSE

    -- Q8: Support network & contact preference
    has_support_network    BOOLEAN NOT NULL,
    contact_preference     TEXT NOT NULL
                               CHECK (contact_preference IN ('sms', 'call', 'email')),

    -- One baseline assessment per participant per cohort enrollment
    CONSTRAINT unique_baseline_per_enrollment
        UNIQUE (participant_id, cohort_id),

    CONSTRAINT childcare_logic
        CHECK (has_dependents = TRUE OR childcare_arranged IS NULL),

    CONSTRAINT food_service_years_logic
        CHECK (prior_food_service = TRUE OR prior_food_service_years IS NULL)
);

-- ─────────────────────────────────────────────
-- WEEKLY CHECK-INS
-- One per participant per week — 7 barrier signals via SMS
-- ─────────────────────────────────────────────
CREATE TABLE weekly_checkins (
    checkin_id     SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    week_number    INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    channel        TEXT NOT NULL DEFAULT 'sms'
                       CHECK (channel IN ('sms', 'web', 'coordinator')),

    -- 7 barrier signals (1–5, 5 = most severe)
    -- NULL across all signals means no_reply = TRUE
    transport_barrier    INTEGER CHECK (transport_barrier    BETWEEN 1 AND 5),
    housing_barrier      INTEGER CHECK (housing_barrier      BETWEEN 1 AND 5),
    childcare_barrier    INTEGER CHECK (childcare_barrier    BETWEEN 1 AND 5),
    financial_stress     INTEGER CHECK (financial_stress     BETWEEN 1 AND 5),
    motivation_score     INTEGER CHECK (motivation_score     BETWEEN 1 AND 5),
    physical_wellbeing   INTEGER CHECK (physical_wellbeing   BETWEEN 1 AND 5),
    feeling_overwhelmed  INTEGER CHECK (feeling_overwhelmed  BETWEEN 1 AND 5),

    open_response  TEXT,
    no_reply       BOOLEAN NOT NULL DEFAULT FALSE,

    -- One check-in per participant per week
    CONSTRAINT unique_checkin_per_week
        UNIQUE (participant_id, week_number),

    -- Signals must be NULL when there is no reply
    CONSTRAINT no_reply_signals_null
        CHECK (
            no_reply = FALSE OR (
                transport_barrier   IS NULL AND
                housing_barrier     IS NULL AND
                childcare_barrier   IS NULL AND
                financial_stress    IS NULL AND
                motivation_score    IS NULL AND
                physical_wellbeing  IS NULL AND
                feeling_overwhelmed IS NULL
            )
        )
);

-- ─────────────────────────────────────────────
-- CHAPTER CONFIDENCE CHECKS
-- Confidence score 1–5 after each module
-- ─────────────────────────────────────────────
CREATE TABLE chapter_confidence_checks (
    confidence_id  SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    week_number    INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    chapter_name   TEXT NOT NULL,                 -- e.g. "Knife Skills", "Food Safety"
    submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confidence_score INTEGER NOT NULL
                         CHECK (confidence_score BETWEEN 1 AND 5),
    notes          TEXT,

    -- One confidence check per participant per chapter
    CONSTRAINT unique_confidence_per_chapter
        UNIQUE (participant_id, chapter_name)
);

-- ─────────────────────────────────────────────
-- ATTENDANCE LOGS
-- Daily record Mon–Fri for each participant
-- ─────────────────────────────────────────────
CREATE TABLE attendance_logs (
    attendance_id  SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    log_date       DATE NOT NULL,
    week_number    INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    status         TEXT NOT NULL
                       CHECK (status IN ('present', 'absent', 'late', 'excused')),
    absence_reason TEXT,
    recorded_by    TEXT,

    -- One attendance record per participant per day
    CONSTRAINT unique_attendance_per_day
        UNIQUE (participant_id, log_date),

    CONSTRAINT absence_reason_when_not_present
        CHECK (status = 'present' OR absence_reason IS NOT NULL OR status = 'late')
);

-- ─────────────────────────────────────────────
-- DASHBOARD ACTIVITY LOGS
-- Daily engagement: streaks, coursework, quests
-- ─────────────────────────────────────────────
CREATE TABLE dashboard_activity_logs (
    activity_id          SERIAL PRIMARY KEY,
    participant_id       INTEGER NOT NULL
                             REFERENCES participants(participant_id)
                             ON DELETE RESTRICT,
    log_date             DATE NOT NULL,
    week_number          INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    login_count          INTEGER NOT NULL DEFAULT 0 CHECK (login_count >= 0),
    coursework_completed INTEGER NOT NULL DEFAULT 0 CHECK (coursework_completed >= 0),
    quests_completed     INTEGER NOT NULL DEFAULT 0 CHECK (quests_completed >= 0),
    current_streak_days  INTEGER NOT NULL DEFAULT 0 CHECK (current_streak_days >= 0),
    total_points         INTEGER NOT NULL DEFAULT 0 CHECK (total_points >= 0),

    -- One activity log per participant per day
    CONSTRAINT unique_activity_per_day
        UNIQUE (participant_id, log_date)
);

-- ─────────────────────────────────────────────
-- RISK SCORES
-- Weekly dropout risk score — output of logistic regression + SHAP
-- ─────────────────────────────────────────────
CREATE TABLE risk_scores (
    risk_score_id  SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    week_number    INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    scored_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    risk_score     NUMERIC(4,3) NOT NULL
                       CHECK (risk_score BETWEEN 0 AND 1),
    risk_tier      TEXT NOT NULL
                       CHECK (risk_tier IN ('low', 'medium', 'high')),
    -- SHAP top contributing features as JSON
    -- e.g. {"transport_barrier": 0.32, "attendance": 0.28}
    top_features   JSONB,
    model_version  TEXT NOT NULL DEFAULT 'v1',

    -- One risk score per participant per week
    CONSTRAINT unique_risk_score_per_week
        UNIQUE (participant_id, week_number),

    -- risk_tier must be consistent with risk_score (3NF: prevents derived-field drift)
    CONSTRAINT risk_tier_matches_score CHECK (
        (risk_score <  0.40 AND risk_tier = 'low')    OR
        (risk_score >= 0.40 AND risk_score < 0.70 AND risk_tier = 'medium') OR
        (risk_score >= 0.70 AND risk_tier = 'high')
    )
);

-- ─────────────────────────────────────────────
-- RISK EVENTS
-- Specific triggers that raised a risk flag
-- Real-time: generated immediately when threshold crossed
-- ─────────────────────────────────────────────
CREATE TABLE risk_events (
    event_id       SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL
                       REFERENCES participants(participant_id)
                       ON DELETE RESTRICT,
    week_number    INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 10),
    detected_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    trigger_type   TEXT NOT NULL
                       CHECK (trigger_type IN (
                           'transport_barrier',
                           'housing_instability',
                           'childcare_load_change',
                           'financial_stress_spike',
                           'motivation_drop',
                           'feeling_overwhelmed',
                           'missing_reminders'
                       )),
    trigger_value  TEXT,                          -- raw value that crossed threshold
    resolved       BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at    TIMESTAMPTZ,

    CONSTRAINT resolved_requires_timestamp
        CHECK (resolved = FALSE OR resolved_at IS NOT NULL)
);

-- ─────────────────────────────────────────────
-- INTERVENTIONS
-- Coordinator actions triggered by risk events
-- risk_event_id NOT NULL — every intervention must trace to a risk event
-- ─────────────────────────────────────────────
CREATE TABLE interventions (
    intervention_id   SERIAL PRIMARY KEY,
    participant_id    INTEGER NOT NULL
                          REFERENCES participants(participant_id)
                          ON DELETE RESTRICT,
    risk_event_id     INTEGER NOT NULL
                          REFERENCES risk_events(event_id)
                          ON DELETE RESTRICT,
    coordinator_id    INTEGER NOT NULL
                          REFERENCES coordinators(coordinator_id)
                          ON DELETE RESTRICT,
    initiated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    intervention_type TEXT NOT NULL
                          CHECK (intervention_type IN (
                              'sms_nudge',
                              'phone_call',
                              'resource_card',
                              'referral',
                              'schedule_adjustment',
                              'peer_mentor_match',
                              'in_person_meeting'
                          )),

    -- Resource card fields — populated when intervention_type = 'resource_card'
    resource_partner   TEXT,
    resource_url       TEXT,
    resource_maps_link TEXT,

    outcome            TEXT NOT NULL DEFAULT 'pending'
                           CHECK (outcome IN (
                               'resolved', 'pending', 'escalated', 'no_response'
                           )),
    outcome_notes      TEXT,
    closed_at         TIMESTAMPTZ,

    CONSTRAINT resource_card_needs_partner
        CHECK (
            intervention_type != 'resource_card' OR resource_partner IS NOT NULL
        ),

    CONSTRAINT closed_requires_non_pending_outcome
        CHECK (closed_at IS NULL OR outcome != 'pending')
);

-- ─────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────
CREATE INDEX idx_participants_cohort        ON participants(cohort_id);
CREATE INDEX idx_participants_status        ON participants(status);
CREATE INDEX idx_baseline_participant       ON baseline_assessments(participant_id);
CREATE INDEX idx_checkins_participant_week  ON weekly_checkins(participant_id, week_number);
CREATE INDEX idx_checkins_no_reply         ON weekly_checkins(no_reply) WHERE no_reply = TRUE;
CREATE INDEX idx_attendance_participant    ON attendance_logs(participant_id, log_date);
CREATE INDEX idx_attendance_status        ON attendance_logs(status) WHERE status = 'absent';
CREATE INDEX idx_confidence_participant    ON chapter_confidence_checks(participant_id);
CREATE INDEX idx_dashboard_participant     ON dashboard_activity_logs(participant_id, log_date);
CREATE INDEX idx_risk_scores_participant   ON risk_scores(participant_id, week_number);
CREATE INDEX idx_risk_scores_tier         ON risk_scores(risk_tier) WHERE risk_tier = 'high';
CREATE INDEX idx_risk_events_participant   ON risk_events(participant_id, resolved);
CREATE INDEX idx_risk_events_unresolved   ON risk_events(detected_at) WHERE resolved = FALSE;
CREATE INDEX idx_interventions_participant ON interventions(participant_id, outcome);
CREATE INDEX idx_interventions_pending    ON interventions(initiated_at) WHERE outcome = 'pending';
