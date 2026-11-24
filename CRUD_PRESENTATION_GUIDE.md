# UniScout: System CRUD Functions Presentation Document

**Faculty:** Faculty of Informatics and Computing (FIK), Universiti Sultan Zainal Abidin (UniSZA)  
**Programme:** Bachelor of Computer Science (Software Development) with Honours — Semester 5  
**Course:** CSD34103 Software Development Workshop  
**Lecturer:** Prof. Madya Ts. Dr. Mohd Khalid Bin Awang  
**Project Title:** Event and Opportunity Management System (*UniScout*)  
**Group Name:** Sentry  

| No. | Group Member Name | Matric Number | Assigned CRUD Presentation Module |
| :-: | :--- | :---: | :--- |
| **1** | **Muhammad Adam Haris Bin Jusoh** | `083370` | **Module 1:** Account Registration & Participant Profile, Interests & Skills (Processes 1.0 & 2.0) |
| **2** | **Ahmad Ilman Wafi Bin Mohd Azami** | `081999` | **Module 2:** Organizer Campus Event Management (Process 3.0) |
| **3** | **Aniq Danish Ilman Bin Mazlan** | `082284` | **Module 3:** Event Registration, Bookmarks, Recommendations & Notifications (Processes 4.0, 6.0 & 7.0) |
| **4** | **Muhammad Adam Adli Bin Mohd Nasir** | `081377` | **Module 4:** Admin Event Approval, Users, Organizations & Analytics (Processes 5.0 & 8.0) |

---

## 1. Master CRUD Matrix Across All 11 MySQL Tables (`uniscout_db`)

This matrix summarizes how every relational table in **Chapter 4 of the SDD (Pages 81–90)** supports **Create (`INSERT`), Read (`SELECT`), Update (`UPDATE`), and Delete (`DELETE` / Soft-Delete)** across the 8 main processes in **Chapter 3 of the SDD (Pages 11–80)**.

| No. | Table Name | Primary / Composite Key (`PK`) & Unique Key (`UK`) | **C**reate (`INSERT`) | **R**ead (`SELECT`) | **U**pdate (`UPDATE`) | **D**elete (`DELETE` / Soft-Delete) |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `ACCOUNT` | **PK:** `account_id`<br>**UK:** `email` | **Process 1.0:** Student Sign Up<br>**Process 8.1:** Admin Add User | **Process 1.0:** Sign In Auth<br>**Process 8.1:** View/Search Users | **Process 1.0:** Reset Password<br>**Process 8.1:** Change Role (`participant`/`organizer`/`admin`) | **Process 8.1:** Suspend Account (`account_status='S'`) or Hard Delete (`DELETE`) |
| **2** | `PARTICIPANT` | **PK:** `participant_id`<br>**UK:** `account_id`, `participant_code` | **Process 1.0:** Create Profile on Registration | **Process 2.1:** View Participant Profile<br>**Process 6.3:** Read Profile for Matching | **Process 2.2:** Update Name, Faculty, Program, Year, Phone | **Process 8.1:** Cascades on Account Delete (`ON DELETE CASCADE`) |
| **3** | `ORGANIZATION` | **PK:** `organization_id`<br>**UK:** `org_name` | **Process 8.2:** Admin Add Campus Organization | **Process 8.2:** View & Filter Organizations | **Process 8.2:** Update Details & Verification Status (`'P'`/`'A'`/`'S'`/`'R'`) | **Process 8.2:** Suspend (`'S'`) or Delete Unreferenced Organization |
| **4** | `ORGANIZER` | **PK:** `organizer_id`<br>**UK:** `account_id` | **Process 8.1:** Create Organizer Profile when Role = `organizer` | **Process 3.0 & 5.0:** Identify Event Host & Club Affiliation | **Process 8.1 / 8.2:** Update Position, Phone, Organization Link | **Process 8.1:** Cascades on Account Delete |
| **5** | `CATEGORY` | **PK:** `category_id`<br>**UK:** `category_name` | Seeded / Admin Taxonomy Setup (`Workshop`, `Hackathon`, etc.) | **Process 2.3, 3.1, 6.3, 8.3:** Populate Category Filters & Analytics | Activate / Deactivate Category (`category_status = 'A'` / `'I'`) | Deactivate (`category_status = 'I'`, Protected by `ON DELETE RESTRICT`) |
| **6** | `EVENT` | **Composite PK:** `(event_id, organizer_id, category_id, start_datetime)`<br>**UK:** `event_id` | **Process 3.1:** Organizer Create Campus Event (`'D'` or `'P'`) | **Process 3.1–3.3, 4.1, 5.1, 6.3, 8.3:** Browse, Search, Review & Analyze Events | **Process 3.2:** Edit Event Details<br>**Process 5.2:** Approve (`'A'`)<br>**Process 5.3:** Reject (`'R'`) | **Process 3.3:** Cancel Event (`event_status = 'X'`) or Delete Draft (`DELETE`) |
| **7** | `REGISTRATION` | **Composite PK:** `(participant_id, event_id)`<br>**UK:** `registration_id` | **Process 4.1:** Student Register for Event (`reg_status = 'R'`) | **Process 4.3:** View Admission Pass & QR Code<br>**Process 6.3 & 8.3:** History & Turnout | **Process 4.2:** Cancel Seat Registration (`reg_status = 'C'`) | **Process 4.2:** Withdraw / Delete Registration Row (`DELETE`) |
| **8** | `BOOKMARK` | **Composite PK:** `(participant_id, event_id)`<br>**UK:** `bookmark_id` | **Process 6.1:** Save Event Bookmark | **Process 6.2:** View Saved Bookmarks List | Timestamp Updated on Re-save | **Process 6.2:** Remove Saved Bookmark (`DELETE FROM BOOKMARK`) |
| **9** | `INTEREST` | **Composite PK:** `(participant_id, category_id, interest_tag)`<br>**UK:** `interest_id` | **Process 2.3:** Add Participant Interest Tag | **Process 2.1 & 2.3:** View Interests<br>**Process 6.3:** Match Events by Category | Re-tag via Add / Remove | **Process 2.3:** Remove Interest Tag using Composite PK (`DELETE`) |
| **10** | `SKILL` | **Composite PK:** `(participant_id, skill_name)`<br>**UK:** `skill_id` | **Process 2.4:** Add Participant Skill & Proficiency | **Process 2.1 & 2.4:** View Verified Skills List | **Process 2.4:** Update Proficiency (`Beginner`, `Intermediate`, `Advanced`) | **Process 2.4:** Remove Skill using Composite PK (`DELETE`) |
| **11** | `NOTIFICATION` | **PK:** `notification_id` | **Process 4.1, 5.2, 5.3, 7.0:** Dispatch System Alert | **Process 7.0:** View Alerts, Filter Tabs & Compute Unread Count | **Process 7.0:** Mark Alert as Read (`is_read = 'Y'`) | **Process 7.0:** Dismiss / Delete Notification (`DELETE`) |

