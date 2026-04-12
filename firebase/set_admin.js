/**
 * set_admin.js  –  Sets amanbuild9371@gmail.com role to 'admin' in Firestore.
 * Uses client SDK (no auth required while temp rules are open).
 * Run: node set_admin.js
 */
const { initializeApp } = require('firebase/app');
const { getFirestore, collection, query, where, getDocs, updateDoc } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyC5koHsL0YF0vzSEcaCFgH1WlN0RhvbJTk",
  authDomain: "aman-build-0tehsj.firebaseapp.com",
  projectId: "aman-build-0tehsj",
  storageBucket: "aman-build-0tehsj.firebasestorage.app",
  messagingSenderId: "1037864788293",
  appId: "1:1037864788293:web:a3778dc72c14b79c101e2c",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function setAdmin() {
  const email = 'amanbuild9371@gmail.com';
  const snap = await getDocs(query(collection(db, 'users'), where('email', '==', email)));

  if (snap.empty) {
    console.error(`No user found with email: ${email}`);
    console.log('Make sure the account has registered in the app first.');
    process.exit(1);
  }

  for (const doc of snap.docs) {
    await updateDoc(doc.ref, { role: 'admin' });
    console.log(`✅ Set role=admin for ${email}  (uid: ${doc.id})`);
  }
  process.exit(0);
}

setAdmin().catch(err => {
  console.error('Error:', err.message || err);
  process.exit(1);
});
