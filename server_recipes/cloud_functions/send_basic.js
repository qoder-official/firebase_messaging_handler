'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendBasicPush(token) {
  const message = {
    token,
    notification: {
      title: 'Order shipped',
      body: 'Track package #A-1042 in the app.',
    },
    data: {
      deeplink: 'app://orders/A-1042',
      analytics: JSON.stringify({
        campaign: 'shipping_update',
        source: 'cloud_function',
      }),
    },
  };

  const messageId = await admin.messaging().send(message);
  console.log('Sent basic push:', messageId);
}

sendBasicPush(process.env.FCM_TOKEN).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