---

## 2. Detailed CRUD Breakdown by Team Member

---

### Module 1: Account Registration & Participant Profile Management
**Presenter:** Muhammad Adam Haris Bin Jusoh (`083370`)  
**Actor:** Participant  
**SDD References:** Section 3.1 Process 1.0 (*Pages 11–14*) & Section 3.2 Process 2.0 (*Pages 15–28*)  
**Target Tables:** `ACCOUNT` (4.2.1), `PARTICIPANT` (4.2.2), `INTEREST` (4.2.9), `SKILL` (4.2.10)  
**Mobile GUI Screens:** `Sign up.png`, `Sign in.png`, `My Profile.png`, `Edit Profile & Skills.png`

#### A. CREATE (`INSERT`) Operations
1. **Process 1.0 — Account & Profile Registration:**
   - **Inputs:** `email`, `password`, `full_name`, `participant_code` (Matric No.), `faculty`, `program`, `academic_year`.
   - **Validation:** Checks required fields, password confirmation match, and unique `email` / `participant_code`.
   - **SQL Executed:**
     ```sql
     INSERT INTO ACCOUNT (account_id, email, password_hash, role, account_status)
     VALUES ('ACC-1008', '084500@putra.unisza.edu.my', '$2y$10$...', 'participant', 'A');

     INSERT INTO PARTICIPANT (participant_id, account_id, participant_code, full_name, faculty, program, academic_year, phone_no)
     VALUES ('PRT-1005', 'ACC-1008', '084500', 'Nur Aisyah Binti Kamal', 'Faculty of Informatics and Computing', 'Bachelor of Computer Science', 3, '012-9988776');
     ```
2. **Process 2.3 — Add Participant Interest (Composite PK):**
   - **SQL Executed:**
     ```sql
     INSERT INTO INTEREST (interest_id, participant_id, category_id, interest_tag)
     VALUES ('INT-1009', 'PRT-1001', 'CAT-1001', 'Flutter Mobile Dev');
     ```
3. **Process 2.4 — Add Participant Skill (Composite PK):**
   - **SQL Executed:**
     ```sql
     INSERT INTO SKILL (skill_id, participant_id, skill_name, proficiency_level)
     VALUES ('SKL-1009', 'PRT-1001', 'Flutter & Dart', 'Advanced');
     ```

