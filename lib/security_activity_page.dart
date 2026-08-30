import 'package:flutter/material.dart';

import 'security_activity_log.dart';

class SecurityActivityPage extends StatelessWidget {
  const SecurityActivityPage({super.key});

  String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: securityActivityLog,
      builder: (context, _) {
        final events = securityActivityLog.events;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Security Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (events.isNotEmpty)
                IconButton(
                  tooltip: 'Clear activity',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => securityActivityLog.clear(),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Activity & Events',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review recent activity recorded by this app on this device.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Local activity record',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'This is not a real-time Firebase audit log or cloud security monitoring service. Records are temporary and stay in app memory.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (events.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.history, color: Colors.grey),
                        title: Text('No activity recorded yet'),
                        subtitle: Text(
                          'Activity will appear here after supported actions are recorded.',
                        ),
                      ),
                    )
                  else
                    ...events.map(
                      (event) => Card(
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(
                            Icons.shield_outlined,
                            color: Colors.green,
                            size: 32,
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${event.description}\n${formatDateTime(event.occurredAt)}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
