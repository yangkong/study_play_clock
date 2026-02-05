import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> init(Function(RemoteMessage) onMessage) async {
    await _initLocalNotifications();
    await _initFCM(onMessage);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'study_play_clock_channel',
      'Study Play Clock Notifications',
      description: 'Notifications for game expiration and device link',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initFCM(Function(RemoteMessage) onMessage) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await messaging.getToken();
        
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("포그라운드 메시지 수신: ${message.data}");
          onMessage(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("푸시 클릭으로 앱 열림: ${message.data}");
          onMessage(message);
        });
      }
      debugPrint("FCM 초기화 성공: $_fcmToken");
    } catch (e) {
      debugPrint("FCM 초기화 실패: $e");
    }
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'study_play_clock_channel',
      'Study Play Clock Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> sendPushNotification(String targetToken, String title, String body) async {
    debugPrint("푸시 알림 전송 시도: target=$targetToken, title=$title");
    
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "study-play-clock-1a0a4",
      "private_key": "",
      "client_email": "firebase-adminsdk-fbsvc@study-play-clock-1a0a4.iam.gserviceaccount.com",
      "client_id": "107320225507075806122",
    };

    if (serviceAccountJson["private_key"] == "YOUR_PRIVATE_KEY_HERE") {
      debugPrint("FCM 전송 실패: 서비스 계정 키가 설정되지 않았습니다.");
      return;
    }

    try {
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      final String projectId = serviceAccountJson["project_id"] as String;
      final String fcmUrl = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await client.post(
        Uri.parse(fcmUrl),
        body: jsonEncode({
          'message': {
            'token': targetToken,
            'notification': {'title': title, 'body': body},
            'data': {'type': title, 'payload': body}
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("푸시 전송 성공");
      } else {
        debugPrint("푸시 전송 실패: ${response.body}");
      }
      client.close();
    } catch (e) {
      debugPrint("푸시 전송 에러: $e");
    }
  }
}