#### B. READ (`SELECT`) Operations
- **Process 1.0 & 2.1 — Authenticate & Retrieve Full Student Profile:**
  ```sql
  SELECT a.account_id, a.email, a.role, p.*
  FROM ACCOUNT a
  JOIN PARTICIPANT p ON p.account_id = a.account_id
  WHERE a.participant_id = 'PRT-1001';

  SELECT i.*, c.category_name FROM INTEREST i JOIN CATEGORY c ON c.category_id = i.category_id WHERE i.participant_id = 'PRT-1001';
  SELECT * FROM SKILL WHERE participant_id = 'PRT-1001';
  ```

#### C. UPDATE (`UPDATE`) Operations
1. **Process 2.2 — Update Participant Profile Details:**
   ```sql
   UPDATE PARTICIPANT
   SET full_name = 'Muhammad Adam Haris bin Jusoh',
       faculty = 'Faculty of Informatics and Computing',
       program = 'Bachelor of Computer Science (Software Development)',
       academic_year = 3,
       phone_no = '012-3456789'
   WHERE participant_id = 'PRT-1001';
   ```
2. **Process 2.4 — Update Skill Proficiency Level (Targeting Composite PK):**
   ```sql
   UPDATE SKILL
   SET proficiency_level = 'Advanced'
   WHERE participant_id = 'PRT-1001' AND skill_name = 'Python';
   ```

#### D. DELETE (`DELETE`) Operations
- **Process 2.3 & 2.4 — Remove Interest Tag & Skill via Composite Primary Keys:**
  ```sql
  DELETE FROM INTEREST
  WHERE participant_id = 'PRT-1001' AND category_id = 'CAT-1001' AND interest_tag = 'Flutter Mobile Dev';

  DELETE FROM SKILL
  WHERE participant_id = 'PRT-1001' AND skill_name = 'Flutter & Dart';
  ```

---

### Module 2: Organizer Campus Event Management
**Presenter:** Ahmad Ilman Wafi Bin Mohd Azami (`081999`)  
**Actor:** Organizer  
**SDD References:** Section 3.3 Process 3.0 — Subprocesses 3.1, 3.2, 3.3 (*Pages 29–39*)  
**Target Tables:** `EVENT` (4.2.6 — Composite PK: `event_id, organizer_id, category_id, start_datetime`), `CATEGORY` (4.2.5)  
**Mobile GUI Screens:** `Create Campus Event.png`, `Edit campus event.png`, `Cancel event confirmation.png`

#### A. CREATE (`INSERT`) Operations
- **Process 3.1 — Create Campus Event:**
  - **Inputs:** `title`, `category_id`, `event_mode` (`Physical`/`Online`/`Hybrid`), `location`, `start_datetime`, `end_datetime`, `reg_deadline`, `capacity`, `eligibility_criteria`, `description`.
  - **Validation:** Ensures `end_datetime >= start_datetime`, `reg_deadline <= start_datetime`, and `capacity > 0`. Sets initial `event_status` to `'P'` (Pending Admin Approval) or `'D'` (Draft).
  - **SQL Executed:**
    ```sql
    INSERT INTO EVENT (
        event_id, organizer_id, category_id, title, description, event_mode,
        location, start_datetime, end_datetime, reg_deadline, capacity,
        eligibility_criteria, event_status
    ) VALUES (
        'EVT-2026-006', 'OGN-1001', 'CAT-1001', 'Flutter & Firebase Workshop 2026',
        'Hands-on mobile CRUD workshop for FIK students.', 'Physical',
        'Makmal Al-Biruni 3, UniSZA', '2026-12-12 09:00:00', '2026-12-12 17:00:00',
        '2026-12-10 23:59:59', 60, 'Open to all FIK students', 'P'
    );
    ```

#### B. READ (`SELECT`) Operations
- **Retrieve Organizer's Managed Events & Live Seat Count:**
  ```sql
  SELECT e.*, c.category_name,
         (SELECT COUNT(*) FROM REGISTRATION r WHERE r.event_id = e.event_id AND r.reg_status = 'R') AS registered_count
  FROM EVENT e
  JOIN CATEGORY c ON c.category_id = e.category_id
  WHERE e.organizer_id = 'OGN-1001'
  ORDER BY e.start_datetime ASC;
  ```

