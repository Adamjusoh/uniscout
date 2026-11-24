<?php
/**
 * UniScout Local REST API Bridge for MySQL Workbench (uniscout_db)
 * CSD34103 Software Development Workshop - Group Sentry (UniSZA)
 */

declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-DB-Host, X-DB-Port, X-DB-User, X-DB-Password, X-DB-Name');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Default MySQL Workbench connection settings (overridden by app headers or env vars)
const DEFAULT_DB_HOST = '127.0.0.1';
const DEFAULT_DB_PORT = '3306';
const DEFAULT_DB_USER = 'root';
const DEFAULT_DB_PASS = '';
const DEFAULT_DB_NAME = 'uniscout_db';

function respond(array $payload, int $status = 200): void {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function dbConfig(): array {
    $host = $_SERVER['HTTP_X_DB_HOST'] ?? (getenv('DB_HOST') ?: DEFAULT_DB_HOST);
    $port = $_SERVER['HTTP_X_DB_PORT'] ?? (getenv('DB_PORT') ?: DEFAULT_DB_PORT);
    $user = $_SERVER['HTTP_X_DB_USER'] ?? (getenv('DB_USER') ?: DEFAULT_DB_USER);
    $pass = $_SERVER['HTTP_X_DB_PASSWORD'] ?? (getenv('DB_PASS') !== false ? getenv('DB_PASS') : DEFAULT_DB_PASS);
    $name = $_SERVER['HTTP_X_DB_NAME'] ?? (getenv('DB_NAME') ?: DEFAULT_DB_NAME);
    return [
        'host' => trim((string)$host) ?: DEFAULT_DB_HOST,
        'port' => trim((string)$port) ?: DEFAULT_DB_PORT,
        'user' => trim((string)$user) ?: DEFAULT_DB_USER,
        'pass' => (string)$pass,
        'name' => trim((string)$name) ?: DEFAULT_DB_NAME,
    ];
}

function connectPdo(bool $withDatabase = true): PDO {
    $cfg = dbConfig();
    $dsn = "mysql:host={$cfg['host']};port={$cfg['port']};charset=utf8mb4";
    if ($withDatabase) {
        $dsn .= ";dbname={$cfg['name']}";
    }
    return new PDO($dsn, $cfg['user'], $cfg['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => true,
    ]);
}

function runSqlFile(PDO $pdo, string $filePath): int {
    if (!is_file($filePath)) {
        throw new RuntimeException("SQL file not found: {$filePath}");
    }
    $lines = file($filePath, FILE_IGNORE_NEW_LINES);
    $cleanLines = [];
    foreach ($lines as $line) {
        $trimmed = ltrim($line);
        if (str_starts_with($trimmed, '--') || $trimmed === '') {
            continue;
        }
        $cleanLines[] = $line;
    }
    $statements = explode(';', implode("\n", $cleanLines));
    $count = 0;
    foreach ($statements as $stmt) {
        $sql = trim($stmt);
        if ($sql === '') {
            continue;
        }
        $pdo->exec($sql);
        $count++;
    }
    return $count;
}

function nextPrefixedId(PDO $pdo, string $table, string $column, string $prefix, int $padWidth, int $minStart = 1): string {
    $stmt = $pdo->prepare("SELECT {$column} FROM {$table} WHERE {$column} LIKE ?");
    $stmt->execute([$prefix . '%']);
    $maxNum = $minStart - 1;
    $prefixLen = strlen($prefix);
    foreach ($stmt->fetchAll(PDO::FETCH_COLUMN) as $val) {
        $suffix = substr((string)$val, $prefixLen);
        if (ctype_digit($suffix)) {
            $num = (int)$suffix;
            if ($num > $maxNum) {
                $maxNum = $num;
            }
        }
    }
    $next = $maxNum + 1;
    return $prefix . str_pad((string)$next, $padWidth, '0', STR_PAD_LEFT);
}

function readJsonInput(): array {
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : $_POST;
}

function bootstrapPayload(PDO $pdo): array {
    $accounts = $pdo->query("
        SELECT a.account_id, a.email, a.role, a.account_status, a.created_at,
               p.participant_id, p.participant_code, p.full_name AS participant_name,
               p.faculty, p.program, p.academic_year, p.phone_no AS participant_phone,
               o.organizer_id, o.organization_id, o.full_name AS organizer_name,
               o.position, o.phone_no AS organizer_phone
        FROM ACCOUNT a
        LEFT JOIN PARTICIPANT p ON p.account_id = a.account_id
        LEFT JOIN ORGANIZER o ON o.account_id = a.account_id
        ORDER BY a.account_id ASC
    ")->fetchAll();

    $participants = $pdo->query("SELECT * FROM PARTICIPANT ORDER BY participant_id ASC")->fetchAll();
    $organizations = $pdo->query("SELECT * FROM ORGANIZATION ORDER BY organization_id ASC")->fetchAll();
    $organizers = $pdo->query("
        SELECT o.*, org.org_name, org.verification_status
        FROM ORGANIZER o
        JOIN ORGANIZATION org ON org.organization_id = o.organization_id
        ORDER BY o.organizer_id ASC
    ")->fetchAll();
    $categories = $pdo->query("SELECT * FROM CATEGORY ORDER BY category_id ASC")->fetchAll();
    $events = $pdo->query("
        SELECT e.*,
               c.category_name,
               og.full_name AS organizer_name,
               org.org_name,
               COALESCE((SELECT COUNT(*) FROM REGISTRATION r WHERE r.event_id = e.event_id AND r.reg_status IN ('R', 'A')), 0) AS registered_count
        FROM EVENT e
        JOIN CATEGORY c ON c.category_id = e.category_id
        JOIN ORGANIZER og ON og.organizer_id = e.organizer_id
        JOIN ORGANIZATION org ON org.organization_id = og.organization_id
        ORDER BY e.start_datetime ASC, e.event_id ASC
    ")->fetchAll();

    $registrations = $pdo->query("
        SELECT r.*, e.title AS event_title, e.start_datetime, e.location, e.event_mode,
               c.category_name, p.full_name AS participant_name, p.participant_code
        FROM REGISTRATION r
        JOIN EVENT e ON e.event_id = r.event_id
        JOIN CATEGORY c ON c.category_id = e.category_id
        JOIN PARTICIPANT p ON p.participant_id = r.participant_id
        ORDER BY r.reg_datetime DESC
    ")->fetchAll();

    $bookmarks = $pdo->query("
        SELECT b.*, e.title AS event_title, e.start_datetime, e.location, e.event_mode, c.category_name
        FROM BOOKMARK b
        JOIN EVENT e ON e.event_id = b.event_id
        JOIN CATEGORY c ON c.category_id = e.category_id
        ORDER BY b.saved_datetime DESC
    ")->fetchAll();

    $interests = $pdo->query("
        SELECT i.*, c.category_name
        FROM INTEREST i
        JOIN CATEGORY c ON c.category_id = i.category_id
        ORDER BY i.interest_id ASC
    ")->fetchAll();

    $skills = $pdo->query("SELECT * FROM SKILL ORDER BY skill_id ASC")->fetchAll();
    $notifications = $pdo->query("SELECT * FROM NOTIFICATION ORDER BY sent_datetime DESC, notification_id DESC")->fetchAll();

    return [
        'ok' => true,
        'connected' => true,
        'database' => dbConfig()['name'],
        'accounts' => $accounts,
        'participants' => $participants,
        'organizations' => $organizations,
        'organizers' => $organizers,
        'categories' => $categories,
        'events' => $events,
        'registrations' => $registrations,
        'bookmarks' => $bookmarks,
        'interests' => $interests,
        'skills' => $skills,
        'notifications' => $notifications,
    ];
}

function requireFields(array $in, array $fields): void {
    foreach ($fields as $f) {
        if (!isset($in[$f]) || trim((string)$in[$f]) === '') {
            respond(['ok' => false, 'message' => "Missing required field: {$f}"], 400);
        }
    }
}

$action = $_GET['action'] ?? ($_POST['action'] ?? 'bootstrap');
$in = readJsonInput();
if (isset($in['action']) && !isset($_GET['action'])) {
    $action = (string)$in['action'];
}

try {
    if ($action === 'init_db') {
        $pdo = connectPdo(false);
        $baseDir = __DIR__;
        $schemaCount = runSqlFile($pdo, $baseDir . '/uniscout_schema.sql');
        $seedCount = runSqlFile($pdo, $baseDir . '/uniscout_seed.sql');
        $pdoDb = connectPdo(true);
        $payload = bootstrapPayload($pdoDb);
        $payload['message'] = "Initialized uniscout_db ({$schemaCount} DDL + {$seedCount} seed statements executed).";
        $payload['sql'] = 'SOURCE uniscout_schema.sql; SOURCE uniscout_seed.sql;';
        $payload['sdd_ref'] = 'Chapter 4: 11 Tables Initialized';
        respond($payload);
    }

    $pdo = connectPdo(true);

    switch ($action) {
        case 'bootstrap': {
            $payload = bootstrapPayload($pdo);
            $payload['message'] = 'Connected to MySQL Workbench (uniscout_db)';
            $payload['sql'] = 'SELECT * FROM ACCOUNT, PARTICIPANT, ORGANIZATION, ORGANIZER, CATEGORY, EVENT, REGISTRATION, BOOKMARK, INTEREST, SKILL, NOTIFICATION;';
            $payload['sdd_ref'] = 'Chapter 4: Data Dictionary (All 11 Tables)';
            respond($payload);
        }

        // -----------------------------------------------------------------
        // PROCESS 1.0: Registration & Login (ACCOUNT + PARTICIPANT)
        // -----------------------------------------------------------------
        case 'login': {
            requireFields($in, ['email']);
            $email = trim((string)$in['email']);
            $stmt = $pdo->prepare("
                SELECT a.account_id, a.email, a.role, a.account_status,
                       p.participant_id, p.participant_code, p.full_name AS participant_name,
                       o.organizer_id, o.full_name AS organizer_name
                FROM ACCOUNT a
                LEFT JOIN PARTICIPANT p ON p.account_id = a.account_id
                LEFT JOIN ORGANIZER o ON o.account_id = a.account_id
                WHERE LOWER(a.email) = LOWER(?)
                LIMIT 1
            ");
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            if (!$user) {
                respond(['ok' => false, 'message' => "Account not found for {$email}"], 404);
            }
            if ($user['account_status'] === 'S') {
                respond(['ok' => false, 'message' => 'This account is currently suspended (account_status = S).'], 403);
            }
            respond([
                'ok' => true,
                'user' => $user,
                'message' => "Signed in as {$user['email']} ({$user['role']})",
                'sql' => "SELECT * FROM ACCOUNT WHERE email = '{$email}';",
                'sdd_ref' => 'Process 1.0 (SDD p.11) · Table 4.2.1 ACCOUNT',
            ]);
        }

        case 'register_account': {
            requireFields($in, ['email', 'password', 'full_name', 'participant_code']);
            $email = trim((string)$in['email']);
            $password = (string)$in['password'];
            $role = in_array($in['role'] ?? 'participant', ['participant', 'organizer', 'admin'], true)
                ? (string)$in['role']
                : 'participant';
            $fullName = trim((string)$in['full_name']);
            $code = trim((string)$in['participant_code']);
            $faculty = trim((string)($in['faculty'] ?? 'Faculty of Informatics and Computing'));
            $program = trim((string)($in['program'] ?? 'Bachelor of Computer Science (Software Development)'));
            $year = max(1, min(6, (int)($in['academic_year'] ?? 3)));
            $phone = trim((string)($in['phone_no'] ?? '012-0000000'));

            $accId = nextPrefixedId($pdo, 'ACCOUNT', 'account_id', 'ACC-', 4, 1001);
            $hash = password_hash($password, PASSWORD_BCRYPT);

            $pdo->beginTransaction();
            $stmtAcc = $pdo->prepare("INSERT INTO ACCOUNT (account_id, email, password_hash, role, account_status) VALUES (?, ?, ?, ?, 'A')");
            $stmtAcc->execute([$accId, $email, $hash, $role]);

            $prtId = null;
            if ($role === 'participant') {
                $prtId = nextPrefixedId($pdo, 'PARTICIPANT', 'participant_id', 'PRT-', 4, 1001);
                $stmtPrt = $pdo->prepare("
                    INSERT INTO PARTICIPANT (participant_id, account_id, participant_code, full_name, faculty, program, academic_year, phone_no)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ");
                $stmtPrt->execute([$prtId, $accId, $code, $fullName, $faculty, $program, $year, $phone]);
            }
            $pdo->commit();

            respond([
                'ok' => true,
                'account_id' => $accId,
                'participant_id' => $prtId,
                'message' => "Registered {$email} ({$accId})",
                'sql' => "INSERT INTO ACCOUNT VALUES ('{$accId}','{$email}',...,'{$role}','A'); INSERT INTO PARTICIPANT VALUES ('{$prtId}','{$accId}','{$code}','{$fullName}',...);",
                'sdd_ref' => 'Process 1.0 (SDD p.11) · Tables ACCOUNT & PARTICIPANT',
            ]);
        }

        // -----------------------------------------------------------------
        // PROCESS 2.0: Profile, Interests & Skills (Member 1 CRUD)
        // -----------------------------------------------------------------
        case 'update_profile': {
            requireFields($in, ['participant_id', 'full_name', 'participant_code']);
            $stmt = $pdo->prepare("
                UPDATE PARTICIPANT
                SET full_name = ?, participant_code = ?, faculty = ?, program = ?, academic_year = ?, phone_no = ?
                WHERE participant_id = ?
            ");
            $stmt->execute([
                trim((string)$in['full_name']),
                trim((string)$in['participant_code']),
                trim((string)($in['faculty'] ?? '')),
                trim((string)($in['program'] ?? '')),
                max(1, min(6, (int)($in['academic_year'] ?? 1))),
                trim((string)($in['phone_no'] ?? '')),
                $in['participant_id'],
            ]);
            respond([
                'ok' => true,
                'message' => "Updated profile {$in['participant_id']}",
                'sql' => "UPDATE PARTICIPANT SET full_name='{$in['full_name']}', ... WHERE participant_id='{$in['participant_id']}';",
                'sdd_ref' => 'Process 2.2 (SDD p.18) · Table 4.2.2 PARTICIPANT',
            ]);
        }

        case 'add_interest': {
            requireFields($in, ['participant_id', 'category_id', 'interest_tag']);
            $intId = nextPrefixedId($pdo, 'INTEREST', 'interest_id', 'INT-', 4, 1001);
            $stmt = $pdo->prepare("INSERT INTO INTEREST (interest_id, participant_id, category_id, interest_tag) VALUES (?, ?, ?, ?)");
            $stmt->execute([$intId, $in['participant_id'], $in['category_id'], trim((string)$in['interest_tag'])]);
            respond([
                'ok' => true,
                'interest_id' => $intId,
                'message' => "Added interest '{$in['interest_tag']}' ({$intId})",
                'sql' => "INSERT INTO INTEREST (interest_id, participant_id, category_id, interest_tag) VALUES ('{$intId}', '{$in['participant_id']}', '{$in['category_id']}', '{$in['interest_tag']}');",
                'sdd_ref' => 'Process 2.3 (SDD p.22) · Table 4.2.9 INTEREST (Composite PK)',
            ]);
        }

        case 'delete_interest': {
            requireFields($in, ['participant_id', 'category_id', 'interest_tag']);
            $stmt = $pdo->prepare("DELETE FROM INTEREST WHERE participant_id = ? AND category_id = ? AND interest_tag = ?");
            $stmt->execute([$in['participant_id'], $in['category_id'], $in['interest_tag']]);
            respond([
                'ok' => true,
                'message' => "Deleted interest '{$in['interest_tag']}'",
                'sql' => "DELETE FROM INTEREST WHERE participant_id='{$in['participant_id']}' AND category_id='{$in['category_id']}' AND interest_tag='{$in['interest_tag']}';",
                'sdd_ref' => 'Process 2.3 (SDD p.22) · Table 4.2.9 INTEREST (Composite PK)',
            ]);
        }

        case 'add_skill': {
            requireFields($in, ['participant_id', 'skill_name', 'proficiency_level']);
            $sklId = nextPrefixedId($pdo, 'SKILL', 'skill_id', 'SKL-', 4, 1001);
            $stmt = $pdo->prepare("INSERT INTO SKILL (skill_id, participant_id, skill_name, proficiency_level) VALUES (?, ?, ?, ?)");
            $stmt->execute([$sklId, $in['participant_id'], trim((string)$in['skill_name']), $in['proficiency_level']]);
            respond([
                'ok' => true,
                'skill_id' => $sklId,
                'message' => "Added skill '{$in['skill_name']}' ({$sklId})",
                'sql' => "INSERT INTO SKILL (skill_id, participant_id, skill_name, proficiency_level) VALUES ('{$sklId}', '{$in['participant_id']}', '{$in['skill_name']}', '{$in['proficiency_level']}');",
                'sdd_ref' => 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
            ]);
        }

        case 'update_skill': {
            requireFields($in, ['participant_id', 'skill_name', 'proficiency_level']);
            $stmt = $pdo->prepare("UPDATE SKILL SET proficiency_level = ? WHERE participant_id = ? AND skill_name = ?");
            $stmt->execute([$in['proficiency_level'], $in['participant_id'], $in['skill_name']]);
            respond([
                'ok' => true,
                'message' => "Updated '{$in['skill_name']}' to {$in['proficiency_level']}",
                'sql' => "UPDATE SKILL SET proficiency_level='{$in['proficiency_level']}' WHERE participant_id='{$in['participant_id']}' AND skill_name='{$in['skill_name']}';",
                'sdd_ref' => 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
            ]);
        }

        case 'delete_skill': {
            requireFields($in, ['participant_id', 'skill_name']);
            $stmt = $pdo->prepare("DELETE FROM SKILL WHERE participant_id = ? AND skill_name = ?");
            $stmt->execute([$in['participant_id'], $in['skill_name']]);
            respond([
                'ok' => true,
                'message' => "Deleted skill '{$in['skill_name']}'",
                'sql' => "DELETE FROM SKILL WHERE participant_id='{$in['participant_id']}' AND skill_name='{$in['skill_name']}';",
                'sdd_ref' => 'Process 2.4 (SDD p.25) · Table 4.2.10 SKILL (Composite PK)',
            ]);
        }

        // -----------------------------------------------------------------
        // PROCESS 3.0: Manage Events (Member 2 CRUD)
        // -----------------------------------------------------------------
        case 'create_event': {
            requireFields($in, ['organizer_id', 'category_id', 'title', 'description', 'location', 'start_datetime', 'end_datetime', 'reg_deadline']);
            $evtId = nextPrefixedId($pdo, 'EVENT', 'event_id', 'EVT-2026-', 3, 1);
            $status = in_array($in['event_status'] ?? 'P', ['D', 'P', 'A'], true) ? (string)$in['event_status'] : 'P';
            $mode = in_array($in['event_mode'] ?? 'Physical', ['Physical', 'Online', 'Hybrid'], true) ? (string)$in['event_mode'] : 'Physical';
            $capacity = max(1, (int)($in['capacity'] ?? 50));

            $stmt = $pdo->prepare("
                INSERT INTO EVENT (event_id, organizer_id, category_id, title, description, event_mode, location, start_datetime, end_datetime, reg_deadline, capacity, eligibility_criteria, event_status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $evtId,
                $in['organizer_id'],
                $in['category_id'],
                trim((string)$in['title']),
                trim((string)$in['description']),
                $mode,
                trim((string)$in['location']),
                $in['start_datetime'],
                $in['end_datetime'],
                $in['reg_deadline'],
                $capacity,
                trim((string)($in['eligibility_criteria'] ?? 'Open to all UniSZA students')),
                $status,
            ]);
            respond([
                'ok' => true,
                'event_id' => $evtId,
                'message' => "Created event {$evtId} ({$in['title']})",
                'sql' => "INSERT INTO EVENT (event_id, organizer_id, category_id, title, ..., start_datetime, event_status) VALUES ('{$evtId}', '{$in['organizer_id']}', '{$in['category_id']}', '{$in['title']}', ..., '{$status}');",
                'sdd_ref' => 'Process 3.1 (SDD p.29) · Table 4.2.6 EVENT (Composite PK)',
            ]);
        }

        case 'update_event': {
            requireFields($in, ['event_id', 'category_id', 'title', 'description', 'location', 'start_datetime', 'end_datetime', 'reg_deadline']);
            $status = in_array($in['event_status'] ?? 'P', ['D', 'P', 'A', 'R', 'X', 'C'], true) ? (string)$in['event_status'] : 'P';
            $mode = in_array($in['event_mode'] ?? 'Physical', ['Physical', 'Online', 'Hybrid'], true) ? (string)$in['event_mode'] : 'Physical';
            $stmt = $pdo->prepare("
                UPDATE EVENT
                SET category_id = ?, title = ?, description = ?, event_mode = ?, location = ?,
                    start_datetime = ?, end_datetime = ?, reg_deadline = ?, capacity = ?,
                    eligibility_criteria = ?, event_status = ?
                WHERE event_id = ?
            ");
            $stmt->execute([
                $in['category_id'],
                trim((string)$in['title']),
                trim((string)$in['description']),
                $mode,
                trim((string)$in['location']),
                $in['start_datetime'],
                $in['end_datetime'],
                $in['reg_deadline'],
                max(0, (int)($in['capacity'] ?? 50)),
                trim((string)($in['eligibility_criteria'] ?? '')),
                $status,
                $in['event_id'],
            ]);
            respond([
                'ok' => true,
                'message' => "Updated event {$in['event_id']}",
                'sql' => "UPDATE EVENT SET title='{$in['title']}', category_id='{$in['category_id']}', event_status='{$status}' WHERE event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 3.2 (SDD p.33) · Table 4.2.6 EVENT',
            ]);
        }

        case 'cancel_event': {
            requireFields($in, ['event_id']);
            $reason = trim((string)($in['review_remarks'] ?? 'Cancelled by organizer'));
            $stmt = $pdo->prepare("UPDATE EVENT SET event_status = 'X', review_remarks = ? WHERE event_id = ?");
            $stmt->execute([$reason, $in['event_id']]);
            respond([
                'ok' => true,
                'message' => "Cancelled event {$in['event_id']} (status = X)",
                'sql' => "UPDATE EVENT SET event_status='X', review_remarks='{$reason}' WHERE event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 3.3 (SDD p.37) · Table 4.2.6 EVENT (Soft-Delete)',
            ]);
        }

        case 'delete_event': {
            requireFields($in, ['event_id']);
            $stmt = $pdo->prepare("DELETE FROM EVENT WHERE event_id = ?");
            $stmt->execute([$in['event_id']]);
            respond([
                'ok' => true,
                'message' => "Deleted event {$in['event_id']} from database",
                'sql' => "DELETE FROM EVENT WHERE event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 3.3 (SDD p.37) · Table 4.2.6 EVENT (Hard Delete)',
            ]);
        }

        // -----------------------------------------------------------------
        // PROCESS 4.0, 6.0, 7.0: Registration, Bookmarks, Notifications (Member 3 CRUD)
        // -----------------------------------------------------------------
        case 'register_event': {
            requireFields($in, ['participant_id', 'event_id']);
            $pid = $in['participant_id'];
            $eid = $in['event_id'];

            $chk = $pdo->prepare("SELECT registration_id, reg_status FROM REGISTRATION WHERE participant_id = ? AND event_id = ?");
            $chk->execute([$pid, $eid]);
            $existing = $chk->fetch();

            $pdo->beginTransaction();
            if ($existing) {
                if ($existing['reg_status'] === 'R' || $existing['reg_status'] === 'A') {
                    $pdo->rollBack();
                    respond(['ok' => false, 'message' => 'Participant is already registered for this event.'], 409);
                }
                $regId = $existing['registration_id'];
                $upd = $pdo->prepare("UPDATE REGISTRATION SET reg_status = 'R', reg_datetime = CURRENT_TIMESTAMP WHERE participant_id = ? AND event_id = ?");
                $upd->execute([$pid, $eid]);
                $sqlText = "UPDATE REGISTRATION SET reg_status='R', reg_datetime=NOW() WHERE participant_id='{$pid}' AND event_id='{$eid}';";
            } else {
                $regId = nextPrefixedId($pdo, 'REGISTRATION', 'registration_id', 'REG-2026-', 4, 1);
                $ins = $pdo->prepare("INSERT INTO REGISTRATION (registration_id, participant_id, event_id, reg_status) VALUES (?, ?, ?, 'R')");
                $ins->execute([$regId, $pid, $eid]);
                $sqlText = "INSERT INTO REGISTRATION (registration_id, participant_id, event_id, reg_status) VALUES ('{$regId}', '{$pid}', '{$eid}', 'R');";
            }

            // Send notification to participant's account
            $accStmt = $pdo->prepare("SELECT account_id FROM PARTICIPANT WHERE participant_id = ?");
            $accStmt->execute([$pid]);
            $accId = $accStmt->fetchColumn();
            if ($accId) {
                $ntfId = nextPrefixedId($pdo, 'NOTIFICATION', 'notification_id', 'NTF-2026-', 4, 1);
                $ntfStmt = $pdo->prepare("
                    INSERT INTO NOTIFICATION (notification_id, account_id, event_id, title, message, notification_type, is_read)
                    VALUES (?, ?, ?, 'Registration Confirmed', ?, 'Reminder', 'N')
                ");
                $ntfStmt->execute([$ntfId, $accId, $eid, "Your ticket {$regId} for {$eid} is confirmed."]);
            }
            $pdo->commit();

            respond([
                'ok' => true,
                'registration_id' => $regId,
                'message' => "Registered ({$regId}) and notification sent",
                'sql' => $sqlText,
                'sdd_ref' => 'Process 4.1 (SDD p.40) · Tables REGISTRATION & NOTIFICATION',
            ]);
        }

        case 'cancel_registration': {
            requireFields($in, ['participant_id', 'event_id']);
            $stmt = $pdo->prepare("UPDATE REGISTRATION SET reg_status = 'C' WHERE participant_id = ? AND event_id = ?");
            $stmt->execute([$in['participant_id'], $in['event_id']]);
            respond([
                'ok' => true,
                'message' => "Cancelled registration for {$in['event_id']}",
                'sql' => "UPDATE REGISTRATION SET reg_status='C' WHERE participant_id='{$in['participant_id']}' AND event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 4.2 (SDD p.43) · Table 4.2.7 REGISTRATION (Composite PK)',
            ]);
        }

        case 'delete_registration': {
            requireFields($in, ['participant_id', 'event_id']);
            $stmt = $pdo->prepare("DELETE FROM REGISTRATION WHERE participant_id = ? AND event_id = ?");
            $stmt->execute([$in['participant_id'], $in['event_id']]);
            respond([
                'ok' => true,
                'message' => "Removed registration record for {$in['event_id']}",
                'sql' => "DELETE FROM REGISTRATION WHERE participant_id='{$in['participant_id']}' AND event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 4.2 (SDD p.43) · Table 4.2.7 REGISTRATION (Hard Delete)',
            ]);
        }

        case 'add_bookmark': {
            requireFields($in, ['participant_id', 'event_id']);
            $bkmId = nextPrefixedId($pdo, 'BOOKMARK', 'bookmark_id', 'BKM-2026-', 4, 1);
            $stmt = $pdo->prepare("INSERT INTO BOOKMARK (bookmark_id, participant_id, event_id) VALUES (?, ?, ?)");
            $stmt->execute([$bkmId, $in['participant_id'], $in['event_id']]);
            respond([
                'ok' => true,
                'bookmark_id' => $bkmId,
                'message' => "Saved bookmark {$bkmId}",
                'sql' => "INSERT INTO BOOKMARK (bookmark_id, participant_id, event_id) VALUES ('{$bkmId}', '{$in['participant_id']}', '{$in['event_id']}');",
                'sdd_ref' => 'Process 6.1 (SDD p.58) · Table 4.2.8 BOOKMARK (Composite PK)',
            ]);
        }

        case 'delete_bookmark': {
            requireFields($in, ['participant_id', 'event_id']);
            $stmt = $pdo->prepare("DELETE FROM BOOKMARK WHERE participant_id = ? AND event_id = ?");
            $stmt->execute([$in['participant_id'], $in['event_id']]);
            respond([
                'ok' => true,
                'message' => "Removed bookmark for {$in['event_id']}",
                'sql' => "DELETE FROM BOOKMARK WHERE participant_id='{$in['participant_id']}' AND event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 6.2 (SDD p.61) · Table 4.2.8 BOOKMARK (Composite PK)',
            ]);
        }

        case 'mark_notification_read': {
            requireFields($in, ['notification_id']);
            $isRead = ($in['is_read'] ?? 'Y') === 'N' ? 'N' : 'Y';
            $stmt = $pdo->prepare("UPDATE NOTIFICATION SET is_read = ? WHERE notification_id = ?");
            $stmt->execute([$isRead, $in['notification_id']]);
            respond([
                'ok' => true,
                'message' => "Marked {$in['notification_id']} as read={$isRead}",
                'sql' => "UPDATE NOTIFICATION SET is_read='{$isRead}' WHERE notification_id='{$in['notification_id']}';",
                'sdd_ref' => 'Process 7.0 (SDD p.67) · Table 4.2.11 NOTIFICATION',
            ]);
        }

        case 'delete_notification': {
            requireFields($in, ['notification_id']);
            $stmt = $pdo->prepare("DELETE FROM NOTIFICATION WHERE notification_id = ?");
            $stmt->execute([$in['notification_id']]);
            respond([
                'ok' => true,
                'message' => "Deleted notification {$in['notification_id']}",
                'sql' => "DELETE FROM NOTIFICATION WHERE notification_id='{$in['notification_id']}';",
                'sdd_ref' => 'Process 7.0 (SDD p.67) · Table 4.2.11 NOTIFICATION',
            ]);
        }

        // -----------------------------------------------------------------
        // PROCESS 5.0 & 8.0: Approvals, Users, Organizations (Member 4 CRUD)
        // -----------------------------------------------------------------
        case 'review_event': {
            requireFields($in, ['event_id', 'event_status']);
            $status = in_array($in['event_status'], ['A', 'R', 'P'], true) ? (string)$in['event_status'] : 'A';
            $remarks = trim((string)($in['review_remarks'] ?? ($status === 'A' ? 'Approved by Admin' : 'Rejected by Admin')));

            $pdo->beginTransaction();
            $stmt = $pdo->prepare("UPDATE EVENT SET event_status = ?, review_remarks = ? WHERE event_id = ?");
            $stmt->execute([$status, $remarks, $in['event_id']]);

            $orgStmt = $pdo->prepare("SELECT og.account_id, e.title FROM EVENT e JOIN ORGANIZER og ON og.organizer_id = e.organizer_id WHERE e.event_id = ?");
            $orgStmt->execute([$in['event_id']]);
            $row = $orgStmt->fetch();
            if ($row) {
                $ntfId = nextPrefixedId($pdo, 'NOTIFICATION', 'notification_id', 'NTF-2026-', 4, 1);
                $label = $status === 'A' ? 'Event Approved & Published' : 'Event Submission Rejected';
                $ntf = $pdo->prepare("INSERT INTO NOTIFICATION (notification_id, account_id, event_id, title, message, notification_type, is_read) VALUES (?, ?, ?, ?, ?, 'Reminder', 'N')");
                $ntf->execute([$ntfId, $row['account_id'], $in['event_id'], $label, "{$row['title']}: {$remarks}"]);
            }
            $pdo->commit();

            respond([
                'ok' => true,
                'message' => "Event {$in['event_id']} updated to status '{$status}'",
                'sql' => "UPDATE EVENT SET event_status='{$status}', review_remarks='{$remarks}' WHERE event_id='{$in['event_id']}';",
                'sdd_ref' => 'Process 5.2 / 5.3 (SDD p.52-55) · Table 4.2.6 EVENT',
            ]);
        }

        case 'create_user': {
            requireFields($in, ['email', 'full_name', 'role']);
            $role = in_array($in['role'], ['participant', 'organizer', 'admin'], true) ? (string)$in['role'] : 'participant';
            $accId = nextPrefixedId($pdo, 'ACCOUNT', 'account_id', 'ACC-', 4, 1001);
            $hash = password_hash((string)($in['password'] ?? 'Password@123'), PASSWORD_BCRYPT);

            $pdo->beginTransaction();
            $stmt = $pdo->prepare("INSERT INTO ACCOUNT (account_id, email, password_hash, role, account_status) VALUES (?, ?, ?, ?, 'A')");
            $stmt->execute([$accId, trim((string)$in['email']), $hash, $role]);

            if ($role === 'participant') {
                $prtId = nextPrefixedId($pdo, 'PARTICIPANT', 'participant_id', 'PRT-', 4, 1001);
                $code = trim((string)($in['participant_code'] ?? substr((string)time(), -6)));
                $pStmt = $pdo->prepare("INSERT INTO PARTICIPANT (participant_id, account_id, participant_code, full_name, faculty, program, academic_year) VALUES (?, ?, ?, ?, 'Faculty of Informatics and Computing', 'Bachelor of Computer Science', 3)");
                $pStmt->execute([$prtId, $accId, $code, trim((string)$in['full_name'])]);
            } elseif ($role === 'organizer') {
                $ognId = nextPrefixedId($pdo, 'ORGANIZER', 'organizer_id', 'OGN-', 4, 1001);
                $orgId = trim((string)($in['organization_id'] ?? 'ORG-1002'));
                $oStmt = $pdo->prepare("INSERT INTO ORGANIZER (organizer_id, account_id, organization_id, full_name, position) VALUES (?, ?, ?, ?, 'Club Representative')");
                $oStmt->execute([$ognId, $accId, $orgId, trim((string)$in['full_name'])]);
            }
            $pdo->commit();

            respond([
                'ok' => true,
                'account_id' => $accId,
                'message' => "Created user {$in['email']} ({$accId})",
                'sql' => "INSERT INTO ACCOUNT (account_id, email, role, account_status) VALUES ('{$accId}', '{$in['email']}', '{$role}', 'A');",
                'sdd_ref' => 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
            ]);
        }

        case 'update_user': {
            requireFields($in, ['account_id', 'role', 'account_status']);
            $role = in_array($in['role'], ['participant', 'organizer', 'admin'], true) ? (string)$in['role'] : 'participant';
            $status = in_array($in['account_status'], ['A', 'S', 'I'], true) ? (string)$in['account_status'] : 'A';
            $stmt = $pdo->prepare("UPDATE ACCOUNT SET role = ?, account_status = ? WHERE account_id = ?");
            $stmt->execute([$role, $status, $in['account_id']]);
            respond([
                'ok' => true,
                'message' => "Updated {$in['account_id']} (role={$role}, status={$status})",
                'sql' => "UPDATE ACCOUNT SET role='{$role}', account_status='{$status}' WHERE account_id='{$in['account_id']}';",
                'sdd_ref' => 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
            ]);
        }

        case 'delete_user': {
            requireFields($in, ['account_id']);
            $stmt = $pdo->prepare("DELETE FROM ACCOUNT WHERE account_id = ?");
            $stmt->execute([$in['account_id']]);
            respond([
                'ok' => true,
                'message' => "Deleted user account {$in['account_id']}",
                'sql' => "DELETE FROM ACCOUNT WHERE account_id='{$in['account_id']}';",
                'sdd_ref' => 'Process 8.1 (SDD p.70) · Table 4.2.1 ACCOUNT',
            ]);
        }

        case 'create_organization': {
            requireFields($in, ['org_name', 'org_type', 'contact_email']);
            $orgId = nextPrefixedId($pdo, 'ORGANIZATION', 'organization_id', 'ORG-', 4, 1001);
            $orgType = in_array($in['org_type'], ['Faculty', 'Club', 'Department', 'Society'], true) ? (string)$in['org_type'] : 'Club';
            $status = in_array($in['verification_status'] ?? 'P', ['P', 'A', 'S', 'R'], true) ? (string)$in['verification_status'] : 'P';
            $stmt = $pdo->prepare("INSERT INTO ORGANIZATION (organization_id, org_name, org_type, description, contact_email, verification_status) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $orgId,
                trim((string)$in['org_name']),
                $orgType,
                trim((string)($in['description'] ?? '')),
                trim((string)$in['contact_email']),
                $status,
            ]);
            respond([
                'ok' => true,
                'organization_id' => $orgId,
                'message' => "Added organization {$in['org_name']} ({$orgId})",
                'sql' => "INSERT INTO ORGANIZATION VALUES ('{$orgId}', '{$in['org_name']}', '{$orgType}', ..., '{$status}');",
                'sdd_ref' => 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
            ]);
        }

        case 'update_organization': {
            requireFields($in, ['organization_id', 'org_name', 'org_type', 'contact_email', 'verification_status']);
            $orgType = in_array($in['org_type'], ['Faculty', 'Club', 'Department', 'Society'], true) ? (string)$in['org_type'] : 'Club';
            $status = in_array($in['verification_status'], ['P', 'A', 'S', 'R'], true) ? (string)$in['verification_status'] : 'P';
            $stmt = $pdo->prepare("
                UPDATE ORGANIZATION
                SET org_name = ?, org_type = ?, description = ?, contact_email = ?, verification_status = ?
                WHERE organization_id = ?
            ");
            $stmt->execute([
                trim((string)$in['org_name']),
                $orgType,
                trim((string)($in['description'] ?? '')),
                trim((string)$in['contact_email']),
                $status,
                $in['organization_id'],
            ]);
            respond([
                'ok' => true,
                'message' => "Updated {$in['organization_id']} (status={$status})",
                'sql' => "UPDATE ORGANIZATION SET org_name='{$in['org_name']}', verification_status='{$status}' WHERE organization_id='{$in['organization_id']}';",
                'sdd_ref' => 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
            ]);
        }

        case 'delete_organization': {
            requireFields($in, ['organization_id']);
            $stmt = $pdo->prepare("DELETE FROM ORGANIZATION WHERE organization_id = ?");
            $stmt->execute([$in['organization_id']]);
            respond([
                'ok' => true,
                'message' => "Deleted organization {$in['organization_id']}",
                'sql' => "DELETE FROM ORGANIZATION WHERE organization_id='{$in['organization_id']}';",
                'sdd_ref' => 'Process 8.2 (SDD p.74) · Table 4.2.3 ORGANIZATION',
            ]);
        }

        default:
            respond(['ok' => false, 'message' => "Unknown action: {$action}"], 400);
    }
} catch (PDOException $e) {
    $msg = $e->getMessage();
    if ($e->getCode() === '23000') {
        $msg = 'Database constraint violation (duplicate key or record is referenced by child rows): ' . $e->getMessage();
    }
    respond(['ok' => false, 'message' => $msg, 'code' => $e->getCode()], 500);
} catch (Throwable $e) {
    respond(['ok' => false, 'message' => $e->getMessage()], 500);
}

