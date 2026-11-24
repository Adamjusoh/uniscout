import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Holds the active MySQL Workbench connection configuration and state across
/// all 11 tables of `uniscout_db`, plus a live SQL & SDD Process trace.
class UniScoutController extends ChangeNotifier {
  UniScoutController({bool skipNetworkOnInit = false})
      : _skipNetwork = skipNetworkOnInit {
    _loadFallbackSeed();
  }

  final bool _skipNetwork;

  // Connection settings (editable inside app DB Settings dialog)
  String apiUrl = _defaultApiUrl();
  String dbHost = '127.0.0.1';
  String dbPort = '3306';
  String dbUser = 'root';
  String dbPassword = '';
  String dbName = 'uniscout_db';

  bool isConnectedToMySql = false;
  bool isLoading = false;
  String? lastError;
  String lastSqlTrace =
      '-- Connect to database/api.php (MySQL Workbench uniscout_db) or run in Demo Mode';
  String lastSddRef = 'Chapter 4: 11 Tables Ready';

  // Active logged-in user (null shows Auth screen)
  Map<String, dynamic>? currentUser;

  // All 11 tables cached locally & synced with MySQL Workbench
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> participants = [];
  List<Map<String, dynamic>> organizations = [];
  List<Map<String, dynamic>> organizers = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> registrations = [];
  List<Map<String, dynamic>> bookmarks = [];
  List<Map<String, dynamic>> interests = [];
  List<Map<String, dynamic>> skills = [];
  List<Map<String, dynamic>> notifications = [];

