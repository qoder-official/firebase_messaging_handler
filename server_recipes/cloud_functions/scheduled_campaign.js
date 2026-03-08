'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendTopicCampaign() {
  const message = {
    topic: 'weekly_digest',
    notification: {
      title: 'Weekly digest is ready',
      body: 'Top highlights and unread updates are waiting.',
    },
    data: {
      deeplink: 'app://inbox/weekly-digest',
      analytics: JSON.stringify({
        campaign: 'weekly_digest',
        audience: 'topic_subscribers',
      }),
    },
  };

  const messageId = await admin.messaging().send(message);
  console.log('Sent topic campaign:', messageId);
}

sendTopicCampaign().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
