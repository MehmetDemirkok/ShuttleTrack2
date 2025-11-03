const functions = require('firebase-functions');
const admin = require('firebase-admin');

try {
  admin.initializeApp();
} catch (e) {
  // already initialized in emulator
}

exports.createDriverUser = functions.region('us-central1').https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Giriş gerekli');
  }

  const callerUid = context.auth.uid;
  const callerSnap = await admin.firestore().doc(`userProfiles/${callerUid}`).get();
  const caller = callerSnap.data();
  if (!caller || caller.userType !== 'company_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Sadece şirket yetkilisi');
  }

  const { email, fullName, companyId, defaultPassword } = data || {};
  if (!email || !fullName || !companyId) {
    throw new functions.https.HttpsError('invalid-argument', 'Eksik alan');
  }
  if (caller.companyId !== companyId) {
    throw new functions.https.HttpsError('permission-denied', 'Farklı şirket');
  }

  // Eğer e-posta zaten Auth'ta varsa hata ver
  let existing = null;
  try {
    existing = await admin.auth().getUserByEmail(email);
  } catch (e) {
    existing = null;
  }
  if (existing) {
    throw new functions.https.HttpsError('already-exists', 'Bu e‑posta zaten kayıtlı');
  }

  const user = await admin.auth().createUser({
    email,
    password: defaultPassword || '000000',
    displayName: fullName,
    disabled: false
  });

  const now = new Date();
  await admin.firestore().doc(`userProfiles/${user.uid}`).set({
    id: user.uid,
    userId: user.uid,
    userType: 'driver',
    email,
    fullName,
    companyId,
    isActive: true,
    createdAt: now,
    updatedAt: now,
    lastLoginAt: null
  }, { merge: true });

  return { uid: user.uid };
});


