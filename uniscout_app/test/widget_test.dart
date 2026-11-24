import 'package:flutter_test/flutter_test.dart';
import 'package:uniscout_app/main.dart';

void main() {
  testWidgets('UniScout quick-login and SDD role navigation smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const UniScoutApp(skipNetworkOnInit: true));

    // Auth screen loads with quick demo actor options
    expect(find.text('UniScout'), findsOneWidget);
    expect(find.text('Participant (Adam)'), findsOneWidget);

    // Log in as Participant (SDD p.66 bottom nav: Explore, Events, Map, Profile)
    await tester.tap(find.text('Participant (Adam)'));
    await tester.pumpAndSettle();

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Navigate to Profile tab (SDD p.17)
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Verified Skills'), findsOneWidget);
    expect(find.text('Interest'), findsOneWidget);

    // Switch role to Admin via role chip menu (SDD p.51, p.73, p.77, p.80 bottom nav: Approvals, Analytics, Management, Profile)
    await tester.tap(find.text('PARTICIPANT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Role: Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Approvals'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Management'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
