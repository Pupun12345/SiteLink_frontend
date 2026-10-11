import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/mask_secret.dart';

class RestApi {
  final GetStorage storage = GetStorage();

  // ---------- 🔹 Token Helper ----------
  String get _token => storage.read("token") ?? "";

  /// Har token-wali (auth) API pe endpoint + bearer token print karo.
  /// Token masked hai — poora JWT log me jaana account handover ke
  /// barabar hai, aur debug logs share hote rehte hain.
  void _logAuth(String method, String url) {
    if (!kDebugMode) return;
    print("[RestApi] $method (Auth) → $url");
    print("[RestApi] 🔑 Bearer Token: ${maskSecret(_token)}");
  }

  Map<String, String> get _baseHeaders => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    "Authorization": "Bearer $_token",

  };
  Future<http.Response> putApiWithAuth(String url, String request) async {
    try {
      _logAuth("PUT", url);
      return await http
          .put(Uri.parse(url), body: request, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }
  // ---------- 🔹 POST (No Auth) ----------
  Future<Map<String, dynamic>> post(String url, String body) async {
    try {
      _log("POST → $url | Body: $body");
      final response = await http
          .post(Uri.parse(url), body: body, headers: _baseHeaders)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      return {"success": false, "message": "No Internet connection."};
    } on TimeoutException {
      return {"success": false, "message": "Request timed out."};
    } catch (e) {
      return {"success": false, "message": "Something went wrong: $e"};
    }
  }

  // ---------- 🔹 POST (No Auth) — returns raw Response ----------
  Future<http.Response> postApi(String url, String request) async {
    try {
      _log("POST (Raw) → $url");
      return await http
          .post(Uri.parse(url), body: request, headers: _baseHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }

  // ---------- 🔹 POST (With Auth) ----------
  Future<http.Response> postApiWithAuth(String url, String request) async {
    try {
      _logAuth("POST", url);
      return await http
          .post(Uri.parse(url), body: request, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }

  // ---------- 🔹 GET (No Auth) ----------
  Future<http.Response> get(String url) async {
    try {
      _log("GET → $url");
      return await http
          .get(Uri.parse(url), headers: _baseHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }

  // ---------- 🔹 GET (With Auth) ----------
  Future<http.Response> getApiWithAuth(String url) async {
    try {
      _logAuth("GET", url);
      return await http
          .get(Uri.parse(url), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }

  // ---------- 🔹 DELETE (With Auth) ----------
  Future<http.Response> deleteApiWithAuth(String url, String request) async {
    try {
      _logAuth("DELETE", url);
      return await http
          .delete(Uri.parse(url), body: request, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      return _errorResponse("No Internet connection.");
    } on TimeoutException {
      return _errorResponse("Request timed out.");
    } catch (e) {
      return _errorResponse("Something went wrong: $e");
    }
  }

  // ---------- 🔹 Private Helpers ----------
  Map<String, dynamic> _processResponse(http.Response response) {
    _log("Response → ${response.statusCode}: ${response.body}");
    try {
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "data": data};
    } catch (e) {
      return {"success": false, "message": "Invalid server response"};
    }
  }

  http.Response _errorResponse(String message) {
    _log("⚠️ $message");
    return http.Response(jsonEncode({"success": false, "message": message}), 200);
  }

  void _log(String message) {
    if (kDebugMode) print("[RestApi] $message");
  }
}