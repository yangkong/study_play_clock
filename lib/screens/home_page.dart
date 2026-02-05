import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_provider.dart';
import '../widgets/analog_clock.dart';
import 'parent_menu_page.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showParentAuthPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentMenuPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('STUDY PLAY CLOCK'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showParentAuthPage(context),
          ),
        ],
      ),
      body: Consumer<TimeProvider>(
        builder: (context, timeProvider, child) {
          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                      child: AnalogClock(
                        totalSeconds: timeProvider.accumulatedSeconds,
                        initialSeconds: timeProvider.initialGameSeconds,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _formatTime(timeProvider.accumulatedSeconds),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        ElevatedButton(
                          onPressed: timeProvider.isPlaying 
                            ? null 
                            : (timeProvider.isStudying ? timeProvider.stopStudy : timeProvider.startStudy),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: timeProvider.isStudying ? Colors.red[100] : Colors.green[100],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(timeProvider.isStudying ? Icons.stop : Icons.play_arrow),
                              const SizedBox(width: 8),
                              Text(timeProvider.isStudying ? '공부 중단' : '공부 시작'),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: timeProvider.isStudying || (timeProvider.accumulatedSeconds <= 0 && !timeProvider.isPlaying)
                            ? null 
                            : (timeProvider.isPlaying ? timeProvider.stopGame : timeProvider.startGame),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: timeProvider.isPlaying ? Colors.red[100] : Colors.blue[100],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(timeProvider.isPlaying ? Icons.videogame_asset_off : Icons.videogame_asset),
                              const SizedBox(width: 8),
                              Text(timeProvider.isPlaying ? '게임 중단' : '게임 시작'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timeProvider.accumulatedSeconds <= 0 && !timeProvider.isStudying && !timeProvider.isPlaying)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        '게임을 하려면 먼저 공부를 해서 시간을 모으세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
