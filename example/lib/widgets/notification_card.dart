import 'package:flutter/material.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';

class NotificationCard extends StatelessWidget {
  final NotificationData notification;
  final bool isInitial;

  const NotificationCard({
    super.key,
    required this.notification,
    this.isInitial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInitial ? Icons.launch : Icons.notifications,
                  size: 16,
                  color: isInitial ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title ?? 'Notification',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    notification.type.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification.body ?? 'No body',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Payload: ${notification.payload.length} items',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  notification.timestamp != null
                      ? '${notification.timestamp!.hour}:${notification.timestamp!.minute.toString().padLeft(2, '0')}'
                      : 'No timestamp',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (notification.actions != null &&
                notification.actions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Actions: ${notification.actions!.map((a) => a.title).join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
            if (notification.badgeCount != null) ...[
              const SizedBox(height: 4),
              Text(
                'Badge: ${notification.badgeCount}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationTypeEnum type) {
    switch (type) {
      case NotificationTypeEnum.foreground:
        return Colors.blue;
      case NotificationTypeEnum.background:
        return Colors.orange;
      case NotificationTypeEnum.terminated:
        return Colors.green;
    }
  }
}