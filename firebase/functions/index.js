const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ─── Stripe ───────────────────────────────────────────────────────────────────
// Set your Stripe secret key:
//   firebase functions:config:set stripe.secret="sk_test_YOUR_SECRET_KEY"
// Then deploy: firebase deploy --only functions
const stripe = require("stripe")(
  (functions.config().stripe && functions.config().stripe.secret) ||
  "sk_test_REPLACE_WITH_YOUR_STRIPE_TEST_SECRET_KEY"
);

exports.createStripePaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
  }

  const { amount, currency, orderId } = data;
  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid amount.");
  }

  // BHD/KWD/JOD/OMR are 3-decimal currencies (1 BHD = 1000 fils)
  const threeDecimal = ["bhd", "jod", "kwd", "omr", "tnd"];
  const zeroDecimal  = ["jpy", "krw", "vnd", "xaf", "xof"];
  const cur = (currency || "bhd").toLowerCase();

  let units;
  if (zeroDecimal.includes(cur))  units = Math.round(amount);
  else if (threeDecimal.includes(cur)) units = Math.round(amount * 1000);
  else units = Math.round(amount * 100);

  const intent = await stripe.paymentIntents.create({
    amount:   units,
    currency: cur,
    metadata: { orderId: orderId || "", userId: context.auth.uid },
  });

  return { clientSecret: intent.client_secret };
});

// ─── Auth cleanup ─────────────────────────────────────────────────────────────
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const firestore = admin.firestore();
  const userRef = firestore.doc("users/" + user.uid);
});
