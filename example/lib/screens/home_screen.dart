import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/notification_provider.dart';
import '../router/app_router.dart';
import '../screens/timeline_details_screen.dart';
import '../services/notification_service.dart' as example;
import '../services/firebase_setup_service.dart';
import '../widgets/notification_card.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const String _firebaseConsoleUrl = 'https://console.firebase.google.com/';

const String _sampleFcmPayload = '''
{
  "message": {
    "token": "<device-fcm-token>",
    "notification": {
      "title": "Welcome to FMH",
      "body": "Tap to open the Scenario screen"
    },
    "data": {
      "campaign": "showcase",
      "step": "console-push",
      "deep_link": "app://notifications/showcase"
    }
  }
}
''';

class _HomeScreenState extends State<HomeScreen> {
  late example.NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = example.NotificationService(
      Provider.of<NotificationProvider>(context, listen: false),
      rootNavigatorKey,
    );
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();

    // Load cached timeline data
    if (mounted) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.loadCachedData();

      // Fetch FCM token directly if not set by callback
      if (provider.fcmToken == null) {
        try {
          final token = await FirebaseMessagingHandler.instance.getFcmToken();
          if (token != null && mounted) {
            provider.setFcmToken(token);
          }
        } catch (e) {
          debugPrint('Error fetching FCM token: $e');
        }
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View analytics events',
            onPressed: () => _showAnalyticsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'About the handler',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShowcaseBanner(context, provider),
                const SizedBox(height: 20),
                _buildApnsWarningBanner(context),
                const SizedBox(height: 20),
                _buildStatusStrip(provider),
                const SizedBox(height: 28),
                _buildFeatureSection(
                  title: 'Quick Start Scenarios',
                  subtitle: 'Run these to validate setup in under a minute.',
                  features: [
                    FeatureCard(
                      title: 'Send Interactive Push',
                      description:
                          'Triggers a foreground notification with action buttons.',
                      icon: Icons.send,
                      color: Colors.blue,
                      onTap: _notificationService.sendTestNotification,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Send Interactive Push',
                        body:
                            'Calls FirebaseMessagingHandler.showNotificationWithActions with a demo payload '
                            'to demonstrate interactive notifications and analytics events.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Schedule in 60 Seconds',
                      description:
                          'Demonstrates time-based delivery with analytics hooks.',
                      icon: Icons.schedule_send,
                      color: Colors.green,
                      onTap: _notificationService.scheduleTestNotification,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Schedule Notification',
                        body:
                            'Uses FirebaseMessagingHandler.scheduleNotification with a DateTime 60 seconds in the future. '
                            'We automatically manage timezone-safe delivery via flutter_local_notifications.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Daily Reminder Demo',
                      description:
                          'Configures a recurring daily notification at 09:00.',
                      icon: Icons.repeat,
                      color: Colors.orange,
                      onTap: _notificationService.scheduleRecurringNotification,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Recurring Notification',
                        body:
                            'Wraps scheduleRecurringNotification with daily cadence. The handler persists the cadence '
                            'and analytics logs each repetition under notification_scheduled.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Grouped Inbox',
                      description:
                          'Creates an Android notification group with three messages.',
                      icon: Icons.group_work,
                      color: Colors.purple,
                      onTap: _notificationService.createNotificationGroup,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Notification Groups',
                        body:
                            'Calls createNotificationGroup with three NotificationData instances so you can inspect '
                            'group summaries and taps inside the Scenario screen.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFeatureSection(
                  title: 'Power Features & Utilities',
                  subtitle: 'Fine tune presentation, badges and sound.',
                  features: [
                    FeatureCard(
                      title: 'Update Badges',
                      description:
                          'Sync iOS + Android badge counts to show parity.',
                      icon: Icons.confirmation_num,
                      color: Colors.teal,
                      onTap: _notificationService.updateBadges,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Badge Management',
                        body:
                            'Invokes setIOSBadgeCount and setAndroidBadgeCount through the handler and mirrors the '
                            'state in the provider so you can observe how parity is achieved.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Custom Sound Channel',
                      description:
                          'Build and register a sound-enabled notification channel.',
                      icon: Icons.music_note,
                      color: Colors.pink,
                      onTap: () async {
                        final notificationProvider =
                            Provider.of<NotificationProvider>(
                          context,
                          listen: false,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await _notificationService.messagingHandler
                            .createCustomSoundChannel(
                          channelId: 'music_channel',
                          channelName: 'Music Notifications',
                          channelDescription: 'Notifications with custom sound',
                          soundFileName: 'default',
                          importance: NotificationImportanceEnum.high,
                          priority: NotificationPriorityEnum.high,
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Custom sound channel registered.'),
                          ),
                        );
                        notificationProvider.addActivity(
                          'Registered custom sound channel',
                        );
                      },
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Custom Sounds',
                        body:
                            'Demonstrates createCustomSoundChannel to provision an Android channel with explicit sound, '
                            'importance and vibration configuration.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Clear Demo State',
                      description:
                          'Reset scheduled notifications, badges and timeline.',
                      icon: Icons.delete_sweep,
                      color: Colors.redAccent,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await _notificationService.clearAllNotifications();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Demo state cleared.')),
                        );
                      },
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Clear Demo State',
                        body:
                            'Cancels scheduled notifications, resets badges, clears local history and activity logs to give '
                            'you a fresh testing slate.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildNotificationStream(context, provider),
                const SizedBox(height: 28),
                _buildActivityTimeline(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShowcaseBanner(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final token = provider.fcmToken;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to your FCM Showcase',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This example showcases every optional feature in the Firebase Messaging Handler. '
              'Follow the three-step loop below and watch analytics, badges, and navigation respond in real time.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildShowcaseStep(
              context,
              icon: Icons.touch_app,
              title: 'Trigger a showcase',
              description:
                  'Tap a card under "Quick Start" to fire an instant notification, scheduling job, or grouped inbox.',
            ),
            _buildShowcaseStep(
              context,
              icon: Icons.cast,
              title: 'Send a remote push',
              description:
                  'Use the Firebase console payload template to target this device and inspect the Scenario screen.',
            ),
            _buildShowcaseStep(
              context,
              icon: Icons.analytics_outlined,
              title: 'Review insights',
              description:
                  'Open the analytics dialog, observe badge parity, and track activity timeline updates.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: token == null
                      ? null
                      : () => _copyFcmToken(context, token),
                  icon: const Icon(Icons.copy),
                  label: Text(
                    token == null ? 'Waiting for FCM token…' : 'Copy FCM token',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFirebaseConsole,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Firebase Console'),
                ),
                TextButton.icon(
                  onPressed: () => _showPayloadDialog(context),
                  icon: const Icon(Icons.code),
                  label: const Text('Sample payload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              token ?? 'Token will appear here once Firebase provides it.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApnsWarningBanner(BuildContext context) {
    // Only show warning if we continued without APNs
    if (!FirebaseSetupService.isIOSApnsError) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'iOS Notifications Limited',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'iOS notifications won\'t work without APNs setup. Android features work normally.',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStrip(NotificationProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 720) {
          return Row(
            children: [
              Expanded(child: _buildStatusCard(provider)),
              const SizedBox(width: 16),
              Expanded(child: _buildBadgeManagement(provider)),
            ],
          );
        }
        return Column(
          children: [
            _buildStatusCard(provider),
            const SizedBox(height: 16),
            _buildBadgeManagement(provider),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(NotificationProvider provider) {
    final initialized = provider.isInitialized;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  initialized ? Icons.verified : Icons.hourglass_top,
                  color: initialized ? Colors.green : Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    initialized
                        ? 'Handler ready – listening across foreground, background & terminated states.'
                        : 'Initializing Firebase Messaging Handler…',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              initialized
                  ? 'We requested permissions, registered notification channels, and wired analytics callbacks.'
                  : 'Permissions, channels and analytics callbacks are setting up – this typically takes a moment.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeManagement(NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badge Snapshot',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BadgePill(
                  label: 'iOS',
                  value: provider.iosBadgeCount,
                  color: Colors.blueAccent,
                ),
                _BadgePill(
                  label: 'Android',
                  value: provider.androidBadgeCount,
                  color: Colors.deepPurpleAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Use the “Update Badges” card to sync counts or “Clear Demo State” to reset.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    String? subtitle,
    required List<FeatureCard> features,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 16, runSpacing: 16, children: features),
      ],
    );
  }

  Widget _buildNotificationStream(
    BuildContext context,
    NotificationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Notification Timeline',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (provider.notifications.isNotEmpty)
              TextButton.icon(
                onPressed: () => _clearTimeline(context, provider),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.notifications.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Trigger one of the scenarios above or send a remote push from Firebase Console to populate the timeline.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          )
        else
          ...provider.notifications.take(10).map(
                (notification) => NotificationCard(
                  notification: notification,
                  onTap: () => _openTimelineDetails(context, notification),
                ),
              ),
        if (provider.initialNotification != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Launch Notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          NotificationCard(
            notification: provider.initialNotification!,
            isInitial: true,
            onTap: () =>
                _openTimelineDetails(context, provider.initialNotification!),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityTimeline(NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (provider.activityLog.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _clearActivityLog(context, provider),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.activityLog.isEmpty)
              Text(
                'Actions you take (sending, scheduling, clearing) will be logged here with timestamps.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              ...provider.activityLog.take(8).map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.bolt_outlined),
                      title: Text(entry.label),
                      subtitle: Text(_formatTimestamp(entry.timestamp)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyFcmToken(BuildContext context, String? token) async {
    if (token == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await FlutterClipboard.copy(token);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('FCM token copied to clipboard')),
    );
  }

  void _clearActivityLog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Activity Log'),
        content: const Text(
          'Are you sure you want to clear all activity entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearActivity();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity log cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openFirebaseConsole() {
    launchUrl(
      Uri.parse(_firebaseConsoleUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _showFeatureInfo(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPayloadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sample Firebase Console Payload'),
        content: SizedBox(
          width: double.maxFinite,
          child: SelectableText(
            _sampleFcmPayload,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => FlutterClipboard.copy(_sampleFcmPayload),
            child: const Text('Copy JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why Firebase Messaging Handler'),
        content: const Text(
          'This example app is backed entirely by firebase_messaging_handler. The plugin exposes a unified API for '
          'tokens, initial notification handling, foreground fallbacks, scheduling, grouping, analytics hooks, '
          'badge parity, and in-app templates. Explore each section to see how the optional pieces layer on top '
          'of the core click stream.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openTimelineDetails(BuildContext context, NotificationData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimelineDetailsScreen(notification: data),
      ),
    );
  }

  Future<void> _clearTimeline(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Timeline'),
        content: const Text(
          'This will permanently clear all notification timeline events and activity logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.clearTimelineCache();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Timeline cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
