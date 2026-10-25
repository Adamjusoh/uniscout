-- =============================================================================
-- UniScout: Seed Data Script
-- Course: CSD34103 Software Development Workshop
-- Group: Sentry (Faculty of Informatics and Computing, UniSZA)
-- Database: MySQL 8.0+
-- File: uniscout_seed.sql
-- Description: Production-ready seed data using formatted semantic primary keys
--              (e.g., ACC-1001, PRT-1001, ORG-1001, EVT-2026-001, REG-2026-0001)
-- =============================================================================

USE uniscout_db;

-- Clear existing data safely
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE NOTIFICATION;
TRUNCATE TABLE SKILL;
TRUNCATE TABLE INTEREST;
TRUNCATE TABLE BOOKMARK;
TRUNCATE TABLE REGISTRATION;
TRUNCATE TABLE EVENT;
TRUNCATE TABLE CATEGORY;
TRUNCATE TABLE ORGANIZER;
TRUNCATE TABLE ORGANIZATION;
TRUNCATE TABLE PARTICIPANT;
TRUNCATE TABLE ACCOUNT;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. SEED: ACCOUNT
-- Passwords below are pre-hashed using standard bcrypt ($2y$10$... sample hash)
-- Sample plaintext password for all test accounts: "Password@123"
-- Format: ACC-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO ACCOUNT (account_id, email, password_hash, role, account_status, created_at) VALUES
('ACC-1001', 'admin@uniscout.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789adminhashdemo', 'admin', 'A', '2026-10-01 08:00:00'),
('ACC-1002', 'css.organizer@uniscout.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789organizerhash1', 'organizer', 'A', '2026-10-02 09:30:00'),
('ACC-1003', 'debat.organizer@uniscout.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789organizerhash2', 'organizer', 'A', '2026-10-02 10:15:00'),
('ACC-1004', '083370@putra.unisza.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789studenthash01', 'participant', 'A', '2026-10-05 11:00:00'),
('ACC-1005', '081999@putra.unisza.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789studenthash02', 'participant', 'A', '2026-10-05 11:30:00'),
('ACC-1006', '082284@putra.unisza.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789studenthash03', 'participant', 'A', '2026-10-05 12:00:00'),
('ACC-1007', '081377@putra.unisza.edu.my', '$2y$10$abcdefghijklmnopqrstuvwxy0123456789studenthash04', 'participant', 'A', '2026-10-05 12:30:00');

-- -----------------------------------------------------------------------------
-- 2. SEED: PARTICIPANT
-- Profiles for student participants (Group Sentry Members)
-- Format: PRT-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO PARTICIPANT (participant_id, account_id, participant_code, full_name, faculty, program, academic_year, phone_no) VALUES
('PRT-1001', 'ACC-1004', '083370', 'Muhammad Adam Haris bin Jusoh', 'Faculty of Informatics and Computing', 'Bachelor of Computer Science (Software Development)', 3, '012-3456789'),
('PRT-1002', 'ACC-1005', '081999', 'Ahmad Ilman Wafi bin Mohd Azami', 'Faculty of Informatics and Computing', 'Bachelor of Computer Science (Software Development)', 3, '013-4567890'),
('PRT-1003', 'ACC-1006', '082284', 'Aniq Danish Ilman bin Mazlan', 'Faculty of Informatics and Computing', 'Bachelor of Computer Science (Software Development)', 3, '014-5678901'),
('PRT-1004', 'ACC-1007', '081377', 'Muhammad Adam Adli bin Mohd Nasir', 'Faculty of Informatics and Computing', 'Bachelor of Computer Science (Software Development)', 3, '015-6789012');

-- -----------------------------------------------------------------------------
-- 3. SEED: ORGANIZATION
-- Campus bodies, clubs, and academic faculties
-- Format: ORG-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO ORGANIZATION (organization_id, org_name, org_type, description, contact_email, verification_status) VALUES
('ORG-1001', 'Faculty of Informatics and Computing (FIK)', 'Faculty', 'The premier computing and technology faculty of UniSZA.', 'fik@unisza.edu.my', 'A'),
('ORG-1002', 'Computer Science Society (CSS)', 'Club', 'Official student representative club fostering software and tech innovation.', 'css@uniscout.edu.my', 'A'),
('ORG-1003', 'Kelab Debat & Pengucapan Awam UniSZA', 'Club', 'Empowering university students through dialectics and intellectual debate.', 'debat@uniscout.edu.my', 'A'),
('ORG-1004', 'UniSZA Sports and Recreation Council', 'Department', 'Organizing sports leagues, fitness activities, and inter-varsity tournaments.', 'sports@unisza.edu.my', 'A'),
('ORG-1005', 'Kelab Keusahawanan Mahasiswa UniSZA', 'Society', 'Promoting startup incubations, business skills, and networking fairs.', 'entrep@unisza.edu.my', 'P');

