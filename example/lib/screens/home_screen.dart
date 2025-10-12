import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/notification_provider.dart';
import '../router/app_router.dart';
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
      "deep_link": "app://notifications/showcase",
      "fcmh_inapp": "{\\"id\\":\\"version_prompt_demo\\",\\"templateId\\":\\"builtin_version_prompt\\",\\"trigger\\":\\"immediate\\",\\"content\\":{\\"title\\":\\"Update ready\\",\\"message\\":\\"Ship the new experience with background delivery controls.\\",\\"primaryLabel\\":\\"View changelog\\",\\"secondaryLabel\\":\\"Maybe later\\",\\"dismissLabel\\":\\"Skip\\"}}"
    }
  }
}
''';

const Map<String, String> _templateSamples = {
  'Version Prompt Dialog': '''
{
  "id": "demo-version",
  "templateId": "builtin_generic",
  "trigger": "immediate",
  "content": {
    "layout": "dialog",
    "title": "Update available",
    "subtitle": "Version 2.0 ships with quiet hours",
    "body": "Install the latest build to unlock throttling controls and background listeners.",
    "imageUrl": "https://via.placeholder.com/600x320/111827/ffffff?text=Version+2.0",
    "buttons": [
      {"id": "primary", "label": "View changelog", "style": "filled"},
      {"id": "secondary", "label": "Remind me later", "style": "outlined", "dismissOnly": true}
    ],
    "blurSigma": 18,
    "barrierColor": "#33000000"
  }
}
''',
  'Promo Banner': '''
{
  "id": "demo-banner",
  "templateId": "builtin_generic",
  "trigger": "immediate",
  "content": {
    "layout": "banner",
    "position": "top",
    "title": "Flash Sale",
    "body": "Upgrade to Pro in the next 30 minutes and save 50%.",
    "backgroundColor": "#111827",
    "textColor": "#F9FAFB",
    "autoDismissSeconds": 6,
    "buttons": [
      {"id": "cta", "label": "View offer", "style": "filled"}
    ]
  }
}
''',
  'Survey Bottom Sheet': '''
{
  "id": "demo-bottom-sheet",
  "templateId": "builtin_generic",
  "trigger": "immediate",
  "content": {
    "layout": "bottom_sheet",
    "title": "How are we doing?",
    "html": "<p>We are rolling out background delivery controls. Tell us how excited you are!</p>",
    "buttons": [
      {"id": "love_it", "label": "Love it", "style": "filled"},
      {"id": "needs_work", "label": "Needs work", "style": "text"}
    ]
  }
}
''',
  'Tooltip Tip': '''
{
  "id": "demo-tooltip",
  "templateId": "builtin_generic",
  "trigger": "immediate",
  "content": {
    "layout": "tooltip",
    "position": "bottom",
    "title": "Pro tip",
    "body": "Long-press a notification in the timeline to jump to the detail inspector.",
    "backgroundColor": "#1E293B",
    "buttons": [
      {"id": "dismiss", "label": "Got it", "style": "text", "dismissOnly": true}
    ],
    "autoDismissSeconds": 5
  }
}
''',
  'Carousel Survey': '''
{
  "id": "demo-carousel",
  "templateId": "builtin_generic",
  "trigger": "immediate",
  "content": {
    "layout": "carousel",
    "pages": [
      {
        "title": "Quiet hours",
        "body": "We are preparing quiet-hour controls. Would you use them?",
        "imageUrl": "https://via.placeholder.com/600x320/0F172A/ffffff?text=Quiet+Hours",
        "buttons": [
          {"id": "yes", "label": "Absolutely", "style": "filled"},
          {"id": "later", "label": "Tell me later", "style": "outlined", "dismissOnly": true}
        ]
      },
      {
        "title": "Background actions",
        "body": "How important is handling notification actions while the app is killed?",
        "buttons": [
          {"id": "critical", "label": "Critical", "style": "filled"},
          {"id": "nice_to_have", "label": "Nice to have", "style": "text"}
        ]
      }
    ]
  }
}
'''
};

class _HomeScreenState extends State<HomeScreen> {
  late example.NotificationService _notificationService;
  bool _templatesRegistered = false;
  late TextEditingController _templateController;
  String _selectedTemplate = _templateSamples.keys.first;

  @override
  void initState() {
    super.initState();
    _notificationService = example.NotificationService(
      Provider.of<NotificationProvider>(context, listen: false),
      rootNavigatorKey,
    );
    _templateController =
        TextEditingController(text: _templateSamples[_selectedTemplate]);
    _initializeNotifications();
    _registerInAppTemplates();
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

  void _registerInAppTemplates() {
    if (_templatesRegistered) {
      return;
    }

    FirebaseMessagingHandler.instance.registerInAppNotificationTemplates({
      'builtin_generic': BuiltInInAppTemplates.generic(
        onAction: (actionId, data) {
          Provider.of<NotificationProvider>(context, listen: false)
              .addActivity('Template action: $actionId');
        },
      ),
    });

    _templatesRegistered = true;
  }

  @override
  void dispose() {
    _notificationService.dispose();
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Firebase Messaging Handler Showcase',
          style: TextStyle(fontSize: 18),
        ),
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
                  title: 'In-App Notification Templates',
                  subtitle:
                      'Trigger custom in-app templates with different styles.',
                  features: [
                    FeatureCard(
                      title: 'Welcome Template',
                      description:
                          'Shows a welcome banner with onboarding content.',
                      icon: Icons.waving_hand,
                      color: Colors.green,
                      onTap: _notificationService.triggerWelcomeTemplate,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Welcome Template',
                        body:
                            'Triggers an in-app welcome template that can be used for onboarding flows and user greetings.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Promotion Template',
                      description:
                          'Displays promotional content with call-to-action.',
                      icon: Icons.local_offer,
                      color: Colors.orange,
                      onTap: _notificationService.triggerPromotionTemplate,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Promotion Template',
                        body:
                            'Shows promotional banners with special offers and discount codes for marketing campaigns.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Alert Template',
                      description:
                          'Highlights important alerts and urgent messages.',
                      icon: Icons.warning,
                      color: Colors.red,
                      onTap: _notificationService.triggerAlertTemplate,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Alert Template',
                        body:
                            'Displays urgent alerts and important notifications that require immediate attention.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Success Template',
                      description:
                          'Celebrates successful actions and confirmations.',
                      icon: Icons.check_circle,
                      color: Colors.lightGreen,
                      onTap: _notificationService.triggerSuccessTemplate,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Success Template',
                        body:
                            'Shows success messages and confirmation banners for completed actions.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Info Template',
                      description:
                          'Provides helpful tips and informational content.',
                      icon: Icons.info,
                      color: Colors.blue,
                      onTap: _notificationService.triggerInfoTemplate,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Info Template',
                        body:
                            'Displays informational content, tips, and helpful guidance for users.',
                      ),
                    ),
                    FeatureCard(
                      title: 'Version Prompt',
                      description:
                          'Built-in dialog template for app update prompts.',
                      icon: Icons.system_update,
                      color: Colors.indigo,
                      onTap: _notificationService.triggerVersionPromptDemo,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'Version Prompt Template',
                        body:
                            'Built-in template for encouraging users to update the app. Shows a full-screen dialog with customizable content.',
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
                      title: 'Version Prompt (In-App)',
                      description:
                          'Triggers the built-in version dialog powered by the in-app template kit.',
                      icon: Icons.system_update,
                      color: Colors.indigo,
                      onTap: _notificationService.triggerVersionPromptDemo,
                      onInfoTap: () => _showFeatureInfo(
                        context,
                        title: 'In-App Templates',
                        body:
                            'Demonstrates the bundled version prompt template rendered through the overlay controller. '
                            'You can drive this via a silent FCM payload using templateId=builtin_version_prompt.',
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
                _buildTemplatePlayground(provider),
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
              'Welcome to our Notification Testing Application',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This example showcases every optional feature in the Firebase Messaging Handler. '
              'Follow the three-step loop below and watch analytics, badges, navigation, and in-app templates respond in real time.',
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
                  onTap: () => _openTimelineDetails(notification),
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
            onTap: () => _openTimelineDetails(provider.initialNotification!),
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

  Widget _buildTemplatePlayground(NotificationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Template Playground',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate silent FCM payloads and preview dialog, banner, bottom sheet, tooltip, and carousel layouts.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTemplate,
                    decoration: const InputDecoration(
                      labelText: 'Sample payload',
                      border: OutlineInputBorder(),
                    ),
                    items: _templateSamples.keys
                        .map(
                          (name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedTemplate = value;
                        _templateController.text =
                            _templateSamples[value] ?? _templateController.text;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Reset sample',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _templateController.text =
                          _templateSamples[_selectedTemplate] ?? '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _templateController,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Template JSON',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _triggerTemplateFromJson,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Trigger Template'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: these samples map directly to the payload structure described in the README.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

  void _clearTimeline(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Timeline'),
        content: const Text(
          'This will remove stored notifications and activity entries from the local timeline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.clearTimelineCache();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Timeline cleared'),
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

  void _openTimelineDetails(NotificationData data) {
    _notificationService.openScenarioFromTimeline(data);
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
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

  Future<void> _triggerTemplateFromJson() async {
    try {
      await _notificationService.triggerTemplateFromJson(
        _templateController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template triggered successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template trigger failed: $error')),
      );
    }
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