  static String _defaultApiUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api.php';
    }
    return 'http://127.0.0.1:8080/api.php';
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-DB-Host': dbHost,
        'X-DB-Port': dbPort,
        'X-DB-User': dbUser,
        'X-DB-Password': dbPassword,
        'X-DB-Name': dbName,
      };

  /// Refreshes all 11 tables from the PHP/MySQL Workbench API if reachable.
  Future<bool> refreshFromServer() async {
    if (_skipNetwork) return false;
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('$apiUrl?action=bootstrap'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['ok'] == true) {
        _applyBootstrap(body);
        isConnectedToMySql = true;
        lastSqlTrace = (body['sql'] as String?) ?? lastSqlTrace;
        lastSddRef = (body['sdd_ref'] as String?) ?? lastSddRef;
        isLoading = false;
        notifyListeners();
        return true;
      }
      isConnectedToMySql = false;
      lastError = (body['message'] as String?) ?? 'Database connection failed.';
    } catch (e) {
      isConnectedToMySql = false;
      lastError =
          'Local API unreachable ($e). Using Demo Mode until ./start_backend.sh is running.';
    }
    isLoading = false;
    notifyListeners();
    return false;
  }

  /// Runs uniscout_schema.sql + uniscout_seed.sql against MySQL Workbench.
  Future<String> initializeMySqlDatabase() async {
    if (_skipNetwork) return 'Offline test mode';
    isLoading = true;
    notifyListeners();
    try {
      final res = await http
          .post(Uri.parse('$apiUrl?action=init_db'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['ok'] == true) {
        _applyBootstrap(body);
        isConnectedToMySql = true;
        lastError = null;
        lastSqlTrace = (body['sql'] as String?) ?? '';
        lastSddRef = (body['sdd_ref'] as String?) ?? '';
        isLoading = false;
        notifyListeners();
        return (body['message'] as String?) ?? 'Database initialized.';
      }
      isLoading = false;
      notifyListeners();
      throw Exception((body['message'] as String?) ?? 'Init failed.');
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void updateDbConfig({
    required String url,
    required String host,
    required String port,
    required String user,
    required String password,
    required String database,
  }) {
    apiUrl = url.trim();
    dbHost = host.trim();
    dbPort = port.trim();
    dbUser = user.trim();
    dbPassword = password;
    dbName = database.trim();
    notifyListeners();
  }

  Future<Map<String, dynamic>> _callAction(
    String action,
    Map<String, dynamic> payload,
    Map<String, dynamic> Function() localFallback,
  ) async {
    if (!_skipNetwork && isConnectedToMySql) {
      final res = await http
          .post(
            Uri.parse('$apiUrl?action=$action'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['ok'] != true) {
        throw Exception((body['message'] as String?) ?? 'Request failed');
      }
      lastSqlTrace = (body['sql'] as String?) ?? '';
      lastSddRef = (body['sdd_ref'] as String?) ?? '';
      await refreshFromServer();
      return body;
    }

    final result = localFallback();
    lastSqlTrace = (result['sql'] as String?) ?? '';
    lastSddRef = (result['sdd_ref'] as String?) ?? '';
    notifyListeners();
    return result;
  }

  void _applyBootstrap(Map<String, dynamic> data) {
    List<Map<String, dynamic>> castList(String key) =>
        ((data[key] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    accounts = castList('accounts');
    participants = castList('participants');
    organizations = castList('organizations');
    organizers = castList('organizers');
    categories = castList('categories');
    events = castList('events');
    registrations = castList('registrations');
    bookmarks = castList('bookmarks');
    interests = castList('interests');
    skills = castList('skills');
    notifications = castList('notifications');

    if (currentUser != null) {
      final accId = currentUser!['account_id'];
      final refreshed = accounts.where((a) => a['account_id'] == accId);
      if (refreshed.isNotEmpty) {
        currentUser = refreshed.first;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Role helpers & lookups
  // ---------------------------------------------------------------------------
  String get currentRole => (currentUser?['role'] as String?) ?? 'participant';
  String get currentAccountId =>
      (currentUser?['account_id'] as String?) ?? 'ACC-1004';
  String get currentParticipantId =>
      (currentUser?['participant_id'] as String?) ?? 'PRT-1001';
  String get currentOrganizerId =>
      (currentUser?['organizer_id'] as String?) ?? 'OGN-1001';

  Map<String, dynamic>? get activeParticipant {
    final pid = currentParticipantId;
    final list = participants.where((p) => p['participant_id'] == pid);
    return list.isEmpty ? null : list.first;
  }

  int get unreadNotificationCount => notifications
      .where((n) => n['account_id'] == currentAccountId && n['is_read'] == 'N')
      .length;

  void signInQuick(String accountId) {
    final found = accounts.where((a) => a['account_id'] == accountId);
    if (found.isEmpty) return;
    final acc = found.first;
    if (acc['account_status'] == 'S') {
      throw Exception('Account is suspended (account_status = S).');
    }
    currentUser = acc;
    lastSqlTrace =
        "SELECT * FROM ACCOUNT WHERE account_id='$accountId' AND account_status!='S';";
    lastSddRef = 'Process 1.0 (SDD p.11) · Table 4.2.1 ACCOUNT';
    notifyListeners();
  }

  Future<void> signInWithEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final found = accounts.where(
      (a) => (a['email'] as String).toLowerCase() == normalized,
    );
    if (found.isEmpty) {
      throw Exception('Account not found for "$email". Try Sign Up.');
    }
    if (found.first['account_status'] == 'S') {
      throw Exception('This account is suspended (account_status = S).');
    }
    if (isConnectedToMySql && !_skipNetwork) {
      final res = await http.post(
        Uri.parse('$apiUrl?action=login'),
        headers: _headers,
        body: jsonEncode({'email': email.trim()}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['ok'] != true) {
        throw Exception(body['message'] ?? 'Login failed');
      }
      lastSqlTrace = (body['sql'] as String?) ?? '';
      lastSddRef = (body['sdd_ref'] as String?) ?? '';
    } else {
      lastSqlTrace = "SELECT * FROM ACCOUNT WHERE email='${email.trim()}';";
      lastSddRef = 'Process 1.0 (SDD p.11) · Table 4.2.1 ACCOUNT';
    }
    currentUser = found.first;
    notifyListeners();
  }

  void signOut() {
    currentUser = null;
    notifyListeners();
  }

  /// Switches demo actor role cleanly during presentation (Participant/Organizer/Admin).
  void switchDemoRole(String role) {
    final match = accounts.where((a) => a['role'] == role);
    if (match.isNotEmpty) {
      currentUser = match.first;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // PROCESS 1.0: Register Account
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> registerAccount({
    required String email,
    required String password,
    required String fullName,
    required String participantCode,
    String faculty = 'Faculty of Informatics and Computing',
    String program = 'Bachelor of Computer Science (Software Development)',
    int academicYear = 3,
    String phoneNo = '012-3456789',
  }) async {
    final res = await _callAction(
      'register_account',
      {
        'email': email,
        'password': password,
        'role': 'participant',
        'full_name': fullName,
        'participant_code': participantCode,
        'faculty': faculty,
        'program': program,
        'academic_year': academicYear,
        'phone_no': phoneNo,
      },
      () {
        final accId = _nextId(accounts, 'account_id', 'ACC-', 4, 1001);
        final prtId = _nextId(participants, 'participant_id', 'PRT-', 4, 1001);
        final prt = {
          'participant_id': prtId,
          'account_id': accId,
          'participant_code': participantCode,
          'full_name': fullName,
          'faculty': faculty,
          'program': program,
          'academic_year': academicYear,
          'phone_no': phoneNo,
        };
        final acc = {
          'account_id': accId,
          'email': email,
          'role': 'participant',
          'account_status': 'A',
          'participant_id': prtId,
          'participant_code': participantCode,
          'participant_name': fullName,
          'faculty': faculty,
          'program': program,
          'academic_year': academicYear,
          'participant_phone': phoneNo,
        };
        accounts.add(acc);
        participants.add(prt);
        return {
          'ok': true,
          'account_id': accId,
          'participant_id': prtId,
          'message': 'Registered $email ($accId)',
          'sql':
              "INSERT INTO ACCOUNT VALUES ('$accId','$email',...,'participant','A'); INSERT INTO PARTICIPANT VALUES ('$prtId','$accId','$participantCode','$fullName',...);",
          'sdd_ref': 'Process 1.0 (SDD p.11) · Tables ACCOUNT & PARTICIPANT',
        };
      },
    );
    await signInWithEmail(email);
    return res;
  }

  // ---------------------------------------------------------------------------
  // MEMBER 1 CRUD (Process 2.0: Profile, Interests, Skills)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> updateProfile({
    required String participantId,
    required String fullName,
    required String participantCode,
    required String faculty,
    required String program,
    required int academicYear,
    required String phoneNo,
  }) {
    return _callAction(
      'update_profile',
      {
        'participant_id': participantId,
        'full_name': fullName,
        'participant_code': participantCode,
        'faculty': faculty,
        'program': program,
        'academic_year': academicYear,
        'phone_no': phoneNo,
      },
      () {
        for (final p in participants) {
          if (p['participant_id'] == participantId) {
            p['full_name'] = fullName;
            p['participant_code'] = participantCode;
            p['faculty'] = faculty;
            p['program'] = program;
            p['academic_year'] = academicYear;
            p['phone_no'] = phoneNo;
          }
        }
        return {
          'ok': true,
          'message': 'Updated participant $participantId',
          'sql':
              "UPDATE PARTICIPANT SET full_name='$fullName', faculty='$faculty', academic_year=$academicYear WHERE participant_id='$participantId';",
          'sdd_ref': 'Process 2.2 (SDD p.18) · Table 4.2.2 PARTICIPANT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> addInterest({
    required String participantId,
    required String categoryId,
    required String interestTag,
  }) {
    return _callAction(
      'add_interest',
      {
        'participant_id': participantId,
        'category_id': categoryId,
        'interest_tag': interestTag,
      },
      () {
        final dup = interests.any(
          (i) =>
              i['participant_id'] == participantId &&
              i['category_id'] == categoryId &&
              (i['interest_tag'] as String).toLowerCase() ==
                  interestTag.toLowerCase(),
        );
        if (dup) {
          throw Exception(
              'Duplicate composite primary key (participant_id, category_id, interest_tag).');
        }
        final id = _nextId(interests, 'interest_id', 'INT-', 4, 1001);
        final catName = categories
            .firstWhere((c) => c['category_id'] == categoryId,
                orElse: () => {'category_name': 'General'})['category_name'];
        interests.add({
          'interest_id': id,
          'participant_id': participantId,
          'category_id': categoryId,
          'interest_tag': interestTag,
          'category_name': catName,
        });
        return {
          'ok': true,
          'message': "Added interest '$interestTag' ($id)",
          'sql':
              "INSERT INTO INTEREST (interest_id, participant_id, category_id, interest_tag) VALUES ('$id', '$participantId', '$categoryId', '$interestTag');",
          'sdd_ref':
              'Process 2.3 (SDD p.22) · Table 4.2.9 INTEREST (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteInterest({
    required String participantId,
    required String categoryId,
    required String interestTag,
  }) {
    return _callAction(
      'delete_interest',
      {
        'participant_id': participantId,
        'category_id': categoryId,
        'interest_tag': interestTag,
      },
      () {
        interests.removeWhere((i) =>
            i['participant_id'] == participantId &&
            i['category_id'] == categoryId &&
            i['interest_tag'] == interestTag);
        return {
          'ok': true,
          'message': "Removed interest '$interestTag'",
          'sql':
              "DELETE FROM INTEREST WHERE participant_id='$participantId' AND category_id='$categoryId' AND interest_tag='$interestTag';",
          'sdd_ref':
              'Process 2.3 (SDD p.22) · Table 4.2.9 INTEREST (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> addSkill({
    required String participantId,
    required String skillName,
    required String proficiencyLevel,
  }) {
    return _callAction(
      'add_skill',
      {
        'participant_id': participantId,
        'skill_name': skillName,
        'proficiency_level': proficiencyLevel,
      },
      () {
        final dup = skills.any(
          (s) =>
              s['participant_id'] == participantId &&
              (s['skill_name'] as String).toLowerCase() ==
                  skillName.toLowerCase(),
        );
        if (dup) {
          throw Exception(
              'Skill already exists for this participant (composite PK).');
        }
        final id = _nextId(skills, 'skill_id', 'SKL-', 4, 1001);
        skills.add({
          'skill_id': id,
          'participant_id': participantId,
          'skill_name': skillName,
          'proficiency_level': proficiencyLevel,
        });
        return {
          'ok': true,
          'message': "Added skill '$skillName' ($id)",
          'sql':
              "INSERT INTO SKILL (skill_id, participant_id, skill_name, proficiency_level) VALUES ('$id', '$participantId', '$skillName', '$proficiencyLevel');",
          'sdd_ref': 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> updateSkill({
    required String participantId,
    required String skillName,
    required String proficiencyLevel,
  }) {
    return _callAction(
      'update_skill',
      {
        'participant_id': participantId,
        'skill_name': skillName,
        'proficiency_level': proficiencyLevel,
      },
      () {
        for (final s in skills) {
          if (s['participant_id'] == participantId &&
              s['skill_name'] == skillName) {
            s['proficiency_level'] = proficiencyLevel;
          }
        }
        return {
          'ok': true,
          'message': "Updated '$skillName' to $proficiencyLevel",
          'sql':
              "UPDATE SKILL SET proficiency_level='$proficiencyLevel' WHERE participant_id='$participantId' AND skill_name='$skillName';",
          'sdd_ref': 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteSkill({
    required String participantId,
    required String skillName,
  }) {
    return _callAction(
      'delete_skill',
      {'participant_id': participantId, 'skill_name': skillName},
      () {
        skills.removeWhere((s) =>
            s['participant_id'] == participantId &&
            s['skill_name'] == skillName);
        return {
          'ok': true,
          'message': "Deleted skill '$skillName'",
          'sql':
              "DELETE FROM SKILL WHERE participant_id='$participantId' AND skill_name='$skillName';",
          'sdd_ref': 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
        };
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBER 2 CRUD (Process 3.0: Organizer Events)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> createEvent({
    required String organizerId,
    required String categoryId,
    required String title,
    required String description,
    required String eventMode,
    required String location,
    required String startDatetime,
    required String endDatetime,
    required String regDeadline,
    required int capacity,
    required String eligibilityCriteria,
    required String eventStatus,
  }) {
    return _callAction(
      'create_event',
      {
        'organizer_id': organizerId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'event_mode': eventMode,
        'location': location,
        'start_datetime': startDatetime,
        'end_datetime': endDatetime,
        'reg_deadline': regDeadline,
        'capacity': capacity,
        'eligibility_criteria': eligibilityCriteria,
        'event_status': eventStatus,
      },
      () {
        final id = _nextId(events, 'event_id', 'EVT-2026-', 3, 1);
        final catName = categories.firstWhere(
          (c) => c['category_id'] == categoryId,
          orElse: () => {'category_name': 'Workshop'},
        )['category_name'];
        events.add({
          'event_id': id,
          'organizer_id': organizerId,
          'category_id': categoryId,
          'category_name': catName,
          'organizer_name': currentUser?['organizer_name'] ?? 'Campus Organizer',
          'org_name': 'Computer Science Society (CSS)',
          'title': title,
          'description': description,
          'event_mode': eventMode,
          'location': location,
          'start_datetime': startDatetime,
          'end_datetime': endDatetime,
          'reg_deadline': regDeadline,
          'capacity': capacity,
          'registered_count': 0,
          'eligibility_criteria': eligibilityCriteria,
          'event_status': eventStatus,
          'review_remarks': null,
        });
        return {
          'ok': true,
          'event_id': id,
          'message': 'Created event $id ($title)',
          'sql':
              "INSERT INTO EVENT (event_id, organizer_id, category_id, title, ..., start_datetime, event_status) VALUES ('$id', '$organizerId', '$categoryId', '$title', ..., '$startDatetime', '$eventStatus');",
          'sdd_ref': 'Process 3.1 (SDD p.29) · Table 4.2.6 EVENT (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String categoryId,
    required String title,
    required String description,
    required String eventMode,
    required String location,
    required String startDatetime,
    required String endDatetime,
    required String regDeadline,
    required int capacity,
    required String eligibilityCriteria,
    required String eventStatus,
  }) {
    return _callAction(
      'update_event',
      {
        'event_id': eventId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'event_mode': eventMode,
        'location': location,
        'start_datetime': startDatetime,
        'end_datetime': endDatetime,
        'reg_deadline': regDeadline,
        'capacity': capacity,
        'eligibility_criteria': eligibilityCriteria,
        'event_status': eventStatus,
      },
      () {
        final catName = categories.firstWhere(
          (c) => c['category_id'] == categoryId,
          orElse: () => {'category_name': 'Workshop'},
        )['category_name'];
        for (final e in events) {
          if (e['event_id'] == eventId) {
            e['category_id'] = categoryId;
            e['category_name'] = catName;
            e['title'] = title;
            e['description'] = description;
            e['event_mode'] = eventMode;
            e['location'] = location;
            e['start_datetime'] = startDatetime;
            e['end_datetime'] = endDatetime;
            e['reg_deadline'] = regDeadline;
            e['capacity'] = capacity;
            e['eligibility_criteria'] = eligibilityCriteria;
            e['event_status'] = eventStatus;
          }
        }
        return {
          'ok': true,
          'message': 'Updated event $eventId',
          'sql':
              "UPDATE EVENT SET title='$title', category_id='$categoryId', capacity=$capacity, event_status='$eventStatus' WHERE event_id='$eventId';",
          'sdd_ref': 'Process 3.2 (SDD p.33) · Table 4.2.6 EVENT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> cancelEvent({
    required String eventId,
    required String reason,
  }) {
    return _callAction(
      'cancel_event',
      {'event_id': eventId, 'review_remarks': reason},
      () {
        for (final e in events) {
          if (e['event_id'] == eventId) {
            e['event_status'] = 'X';
            e['review_remarks'] = reason;
          }
        }
        return {
          'ok': true,
          'message': "Cancelled event $eventId (event_status = 'X')",
          'sql':
              "UPDATE EVENT SET event_status='X', review_remarks='$reason' WHERE event_id='$eventId';",
          'sdd_ref': 'Process 3.3 (SDD p.37) · Table 4.2.6 EVENT (Soft-Delete)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteEvent(String eventId) {
    return _callAction(
      'delete_event',
      {'event_id': eventId},
      () {
        events.removeWhere((e) => e['event_id'] == eventId);
        registrations.removeWhere((r) => r['event_id'] == eventId);
        bookmarks.removeWhere((b) => b['event_id'] == eventId);
        return {
          'ok': true,
          'message': 'Deleted event $eventId',
          'sql': "DELETE FROM EVENT WHERE event_id='$eventId';",
          'sdd_ref': 'Process 3.3 (SDD p.37) · Table 4.2.6 EVENT (Hard Delete)',
        };
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBER 3 CRUD (Process 4.0, 6.0, 7.0: Registration, Bookmarks, Notifications)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> registerForEvent({
    required String participantId,
    required String eventId,
  }) {
    return _callAction(
      'register_event',
      {'participant_id': participantId, 'event_id': eventId},
      () {
        final evt = events.firstWhere((e) => e['event_id'] == eventId);
        final existing = registrations.where(
          (r) => r['participant_id'] == participantId && r['event_id'] == eventId,
        );
        late String regId;
        if (existing.isNotEmpty) {
          if (existing.first['reg_status'] == 'R' ||
              existing.first['reg_status'] == 'A') {
            throw Exception('Already registered for this event.');
          }
          existing.first['reg_status'] = 'R';
          existing.first['reg_datetime'] = _nowStr();
          regId = existing.first['registration_id'] as String;
        } else {
          regId = _nextId(registrations, 'registration_id', 'REG-2026-', 4, 1);
          registrations.insert(0, {
            'registration_id': regId,
            'participant_id': participantId,
            'event_id': eventId,
            'reg_datetime': _nowStr(),
            'reg_status': 'R',
            'event_title': evt['title'],
            'start_datetime': evt['start_datetime'],
            'location': evt['location'],
            'event_mode': evt['event_mode'],
            'category_name': evt['category_name'],
            'participant_name': activeParticipant?['full_name'] ?? 'Student',
            'participant_code': activeParticipant?['participant_code'] ?? '083370',
          });
        }
        evt['registered_count'] = ((evt['registered_count'] as int?) ?? 0) + 1;
        final ntfId = _nextId(notifications, 'notification_id', 'NTF-2026-', 4, 1);
        notifications.insert(0, {
          'notification_id': ntfId,
          'account_id': currentAccountId,
          'event_id': eventId,
          'title': 'Registration Confirmed',
          'message': "Your ticket $regId for ${evt['title']} is confirmed.",
          'notification_type': 'Reminder',
          'is_read': 'N',
          'sent_datetime': _nowStr(),
        });
        return {
          'ok': true,
          'registration_id': regId,
          'message': 'Registered ($regId) + confirmation notification inserted',
          'sql':
              "INSERT INTO REGISTRATION (registration_id, participant_id, event_id, reg_status) VALUES ('$regId', '$participantId', '$eventId', 'R');",
          'sdd_ref':
              'Process 4.1 (SDD p.40) · Tables REGISTRATION & NOTIFICATION',
        };
      },
    );
  }

  Future<Map<String, dynamic>> cancelRegistration({
    required String participantId,
    required String eventId,
    bool hardDelete = false,
  }) {
    return _callAction(
      hardDelete ? 'delete_registration' : 'cancel_registration',
      {'participant_id': participantId, 'event_id': eventId},
      () {
        if (hardDelete) {
          registrations.removeWhere((r) =>
              r['participant_id'] == participantId && r['event_id'] == eventId);
        } else {
          for (final r in registrations) {
            if (r['participant_id'] == participantId &&
                r['event_id'] == eventId) {
              r['reg_status'] = 'C';
            }
          }
        }
        return {
          'ok': true,
          'message': hardDelete
              ? 'Deleted registration row'
              : "Cancelled seat (reg_status = 'C')",
          'sql': hardDelete
              ? "DELETE FROM REGISTRATION WHERE participant_id='$participantId' AND event_id='$eventId';"
              : "UPDATE REGISTRATION SET reg_status='C' WHERE participant_id='$participantId' AND event_id='$eventId';",
          'sdd_ref':
              'Process 4.2 (SDD p.43) · Table 4.2.7 REGISTRATION (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> toggleBookmark({
    required String participantId,
    required String eventId,
  }) {
    final exists = bookmarks.any(
      (b) => b['participant_id'] == participantId && b['event_id'] == eventId,
    );
    if (exists) {
      return _callAction(
        'delete_bookmark',
        {'participant_id': participantId, 'event_id': eventId},
        () {
          bookmarks.removeWhere((b) =>
              b['participant_id'] == participantId && b['event_id'] == eventId);
          return {
            'ok': true,
            'message': 'Removed bookmark for $eventId',
            'sql':
                "DELETE FROM BOOKMARK WHERE participant_id='$participantId' AND event_id='$eventId';",
            'sdd_ref':
                'Process 6.2 (SDD p.61) · Table 4.2.8 BOOKMARK (Composite PK)',
          };
        },
      );
    }
    return _callAction(
      'add_bookmark',
      {'participant_id': participantId, 'event_id': eventId},
      () {
        final evt = events.firstWhere((e) => e['event_id'] == eventId);
        final id = _nextId(bookmarks, 'bookmark_id', 'BKM-2026-', 4, 1);
        bookmarks.insert(0, {
          'bookmark_id': id,
          'participant_id': participantId,
          'event_id': eventId,
          'saved_datetime': _nowStr(),
          'event_title': evt['title'],
          'start_datetime': evt['start_datetime'],
          'location': evt['location'],
          'event_mode': evt['event_mode'],
          'category_name': evt['category_name'],
        });
        return {
          'ok': true,
          'message': 'Bookmarked $eventId ($id)',
          'sql':
              "INSERT INTO BOOKMARK (bookmark_id, participant_id, event_id) VALUES ('$id', '$participantId', '$eventId');",
          'sdd_ref':
              'Process 6.1 (SDD p.58) · Table 4.2.8 BOOKMARK (Composite PK)',
        };
      },
    );
  }

  Future<Map<String, dynamic>> markNotificationRead(String notificationId) {
    return _callAction(
      'mark_notification_read',
      {'notification_id': notificationId, 'is_read': 'Y'},
      () {
        for (final n in notifications) {
          if (n['notification_id'] == notificationId) {
            n['is_read'] = 'Y';
          }
        }
        return {
          'ok': true,
          'message': 'Marked $notificationId as read',
          'sql':
              "UPDATE NOTIFICATION SET is_read='Y' WHERE notification_id='$notificationId';",
          'sdd_ref': 'Process 7.0 (SDD p.67) · Table 4.2.11 NOTIFICATION',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteNotification(String notificationId) {
    return _callAction(
      'delete_notification',
      {'notification_id': notificationId},
      () {
        notifications.removeWhere((n) => n['notification_id'] == notificationId);
        return {
          'ok': true,
          'message': 'Deleted notification $notificationId',
          'sql': "DELETE FROM NOTIFICATION WHERE notification_id='$notificationId';",
          'sdd_ref': 'Process 7.0 (SDD p.67) · Table 4.2.11 NOTIFICATION',
        };
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBER 4 CRUD (Process 5.0 & 8.0: Approvals, Users, Organizations)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> reviewEvent({
    required String eventId,
    required String status,
    required String remarks,
  }) {
    return _callAction(
      'review_event',
      {'event_id': eventId, 'event_status': status, 'review_remarks': remarks},
      () {
        for (final e in events) {
          if (e['event_id'] == eventId) {
            e['event_status'] = status;
            e['review_remarks'] = remarks;
          }
        }
        return {
          'ok': true,
          'message': "Event $eventId set to '$status'",
          'sql':
              "UPDATE EVENT SET event_status='$status', review_remarks='$remarks' WHERE event_id='$eventId';",
          'sdd_ref': 'Process 5.2 / 5.3 (SDD p.52-55) · Table 4.2.6 EVENT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    String? participantCode,
    String? organizationId,
  }) {
    return _callAction(
      'create_user',
      {
        'email': email,
        'full_name': fullName,
        'role': role,
        'participant_code': participantCode,
        'organization_id': organizationId,
      },
      () {
        final accId = _nextId(accounts, 'account_id', 'ACC-', 4, 1001);
        final entry = <String, dynamic>{
          'account_id': accId,
          'email': email,
          'role': role,
          'account_status': 'A',
          'created_at': _nowStr(),
        };
        if (role == 'participant') {
          final prtId = _nextId(participants, 'participant_id', 'PRT-', 4, 1001);
          final code = participantCode ?? '089999';
          participants.add({
            'participant_id': prtId,
            'account_id': accId,
            'participant_code': code,
            'full_name': fullName,
            'faculty': 'Faculty of Informatics and Computing',
            'program': 'Bachelor of Computer Science',
            'academic_year': 3,
          });
          entry['participant_id'] = prtId;
          entry['participant_code'] = code;
          entry['participant_name'] = fullName;
        } else if (role == 'organizer') {
          final ognId = _nextId(organizers, 'organizer_id', 'OGN-', 4, 1001);
          organizers.add({
            'organizer_id': ognId,
            'account_id': accId,
            'organization_id': organizationId ?? 'ORG-1002',
            'full_name': fullName,
            'position': 'Club Representative',
          });
          entry['organizer_id'] = ognId;
          entry['organizer_name'] = fullName;
        }
        accounts.add(entry);
        return {
          'ok': true,
          'message': 'Created user $email ($accId)',
          'sql':
              "INSERT INTO ACCOUNT (account_id, email, role, account_status) VALUES ('$accId', '$email', '$role', 'A');",
          'sdd_ref': 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> updateUser({
    required String accountId,
    required String role,
    required String accountStatus,
  }) {
    return _callAction(
      'update_user',
      {'account_id': accountId, 'role': role, 'account_status': accountStatus},
      () {
        for (final a in accounts) {
          if (a['account_id'] == accountId) {
            a['role'] = role;
            a['account_status'] = accountStatus;
          }
        }
        return {
          'ok': true,
          'message': 'Updated $accountId (role=$role, status=$accountStatus)',
          'sql':
              "UPDATE ACCOUNT SET role='$role', account_status='$accountStatus' WHERE account_id='$accountId';",
          'sdd_ref': 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteUser(String accountId) {
    return _callAction(
      'delete_user',
      {'account_id': accountId},
      () {
        accounts.removeWhere((a) => a['account_id'] == accountId);
        participants.removeWhere((p) => p['account_id'] == accountId);
        return {
          'ok': true,
          'message': 'Deleted account $accountId',
          'sql': "DELETE FROM ACCOUNT WHERE account_id='$accountId';",
          'sdd_ref': 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
        };
      },
    );
  }

  Future<Map<String, dynamic>> createOrganization({
    required String orgName,
    required String orgType,
    required String description,
    required String contactEmail,
    required String verificationStatus,
  }) {
    return _callAction(
      'create_organization',
      {
        'org_name': orgName,
        'org_type': orgType,
        'description': description,
        'contact_email': contactEmail,
        'verification_status': verificationStatus,
      },
      () {
        final id = _nextId(organizations, 'organization_id', 'ORG-', 4, 1001);
        organizations.add({
          'organization_id': id,
          'org_name': orgName,
          'org_type': orgType,
          'description': description,
          'contact_email': contactEmail,
          'verification_status': verificationStatus,
        });
        return {
          'ok': true,
          'message': 'Added organization $orgName ($id)',
          'sql':
              "INSERT INTO ORGANIZATION VALUES ('$id', '$orgName', '$orgType', ..., '$verificationStatus');",
          'sdd_ref': 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
        };
      },
    );
  }

  Future<Map<String, dynamic>> updateOrganization({
    required String organizationId,
    required String orgName,
    required String orgType,
    required String description,
    required String contactEmail,
    required String verificationStatus,
  }) {
    return _callAction(
      'update_organization',
      {
        'organization_id': organizationId,
        'org_name': orgName,
        'org_type': orgType,
        'description': description,
        'contact_email': contactEmail,
        'verification_status': verificationStatus,
      },
      () {
        for (final o in organizations) {
          if (o['organization_id'] == organizationId) {
            o['org_name'] = orgName;
            o['org_type'] = orgType;
            o['description'] = description;
            o['contact_email'] = contactEmail;
            o['verification_status'] = verificationStatus;
          }
        }
        return {
          'ok': true,
          'message': 'Updated organization $organizationId',
          'sql':
              "UPDATE ORGANIZATION SET org_name='$orgName', verification_status='$verificationStatus' WHERE organization_id='$organizationId';",
          'sdd_ref': 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
        };
      },
    );
  }

  Future<Map<String, dynamic>> deleteOrganization(String organizationId) {
    return _callAction(
      'delete_organization',
      {'organization_id': organizationId},
      () {
        final referenced = organizers.any(
          (og) => og['organization_id'] == organizationId,
        );
        if (referenced) {
          throw Exception(
              'Cannot delete: organization is referenced by an Organizer (ON DELETE RESTRICT).');
        }
        organizations
            .removeWhere((o) => o['organization_id'] == organizationId);
        return {
          'ok': true,
          'message': 'Deleted organization $organizationId',
          'sql':
              "DELETE FROM ORGANIZATION WHERE organization_id='$organizationId';",
          'sdd_ref': 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
        };
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers & Local Demo Seed Data (mirrors database/uniscout_seed.sql)
  // ---------------------------------------------------------------------------
  String _nextId(
    List<Map<String, dynamic>> list,
    String field,
    String prefix,
    int padWidth,
    int minStart,
  ) {
    int maxNum = minStart - 1;
    for (final row in list) {
      final raw = row[field]?.toString() ?? '';
      if (raw.startsWith(prefix)) {
        final n = int.tryParse(raw.substring(prefix.length));
        if (n != null && n > maxNum) maxNum = n;
      }
    }
    return '$prefix${(maxNum + 1).toString().padLeft(padWidth, '0')}';
  }

  String _nowStr() => DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');

  void _loadFallbackSeed() {
    accounts = [
      {
        'account_id': 'ACC-1001',
        'email': 'admin@uniscout.edu.my',
        'role': 'admin',
        'account_status': 'A',
        'created_at': '2026-10-01 08:00:00',
      },
      {
        'account_id': 'ACC-1002',
        'email': 'css.organizer@uniscout.edu.my',
        'role': 'organizer',
        'account_status': 'A',
        'organizer_id': 'OGN-1001',
        'organization_id': 'ORG-1002',
        'organizer_name': 'Ts. Dr. Nurul Hidayah binti Che Mat',
      },
      {
        'account_id': 'ACC-1004',
        'email': '083370@putra.unisza.edu.my',
        'role': 'participant',
        'account_status': 'A',
        'participant_id': 'PRT-1001',
        'participant_code': '083370',
        'participant_name': 'Muhammad Adam Haris bin Jusoh',
      },
      {
        'account_id': 'ACC-1005',
        'email': '081999@putra.unisza.edu.my',
        'role': 'participant',
        'account_status': 'A',
        'participant_id': 'PRT-1002',
        'participant_code': '081999',
        'participant_name': 'Ahmad Ilman Wafi bin Mohd Azami',
      },
      {
        'account_id': 'ACC-1006',
        'email': '082284@putra.unisza.edu.my',
        'role': 'participant',
        'account_status': 'A',
        'participant_id': 'PRT-1003',
        'participant_code': '082284',
        'participant_name': 'Aniq Danish Ilman bin Mazlan',
      },
      {
        'account_id': 'ACC-1007',
        'email': '081377@putra.unisza.edu.my',
        'role': 'participant',
        'account_status': 'A',
        'participant_id': 'PRT-1004',
        'participant_code': '081377',
        'participant_name': 'Muhammad Adam Adli bin Mohd Nasir',
      },
    ];
    participants = [
      {
        'participant_id': 'PRT-1001',
        'account_id': 'ACC-1004',
        'participant_code': '083370',
        'full_name': 'Muhammad Adam Haris bin Jusoh',
        'faculty': 'Faculty of Informatics and Computing',
        'program': 'Bachelor of Computer Science (Software Development)',
        'academic_year': 3,
        'phone_no': '012-3456789',
      },
      {
        'participant_id': 'PRT-1002',
        'account_id': 'ACC-1005',
        'participant_code': '081999',
        'full_name': 'Ahmad Ilman Wafi bin Mohd Azami',
        'faculty': 'Faculty of Informatics and Computing',
        'program': 'Bachelor of Computer Science (Software Development)',
        'academic_year': 3,
        'phone_no': '013-4567890',
      },
    ];
    organizations = [
      {
        'organization_id': 'ORG-1001',
        'org_name': 'Faculty of Informatics and Computing (FIK)',
        'org_type': 'Faculty',
        'description': 'The premier computing and technology faculty of UniSZA.',
        'contact_email': 'fik@unisza.edu.my',
        'verification_status': 'A',
      },
      {
        'organization_id': 'ORG-1002',
        'org_name': 'Computer Science Society (CSS)',
        'org_type': 'Club',
        'description': 'Official student representative club fostering software and tech innovation.',
        'contact_email': 'css@uniscout.edu.my',
        'verification_status': 'A',
      },
      {
        'organization_id': 'ORG-1005',
        'org_name': 'Kelab Keusahawanan Mahasiswa UniSZA',
        'org_type': 'Society',
        'description': 'Promoting startup incubations, business skills, and networking fairs.',
        'contact_email': 'entrep@unisza.edu.my',
        'verification_status': 'P',
      },
    ];
    organizers = [
      {
        'organizer_id': 'OGN-1001',
        'account_id': 'ACC-1002',
        'organization_id': 'ORG-1002',
        'full_name': 'Ts. Dr. Nurul Hidayah binti Che Mat',
        'position': 'Faculty Advisor / Lead Coordinator',
      },
    ];
    categories = [
      {'category_id': 'CAT-1001', 'category_name': 'Workshop'},
      {'category_id': 'CAT-1002', 'category_name': 'Hackathon'},
      {'category_id': 'CAT-1003', 'category_name': 'Seminar'},
      {'category_id': 'CAT-1004', 'category_name': 'Sports'},
      {'category_id': 'CAT-1005', 'category_name': 'Volunteering'},
      {'category_id': 'CAT-1006', 'category_name': 'Career Fair'},
    ];
    events = [
      {
        'event_id': 'EVT-2026-001',
        'organizer_id': 'OGN-1001',
        'category_id': 'CAT-1001',
        'category_name': 'Workshop',
        'organizer_name': 'Ts. Dr. Nurul Hidayah binti Che Mat',
        'org_name': 'Computer Science Society (CSS)',
        'title': 'Full-Stack Flutter Mobile App Bootcamp',
        'description': 'Build Flutter widgets, explore state management, and connect to MySQL.',
        'event_mode': 'Physical',
        'location': 'Makmal Al-Biruni 3, UniSZA Besut Campus',
        'start_datetime': '2026-11-25 09:00:00',
        'end_datetime': '2026-11-25 17:00:00',
        'reg_deadline': '2026-11-24 23:59:59',
        'capacity': 50,
        'registered_count': 3,
        'eligibility_criteria': 'Open to FIK Students',
        'event_status': 'A',
      },
      {
        'event_id': 'EVT-2026-002',
        'organizer_id': 'OGN-1001',
        'category_id': 'CAT-1002',
        'category_name': 'Hackathon',
        'organizer_name': 'Ts. Dr. Nurul Hidayah binti Che Mat',
        'org_name': 'Computer Science Society (CSS)',
        'title': 'UniSZA Smart Campus Hackathon 2026',
        'description': 'A 36-hour sprint tackling event discovery and sustainability on campus.',
        'event_mode': 'Physical',
        'location': 'Dewan Al-Muktafi Billah Shah',
        'start_datetime': '2026-11-28 08:30:00',
        'end_datetime': '2026-11-29 20:00:00',
        'reg_deadline': '2026-11-27 23:59:59',
        'capacity': 100,
        'registered_count': 2,
        'eligibility_criteria': 'All undergraduate UniSZA students',
        'event_status': 'A',
      },
      {
        'event_id': 'EVT-2026-004',
        'organizer_id': 'OGN-1001',
        'category_id': 'CAT-1006',
        'category_name': 'Career Fair',
        'organizer_name': 'Ts. Dr. Nurul Hidayah binti Che Mat',
        'org_name': 'Computer Science Society (CSS)',
        'title': 'Tech Career & Internship Expo 2026',
        'description': 'Connect directly with fintech firms and software houses hiring for LI.',
        'event_mode': 'Physical',
        'location': 'Student Center Hall, Gong Badak Campus',
        'start_datetime': '2026-12-05 09:00:00',
        'end_datetime': '2026-12-05 16:30:00',
        'reg_deadline': '2026-12-01 23:59:59',
        'capacity': 250,
        'registered_count': 0,
        'eligibility_criteria': 'Final year & Year 3 students',
        'event_status': 'P',
      },
    ];
    registrations = [
      {
        'registration_id': 'REG-2026-0001',
        'participant_id': 'PRT-1001',
        'event_id': 'EVT-2026-001',
        'reg_datetime': '2026-10-15 14:20:00',
        'reg_status': 'R',
        'event_title': 'Full-Stack Flutter Mobile App Bootcamp',
        'start_datetime': '2026-11-25 09:00:00',
        'location': 'Makmal Al-Biruni 3, UniSZA Besut Campus',
        'event_mode': 'Physical',
        'category_name': 'Workshop',
        'participant_name': 'Muhammad Adam Haris bin Jusoh',
        'participant_code': '083370',
      },
    ];
    bookmarks = [
      {
        'bookmark_id': 'BKM-2026-0001',
        'participant_id': 'PRT-1001',
        'event_id': 'EVT-2026-002',
        'saved_datetime': '2026-10-16 10:00:00',
        'event_title': 'UniSZA Smart Campus Hackathon 2026',
        'start_datetime': '2026-11-28 08:30:00',
        'location': 'Dewan Al-Muktafi Billah Shah',
        'event_mode': 'Physical',
        'category_name': 'Hackathon',
      },
    ];
    interests = [
      {
        'interest_id': 'INT-1001',
        'participant_id': 'PRT-1001',
        'category_id': 'CAT-1001',
        'category_name': 'Workshop',
        'interest_tag': 'Flutter',
      },
      {
        'interest_id': 'INT-1002',
        'participant_id': 'PRT-1001',
        'category_id': 'CAT-1002',
        'category_name': 'Hackathon',
        'interest_tag': 'AI & ML',
      },
    ];
    skills = [
      {
        'skill_id': 'SKL-1001',
        'participant_id': 'PRT-1001',
        'skill_name': 'Flutter & Dart',
        'proficiency_level': 'Advanced',
      },
      {
        'skill_id': 'SKL-1002',
        'participant_id': 'PRT-1001',
        'skill_name': 'MySQL Workbench',
        'proficiency_level': 'Advanced',
      },
      {
        'skill_id': 'SKL-1003',
        'participant_id': 'PRT-1001',
        'skill_name': 'Python',
        'proficiency_level': 'Intermediate',
      },
    ];
    notifications = [
      {
        'notification_id': 'NTF-2026-0001',
        'account_id': 'ACC-1004',
        'event_id': 'EVT-2026-001',
        'title': 'Registration Confirmed',
        'message': 'Your seat for Full-Stack Flutter Mobile App Bootcamp is reserved.',
        'notification_type': 'Reminder',
        'is_read': 'Y',
        'sent_datetime': '2026-10-15 14:21:00',
      },
      {
        'notification_id': 'NTF-2026-0002',
        'account_id': 'ACC-1004',
        'event_id': 'EVT-2026-002',
        'title': 'Registration Deadline Notice',
        'message': 'Only 3 days left before registration closes for UniSZA Smart Campus Hackathon.',
        'notification_type': 'Deadline',
        'is_read': 'N',
        'sent_datetime': '2026-10-22 08:00:00',
      },
      {
        'notification_id': 'NTF-2026-0003',
        'account_id': 'ACC-1004',
        'event_id': 'EVT-2026-001',
        'title': 'Recommended Activity For You',
        'message': 'Based on your interest in Flutter, check out the upcoming Mobile App Bootcamp!',
        'notification_type': 'Recommendation',
        'is_read': 'N',
        'sent_datetime': '2026-10-23 10:00:00',
      },
    ];
  }
}

