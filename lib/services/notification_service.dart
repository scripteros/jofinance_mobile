import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Serviço de notificações push via Firebase Cloud Messaging (FCM).
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  /// Inicializa notificações push: permissões, token, handlers.
  Future<void> initialize() async {
    if (_initialized) return;

    // Configurar notificações locais (Android)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Pedir permissão de notificação (iOS)
    final messagingSettings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obter token FCM e registrar no backend
    _fcmToken = await _fcm.getToken();
    _saveTokenLocally(_fcmToken);
    if (_fcmToken != null) {
      _registerTokenWithBackend(_fcmToken!);
    }

    // Escutar renovação de token
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenLocally(newToken);
      _registerTokenWithBackend(newToken);
    });

    // Handler para notificações em foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handler para quando app é aberto por notificação (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // Handler para quando app é aberto por notificação (fechado -> foreground)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationOpenedApp(initialMessage);
    }

    _initialized = true;
    print('🔔 NotificationService initialized. Token: $_fcmToken');
  }

  /// Retorna o token FCM atual.
  String? get token => _fcmToken;

  /// Registra o token no backend.
  Future<bool> registerWithBackend({String platform = 'android'}) async {
    if (_fcmToken == null) return false;
    return _registerTokenWithBackend(_fcmToken!, platform: platform);
  }

  Future<bool> _registerTokenWithBackend(String token,
      {String platform = 'android'}) async {
    try {
      final api = ApiService();
      await api.fcmRegister(token, platform);
      print('✅ FCM token registrado no backend');
      return true;
    } catch (e) {
      print('❌ Erro ao registrar FCM token: $e');
      return false;
    }
  }

  /// Handler para notificações recebidas em foreground.
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        notification.title ?? '',
        notification.body ?? '',
        message.data,
      );
    } else if (message.data.isNotEmpty) {
      // Notificação silenciosa com data
      _showLocalNotification(
        message.data['title'] ?? 'Jo Finance',
        message.data['body'] ?? '',
        message.data,
      );
    }
  }

  /// Handler quando o usuário toca na notificação.
  void _onNotificationTap(NotificationResponse response) {
    // Payload pode conter URL ou action
    print('🔔 Notification tapped: ${response.payload}');
  }

  /// Handler quando app é aberto por notificação.
  void _onNotificationOpenedApp(RemoteMessage message) {
    print('🔔 App opened by notification: ${message.data}');
  }

  /// Exibe notificação local na bandeja do sistema.
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'jo_finance_channel',
      'Jo Finance',
      channelDescription: 'Notificações do Jo Finance',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// Salva token localmente para registro posterior.
  Future<void> _saveTokenLocally(String? token) async {
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Recupera token salvo localmente.
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
