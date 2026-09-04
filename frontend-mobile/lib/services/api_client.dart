import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/pole_model.dart';

class ApiClient {
  static String baseUrl = AppConstants.defaultApiBaseUrl;
  static String? authToken;

  static void setAuthToken(String token) {
    authToken = token;
  }

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Fetches all registered poles from GET /api/v1/poles
  static Future<List<PoleModel>> getPoles() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/poles'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => PoleModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Fallback to local default poles when network/backend is offline (Section 47)
    }
    return _getFallbackPoles();
  }

  /// Fetches single pole details from GET /api/v1/poles/{pole_id}
  static Future<PoleModel?> getPole(String poleId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/poles/$poleId'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return PoleModel.fromJson(decoded['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _getFallbackPoles().firstWhere((p) => p.id == poleId, orElse: () => _getFallbackPoles().first);
  }

  /// Fetches historical trend readings from GET /api/v1/poles/{pole_id}/history
  static Future<List<Map<String, dynamic>>> getPoleHistory(String poleId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/poles/$poleId/history'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Submits telemetry to POST /api/v1/telemetry
  static Future<Map<String, dynamic>?> sendTelemetry(Map<String, dynamic> telemetryPayload) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/telemetry'),
            headers: _headers,
            body: jsonEncode(telemetryPayload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static List<PoleModel> _getFallbackPoles() {
    return const [
      PoleModel(
        id: "P-001",
        name: "MG Road - Junction 4",
        location: "MG Road, Opp. Metro Pillar 42",
        latitude: 18.5204,
        longitude: 73.8567,
        zone: "Sector 4",
        status: "CRITICAL",
        leakageCurrent: 48.5,
        voltage: 74.2,
        temperature: 28.0,
        humidity: 96.0,
        rain: true,
        healthScore: 58,
        riskScore: 94,
        riskTier: RiskTier.emergency,
        humanDetected: true,
        standingWaterDetected: true,
        isOnline: true,
      ),
      PoleModel(
        id: "P-002",
        name: "FC Road - Near Metro Station",
        location: "FC Road Central",
        latitude: 18.5280,
        longitude: 73.8420,
        zone: "Sector 1",
        status: "WARNING",
        leakageCurrent: 14.8,
        voltage: 228.0,
        temperature: 29.1,
        humidity: 65.0,
        rain: false,
        healthScore: 76,
        riskScore: 42,
        riskTier: RiskTier.warning,
        isOnline: true,
      ),
      PoleModel(
        id: "P-003",
        name: "Station Road - East Zone",
        location: "Pune Station Road",
        latitude: 18.5312,
        longitude: 73.8745,
        zone: "Sector 2",
        status: "HEALTHY",
        leakageCurrent: 1.8,
        voltage: 231.0,
        temperature: 27.5,
        humidity: 50.0,
        rain: false,
        healthScore: 94,
        riskScore: 6,
        riskTier: RiskTier.safe,
        isOnline: true,
      ),
      PoleModel(
        id: "P-004",
        name: "Kothrud Market Center",
        location: "Kothrud Commercial Hub",
        latitude: 18.5074,
        longitude: 73.8077,
        zone: "Sector 3",
        status: "HEALTHY",
        leakageCurrent: 0.9,
        voltage: 229.5,
        temperature: 26.8,
        humidity: 45.0,
        rain: false,
        healthScore: 98,
        riskScore: 3,
        riskTier: RiskTier.safe,
        isOnline: true,
      ),
    ];
  }
}