#### C. UPDATE (`UPDATE`) Operations
- **Process 3.2 — Edit Campus Event:**
  - **Validation:** Verifies the event belongs to the logged-in organizer (`organizer_id = 'OGN-1001'`) and re-validates schedule and quota constraints.
  - **SQL Executed:**
    ```sql
    UPDATE EVENT
    SET title = 'Flutter & MySQL Full-Stack Bootcamp',
        category_id = 'CAT-1001',
        event_mode = 'Hybrid',
        location = 'Makmal Al-Biruni 3 & Google Meet',
        capacity = 80,
        event_status = 'P'
    WHERE event_id = 'EVT-2026-006' AND organizer_id = 'OGN-1001';
    ```

#### D. DELETE (`UPDATE` Soft-Delete & `DELETE` Hard-Delete) Operations
- **Process 3.3 — Cancel Event:**
  - **Soft-Delete (Standard Lifecycle Cancellation):** Updates `event_status` to `'X'` (Cancelled) and stores the organizer's cancellation reason so enrolled students receive cancellation notifications while preserving audit history:
    ```sql
    UPDATE EVENT
    SET event_status = 'X',
        review_remarks = 'Cancelled by organizer due to venue maintenance.'
    WHERE event_id = 'EVT-2026-006';
    ```
  - **Hard-Delete (Remove Draft Event):**
    ```sql
    DELETE FROM EVENT WHERE event_id = 'EVT-2026-006';
    ```

---

### Module 3: Event Registration, Bookmarks, Recommendations & Notifications
**Presenter:** Aniq Danish Ilman Bin Mazlan (`082284`)  
**Actor:** Participant  
**SDD References:** Section 3.4 Process 4.0 (*Pages 40–48*), Section 3.6 Process 6.0 (*Pages 58–66*), Section 3.7 Process 7.0 (*Pages 67–69*)  
**Target Tables:** `REGISTRATION` (4.2.7), `BOOKMARK` (4.2.8), `NOTIFICATION` (4.2.11)  
**Mobile GUI Screens:** `Search- White Bar.png`, `Event Details.png`, `Digital Admission Pass.png`, `Cancel Registration.png`, `Bookmarked events.png`, `Recommended For You.png`, `Notification.png`

#### A. CREATE (`INSERT`) Operations
1. **Process 4.1 — Register for Campus Event + Auto-Generate Confirmation Notification:**
   - **Validation:** Checks event is Approved (`event_status = 'A'`), registration deadline has not passed, seat quota is available, and composite key `(participant_id, event_id)` is not already registered.
   - **SQL Executed:**
     ```sql
     INSERT INTO REGISTRATION (registration_id, participant_id, event_id, reg_status)
     VALUES ('REG-2026-0006', 'PRT-1001', 'EVT-2026-003', 'R');

     INSERT INTO NOTIFICATION (notification_id, account_id, event_id, title, message, notification_type, is_read)
     VALUES ('NTF-2026-0005', 'ACC-1004', 'EVT-2026-003', 'Registration Confirmed',
             'Your ticket REG-2026-0006 is confirmed.', 'Reminder', 'N');
     ```
2. **Process 6.1 — Add Event Bookmark (Composite PK):**
   - **SQL Executed:**
     ```sql
     INSERT INTO BOOKMARK (bookmark_id, participant_id, event_id)
     VALUES ('BKM-2026-0005', 'PRT-1001', 'EVT-2026-003');
     ```

#### B. READ (`SELECT`) Operations
1. **Process 4.3 — View Digital Admission Pass (QR Code Ticket):**
   ```sql
   SELECT r.registration_id, r.reg_status, r.reg_datetime,
          e.title, e.start_datetime, e.location, p.full_name, p.participant_code
   FROM REGISTRATION r
   JOIN EVENT e ON e.event_id = r.event_id
   JOIN PARTICIPANT p ON p.participant_id = r.participant_id
   WHERE r.participant_id = 'PRT-1001';
   ```
2. **Process 6.2 & 6.3 — View Bookmarks & Generate Personalized Recommendations:**
   ```sql
   -- Process 6.3: Match approved upcoming events with participant's INTEREST categories
   SELECT DISTINCT e.*, c.category_name
   FROM EVENT e
   JOIN CATEGORY c ON c.category_id = e.category_id
   WHERE e.event_status = 'A'
     AND e.category_id IN (SELECT category_id FROM INTEREST WHERE participant_id = 'PRT-1001');
   ```
3. **Process 7.0 — Retrieve Notifications & Unread Counter Badge:**
   ```sql
   SELECT * FROM NOTIFICATION WHERE account_id = 'ACC-1004' ORDER BY sent_datetime DESC;
   SELECT COUNT(*) AS unread_count FROM NOTIFICATION WHERE account_id = 'ACC-1004' AND is_read = 'N';
   ```

