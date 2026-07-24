import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task.dart';
import '../../core/providers/timer_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TimerScreen({super.key, this.task});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  TimerMode _selectedMode = TimerMode.countdown;
  int _selectedMinutes = 25;

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final isIdle = timerState.status == TimerStatus.idle;
    final isFinished = timerState.status == TimerStatus.finished;
    final isRunning = timerState.status == TimerStatus.running;
    final isPaused = timerState.status == TimerStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task != null ? 'Görev Sayacı' : 'Sayaç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (widget.task != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '"${widget.task!.title}" için çalışıyor',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            if (isIdle) ...[
              SegmentedButton<TimerMode>(
                segments: const [
                  ButtonSegment(
                    value: TimerMode.countdown,
                    label: Text('Geri Sayım'),
                    icon: Icon(Icons.hourglass_bottom),
                  ),
                  ButtonSegment(
                    value: TimerMode.countUp,
                    label: Text('Kronometre'),
                    icon: Icon(Icons.timer_outlined),
                  ),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (selection) {
                  setState(() => _selectedMode = selection.first);
                },
              ),
              const SizedBox(height: 24),
              if (_selectedMode == TimerMode.countdown) ...[
                Text(
                  '$_selectedMinutes dakika',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Slider(
                  value: _selectedMinutes.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  label: '$_selectedMinutes dk',
                  onChanged: (value) {
                    setState(() => _selectedMinutes = value.round());
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedMode == TimerMode.countdown) {
                    notifier.startCountdown(
                      _selectedMinutes,
                      taskId: widget.task?.id,
                      taskTitle: widget.task?.title,
                    );
                  } else {
                    notifier.startCountUp(
                      taskId: widget.task?.id,
                      taskTitle: widget.task?.title,
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Başlat'),
              ),
            ] else ...[
              Text(
                timerState.mode == TimerMode.countdown
                    ? _formatSeconds(timerState.remainingSeconds)
                    : _formatSeconds(timerState.elapsedSeconds),
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (isFinished)
                const Text(
                  'Süre tamamlandı! 🎉',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRunning)
                    ElevatedButton.icon(
                      onPressed: notifier.pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Duraklat'),
                    ),
                  if (isPaused)
                    ElevatedButton.icon(
                      onPressed: notifier.resume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Devam Et'),
                    ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: notifier.reset,
                    icon: const Icon(Icons.stop),
                    label: const Text('Sıfırla'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}