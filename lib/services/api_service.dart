import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'https://iapi.mobap.com.br/api/v1';


  Future<List<dynamic>> getGoalsProgress() async {
    final response = await http.get(Uri.parse('$baseUrl/goals/progress'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao obter progresso das metas');
  }

  Future<Map<String, dynamic>> getForecast(String period) async {
    final response = await http.get(Uri.parse('$baseUrl/forecast/$period'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao obter forecast');
  }

  Future<Map<String, dynamic>> getNetWorth() async {
    final response = await http.get(Uri.parse('$baseUrl/net-worth'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao obter patrimônio');
  }

  Future<List<dynamic>> getUpcomingBills() async {
    final response = await http.get(Uri.parse('$baseUrl/bills/upcoming'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao obter contas a vencer');
  }

  Future<Map<String, dynamic>> getOnboardingStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/onboarding/status'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter status do onboarding: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitOnboarding(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/submit'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao enviar onboarding: ${response.body}');
    }
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jo_finance_token');
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _request(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    http.Response response;
    try {
      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: jsonEncode(body));
      } else {
        response = await http.get(url, headers: headers);
      }
    } catch (e) {
      throw Exception('Erro de conexão com o servidor.');
    }

    if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jo_finance_token');
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Erro ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        message = errorBody['detail'] ?? errorBody['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _request('/auth/login', method: 'POST', body: {
      'email': email,
      'password': password,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jo_finance_token', data['access_token']);
    
    return data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, [String? phone]) async {
    final data = await _request('/auth/register', method: 'POST', body: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jo_finance_token', data['access_token']);
    
    return data;
  }

  Future<User> getMe() async {
    final data = await _request('/auth/me');
    return User.fromJson(data);
  }

  Future<List<Transaction>> getTransactions() async {
    final List data = await _request('/transactions');
    final txs = data.map((json) => Transaction.fromJson(json)).toList();
    txs.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return txs;
  }

  Future<List<Goal>> getGoals() async {
    final List data = await _request('/goals');
    return data.map((json) => Goal.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> createGoal({
    required String name,
    required double targetAmount,
    required String category,
    double monthlyContribution = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'target_amount': targetAmount,
        'category': category,
        'monthly_contribution': monthlyContribution,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao criar meta');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createTransaction({
    required String description,
    required double amount,
    required String category,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'category': category,
        'type': type,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create transaction');
    }
    return jsonDecode(response.body);
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao excluir transação');
    }
  }

  // --- AI Chat Endpoints ---
  
  Future<List<dynamic>> getChatHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/chat/history'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: await _getHeaders(),
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Falha ao enviar mensagem');
  }

  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/history/save'),
      headers: await _getHeaders(),
      body: jsonEncode({'messages': messages}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao salvar histórico');
    }
  }

  Future<void> deleteMessages(List<int> historyIds) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chat/history'),
      headers: await _getHeaders(),
      body: jsonEncode({'message_ids': historyIds}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao apagar mensagens');
  }

  Future<List<int>> getTTS(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/tts'),
      headers: await _getHeaders(),
      body: jsonEncode({'text': text, 'voice': 'pt-BR-FranciscaNeural'}),
    );
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Falha ao gerar TTS');
  }

  Future<String> transcribeAudio(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transcribe'));
    request.headers.addAll(await _getHeaders(isMultipart: true));
    request.files.add(await http.MultipartFile.fromPath('audio', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text']?.toString() ?? '';
    }
    throw Exception('Falha ao transcrever áudio');
  }

  // --- Account Management ---

  Future<Map<String, dynamic>> resetUserData() async {
    return await _request('/account/reset', method: 'POST');
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    return await _request('/account/delete', method: 'DELETE');
  }

  // --- Plans ---

  Future<List<dynamic>> getPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/plans'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao obter planos');
  }

  // --- FCM Push Notifications ---

  Future<Map<String, dynamic>> fcmRegister(String token, String platform) async {
    return await _request('/fcm/register', method: 'POST', body: {
      'token': token,
      'platform': platform,
    });
  }

  Future<Map<String, dynamic>> fcmUnregister(String token) async {
    return await _request('/fcm/unregister', method: 'POST', body: {
      'token': token,
    });
  }
}
