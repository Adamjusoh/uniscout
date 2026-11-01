# 🎨 UniScout UI/UX Master Plan & Design System Specification
**Project:** UniScout — Centralized Campus Event & Opportunity Management System  
**Course:** CSD34103 Software Development Workshop  
**Institution:** Faculty of Informatics and Computing (FIK), Universiti Sultan Zainal Abidin (UniSZA)  
**Author:** Senior UI/UX Designer & Frontend Lead (Group Sentry)  
**Reference Model:** Orbit Design System (Modern 3-Column SaaS Student Hub)  
**Date:** November 2026 | Semester I 2026/2027  

---

## 1. Design Philosophy & Model

The user interface follows the **Orbit Design System model**: a clean, highly modern, light-themed, three-column student portal that maximizes visual hierarchy, clarity, and ease of event tracking.

### Core Architectural Structure:
1. **Left Navigation Sidebar (260px):** Permanent navigation anchor with brand mark, primary navigation links (Home, Explore, Calendar, My Registrations, Saved, Recommendations), secondary utilities ("MORE": Notifications with badge counters, Profile, Settings), and an institutional engagement card at the bottom.
2. **Top Header Bar (70px):** Universal search field with placeholder *"Search events, opportunities, or organizations..."*, notification bell with unread dot, and user profile snippet with avatar, name, major, and menu chevron.
3. **Main Central Workspace:** Page title, view switchers (Month, Week, Day), calendar month controls (`< April 2025 >`), interactive 7x5 monthly calendar grid with colorful event pills, and contextual tip cards.
4. **Right Utility Sidebar (320px):** Interactive mini-calendar date picker, multi-select category checkboxes with colored dots and a `Clear` action, and a chronological upcoming events list with color-coded date blocks.

---

## 2. Color Palette & Category Tokens

| Element / Category | Background Tint | Accent / Text | Dot Indicator | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **App Canvas** | `#F4F6FA` | `#0F172A` | — | Soft off-white canvas |
| **Surfaces & Cards** | `#FFFFFF` | `#1E293B` | — | White cards with `#E2E8F0` borders |
| **Active Nav Item** | `#EBF3FF` | `#2563EB` | — | Soft blue pill with deep blue text |
| **Workshop** | `#FEF3C7` | `#B45309` | `#F59E0B` | Hands-on skill sessions & bootcamps |
| **Seminar** | `#F3E8FF` | `#7E22CE` | `#A855F7` | Symposia, talks, and keynotes |
| **Competition** | `#FFE4E6` | `#BE123C` | `#F43F5E` | Hackathons, sprints, case competitions |
| **Career** | `#E0F2FE` | `#0369A1` | `#0EA5E9` | Career fairs, networking, internship drives |
| **Volunteering** | `#CFFAFE` | `#0E7490` | `#06B6D4` | Community service, outreach campaigns |
| **Sports** | `#DCFCE7` | `#15803D` | `#22C55E` | Campus athletic meets, tournaments, wellness |
| **Other** | `#F1F5F9` | `#475569` | `#94A3B8` | General administrative notices |

---

## 3. Screen Inventory & Process Decomposition

In accordance with the UniSZA SDD Guidelines (`Guideline SDD v1.2.pdf`), the UniScout SRS v1.0, and the lecturer's guidance (*"Dr x nak letak login"*), the functional screens are structured to map every process from the Data Flow Diagram:

### Process Decomposition Hierarchy (Exact Mapping to Figure 2.3: `UniScout_Process_Decomposition.png`):
- **PARTICIPANT Domain:**
  - **2.0 Manage Participant Profile:** 2.1 View Profile, 2.2 Update Profile, 2.3 Manage Interest, 2.4 Manage Skills -> `GUI-PROF-01`, `GUI-PROF-02`
  - **3.0 Manage Events:** 3.3 View/Search Events -> `GUI-CAL-01`, `GUI-CAL-02`
  - **4.0 Manage Event Registration:** 4.1 Register Event (4.1.1 Receive Registration Request, 4.1.2 Check Registration Deadline, 4.1.3 Check Event Capacity, 4.1.4 Check Existing Registration, 4.1.5 Process Registration, 4.1.6 Send Registration Confirmation), 4.2 Cancel Registration, 4.3 View Registration -> `GUI-CAL-02`, `GUI-CAL-03`, `GUI-REG-01`, `GUI-REG-02`
  - **6.0 Manage Bookmarks and Recommendations:** 6.1 Save Bookmark, 6.2 Remove Bookmark, 6.3 View Bookmarks, 6.4 Generate Recommendations (6.4.1 Retrieve Participant Profile, 6.4.2 Retrieve Participant Interests, 6.4.3 Retrieve Participant Skills, 6.4.4 Retrieve Participation History, 6.4.5 Match Suitable Events, 6.4.6 Generate Recommendations) -> `GUI-BOOK-01`, `GUI-REC-01`
