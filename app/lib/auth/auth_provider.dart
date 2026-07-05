import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final SharedPreferences? _prefs;

  AuthStatus _status = AuthStatus.unauthenticated;
  User? _user;
  String? _token;
  String? _errorMessage;

  AuthProvider({
    AuthRepository repository = const AuthRepository(),
    SharedPreferences? prefs,
  })  : _repository = repository,
        _prefs = prefs {
    if (_prefs != null) {
      _loadSync();
    } else {
      _init();
    }
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userNameKey = 'auth_user_name';
  static const String _userIdKey = 'auth_user_id';

  void _loadSync() {
    try {
      final savedToken = _prefs!.getString(_tokenKey);
      if (savedToken != null) {
        final userId = _prefs!.getString(_userIdKey) ?? '';
        final userName = _prefs!.getString(_userNameKey) ?? 'João Silva';
        final userEmail = _prefs!.getString(_userEmailKey) ?? 'joao.silva@example.com';
        
        _token = savedToken;
        _user = User(id: userId, name: userName, email: userEmail);
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken != null) {
        final userId = prefs.getString(_userIdKey) ?? '';
        final userName = prefs.getString(_userNameKey) ?? 'João Silva';
        final userEmail = prefs.getString(_userEmailKey) ?? 'joao.silva@example.com';
        
        _token = savedToken;
        _user = User(id: userId, name: userName, email: userEmail);
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    await _login(() => _repository.loginWithGoogle());
  }

  Future<void> loginWithApple() async {
    await _login(() => _repository.loginWithApple());
  }

  Future<void> _login(Future<(User, String)> Function() loginMethod) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final (user, token) = await loginMethod();
      _user = user;
      _token = token;
      
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, user.id);
      await prefs.setString(_userNameKey, user.name);
      await prefs.setString(_userEmailKey, user.email);

      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao realizar login. Tente novamente.';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
      
      _token = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erro ao realizar logout.';
    }
    notifyListeners();
  }
}

class AuthProviderScope extends InheritedNotifier<AuthProvider> {
  const AuthProviderScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AuthProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthProviderScope>();
    assert(scope != null, 'Nenhum AuthProviderScope encontrado no BuildContext');
    return scope!.notifier!;
  }
}
