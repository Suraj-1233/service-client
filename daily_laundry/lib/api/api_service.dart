import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../screens/address/address_model.dart';
import '../screens/auth/login_screen.dart';

class ApiService {
  // 🌐 Base URL for your backend
  static const String baseUrl = 'http://3.94.103.35:8080/api';

  // 🔒 Secure token storage
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static String? token;

  // ------------------ Load token from secure storage ------------------
  static Future<void> loadToken() async {
    try {
      token = await _secureStorage.read(key: 'jwt_token');
      debugPrint("🔁 Token auto-loaded from secure storage: ${token != null}");
    } catch (e) {
      debugPrint("⚠️ Failed to load token from secure storage: $e");
    }
  }

  // ------------------ Save & clear token ------------------
  static Future<void> saveToken(String newToken) async {
    token = newToken;
    await _secureStorage.write(key: 'jwt_token', value: newToken);
    debugPrint("💾 Token saved securely");
  }

  static Future<void> clearToken() async {
    token = null;
    await _secureStorage.delete(key: 'jwt_token');
    debugPrint("🧹 Token cleared");
  }

  // ------------------ Helper for headers ------------------
  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = {"Content-Type": "application/json"};

    if (withAuth && (token == null || token!.isEmpty)) {
      await loadToken();
    }

    if (withAuth && token != null && token!.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  // ------------------ Global 401 Handler ------------------
  static Future<bool> _checkUnauthorized(BuildContext context, http.Response res) async {
    if (res.statusCode == 401) {
      debugPrint("⚠️ Unauthorized (401) — Redirecting to LoginScreen");
      await clearToken();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
      return true;
    }
    return false;
  }

  // ------------------ Registration ------------------
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    debugPrint("➡️ POST /auth/register | Body: ${json.encode(userData)}");
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: await _headers(),
      body: json.encode(userData),
    );

