import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/time_provider.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/remote_status_info.dart';

class ParentMenuPage extends StatefulWidget {
  const ParentMenuPage({super.key});

  @override
  State<ParentMenuPage> createState() => _ParentMenuPageState();
}

class _ParentMenuPageState extends State<ParentMenuPage> {
  bool _isAuthenticated = false;
  String _inputPassword = '';
  String _firstPassword = '';
  String _secondPassword = '';
  bool _isSettingPassword = false;
  bool _isConfirmingPassword = false;

  @override
  void initState() {
    super.initState();
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    if (!timeProvider.hasPassword) {
      _isSettingPassword = true;
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_isSettingPassword) {
        if (_isConfirmingPassword) {
          if (_secondPassword.length < 4) _secondPassword += number;
        } else {
          if (_firstPassword.length < 4) _firstPassword += number;
        }
      } else {
        if (_inputPassword.length < 4) {
          _inputPassword += number;
          if (_inputPassword.length == 4) {
            final timeProvider = Provider.of<TimeProvider>(context, listen: false);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (timeProvider.checkPassword(_inputPassword)) {
                setState(() {
                  _isAuthenticated = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호가 틀렸습니다')),
                );
                setState(() {
                  _inputPassword = '';
                });
              }
            });
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_isSettingPassword) {
        if (_isConfirmingPassword) {
          if (_secondPassword.isNotEmpty) {
            _secondPassword = _secondPassword.substring(0, _secondPassword.length - 1);
          }
        } else {
          if (_firstPassword.isNotEmpty) {
            _firstPassword = _firstPassword.substring(0, _firstPassword.length - 1);
          }
        }
      } else {
        if (_inputPassword.isNotEmpty) {
          _inputPassword = _inputPassword.substring(0, _inputPassword.length - 1);
        }
      }
    });
  }

  void _onClear() {
    setState(() {
      if (_isSettingPassword) {
        if (_isConfirmingPassword) {
          _secondPassword = '';
        } else {
          _firstPassword = '';
        }
      } else {
        _inputPassword = '';
      }
    });
  }

  void _showQRCodeDialog(BuildContext context, String? token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 QR 코드'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: token == null
              ? const Center(child: Text('FCM 토큰을 불러오는 중...'))
              : QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showQRScannerDialog(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('QR 코드 스캔'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null) {
                    Provider.of<TimeProvider>(context, listen: false).addLinkedToken(code);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('기기가 성공적으로 연결되었습니다.')),
                    );
                    break;
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 필요합니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated && !_isSettingPassword) {
      return Scaffold(
        appBar: AppBar(title: const Text('부모 인증')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('비밀번호 4자리를 입력하세요.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              _buildPasswordDots(_inputPassword),
              const SizedBox(height: 40),
              NumericKeypad(
                onNumberPressed: _onNumberPressed,
                onDeletePressed: _onDelete,
                onClearPressed: _onClear,
              ),
            ],
          ),
        ),
      );
    }

    if (_isSettingPassword) {
      String currentInput = _isConfirmingPassword ? _secondPassword : _firstPassword;
      String displayTitle = _isConfirmingPassword ? '비밀번호 확인' : '비밀번호 초기 설정';
      String instruction = _isConfirmingPassword ? '설정한 비밀번호를 다시 입력하세요.' : '최초 1회 비밀번호 4자리를 설정합니다.';

      return Scaffold(
        appBar: AppBar(title: Text(displayTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(instruction, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              _buildPasswordDots(currentInput),
              const SizedBox(height: 40),
              NumericKeypad(
                onNumberPressed: _onNumberPressed,
                onDeletePressed: _onDelete,
                onClearPressed: _onClear,
              ),
              const SizedBox(height: 20),
              if (currentInput.length == 4)
                ElevatedButton(
                  onPressed: () {
                    if (!_isConfirmingPassword) {
                      setState(() {
                        _isConfirmingPassword = true;
                      });
                    } else {
                      if (_firstPassword == _secondPassword) {
                        Provider.of<TimeProvider>(context, listen: false).setPassword(_firstPassword);
                        setState(() {
                          _isSettingPassword = false;
                          _isAuthenticated = true;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('비밀번호가 일치하지 않습니다. 다시 시도하세요.')),
                        );
                        setState(() {
                          _isConfirmingPassword = false;
                          _firstPassword = '';
                          _secondPassword = '';
                        });
                      }
                    }
                  },
                  child: Text(_isConfirmingPassword ? '설정 완료' : '다음'),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('부모 메뉴')),
      body: Consumer<TimeProvider>(
        builder: (context, timeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('현재 누적 시간: ${_formatTime(timeProvider.accumulatedSeconds)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => timeProvider.addMinutes(-10),
                              child: const Text('-10분'),
                            ),
                            ElevatedButton(
                              onPressed: () => timeProvider.addMinutes(10),
                              child: const Text('+10분'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text('원격 관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showQRCodeDialog(context, timeProvider.fcmToken),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('내 QR코드'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showQRScannerDialog(context),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('상대 QR코드 스캔'),
                    ),
                  ],
                ),
                if (timeProvider.linkedTokens.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const Divider(),
                  const Text('연결된 기기 시간 관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...timeProvider.linkedTokens.map((token) {
                    String shortToken = token.length > 10 ? '${token.substring(0, 5)}...${token.substring(token.length - 5)}' : token;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text('기기: $shortToken')),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () => timeProvider.requestRemoteStatus(token),
                              tooltip: '상태 새로고침',
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (timeProvider.remoteDevicesStatus.containsKey(token)) ...[
                              RemoteStatusInfo(
                                status: timeProvider.remoteDevicesStatus[token]!,
                                formatTime: _formatTime,
                              ),
                              const SizedBox(height: 8),
                            ],
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => timeProvider.adjustRemoteTime(token, 10),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('10분'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => timeProvider.adjustRemoteTime(token, -10),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text('10분'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => timeProvider.adjustRemoteTime(token, 30),
                                    icon: const Icon(Icons.add_circle, size: 18),
                                    label: const Text('30분'),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => timeProvider.remoteStartStudy(token),
                                    icon: const Icon(Icons.menu_book, size: 18),
                                    label: const Text('공부 시작'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => timeProvider.remoteStartGame(token),
                                    icon: const Icon(Icons.sports_esports, size: 18),
                                    label: const Text('게임 시작'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => timeProvider.remoteStopTimer(token),
                                    icon: const Icon(Icons.stop_circle, size: 18),
                                    label: const Text('정지'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordDots(String password) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < password.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.indigo : Colors.grey[300],
          ),
        );
      }),
    );
  }
}
