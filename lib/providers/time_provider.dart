import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class TimeProvider extends ChangeNotifier {
  int _accumulatedSeconds = 0;
  int _initialGameSeconds = 0;
  bool _isStudying = false;
  bool _isPlaying = false;
  Timer? _timer;
  String? _password;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService();
  
  List<String> _linkedTokens = [];
  Map<String, Map<String, dynamic>> _remoteDevicesStatus = {};

  int get accumulatedSeconds => _accumulatedSeconds;
  int get initialGameSeconds => _initialGameSeconds;
  bool get isStudying => _isStudying;
  bool get isPlaying => _isPlaying;
  bool get hasPassword => _password != null && _password!.isNotEmpty;
  String? get fcmToken => _notificationService.fcmToken;
  List<String> get linkedTokens => _linkedTokens;
  Map<String, Map<String, dynamic>> get remoteDevicesStatus => _remoteDevicesStatus;

  TimeProvider() {
    _loadData();
    _notificationService.init(_handleMessage).then((_) {
      notifyListeners();
    });
  }

  void _handleMessage(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? payload = message.data['payload'];

    if (type == 'DEVICE_LINK') {
      if (payload != null && payload.isNotEmpty) {
        debugPrint("DEVICE_LINK 수신: 새로운 토큰 저장 시도");
        addLinkedToken(payload);
        _notificationService.showLocalNotification("기기 연결 완료", "새로운 기기와 연결되었습니다.");
      }
    } else if (type == '게임 시간 만료') {
      _notificationService.showLocalNotification(
        message.notification?.title ?? "게임 시간 만료",
        message.notification?.body ?? "자녀의 게임 시간이 만료되었습니다.",
      );
    } else if (type == 'ADD_TIME') {
      if (payload != null) {
        int minutes = int.tryParse(payload) ?? 0;
        _accumulatedSeconds += minutes * 60;
        _saveSeconds();
        notifyListeners();
        _notificationService.showLocalNotification("시간 추가", "부모님에 의해 $minutes분이 추가되었습니다.");
      }
    } else if (type == 'REMOVE_TIME') {
      if (payload != null) {
        int minutes = int.tryParse(payload) ?? 0;
        _accumulatedSeconds -= minutes * 60;
        if (_accumulatedSeconds < 0) _accumulatedSeconds = 0;
        _saveSeconds();
        notifyListeners();
        _notificationService.showLocalNotification("시간 제거", "부모님에 의해 $minutes분이 제거되었습니다.");
      }
    } else if (type == 'START_STUDY') {
      startStudy();
      _notificationService.showLocalNotification("공부 시작", "부모님에 의해 공부가 시작되었습니다.");
    } else if (type == 'START_GAME') {
      if (accumulatedSeconds > 0) {
        startGame();
        _notificationService.showLocalNotification("게임 시작", "부모님에 의해 게임이 시작되었습니다.");
      } else {
        _notificationService.showLocalNotification("게임 시작 실패", "사용 가능한 시간이 없습니다.");
      }
    } else if (type == 'STOP_TIMER') {
      stopStudy();
      stopGame();
      _notificationService.showLocalNotification("타이머 정지", "부모님에 의해 모든 활동이 중단되었습니다.");
    } else if (type == 'REQUEST_STATUS') {
      if (payload != null && payload.isNotEmpty) {
        _sendReportStatus(payload);
      }
    } else if (type == 'REPORT_STATUS') {
      if (payload != null) {
        try {
          final data = jsonDecode(payload);
          final String? fromToken = data['from'];
          if (fromToken != null) {
            _remoteDevicesStatus[fromToken] = data;
            notifyListeners();
          }
        } catch (e) {
          debugPrint("REPORT_STATUS 처리 에러: $e");
        }
      }
    }
  }

  Future<void> _sendReportStatus(String targetToken) async {
    final statusData = {
      'from': fcmToken,
      'accumulatedSeconds': _accumulatedSeconds,
      'isStudying': _isStudying,
      'isPlaying': _isPlaying,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _notificationService.sendPushNotification(targetToken, "REPORT_STATUS", jsonEncode(statusData));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _accumulatedSeconds = prefs.getInt('accumulatedSeconds') ?? 0;
    _password = prefs.getString('parentPassword');
    _linkedTokens = prefs.getStringList('linkedTokens') ?? [];
    notifyListeners();
  }

  Future<void> _saveLinkedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('linkedTokens', _linkedTokens);
  }

  Future<void> addLinkedToken(String token) async {
    if (!_linkedTokens.contains(token)) {
      _linkedTokens.add(token);
      await _saveLinkedTokens();
      notifyListeners();
      if (fcmToken != null) {
        _notificationService.sendPushNotification(token, "DEVICE_LINK", fcmToken!);
      }
    }
  }

  Future<void> adjustRemoteTime(String targetToken, int minutes) async {
    if (minutes > 0) {
      await _notificationService.sendPushNotification(targetToken, "ADD_TIME", minutes.toString());
    } else if (minutes < 0) {
      await _notificationService.sendPushNotification(targetToken, "REMOVE_TIME", (minutes.abs()).toString());
    }
  }

  Future<void> remoteStartStudy(String targetToken) async {
    await _notificationService.sendPushNotification(targetToken, "START_STUDY", "START");
  }

  Future<void> remoteStartGame(String targetToken) async {
    await _notificationService.sendPushNotification(targetToken, "START_GAME", "START");
  }

  Future<void> remoteStopTimer(String targetToken) async {
    await _notificationService.sendPushNotification(targetToken, "STOP_TIMER", "STOP");
  }

  Future<void> requestRemoteStatus(String targetToken) async {
    if (fcmToken != null) {
      await _notificationService.sendPushNotification(targetToken, "REQUEST_STATUS", fcmToken!);
    }
  }

  Future<void> _saveSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accumulatedSeconds', _accumulatedSeconds);
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parentPassword', password);
    _password = password;
    notifyListeners();
  }

  bool checkPassword(String input) {
    return _password == input;
  }

  void addMinutes(int minutes) {
    _accumulatedSeconds += minutes * 60;
    if (_accumulatedSeconds < 0) _accumulatedSeconds = 0;
    _saveSeconds();
    notifyListeners();
  }

  void startStudy() {
    if (_isStudying || _isPlaying) return;
    _isStudying = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _accumulatedSeconds++;
      _saveSeconds();
      notifyListeners();
    });
    notifyListeners();
  }

  void stopStudy() {
    if (!_isStudying) return;
    _isStudying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void startGame() {
    if (_isPlaying || _isStudying || _accumulatedSeconds <= 0) return;
    _isPlaying = true;
    _initialGameSeconds = _accumulatedSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_accumulatedSeconds > 0) {
        _accumulatedSeconds--;
        _saveSeconds();
        notifyListeners();
      } else {
        stopGame();
        _playAlarm();
        _notifyGameExpired();
      }
    });
    notifyListeners();
  }

  void _notifyGameExpired() {
    for (String token in _linkedTokens) {
      _notificationService.sendPushNotification(token, "게임 시간 만료", "자녀의 게임 시간이 만료되었습니다.");
    }
  }

  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.play(AssetSource('alarm.mp3'));
      Future.delayed(const Duration(seconds: 5), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      debugPrint("알람 재생 실패: $e");
    }
  }

  void stopGame() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _initialGameSeconds = 0;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
