import 'package:flutter/material.dart';

class RemoteStatusInfo extends StatelessWidget {
  final Map<String, dynamic> status;
  final String Function(int) formatTime;

  const RemoteStatusInfo({
    super.key,
    required this.status,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    int seconds = status['accumulatedSeconds'] ?? 0;
    bool isStudying = status['isStudying'] ?? false;
    bool isPlaying = status['isPlaying'] ?? false;
    int? timestamp = status['timestamp'];
    
    String statusText = '정지';
    Color statusColor = Colors.grey;
    if (isStudying) {
      statusText = '공부 중';
      statusColor = Colors.green;
    } else if (isPlaying) {
      statusText = '게임 중';
      statusColor = Colors.blue;
    }

    String timeStr = formatTime(seconds);
    String lastUpdate = '';
    if (timestamp != null) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      lastUpdate = ' (업데이트: ${dt.hour}:${dt.minute.toString().padLeft(2, '0')})';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('남은 시간: $timeStr', style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          if (lastUpdate.isNotEmpty)
            Text(lastUpdate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