#### C. UPDATE (`UPDATE`) Operations
1. **Process 4.2 — Cancel Event Registration Seat:**
   ```sql
   UPDATE REGISTRATION
   SET reg_status = 'C'
   WHERE participant_id = 'PRT-1001' AND event_id = 'EVT-2026-003';
   ```
2. **Process 7.0 — Mark Notification as Read:**
   ```sql
   UPDATE NOTIFICATION SET is_read = 'Y' WHERE notification_id = 'NTF-2026-0002';
   ```

#### D. DELETE (`DELETE`) Operations
- **Process 6.2 — Remove Saved Bookmark (Targeting Composite PK):**
  ```sql
  DELETE FROM BOOKMARK
  WHERE participant_id = 'PRT-1001' AND event_id = 'EVT-2026-003';
  ```

---

### Module 4: Admin Event Approval, Users, Organizations & Analytics
**Presenter:** Muhammad Adam Adli Bin Mohd Nasir (`081377`)  
**Actor:** Administrator  
**SDD References:** Section 3.5 Process 5.0 (*Pages 49–57*) & Section 3.8 Process 8.0 (*Pages 70–80*)  
**Target Tables:** `EVENT` (4.2.6), `ACCOUNT` (4.2.1), `ORGANIZATION` (4.2.3), `ORGANIZER` (4.2.4)  
**Mobile GUI Screens:** `Event Approvals.png`, `Manage users.png`, `Campus Engagement Analytics.png`

#### A. CREATE (`INSERT`) Operations
1. **Process 8.1 — Admin Create User Account:**
   ```sql
   INSERT INTO ACCOUNT (account_id, email, password_hash, role, account_status)
   VALUES ('ACC-1009', 'robotics.club@uniscout.edu.my', '$2y$10$...', 'organizer', 'A');
   ```
2. **Process 8.2 — Admin Create Campus Organization:**
   ```sql
   INSERT INTO ORGANIZATION (organization_id, org_name, org_type, description, contact_email, verification_status)
   VALUES ('ORG-1006', 'Kelab Robotik & IoT UniSZA', 'Club',
           'Student society focusing on robotics and embedded systems.', 'robotics@uniscout.edu.my', 'A');
   ```

#### B. READ (`SELECT`) Operations
1. **Process 5.1 — View Pending Event Submissions for HEPA Review:**
   ```sql
   SELECT e.*, org.org_name, og.full_name AS organizer_name
   FROM EVENT e
   JOIN ORGANIZER og ON og.organizer_id = e.organizer_id
   JOIN ORGANIZATION org ON org.organization_id = og.organization_id
   WHERE e.event_status = 'P';
   ```
2. **Process 8.3 — View Campus Engagement Analytics (Aggregate Queries):**
   ```sql
   SELECT c.category_name, COUNT(e.event_id) AS total_events
   FROM CATEGORY c
   LEFT JOIN EVENT e ON e.category_id = c.category_id
   GROUP BY c.category_id, c.category_name;
   ```

#### C. UPDATE (`UPDATE`) Operations
1. **Process 5.2 & 5.3 — Approve (`'A'`) or Reject (`'R'`) Submitted Event:**
   ```sql
   -- Process 5.2: Approve & Publish Event
   UPDATE EVENT
   SET event_status = 'A',
       review_remarks = 'Approved by Admin. Venue and quota verified.'
   WHERE event_id = 'EVT-2026-004';

   -- Process 5.3: Reject Event with Feedback
   UPDATE EVENT
   SET event_status = 'R',
       review_remarks = 'Rejected: Please attach official faculty advisor endorsement letter.'
   WHERE event_id = 'EVT-2026-004';
   ```
2. **Process 8.1 — Update User Role & Account Status (`'A'` Active / `'S'` Suspended):**
   ```sql
   UPDATE ACCOUNT
   SET role = 'organizer', account_status = 'A'
   WHERE account_id = 'ACC-1005';
   ```
3. **Process 8.2 — Update Organization Details & Verification Status (`'A'` Verified / `'S'` Suspended):**
   ```sql
   UPDATE ORGANIZATION
   SET org_name = 'Kelab Keusahawanan Mahasiswa UniSZA',
       verification_status = 'A'
   WHERE organization_id = 'ORG-1005';
   ```

#### D. DELETE (`DELETE` / Soft-Suspend) Operations
- **Process 8.1 & 8.2 — Delete or Suspend User Account & Organization:**
  ```sql
  DELETE FROM ACCOUNT WHERE account_id = 'ACC-1009';
  DELETE FROM ORGANIZATION WHERE organization_id = 'ORG-1006';
  ```