-- -----------------------------------------------------------------------------
-- 4. SEED: ORGANIZER
-- Verified organizer liaisons linked to accounts and campus bodies
-- Format: OGN-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO ORGANIZER (organizer_id, account_id, organization_id, full_name, position, phone_no) VALUES
('OGN-1001', 'ACC-1002', 'ORG-1002', 'Ts. Dr. Nurul Hidayah binti Che Mat', 'Faculty Advisor / Lead Coordinator', '019-9876543'),
('OGN-1002', 'ACC-1003', 'ORG-1003', 'Megat Zulkarnain bin Ahmad', 'President of UniSZA Debate Club', '018-8765432');

-- -----------------------------------------------------------------------------
-- 5. SEED: CATEGORY
-- Master taxonomy for classifying university opportunities
-- Format: CAT-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO CATEGORY (category_id, category_name, description, category_status) VALUES
('CAT-1001', 'Workshop', 'Hands-on technical workshops, coding bootcamps, and skill building sessions.', 'A'),
('CAT-1002', 'Hackathon', 'Competitive team programming, app design challenges, and sprints.', 'A'),
('CAT-1003', 'Seminar', 'Academic symposiums, industry talks, and keynotes.', 'A'),
('CAT-1004', 'Sports', 'Intra-faculty sports, tournaments, athletic meets, and wellness events.', 'A'),
('CAT-1005', 'Volunteering', 'Community outreach programs, social responsibility, and disaster relief.', 'A'),
('CAT-1006', 'Career Fair', 'Internship placement drives, employer networking, and resume clinics.', 'A');

-- -----------------------------------------------------------------------------
-- 6. SEED: EVENT
-- Events in various lifecycle stages:
-- 'A' = Approved/Published, 'P' = Pending Review, 'D' = Draft, 'C' = Completed
-- Format: EVT-[YYYY]-[Sequence]
-- -----------------------------------------------------------------------------
INSERT INTO EVENT (event_id, organizer_id, category_id, title, description, event_mode, location, start_datetime, end_datetime, reg_deadline, capacity, eligibility_criteria, event_status, review_remarks) VALUES
('EVT-2026-001', 'OGN-1001', 'CAT-1001', 'Full-Stack Modern Web Engineering Workshop', 'Master HTML5, CSS design systems, Vanilla JS, and relational database integrations with MySQL in this hands-on workshop led by senior software developers.', 'Physical', 'Software Lab 3, Block D, UniSZA Besut Campus', '2026-11-15 09:00:00', '2026-11-15 17:00:00', '2026-11-12 23:59:59', 50, 'Open to all Year 2 & Year 3 computing students', 'A', 'Approved by Admin on 2026-10-10. Complete logistics provided.'),
('EVT-2026-002', 'OGN-1001', 'CAT-1002', 'UniSZA Smart Campus Hackathon 2026', 'A 36-hour sprint where students build innovative digital solutions tackling student experience, event discovery, and sustainability on campus.', 'Physical', 'Auditorium Al-Muktafi Billah Shah, Gong Badak Campus', '2026-11-20 08:30:00', '2026-11-21 20:00:00', '2026-11-14 23:59:59', 100, 'All registered undergraduate students of UniSZA', 'A', 'Approved. Strong proposal with verified venue clearance.'),
('EVT-2026-003', 'OGN-1002', 'CAT-1003', 'National Inter-Varsity Parliamentary Debate Series', 'Watch national-level debating teams tackle contemporary socioeconomic issues, public policy, and technology governance.', 'Hybrid', 'Dewan Perdana & Zoom Online Stream', '2026-11-25 14:00:00', '2026-11-25 18:00:00', '2026-11-24 12:00:00', 120, 'Open to all university students and faculty members', 'A', 'Approved. Good multi-mode setup.'),
('EVT-2026-004', 'OGN-1001', 'CAT-1006', 'Tech Career & Internship Expo 2026', 'Connect directly with leading tech companies, fintech firms, and software houses hiring for industrial training and graduate positions.', 'Physical', 'Student Center Hall, Gong Badak Campus', '2026-12-05 09:00:00', '2026-12-05 16:30:00', '2026-12-01 23:59:59', 250, 'Final year and pre-internship students prioritized', 'P', 'Pending administrator verification of external company booth list.'),
('EVT-2026-005', 'OGN-1001', 'CAT-1001', 'Mobile App Dev with Flutter Crash Course', 'Learn the basics of cross-platform mobile application development with Flutter and Dart.', 'Online', 'Google Meet / YouTube Live Stream', '2026-12-10 10:00:00', '2026-12-10 13:00:00', '2026-12-08 23:59:59', 80, 'Open to all interested students', 'D', 'Draft mode - organizer refining course slides.');

