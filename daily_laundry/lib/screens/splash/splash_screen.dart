import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _overallTimeout = Duration(seconds: 12);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _startChecks();

    // 🧩 Safety fallback (avoid infinite loader)
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        print("⚠️ Fallback navigation triggered");
        _goToLogin();
      }
    });
  }

  Future<void> _startChecks() async {
    await Future.any([
      _checkLoginStatus(),
      Future.delayed(_overallTimeout, () {
        print("⏰ Timeout triggered — going to Login");
        _goToLogin();
      }),
    ]);
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Allow some time for platform channels to initialize (helps in release builds)
      await Future.delayed(const Duration(milliseconds: 250));

      final token = await _secureStorage.read(key: 'jwt_token');
      print("🌐 Using Base URL: ${ApiService.baseUrl}");
      print("🔑 Token found: ${token != null && token.isNotEmpty}");

      if (token == null || token.isEmpty) {
        print("🔓 No token found — navigating to login");
        _goToLogin();
        return;
      }

      final uri = Uri.parse("${ApiService.baseUrl}/users/me");

      try {
        final res = await http
            .get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        )
            .timeout(const Duration(seconds: 8));

        print("➡️ GET ${uri.path} => ${res.statusCode}");

        if (res.statusCode == 200) {
          ApiService.token = token;
          print("✅ Token valid — navigating to home");
          _goToHome();
        } else {
          print("❌ Token invalid — clearing secure storage & going to login");
          await _secureStorage.delete(key: 'jwt_token');
          _goToLogin();
        }
      } on TimeoutException catch (e) {
        print("⏰ Timeout: $e");
        _goToLogin();
      } on SocketException catch (e) {
        print("🌐 Network error: $e");
        _goToLogin();
      } on PlatformException catch (e) {
        print("⚙️ Platform exception: $e");
        _goToLogin();
      } catch (e, st) {
        print("💥 Unexpected error: $e\n$st");
        _goToLogin();
      }
    } catch (e, st) {
      print("💣 Fatal error in _checkLoginStatus: $e\n$st");
      _goToLogin();
    }
  }

  /// Safe navigation wrappers
  void _goToHome() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🚀 Navigating → HomeScreen");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) =>  HomeScreen()),
      );
    });
  }

  void _goToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("🚀 Navigating → LoginScreen");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );
  }
}
