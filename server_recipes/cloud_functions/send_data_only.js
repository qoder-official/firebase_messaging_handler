'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendDataOnlyBridge(token) {
  const message = {
    token,
    data: {
      title: 'Inventory back in stock',
      body: 'SKU #48319 is available again.',
      deeplink: 'app://inventory/48319',
      channelId: 'inventory_updates',
      priority: 'high',
      analytics: JSON.stringify({
        campaign: 'restock_alert',
        sku: '48319',
      }),
      actions: JSON.stringify([
        {
          id: 'open',
          title: 'Open',
          payload: { screen: 'inventory', sku: '48319' },
        },
        {
          id: 'dismiss',
          title: 'Dismiss',
          destructive: true,
        },
      ]),
    },
    android: {
      priority: 'high',
    },
    apns: {
      headers: {
        'apns-priority': '5',
      },
      payload: {
        aps: {
          'content-available': 1,
        },
      },
    },
  };

  const messageId = await admin.messaging().send(message);
  console.log('Sent data-only bridge message:', messageId);
}

sendDataOnlyBridge(process.env.FCM_TOKEN).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
