'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendRichMedia(token) {
  const imageUrl =
    'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80';

  const message = {
    token,
    notification: {
      title: 'New device drop',
      body: 'Tap to view the launch gallery.',
    },
    data: {
      image: imageUrl,
      deeplink: 'app://launches/device-drop',
      channelId: 'marketing',
      analytics: JSON.stringify({
        campaign: 'device_drop_launch',
        format: 'rich_media',
      }),
    },
    android: {
      notification: {
        imageUrl,
        channelId: 'marketing',
      },
    },
    apns: {
      fcmOptions: {
        imageUrl,
      },
    },
    webpush: {
      headers: {
        image: imageUrl,
      },
    },
  };

  const messageId = await admin.messaging().send(message);
  console.log('Sent rich media push:', messageId);
}

sendRichMedia(process.env.FCM_TOKEN).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
