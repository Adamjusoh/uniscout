-- =============================================================================
-- UniScout: Event and Opportunity Management System
-- Course: CSD34103 Software Development Workshop
-- Group: Sentry (Faculty of Informatics and Computing, UniSZA)
-- Database: MySQL 8.0+
-- File: uniscout_schema.sql
-- =============================================================================

DROP DATABASE IF EXISTS uniscout_db;
CREATE DATABASE uniscout_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE uniscout_db;

-- -----------------------------------------------------------------------------
-- 1. TABLE: ACCOUNT
-- Centralized authentication credentials and role assignments
-- -----------------------------------------------------------------------------
CREATE TABLE ACCOUNT (
    account_id VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'participant',
    account_status CHAR(1) NOT NULL DEFAULT 'A',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_account PRIMARY KEY (account_id),
    CONSTRAINT uq_account_email UNIQUE (email),
    CONSTRAINT chk_account_role CHECK (role IN ('participant', 'organizer', 'admin')),
    CONSTRAINT chk_account_status CHECK (account_status IN ('A', 'S', 'I'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. TABLE: PARTICIPANT
-- Extended student participant profile details
-- -----------------------------------------------------------------------------
CREATE TABLE PARTICIPANT (
    participant_id VARCHAR(20) NOT NULL,
    account_id VARCHAR(20) NOT NULL,
    participant_code VARCHAR(20) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    faculty VARCHAR(100) NULL,
    program VARCHAR(100) NULL,
    academic_year INT(2) NULL DEFAULT 1,
    phone_no VARCHAR(15) NULL,
    CONSTRAINT pk_participant PRIMARY KEY (participant_id),
    CONSTRAINT uq_participant_account UNIQUE (account_id),
    CONSTRAINT uq_participant_code UNIQUE (participant_code),
    CONSTRAINT fk_participant_account FOREIGN KEY (account_id)
        REFERENCES ACCOUNT (account_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. TABLE: ORGANIZATION
-- Registered faculties, departments, clubs, or societies
-- -----------------------------------------------------------------------------
CREATE TABLE ORGANIZATION (
    organization_id VARCHAR(20) NOT NULL,
    org_name VARCHAR(100) NOT NULL,
    org_type VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    contact_email VARCHAR(100) NOT NULL,
    verification_status CHAR(1) NOT NULL DEFAULT 'P',
    CONSTRAINT pk_organization PRIMARY KEY (organization_id),
    CONSTRAINT uq_org_name UNIQUE (org_name),
    CONSTRAINT chk_org_type CHECK (org_type IN ('Faculty', 'Club', 'Department', 'Society')),
    CONSTRAINT chk_org_verification CHECK (verification_status IN ('P', 'A', 'S', 'R'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. TABLE: ORGANIZER
-- Extended representative profile linked to an approved organization
-- -----------------------------------------------------------------------------
CREATE TABLE ORGANIZER (
    organizer_id VARCHAR(20) NOT NULL,
    account_id VARCHAR(20) NOT NULL,
    organization_id VARCHAR(20) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NULL,
    phone_no VARCHAR(15) NULL,
    CONSTRAINT pk_organizer PRIMARY KEY (organizer_id),
    CONSTRAINT uq_organizer_account UNIQUE (account_id),
    CONSTRAINT fk_organizer_account FOREIGN KEY (account_id)
        REFERENCES ACCOUNT (account_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_organizer_organization FOREIGN KEY (organization_id)
        REFERENCES ORGANIZATION (organization_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. TABLE: CATEGORY
-- Event taxonomy categories (Workshop, Hackathon, Seminar, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE CATEGORY (
    category_id VARCHAR(20) NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    category_status CHAR(1) NOT NULL DEFAULT 'A',
    CONSTRAINT pk_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name),
    CONSTRAINT chk_category_status CHECK (category_status IN ('A', 'I'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 6. TABLE: EVENT
-- Core event listings managed by organizers and reviewed by admins
-- -----------------------------------------------------------------------------
CREATE TABLE EVENT (
    event_id VARCHAR(20) NOT NULL,
    organizer_id VARCHAR(20) NOT NULL,
    category_id VARCHAR(20) NOT NULL,
    title VARCHAR(150) NOT NULL,
    description VARCHAR(500) NOT NULL,
    event_mode VARCHAR(20) NOT NULL DEFAULT 'Physical',
    location VARCHAR(150) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    reg_deadline DATETIME NOT NULL,
    capacity INT(5) NOT NULL DEFAULT 0,
    eligibility_criteria VARCHAR(255) NULL,
    event_status CHAR(1) NOT NULL DEFAULT 'D',
    review_remarks VARCHAR(255) NULL,
    CONSTRAINT pk_event PRIMARY KEY (event_id),
    CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id)
        REFERENCES ORGANIZER (organizer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_event_category FOREIGN KEY (category_id)
        REFERENCES CATEGORY (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_event_mode CHECK (event_mode IN ('Physical', 'Online', 'Hybrid')),
    CONSTRAINT chk_event_status CHECK (event_status IN ('D', 'P', 'A', 'R', 'X', 'C')),
    CONSTRAINT chk_event_schedule CHECK (end_datetime >= start_datetime),
    CONSTRAINT chk_event_reg_deadline CHECK (reg_deadline <= start_datetime),
    CONSTRAINT chk_event_capacity CHECK (capacity >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 7. TABLE: REGISTRATION
-- Associative entity linking participant enrollment to events
-- -----------------------------------------------------------------------------
CREATE TABLE REGISTRATION (
    registration_id VARCHAR(25) NOT NULL,
    participant_id VARCHAR(20) NOT NULL,
    event_id VARCHAR(20) NOT NULL,
    reg_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reg_status CHAR(1) NOT NULL DEFAULT 'R',
    CONSTRAINT pk_registration PRIMARY KEY (registration_id),
    CONSTRAINT uq_participant_event_reg UNIQUE (participant_id, event_id),
    CONSTRAINT fk_reg_participant FOREIGN KEY (participant_id)
        REFERENCES PARTICIPANT (participant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_reg_event FOREIGN KEY (event_id)
        REFERENCES EVENT (event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_reg_status CHECK (reg_status IN ('R', 'C', 'W', 'A'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 8. TABLE: BOOKMARK
-- Associative entity storing saved events for participants
-- -----------------------------------------------------------------------------
CREATE TABLE BOOKMARK (
    bookmark_id VARCHAR(25) NOT NULL,
    participant_id VARCHAR(20) NOT NULL,
    event_id VARCHAR(20) NOT NULL,
    saved_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bookmark PRIMARY KEY (bookmark_id),
    CONSTRAINT uq_participant_event_bookmark UNIQUE (participant_id, event_id),
    CONSTRAINT fk_bookmark_participant FOREIGN KEY (participant_id)
        REFERENCES PARTICIPANT (participant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_bookmark_event FOREIGN KEY (event_id)
        REFERENCES EVENT (event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 9. TABLE: INTEREST
-- Participant interest topics linked to event categories for recommendation
-- -----------------------------------------------------------------------------
CREATE TABLE INTEREST (
    interest_id VARCHAR(20) NOT NULL,
    participant_id VARCHAR(20) NOT NULL,
    category_id VARCHAR(20) NOT NULL,
    interest_tag VARCHAR(50) NOT NULL,
    CONSTRAINT pk_interest PRIMARY KEY (interest_id),
    CONSTRAINT uq_participant_interest_tag UNIQUE (participant_id, category_id, interest_tag),
    CONSTRAINT fk_interest_participant FOREIGN KEY (participant_id)
        REFERENCES PARTICIPANT (participant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_interest_category FOREIGN KEY (category_id)
        REFERENCES CATEGORY (category_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 10. TABLE: SKILL
-- Participant competencies and proficiency ratings
-- -----------------------------------------------------------------------------
CREATE TABLE SKILL (
    skill_id VARCHAR(20) NOT NULL,
    participant_id VARCHAR(20) NOT NULL,
    skill_name VARCHAR(50) NOT NULL,
    proficiency_level VARCHAR(20) NOT NULL DEFAULT 'Beginner',
    CONSTRAINT pk_skill PRIMARY KEY (skill_id),
    CONSTRAINT uq_participant_skill UNIQUE (participant_id, skill_name),
    CONSTRAINT fk_skill_participant FOREIGN KEY (participant_id)
        REFERENCES PARTICIPANT (participant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_skill_proficiency CHECK (proficiency_level IN ('Beginner', 'Intermediate', 'Advanced'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 11. TABLE: NOTIFICATION
-- System alerts (reminders, deadline cutoffs, status changes, suggestions)
-- -----------------------------------------------------------------------------
CREATE TABLE NOTIFICATION (
    notification_id VARCHAR(25) NOT NULL,
    account_id VARCHAR(20) NOT NULL,
    event_id VARCHAR(20) NULL,
    title VARCHAR(100) NOT NULL,
    message VARCHAR(255) NOT NULL,
    notification_type VARCHAR(30) NOT NULL,
    is_read CHAR(1) NOT NULL DEFAULT 'N',
    sent_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_notification PRIMARY KEY (notification_id),
    CONSTRAINT fk_notification_account FOREIGN KEY (account_id)
        REFERENCES ACCOUNT (account_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_notification_event FOREIGN KEY (event_id)
        REFERENCES EVENT (event_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT chk_notification_type CHECK (notification_type IN ('Reminder', 'Deadline', 'Cancellation', 'Recommendation')),
    CONSTRAINT chk_notification_read CHECK (is_read IN ('Y', 'N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- PERFORMANCE INDEXES
-- Optimizes common searches, filtering, recommendation lookups & calendar queries
-- -----------------------------------------------------------------------------
CREATE INDEX idx_event_status_dates ON EVENT (event_status, start_datetime, end_datetime);
CREATE INDEX idx_event_category ON EVENT (category_id);
CREATE INDEX idx_event_organizer ON EVENT (organizer_id);
CREATE INDEX idx_reg_participant_status ON REGISTRATION (participant_id, reg_status);
CREATE INDEX idx_reg_event_status ON REGISTRATION (event_id, reg_status);
CREATE INDEX idx_notification_account_read ON NOTIFICATION (account_id, is_read);
CREATE INDEX idx_interest_participant ON INTEREST (participant_id);
CREATE INDEX idx_skill_participant ON SKILL (participant_id);
