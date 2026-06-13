import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isLoading = true;
  String? _error;
  bool _isUnlocked = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _isUnlocked;
  bool get hasToken => _token != null && _token!.isNotEmpty;
  String? get error => _error;

  AuthProvider() {
    checkAuth();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jo_finance_token');
      _token = token;
      
      if (token != null && token.isNotEmpty) {
        _user = await _apiService.getMe();
        
        final lastUnlockStr = prefs.getString('last_unlock_time');
        if (lastUnlockStr != null) {
          final lastUnlock = DateTime.parse(lastUnlockStr);
          // Permanece logado se destrancou nas últimas 4 horas
          if (DateTime.now().difference(lastUnlock).inHours < 4) {
            _isUnlocked = true;
          } else {
            _isUnlocked = false;
          }
        } else {
          _isUnlocked = false; 
        }
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unlock() async {
    _isUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_unlock_time', DateTime.now().toIso8601String());
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.login(email, password);
      _user = await _apiService.getMe();
      await unlock(); // Usa a nova função que salva a hora
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password, [String? phone]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.register(name, email, password, phone);
      _user = await _apiService.getMe();
      await unlock();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jo_finance_token');
    await prefs.remove('last_unlock_time');
    _user = null;
    _token = null;
    _isUnlocked = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _apiService.getMe();
      notifyListeners();
    } catch (e) {
      // Ignore errors on silent refresh
    }
  }
}
