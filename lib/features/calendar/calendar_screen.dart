import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/task_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksForDay = ref.watch(tasksForSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(selectedDateProvider.notifier).setDate(selectedDay);
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const Divider(height: 1),
          Expanded(
            child: tasksForDay.isEmpty
                ? const Center(child: Text('Bu gün için görev yok'))
                : ListView.builder(
                    itemCount: tasksForDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForDay[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: task.description != null
                            ? Text(task.description!)
                            : null,
                        trailing: Checkbox(
                          value: task.isCompleted,
                          onChanged: (_) {
                            ref
                                .read(taskListProvider.notifier)
                                .toggleComplete(task.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
