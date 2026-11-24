import 'package:flutter_test/flutter_test.dart';
import 'package:uniscout_app/main.dart';

void main() {
  testWidgets('UniScout quick-login and role navigation smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniScoutApp(skipNetworkOnInit: true));

    // Auth screen loads with quick demo actor options
    expect(find.text('UniScout'), findsOneWidget);
    expect(find.text('Participant (Adam)'), findsOneWidget);

    // Log in as Participant
    await tester.tap(find.text('Participant (Adam)'));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Passes'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Navigate to Profile tab (Member 1 CRUD)
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Verified Skills (Process 2.4)'), findsOneWidget);
    expect(find.text('Interests (Process 2.3)'), findsOneWidget);

    // Switch role to Admin via role chip menu (Member 4 CRUD)
    await tester.tap(find.text('PARTICIPANT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Role: Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