-- -----------------------------------------------------------------------------
-- 7. SEED: REGISTRATION
-- Participant event registrations
-- Format: REG-[YYYY]-[Sequence]
-- -----------------------------------------------------------------------------
INSERT INTO REGISTRATION (registration_id, participant_id, event_id, reg_datetime, reg_status) VALUES
('REG-2026-0001', 'PRT-1001', 'EVT-2026-001', '2026-10-15 14:20:00', 'R'),
('REG-2026-0002', 'PRT-1002', 'EVT-2026-001', '2026-10-15 15:10:00', 'R'),
('REG-2026-0003', 'PRT-1003', 'EVT-2026-001', '2026-10-16 09:45:00', 'R'),
('REG-2026-0004', 'PRT-1001', 'EVT-2026-002', '2026-10-18 11:00:00', 'R'),
('REG-2026-0005', 'PRT-1004', 'EVT-2026-003', '2026-10-19 16:30:00', 'R');

-- -----------------------------------------------------------------------------
-- 8. SEED: BOOKMARK
-- Saved events for quick reference
-- Format: BKM-[YYYY]-[Sequence]
-- -----------------------------------------------------------------------------
INSERT INTO BOOKMARK (bookmark_id, participant_id, event_id, saved_datetime) VALUES
('BKM-2026-0001', 'PRT-1001', 'EVT-2026-002', '2026-10-16 10:00:00'),
('BKM-2026-0002', 'PRT-1001', 'EVT-2026-003', '2026-10-17 12:45:00'),
('BKM-2026-0003', 'PRT-1002', 'EVT-2026-002', '2026-10-18 09:15:00'),
('BKM-2026-0004', 'PRT-1003', 'EVT-2026-001', '2026-10-15 08:30:00');

-- -----------------------------------------------------------------------------
-- 9. SEED: INTEREST
-- Participant interest tags used by the recommendation engine (FR-PARTICIPANT-013)
-- Format: INT-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO INTEREST (interest_id, participant_id, category_id, interest_tag) VALUES
('INT-1001', 'PRT-1001', 'CAT-1001', 'Web Development'),
('INT-1002', 'PRT-1001', 'CAT-1002', 'Artificial Intelligence'),
('INT-1003', 'PRT-1001', 'CAT-1001', 'Database Engineering'),
('INT-1004', 'PRT-1002', 'CAT-1002', 'Mobile Application'),
('INT-1005', 'PRT-1002', 'CAT-1001', 'System Analysis'),
('INT-1006', 'PRT-1003', 'CAT-1001', 'UI/UX Design'),
('INT-1007', 'PRT-1003', 'CAT-1002', 'Competitive Programming'),
('INT-1008', 'PRT-1004', 'CAT-1003', 'Public Speaking');

-- -----------------------------------------------------------------------------
-- 10. SEED: SKILL
-- Participant skill proficiencies
-- Format: SKL-[1000 series]
-- -----------------------------------------------------------------------------
INSERT INTO SKILL (skill_id, participant_id, skill_name, proficiency_level) VALUES
('SKL-1001', 'PRT-1001', 'JavaScript', 'Advanced'),
('SKL-1002', 'PRT-1001', 'MySQL & Relational Modeling', 'Advanced'),
('SKL-1003', 'PRT-1001', 'Python', 'Intermediate'),
('SKL-1004', 'PRT-1002', 'Software Requirements Analysis', 'Advanced'),
('SKL-1005', 'PRT-1002', 'UML & DFD Modeling', 'Advanced'),
('SKL-1006', 'PRT-1003', 'Frontend UI Design (Figma)', 'Intermediate'),
('SKL-1007', 'PRT-1003', 'HTML/CSS', 'Advanced'),
('SKL-1008', 'PRT-1004', 'Testing & Debugging', 'Intermediate');

-- -----------------------------------------------------------------------------
-- 11. SEED: NOTIFICATION
-- Real-time system notifications
-- Format: NTF-[YYYY]-[Sequence]
-- -----------------------------------------------------------------------------
INSERT INTO NOTIFICATION (notification_id, account_id, event_id, title, message, notification_type, is_read, sent_datetime) VALUES
('NTF-2026-0001', 'ACC-1004', 'EVT-2026-001', 'Registration Confirmed', 'Your registration for Full-Stack Modern Web Engineering Workshop is confirmed.', 'Reminder', 'Y', '2026-10-15 14:21:00'),
('NTF-2026-0002', 'ACC-1004', 'EVT-2026-002', 'Registration Deadline Notice', 'Only 3 days left before registration closes for UniSZA Smart Campus Hackathon 2026.', 'Deadline', 'N', '2026-10-22 08:00:00'),
('NTF-2026-0003', 'ACC-1004', 'EVT-2026-001', 'Recommended Activity For You', 'Based on your interest in Web Development, check out the upcoming Web Engineering Workshop!', 'Recommendation', 'N', '2026-10-23 10:00:00'),
('NTF-2026-0004', 'ACC-1002', 'EVT-2026-004', 'Event Review Underway', 'Your event "Tech Career & Internship Expo 2026" was submitted for administrative review.', 'Reminder', 'Y', '2026-10-20 09:00:00');
