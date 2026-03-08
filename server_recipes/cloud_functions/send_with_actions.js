'use strict';

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function sendNotificationWithActions(token) {
  const message = {
    token,
    notification: {
      title: 'New support ticket',
      body: 'Reply or open the ticket from the notification.',
    },
    data: {
      category: 'support_ticket',
      deeplink: 'app://support/tickets/12345',
      analytics: JSON.stringify({
        campaign: 'support_reengage',
        ticketId: '12345',
      }),
      actions: JSON.stringify([
        {
          id: 'reply',
          title: 'Reply',
          payload: { ticketId: '12345', action: 'reply' },
        },
        {
          id: 'open',
          title: 'Open',
          payload: { ticketId: '12345', action: 'open' },
        },
      ]),
    },
  };

  const messageId = await admin.messaging().send(message);
  console.log('Sent notification with actions:', messageId);
}

sendNotificationWithActions(process.env.FCM_TOKEN).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