    debugPrint("⬅️ Status: ${response.statusCode}");
    debugPrint("⬅️ Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to register user: ${response.body}");
    }
  }

  // ------------------ Login ------------------
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final body = {"email": email, "password": password};
    debugPrint("➡️ POST /auth/login | $body");

    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: await _headers(),
      body: json.encode(body),
    );

    debugPrint("⬅️ Status: ${response.statusCode}");
    debugPrint("⬅️ Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newToken = data['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        await saveToken(newToken);
      }
      return data;
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  // ------------------ Place Order ------------------
  static Future<Map<String, dynamic>> placeOrder(
      BuildContext context,
      Map<String, dynamic> orderData,
      ) async {
    debugPrint("➡️ POST /orders | ${json.encode(orderData)}");

    final response = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: await _headers(withAuth: true),
      body: json.encode(orderData),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return Map<String, dynamic>.from(json.decode(response.body));
      } catch (e) {
        debugPrint("⚠️ JSON Decode Error: $e");
        return {"message": "Order placed successfully (non-JSON response)."};
      }
    } else {
      throw Exception("Failed to place order: ${response.statusCode} → ${response.body}");
    }
  }

  // ------------------ Get All Orders ------------------
  static Future<List<Map<String, dynamic>>> getOrders(BuildContext context) async {
    debugPrint("➡️ GET /orders");

    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
      headers: await _headers(withAuth: true),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return [];

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to load orders: ${response.body}");
    }
  }

  // ------------------ Update Order Status ------------------
  static Future<Map<String, dynamic>> updateOrderStatus(
      BuildContext context,
      int orderId,
      String status,
      ) async {
    debugPrint("➡️ PUT /orders/$orderId/status?status=$status");

    final response = await http.put(
      Uri.parse("$baseUrl/orders/$orderId/status?status=$status"),
      headers: await _headers(withAuth: true),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return {};

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to update order: ${response.body}");
    }
  }

  // ------------------ Cancel Order ------------------
  static Future<Map<String, dynamic>> cancelOrder(
      BuildContext context,
      int orderId,
      ) async {
    debugPrint("➡️ PUT /orders/$orderId/cancel");

    final response = await http.put(
      Uri.parse("$baseUrl/orders/$orderId/cancel"),
      headers: await _headers(withAuth: true),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return {};

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to cancel order: ${response.body}");
    }
  }

  // ------------------ Get Order Details ------------------
  static Future<Map<String, dynamic>> getOrderDetails(
      BuildContext context,
      String orderId,
      ) async {
    debugPrint("➡️ GET /orders/$orderId");

    final response = await http.get(
      Uri.parse("$baseUrl/orders/$orderId"),
      headers: await _headers(withAuth: true),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return {};

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to get order details: ${response.body}");
    }
  }

  // ------------------ Get Services with Items ------------------
  static Future<List<dynamic>> getServicesWithItems(BuildContext context) async {
    final response = await http.get(Uri.parse('$baseUrl/pricing/services-with-items'));
    if (await _checkUnauthorized(context, response)) return [];

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services with items');
    }
  }

  // ------------------ User Info ------------------
  static Future<Map<String, dynamic>> getUserInfo() async {
    debugPrint("➡️ GET /users/me");
    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: await _headers(withAuth: true),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to get user info: ${response.body}");
    }
  }

  // ------------------ User Orders ------------------
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    debugPrint("➡️ GET /orders/my");
    final response = await http.get(
      Uri.parse("$baseUrl/orders/my"),
      headers: await _headers(withAuth: true),
    );

    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to get user orders: ${response.body}");
    }
  }

  // ------------------ Update User Info ------------------
  static Future<Map<String, dynamic>> updateUserInfo(Map<String, dynamic> updatedData) async {
    debugPrint("➡️ PUT /users/update | ${json.encode(updatedData)}");
    final response = await http.put(
      Uri.parse("$baseUrl/users/update"),
      headers: await _headers(withAuth: true),
      body: json.encode(updatedData),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to update user info: ${response.body}");
    }
  }

  // ------------------ Addresses ------------------
  static Future<List<Address>> getAddresses(BuildContext context) async {
    debugPrint("➡️ GET /addresses");
    final response = await http.get(
      Uri.parse("$baseUrl/addresses"),
      headers: await _headers(withAuth: true),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");
    if (await _checkUnauthorized(context, response)) return [];

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Address.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch addresses: ${response.body}");
    }
  }

  static Future<Address> addAddress(Address address) async {
    debugPrint("➡️ POST /addresses | ${json.encode(address.toJson())}");
    final response = await http.post(
      Uri.parse("$baseUrl/addresses"),
      headers: await _headers(withAuth: true),
      body: json.encode(address.toJson()),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Address.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to add address: ${response.body}");
    }
  }

  static Future<Address> updateAddress(String id, Address address) async {
    debugPrint("➡️ PUT /addresses/$id | ${json.encode(address.toJson())}");
    final response = await http.put(
      Uri.parse("$baseUrl/addresses/$id"),
      headers: await _headers(withAuth: true),
      body: json.encode(address.toJson()),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      return Address.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to update address: ${response.body}");
    }
  }

  static Future<void> deleteAddress(String id) async {
    debugPrint("➡️ DELETE /addresses/$id");
    final response = await http.delete(
      Uri.parse("$baseUrl/addresses/$id"),
      headers: await _headers(withAuth: true),
    );
    debugPrint("⬅️ ${response.statusCode} | ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete address: ${response.body}");
    }
  }

  static Future<List<dynamic>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/laundry-services'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  // ✅ Fetch Active Orders
  static Future<List<dynamic>> getActiveOrders(BuildContext context) async {
    final url = Uri.parse('$baseUrl/orders/active');
    final response = await http.get(url, headers: await _headers(withAuth: true));
    if (await _checkUnauthorized(context, response)) return [];

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load active orders: ${response.statusCode} ${response.body}');
    }
  }
}