- **ORGANIZER Domain:**
  - **3.0 Manage Events:** 3.1 Create Event, 3.2 Edit Event, 3.4 Cancel Event -> `GUI-ORG-01`, `GUI-ORG-02`
  - **4.0 Manage Event Registration:** 4.4 Manage Attendance -> `GUI-ATT-01`
- **ADMINISTRATOR Domain:**
  - **3.0 Manage Events:** 3.5 Manage Event Categories -> `GUI-ADMIN-01`
  - **5.0 Manage Event Approval:** 5.1 View Pending Events, 5.2 Approve Event, 5.3 Reject Event -> `GUI-APPR-01`
  - **8.0 Manage Administrator and Analytics:** 8.1 Manage Users, 8.2 Manage Organizations, 8.3 Manage Categories, 8.4 View Analytics -> `GUI-ADMIN-01`
- **System-Wide Utilities:**
  - **1.0 Manage User Accounts:** 1.1 Register Account, 1.2 Login, 1.3 Logout, 1.4 Reset Password -> `GUI-SEC-01`
  - **7.0 Manage Notifications:** 7.1 Generate Notification, 7.2 View Notifications, 7.3 Mark as Read -> `GUI-NOTIF-01`

---

## 4. Master Screen & Artifact Inventory (All 16 Figures)

All sixteen interfaces are implemented in the live interactive prototype at [`Software-Design-Description/prototypes/event-discovery/`](prototypes/event-discovery/):

| Figure | Configuration ID | DFD Process ID | Screen Title | Role |
| :--- | :--- | :--- | :--- | :--- |
| **Figure 3.1** | `GUI-CAL-01` | Process 3.3, 3.5 | Primary Calendar & Opportunity Discovery Interface | Student / Participant |
| **Figure 3.2** | `GUI-CAL-02` | Process 3.3, 4.1 | Event Detail & Registration Dialog Modal | Student / Participant |
| **Figure 3.3** | `GUI-CAL-03` | Process 4.1, 4.3 | Fast Check-in Ticket Slip Admission Pass Modal | Student / Participant |
| **Figure 3.4** | `GUI-PROF-01` | Process 2.1, 2.3, 2.4 | Participant Profile & Competency Matrix Hub | Student / Participant |
| **Figure 3.5** | `GUI-PROF-02` | Process 2.2 | Update Participant Profile Dialog Modal | Student / Participant |
| **Figure 3.6** | `GUI-REG-01` | Process 4.3 | My Registrations & Admission Passes Interface | Student / Participant |
| **Figure 3.7** | `GUI-REG-02` | Process 4.2 | Registration Cancellation Confirmation Dialog | Student / Participant |
| **Figure 3.8** | `GUI-REC-01` | Process 6.4 (6.4.1–6.4.6) | Personalized Recommendations Feed | Student / Participant |
| **Figure 3.9** | `GUI-APPR-01` | Process 5.1, 5.2, 5.3 | Event Approval & Administrative Oversight Dashboard | Administrator (HEPA) |
| **Figure 3.10** | `GUI-BOOK-01` | Process 6.1, 6.2, 6.3 | Saved Opportunities & Bookmarks Interface | Student / Participant |
| **Figure 3.11** | `GUI-NOTIF-01` | Process 7.1, 7.2, 7.3 | Multi-Channel Notification Center | Student / All Roles |
| **Figure 3.12** | `GUI-SEC-01` | Process 1.3, 1.4 | Account Security & Password Management Interface | Student / All Roles |
| **Figure 3.13** | `GUI-ORG-01` | Process 3.1, 3.2, 3.4 | Organizer Studio & Event Operations Management | Club / Society Organizer |
| **Figure 3.14** | `GUI-ADMIN-01` | Process 8.1, 8.2, 8.3, 8.4 | Administration & University Analytics Dashboard | Administrator (HEPA/Dean) |
| **Figure 3.15** | `GUI-ORG-02` | Process 3.1, 3.2 | Create & Edit Event Modal | Club / Society Organizer |
| **Figure 3.16** | `GUI-ATT-01` | Process 4.4 | Live Attendance Verification & Attendee Roster Modal | Organizer / Marshal |

