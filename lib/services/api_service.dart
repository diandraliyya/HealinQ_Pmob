import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Android Emulator pakai 10.0.2.2 untuk akses Laravel di laptop
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _publicHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'Login gagal');
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _publicHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveAuthData(data);
      return data;
    }

    throw Exception(data['message'] ?? 'Register gagal');
  }

  static Future<void> saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', data['token']);
    await prefs.setString('name', data['user']['name']);
    await prefs.setString('email', data['user']['email']);
    await prefs.setString('role', data['user']['role']);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Map<String, String> _publicHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getCounselors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/counselors'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil data counselor');
  }

  static Future<List<dynamic>> getJarItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/jar-items'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil data jar items');
  }

  static Future<List<dynamic>> getLyrics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lyrics'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil data lyrics');
  }

  static Future<List<dynamic>> getPassionQuestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/passion/questions'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil data passion questions');
  }

  static Future<List<dynamic>> getMyJournals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-journals'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil journal');
  }

  static Future<Map<String, dynamic>> createJournal({
    required String title,
    required String content,
    required String moodTag,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/journals'),
      headers: await authHeaders(),
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood_tag': moodTag,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Gagal membuat journal');
  }

  static Future<Map<String, dynamic>> createConsultation({
    required int counselorId,
    required String type,
    required String scheduledAt,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/consultations'),
      headers: await authHeaders(),
      body: jsonEncode({
        'counselor_id': counselorId,
        'type': type,
        'scheduled_at': scheduledAt,
        'notes': notes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Gagal membuat booking');
  }

  static Future<Map<String, dynamic>> savePassionResult({
    required String resultTitle,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/passion/result'),
      headers: await authHeaders(),
      body: jsonEncode({
        'result_title': resultTitle,
        'description': description,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Gagal menyimpan hasil passion');
  }

  static Future<List<dynamic>> getMyPassionResults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/passion/my-results'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal mengambil hasil passion');
  }

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await authHeaders(),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
