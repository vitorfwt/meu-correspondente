import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/auth/auth_repository.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/main.dart';

class MockAuthRepository extends AuthRepository {
  final bool shouldFail;
  final Duration delay;

  MockAuthRepository({this.shouldFail = false, this.delay = Duration.zero});

  @override
  Future<(User, String)> loginWithGoogle() async {
    await Future.delayed(delay);
    if (shouldFail) {
      throw Exception('Google login failed');
    }
    return (
      const User(id: 'google_123', name: 'João Silva', email: 'joao.silva@example.com'),
      'mock_google_token'
    );
  }

  @override
  Future<(User, String)> loginWithApple() async {
    await Future.delayed(delay);
    if (shouldFail) {
      throw Exception('Apple login failed');
    }
    return (
      const User(id: 'apple_123', name: 'João Silva', email: 'joao.silva@example.com'),
      'mock_apple_token'
    );
  }
}

void main() {
  group('Auth Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('AuthProvider loads empty initial state when no token saved', () async {
      final authProvider = AuthProvider(prefs: prefs);
      
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('AuthProvider loads authenticated state when token is saved', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'saved_token',
        'auth_user_id': 'saved_id',
        'auth_user_name': 'João Silva',
        'auth_user_email': 'joao@example.com',
      });
      final savedPrefs = await SharedPreferences.getInstance();
      
      final authProvider = AuthProvider(prefs: savedPrefs);
      
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.token, 'saved_token');
      expect(authProvider.user?.name, 'João Silva');
      expect(authProvider.isAuthenticated, isTrue);
    });

    test('AuthProvider loginWithGoogle stores values on success', () async {
      final mockRepo = MockAuthRepository();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);

      expect(authProvider.status, AuthStatus.unauthenticated);
      
      final future = authProvider.loginWithGoogle();
      expect(authProvider.status, AuthStatus.authenticating);
      expect(authProvider.isLoading, isTrue);

      await future;

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.token, 'mock_google_token');
      expect(authProvider.user?.name, 'João Silva');
      expect(prefs.getString('auth_token'), 'mock_google_token');
    });

    test('AuthProvider loginWithApple stores values on success', () async {
      final mockRepo = MockAuthRepository();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);

      expect(authProvider.status, AuthStatus.unauthenticated);
      
      final future = authProvider.loginWithApple();
      expect(authProvider.status, AuthStatus.authenticating);

      await future;

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.token, 'mock_apple_token');
      expect(authProvider.user?.name, 'João Silva');
      expect(prefs.getString('auth_token'), 'mock_apple_token');
    });

    test('AuthProvider login fails and sets error message', () async {
      final mockRepo = MockAuthRepository(shouldFail: true);
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);

      await authProvider.loginWithGoogle();

      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, isNotNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(prefs.getString('auth_token'), isNull);
    });

    test('AuthProvider logout clears values', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'saved_token',
        'auth_user_id': 'saved_id',
        'auth_user_name': 'João Silva',
      });
      final savedPrefs = await SharedPreferences.getInstance();
      final authProvider = AuthProvider(prefs: savedPrefs);

      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
      expect(savedPrefs.getString('auth_token'), isNull);
    });
  });

  group('Login Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('LoginScreen renders brand, slogan, and login buttons', (WidgetTester tester) async {
      final authProvider = AuthProvider(prefs: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
      expect(find.text('Meu Correspondente'), findsOneWidget);
      expect(find.textContaining('Sua conexão direta'), findsOneWidget);
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Entrar com Apple'), findsOneWidget);
    });

    testWidgets('LoginScreen displays loading indicator on button when logging in', (WidgetTester tester) async {
      final mockRepo = MockAuthRepository(delay: const Duration(seconds: 1));
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pump();

      expect(authProvider.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    });

    testWidgets('LoginScreen displays SnackBar on error', (WidgetTester tester) async {
      final mockRepo = MockAuthRepository(shouldFail: true);
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('apple_login_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erro ao realizar login. Tente novamente.'), findsOneWidget);
    });

    testWidgets('Full flow: Login -> Dashboard -> Logout', (WidgetTester tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(MyApp(prefs: prefs));
      await tester.pumpAndSettle();

      expect(find.text('Meu Correspondente'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
      expect(find.text('Entrar com Google'), findsOneWidget);

      await tester.tap(find.byKey(const Key('google_login_button')));
      await tester.pumpAndSettle();

      // Should now be on SimulatorFormScreen
      expect(find.text('Simulador de Financiamento'), findsOneWidget);
      expect(find.text('Faça uma Simulação'), findsOneWidget);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout drawer tile
      await tester.tap(find.byKey(const Key('drawer_logout_tile')));
      await tester.pumpAndSettle();

      expect(find.text('Meu Correspondente'), findsOneWidget);
      expect(find.text('Entrar na sua conta'), findsOneWidget);
    });
  });
}
