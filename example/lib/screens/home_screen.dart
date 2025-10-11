import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:clipboard/clipboard.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      Provider.of<NotificationProvider>(context, listen: false),
    );
    _notificationService.initialize();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Messaging Handler Showcase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.copy),
                onPressed: provider.fcmToken != null
                    ? () async {
                        await FlutterClipboard.copy(provider.fcmToken!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('FCM token Copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                tooltip: 'Copy FCM Token',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _notificationService.clearAllNotifications(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(provider),

                const SizedBox(height: 24),

                // Badge Management
                _buildBadgeManagement(provider),

                const SizedBox(height: 24),

                // Feature Showcase
                const Text(
                  '🚀 Feature Showcase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Core Features
                _buildFeatureSection(
                  title: '📱 Core Features',
                  features: [
                    FeatureCard(
                      title: 'Send Test Notification',
                      description:
                          'Send a notification with interactive actions',
                      icon: Icons.send,
                      color: Colors.blue,
                      onTap: _notificationService.sendTestNotification,
                    ),
                    FeatureCard(
                      title: 'Schedule Notification',
                      description:
                          'Schedule a notification for 1 minute from now',
                      icon: Icons.schedule,
                      color: Colors.green,
                      onTap: _notificationService.scheduleTestNotification,
                    ),
                    FeatureCard(
                      title: 'Schedule Recurring',
                      description:
                          'Schedule daily recurring notifications',
                      icon: Icons.repeat,
                      color: Colors.orange,
                      onTap: _notificationService.scheduleRecurringNotification,
                    ),
                    FeatureCard(
                      title: 'Create Notification Group',
                      description:
                          'Group multiple notifications together',
                      icon: Icons.group_work,
                      color: Colors.purple,
                      onTap: _notificationService.createNotificationGroup,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Advanced Features
                _buildFeatureSection(
                  title: '⚡ Advanced Features',
                  features: [
                    FeatureCard(
                      title: 'Update Badges',
                      description:
                          'Update badge counts for iOS and Android',
                      icon: Icons.badge,
                      color: Colors.teal,
                      onTap: _notificationService.updateBadges,
                    ),
                    FeatureCard(
                      title: 'Custom Sounds',
                      description:
                          'Create notification channel with custom sound',
                      icon: Icons.music_note,
                      color: Colors.pink,
                      onTap: () async {
                        await _notificationService.messagingHandler
                            .createCustomSoundChannel(
                          channelId: 'music_channel',
                          channelName: 'Music Notifications',
                          channelDescription:
                              'Notifications with custom sound',
                          soundFileName: 'default', // Use default for demo
                          importance: NotificationImportanceEnum.high,
                          priority: NotificationPriorityEnum.high,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Notifications List
                if (provider.notifications.isNotEmpty) ...[
                  const Text(
                    '📨 Recent Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...provider.notifications
                      .take(5)
                      .map(
                        (notification) =>
                            NotificationCard(notification: notification),
                      ),
                ],

                const SizedBox(height: 32),

                // Initial Notification (if any)
                if (provider.initialNotification != null) ...[
                  const Text(
                    '🚀 Initial Notification (App Launch)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  NotificationCard(
                    notification: provider.initialNotification!,
                    isInitial: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 How to Test:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Tap any feature button above to trigger notifications\n'
                        '2. Send push notifications from Firebase Console\n'
                        '3. Use FCM tokens for targeted notifications\n'
                        '4. Check the logs for detailed information',
                      ),
                      const SizedBox(height: 8),
                      Consumer<NotificationProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            'FCM Token: ${provider.fcmToken ?? 'Not available yet'}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(NotificationProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  provider.isInitialized ? Icons.check_circle : Icons.error,
                  color: provider.isInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isInitialized
                      ? 'Firebase Messaging Handler Active'
                      : 'Initializing...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provider.isInitialized
                  ? '✅ Ready to receive and handle notifications'
                  : '⏳ Setting up notification handling...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeManagement(NotificationProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏷️ Badge Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('iOS Badge'),
                      Text(
                        provider.iosBadgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Android Badge'),
                      Text(
                        provider.androidBadgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required List<FeatureCard> features,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: features),
      ],
    );
  }

  void _showAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Events'),
        content: const Text(
          'Check your console/logs for detailed analytics events including:\n\n'
          '• notification_received\n'
          '• notification_clicked\n'
          '• notification_action\n'
          '• notification_scheduled\n'
          '• fcm_token events\n\n'
          'All events include platform, timestamp, and relevant metadata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
