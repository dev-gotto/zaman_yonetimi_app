import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_provider.dart';

enum TimerMode { countdown, countUp }

enum TimerStatus { idle, running, paused, finished }

class TimerState {
  final TimerMode mode;
  final TimerStatus status;
  final int totalSeconds; // Geri sayımda başlangıç süresi
  final int remainingSeconds; // Geri sayımda kalan süre
  final int elapsedSeconds; // Kronometrede geçen süre
  final String? taskId;
  final String? taskTitle;

  const TimerState({
    this.mode = TimerMode.countdown,
    this.status = TimerStatus.idle,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.taskId,
    this.taskTitle,
  });

  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    int? elapsedSeconds,
    String? taskId,
    String? taskTitle,
    bool clearTask = false,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      taskId: clearTask ? null : (taskId ?? this.taskId),
      taskTitle: clearTask ? null : (taskTitle ?? this.taskTitle),
    );
  }
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const TimerState();
  }

  void startCountdown(int minutes, {String? taskId, String? taskTitle}) {
    _ticker?.cancel();
    final totalSeconds = minutes * 60;
    state = TimerState(
      mode: TimerMode.countdown,
      status: TimerStatus.running,
      totalSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
      taskId: taskId,
      taskTitle: taskTitle,
    );
    _startTicking();
  }

  void startCountUp({String? taskId, String? taskTitle}) {
    _ticker?.cancel();
    state = TimerState(
      mode: TimerMode.countUp,
      status: TimerStatus.running,
      elapsedSeconds: 0,
      taskId: taskId,
      taskTitle: taskTitle,
    );
    _startTicking();
  }

  void _startTicking() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.mode == TimerMode.countdown) {
        if (state.remainingSeconds <= 1) {
          _ticker?.cancel();
          state = state.copyWith(
            status: TimerStatus.finished,
            remainingSeconds: 0,
          );
          _notifyFinished();
        } else {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        }
      } else {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _notifyFinished() {
    final notificationService = ref.read(notificationServiceProvider);
    final title = state.taskTitle != null
        ? '${state.taskTitle} - süre doldu'
        : 'Sayaç süresi doldu';
    notificationService.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: 'Belirlediğin süre tamamlandı.',
    );
  }

  void pause() {
    if (state.status != TimerStatus.running) return;
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() {
    if (state.status != TimerStatus.paused) return;
    state = state.copyWith(status: TimerStatus.running);
    _startTicking();
  }

  void reset() {
    _ticker?.cancel();
    state = const TimerState();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);