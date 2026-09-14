import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_exceptions.dart';

enum Role { reader, librarian, admin }
extension RoleX on Role {
  String get label => switch (this) {
        Role.reader => 'Читатель',
        Role.librarian => 'Библиотекарь',
        Role.admin => 'Администратор',
      };
  static Role parse(String v) =>
      Role.values.firstWhere((r) => r.name == v, orElse: () => Role.reader);
}

class AppUser {
  final int id;
  final String username;
  final String name;
  final Role role;
  final int? readerId;
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.readerId,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] ?? 0,
        username: j['username'] ?? '',
        name: j['name'] ?? j['username'] ?? '',
        role: RoleX.parse(j['role'] ?? 'reader'),
        readerId: j['readerId'] is num ? (j['readerId'] as num).toInt() : null,
      );
}

class AuthNotifier extends ChangeNotifier {
  static const _kToken = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  final SharedPreferences prefs;
  final Dio dio;
  AppUser? user;
  String? accessToken;
  String? refreshToken;
  bool restoring = true;

  AuthNotifier(this.prefs, this.dio);

  bool get isAuthenticated => user != null;
  bool get isReader => user?.role == Role.reader;
  bool get isLibrarian => user?.role == Role.librarian;
  bool get isAdmin => user?.role == Role.admin;
  bool has(Role role) => user?.role == role;

  Future<void> restore() async {
    accessToken = prefs.getString(_kToken);
    refreshToken = prefs.getString(_kRefresh);
    if (accessToken != null) {
      try {
        final r = await dio.get('/auth/me');
        user = AppUser.fromJson(Map<String, dynamic>.from(r.data));
      } catch (_) {
        await prefs.remove(_kToken);
        await prefs.remove(_kRefresh);
        accessToken = null;
        refreshToken = null;
        user = null;
      }
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    try {
      final r = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      accessToken = r.data['accessToken'];
      refreshToken = r.data['refreshToken'];
      user = AppUser.fromJson(Map<String, dynamic>.from(r.data['user']));
      await prefs.setString(_kToken, accessToken!);
      if (refreshToken != null) await prefs.setString(_kRefresh, refreshToken!);
      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> register(String username, String name, String password) async {
    try {
      final r = await dio.post('/auth/register', data: {
        'username': username,
        'name': name,
        'password': password,
      });
      accessToken = r.data['accessToken'];
      refreshToken = r.data['refreshToken'];
      user = AppUser.fromJson(Map<String, dynamic>.from(r.data['user']));
      await prefs.setString(_kToken, accessToken!);
      if (refreshToken != null) await prefs.setString(_kRefresh, refreshToken!);
      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    user = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kRefresh);
    notifyListeners();
  }
}
