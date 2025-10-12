import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'dart:convert';

class TimelineDetailsScreen extends StatelessWidget {
  const TimelineDetailsScreen({super.key, required this.notification});

  final NotificationData notification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy payload JSON',
            onPressed: () => _copyPayload(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(context),
            const SizedBox(height: 24),
            _buildPayloadSection(context),
            if (notification.actions != null &&
                notification.actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildActionsSection(context),
            ],
            if (notification.metadata != null &&
                notification.metadata!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildMetadataSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Title', notification.title ?? 'N/A'),
            _buildInfoRow('Body', notification.body ?? 'N/A'),
            _buildInfoRow('Type', notification.type.name),
            _buildInfoRow('Message ID', notification.messageId ?? 'N/A'),
            _buildInfoRow('Sender ID', notification.senderId ?? 'N/A'),
            _buildInfoRow('Category', notification.category ?? 'N/A'),
            _buildInfoRow('Sound', notification.sound ?? 'N/A'),
            _buildInfoRow('Tag', notification.tag ?? 'N/A'),
            _buildInfoRow('Group Key', notification.groupKey ?? 'N/A'),
            _buildInfoRow(
              'Badge Count',
              notification.badgeCount?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Is Silent',
              notification.isSilent?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'From Terminated',
              notification.isFromTerminated.toString(),
            ),
            if (notification.timestamp != null)
              _buildInfoRow(
                'Timestamp',
                _formatTimestamp(notification.timestamp!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Raw Payload',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _copyPayload(context),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy JSON'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                _formatJson(notification.payload),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...notification.actions!.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action.destructive
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: action.destructive
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            action.destructive
                                ? Icons.warning
                                : Icons.touch_app,
                            color:
                                action.destructive ? Colors.red : Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            action.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  action.destructive ? Colors.red : Colors.blue,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            action.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      if (action.payload != null &&
                          action.payload!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Payload:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _formatJson(action.payload!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                _formatJson(notification.metadata!),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: value.contains('N/A') ? null : 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final localTime = timestamp.toLocal();

    // Always show HH:mm:ss format
    final timeString = '${localTime.hour.toString().padLeft(2, '0')}:'
        '${localTime.minute.toString().padLeft(2, '0')}:'
        '${localTime.second.toString().padLeft(2, '0')}';

    // Always include date in format: "9, Aug, 2025"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final dateString =
        '${localTime.day}, ${months[localTime.month - 1]}, ${localTime.year}';
    return '$dateString $timeString';
  }

  void _copyPayload(BuildContext context) {
    final jsonString = _formatJson(notification.payload);
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payload copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
