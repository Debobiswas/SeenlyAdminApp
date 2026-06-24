import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seenly_admin_app/src/features/auth/presentation/login_screen.dart';
import 'package:seenly_admin_app/src/shared/providers/session_provider.dart';

class FakeSessionController extends SessionController {
  @override
  Future<AdminSessionState> build() async {
    return const AdminSessionState();
  }
}

void main() {
  testWidgets('Login screen shows credentials form and hero', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => FakeSessionController()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Let the widget build
    await tester.pump();

    // Verify presence of sign-in elements
    expect(find.text('Secure admin sign-in'), findsOneWidget);
    expect(find.textContaining('review pending creators'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
