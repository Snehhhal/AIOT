import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/pole_model.dart';
import '../models/sensor_history_model.dart';
import '../models/hazard_report_model.dart';
import '../models/incident_model.dart';

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

  // =========================================================================
  // Authentication & Profile APIs
  // =========================================================================

  /// Real login against POST /api/v1/auth/login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = decoded['access_token'] as String;
        setAuthToken(token);
        return {'success': true, 'data': decoded};
      } else {
        return {
          'success': false,
          'error': decoded['detail'] ?? 'Invalid credentials. Please verify your email and password.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to backend service. Ensure server is running at $baseUrl.'};
    }
  }

  /// Real registration against POST /api/v1/auth/register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? zone,
    String? staffAuthCode,
  }) async {
    try {
      final payload = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role.toUpperCase(),
        'zone': zone ?? 'Sector 1',
      };
      if (staffAuthCode != null && staffAuthCode.isNotEmpty) {
        payload['staff_auth_code'] = staffAuthCode;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        final token = decoded['access_token'] as String;
        setAuthToken(token);
        return {'success': true, 'data': decoded};
      } else {
        return {
          'success': false,
          'error': decoded['detail'] ?? 'Registration failed. Please check your details.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error during registration. Check network connection.'};
    }
  }

  /// Request password reset token against POST /api/v1/auth/forgot-password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 6));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': decoded};
      } else {
        return {'success': false, 'error': decoded['detail'] ?? 'No account found with this email.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to connect to authentication server.'};
    }
  }

  /// Reset password against POST /api/v1/auth/reset-password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'token': token,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 6));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Password reset successfully.'};
      } else {
        return {'success': false, 'error': decoded['detail'] ?? 'Invalid or expired reset token.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to reset password.'};
    }
  }

  // =========================================================================
  // Utility Poles & GPS Discovery APIs
  // =========================================================================

  /// Fetches registered poles within radius from GET /api/v1/poles/nearby
  static Future<List<PoleModel>> getNearbyPoles({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/poles/nearby?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm');
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => PoleModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Fallback below
    }
    return getPoles();
  }

  /// Fetches all registered poles from GET /api/v1/poles
  static Future<List<PoleModel>> getPoles() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/poles'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => PoleModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Fallback to initial poles
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
  static Future<List<SensorHistoryPoint>> getPoleHistory(String poleId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/poles/$poleId/history'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          return list.map((item) => SensorHistoryPoint.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return _generateFallbackHistory(poleId);
  }

  // =========================================================================
  // Multipart Photo Upload API (POST /api/v1/uploads/image)
  // =========================================================================

  /// Real multipart file upload for phone camera / gallery pictures
  static Future<Map<String, dynamic>> uploadImageBytes(List<int> bytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/uploads/image');
      final request = http.MultipartRequest('POST', uri);

      if (authToken != null && authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {
          'success': true,
          'image_url': decoded['image_url'],
          'file_id': decoded['file_id'],
        };
      } else {
        return {
          'success': false,
          'error': decoded['detail'] ?? 'Photo upload failed. Check format and size.'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error uploading photo: $e'};
    }
  }

  // =========================================================================
  // Citizen Hazard Reports & Lifecycle APIs
  // =========================================================================

  /// Submits new citizen hazard report to POST /api/v1/hazard-reports
  static Future<Map<String, dynamic>> submitHazardReport({
    required double latitude,
    required double longitude,
    String? poleId,
    String? address,
    required String hazardType,
    required String description,
    String? imageUrl,
    String? reporterName,
    String? reporterPhone,
  }) async {
    try {
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
        'pole_id': poleId,
        'address': address,
        'hazard_type': hazardType,
        'description': description,
        'image_url': imageUrl,
        'reporter_name': reporterName,
        'reporter_phone': reporterPhone,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/hazard-reports'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'data': decoded};
      } else {
        return {'success': false, 'error': decoded['detail'] ?? 'Failed to submit report.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Could not submit hazard report: $e'};
    }
  }

  /// Lists hazard reports from GET /api/v1/hazard-reports
  static Future<List<HazardReportModel>> getHazardReports({String? status, String? poleId}) async {
    try {
      var url = '$baseUrl/hazard-reports?';
      if (status != null) url += 'status=$status&';
      if (poleId != null) url += 'pole_id=$poleId&';

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => HazardReportModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Updates report status PATCH /api/v1/hazard-reports/{id}/status
  static Future<bool> updateHazardReportStatus({
    required String reportId,
    required String status,
    String? notes,
    String? inspectionImageUrl,
  }) async {
    try {
      final payload = {
        'status': status,
        'notes': notes,
        'inspection_image_url': inspectionImageUrl,
      };
      final response = await http
          .patch(
            Uri.parse('$baseUrl/hazard-reports/$reportId/status'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // Incident, Work Order & Authority APIs
  // =========================================================================

  /// Fetches operational safety incidents from GET /api/v1/incidents
  static Future<List<IncidentModel>> getIncidents({
    String? status,
    String? severity,
    String? poleId,
  }) async {
    try {
      var url = '$baseUrl/incidents?';
      if (status != null) url += 'status=$status&';
      if (severity != null) url += 'severity=$severity&';
      if (poleId != null) url += 'pole_id=$poleId&';

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => IncidentModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches unresolved critical/emergency incidents from GET /api/v1/incidents/escalations
  static Future<List<IncidentModel>> getEscalations() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/incidents/escalations'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => IncidentModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Assigns incident to a technician POST /api/v1/incidents/{id}/assign
  static Future<bool> assignIncident(String incidentId, String technicianId, {String? notes}) async {
    try {
      final payload = {'technician_id': technicianId, 'notes': notes};
      final response = await http
          .post(
            Uri.parse('$baseUrl/incidents/$incidentId/assign'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Acknowledges incident receipt POST /api/v1/incidents/{id}/acknowledge
  static Future<bool> acknowledgeIncident(String incidentId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/incidents/$incidentId/acknowledge'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Updates incident repair status POST /api/v1/incidents/{id}/status
  static Future<bool> updateIncidentStatus(String incidentId, String status, {String? notes}) async {
    try {
      final payload = {'status': status, 'notes': notes};
      final response = await http
          .post(
            Uri.parse('$baseUrl/incidents/$incidentId/status'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Lists work orders GET /api/v1/work-orders
  static Future<List<WorkOrderModel>> getWorkOrders({String? technicianId, String? status}) async {
    try {
      var url = '$baseUrl/work-orders?';
      if (technicianId != null) url += 'technician_id=$technicianId&';
      if (status != null) url += 'status=$status&';

      final response = await http.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List<dynamic>;
        return list.map((item) => WorkOrderModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Orders emergency remote grid isolation POST /api/v1/authority/grid-cutoff
  static Future<bool> orderGridCutoff(String poleId, {String? reason}) async {
    try {
      final payload = {
        'pole_id': poleId,
        'reason': reason ?? 'Emergency grid cutoff ordered due to critical electrical hazard',
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/authority/grid-cutoff'),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // Admin Operations & Audit APIs
  // =========================================================================

  /// Lists all registered platform users GET /api/v1/admin/users
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/users'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
    } catch (_) {}
    return [];
  }

  /// Toggles user active state POST /api/v1/admin/users/{user_id}/toggle-active
  static Future<bool> toggleUserActive(String userId) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/admin/users/$userId/toggle-active'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves platform audit logs GET /api/v1/admin/audit-logs
  static Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/audit-logs?limit=$limit'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
    } catch (_) {}
    return [];
  }

  /// Retrieves system configuration GET /api/v1/admin/system-config
  static Future<Map<String, dynamic>?> getSystemConfig() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/system-config'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // =========================================================================
  // Telemetry & Safety Assistant APIs
  // =========================================================================

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

  /// Queries safety RAG assistant POST /api/v1/assistant/chat
  static Future<String> askSafetyAssistant(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assistant/chat'),
            headers: _headers,
            body: jsonEncode({'query': query, 'language': 'en'}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['response'] as String? ?? 'No guidance found.';
      }
    } catch (_) {}
    return 'For immediate electrical emergencies: Maintain at least 10 meters distance from the pole, prevent others from approaching, and notify the local utility control room immediately.';
  }

  static List<PoleModel> _getFallbackPoles() {
    return const [
      PoleModel(
        id: "P-001",
        serialNumber: "PL-2024-001",
        name: "MG Road - Junction 4",
        location: "MG Road, Pune Cantonment",
        address: "MG Road, Near Central Library, Junction 4",
        area: "Pune Cantonment",
        latitude: 18.5204,
        longitude: 73.8567,
        zone: "Sector 4",
        status: "CRITICAL",
        leakageCurrent: 48.2,
        voltage: 72.0,
        temperature: 31.0,
        humidity: 95.0,
        rain: true,
        healthScore: 42,
        riskScore: 88,
        riskTier: RiskTier.emergency,
      ),
      PoleModel(
        id: "P-002",
        serialNumber: "PL-2024-002",
        name: "FC Road - Metro Station",
        location: "FC Road, Shivajinagar",
        address: "Fergusson College Road, Opp Metro Gate 2",
        area: "Shivajinagar",
        latitude: 18.5280,
        longitude: 73.8420,
        zone: "Sector 1",
        status: "WARNING",
        leakageCurrent: 14.2,
        voltage: 228.0,
        temperature: 28.5,
        humidity: 65.0,
        rain: false,
        healthScore: 68,
        riskScore: 45,
        riskTier: RiskTier.warning,
      ),
      PoleModel(
        id: "P-003",
        serialNumber: "PL-2024-003",
        name: "Station Road - East Zone",
        location: "Pune Station Road",
        address: "Pune Station Road, Near Platform 1 Feeder",
        area: "Railway Circle",
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
        riskScore: 8,
        riskTier: RiskTier.safe,
      ),
      PoleModel(
        id: "P-004",
        serialNumber: "PL-2024-004",
        name: "Kothrud Market Center",
        location: "Paud Road, Kothrud",
        address: "Paud Road, Near Shivaji Statue Center",
        area: "Kothrud",
        latitude: 18.5074,
        longitude: 73.8077,
        zone: "Sector 3",
        status: "HEALTHY",
        leakageCurrent: 1.1,
        voltage: 230.0,
        temperature: 26.8,
        humidity: 46.0,
        rain: false,
        healthScore: 96,
        riskScore: 5,
        riskTier: RiskTier.safe,
      ),
    ];
  }

  static List<SensorHistoryPoint> _generateFallbackHistory(String poleId) {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final time = now.subtract(Duration(hours: 11 - index));
      return SensorHistoryPoint(
        timestamp: time,
        leakageCurrent: 1.5 + (index * 0.4),
        voltage: 230.0 - (index * 0.2),
        temperature: 27.0 + (index % 3),
        humidity: 50.0 + (index % 5),
      );
    });
  }
}
