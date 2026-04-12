// backfill_ratings.js
// Recalculates rating_avg and rating_count for every contractor from the
// reviews collection and writes the values back to the users document.
// Run: node backfill_ratings.js

const { initializeApp } = require("firebase/app");
const {
  getFirestore,
  collection,
  getDocs,
  query,
  where,
  doc,
  updateDoc,
} = require("firebase/firestore");

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

async function backfill() {
  const usersSnap = await getDocs(collection(db, "users"));
  console.log(`Found ${usersSnap.size} users`);

  for (const userDoc of usersSnap.docs) {
    const userRef = doc(db, "users", userDoc.id);

    const reviewsSnap = await getDocs(
      query(collection(db, "reviews"), where("contractor_ref", "==", userRef))
    );
    const count = reviewsSnap.size;
    if (count === 0) continue;

    const total = reviewsSnap.docs.reduce(
      (sum, d) => sum + (d.data().rating ?? 0),
      0
    );
    const avg = total / count;

    await updateDoc(userRef, { rating_avg: avg, rating_count: count });
    console.log(
      `Updated ${userDoc.data().display_name ?? userDoc.id}: avg=${avg.toFixed(2)}, count=${count}`
    );
  }

  console.log("Done.");
  process.exit(0);
}

backfill().catch((e) => {
  console.error(e);
  process.exit(1);
});
