// add_locations.js
// Adds latitude/longitude to all 20 contractor accounts in Firestore
// Run: node add_locations.js

const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const {
  getFirestore,
  collection,
  query,
  where,
  getDocs,
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
const auth = getAuth(app);
const db = getFirestore(app);

// Realistic Bahrain locations spread across different neighborhoods
const locationMap = {
  "PrimeBuildaman@gmail.com":   { lat: 26.2235, lng: 50.5876, area: "Manama" },
  "Serviqaman@gmail.com":       { lat: 26.2578, lng: 50.6153, area: "Muharraq" },
  "AliKareemaman@gmail.com":    { lat: 26.1288, lng: 50.5572, area: "Riffa" },
  "EliteWorksaman@gmail.com":   { lat: 26.1094, lng: 50.5016, area: "Hamad Town" },
  "SolidHandsaman@gmail.com":   { lat: 26.1781, lng: 50.5481, area: "Isa Town" },
  "OmarFarooqaman@gmail.com":   { lat: 26.1706, lng: 50.5395, area: "Salmabad" },
  "IbrahimSaeedaman@gmail.com": { lat: 26.2143, lng: 50.5348, area: "Jidhafs" },
  "HandyFlowaman@gmail.com":    { lat: 26.1999, lng: 50.5763, area: "Tubli" },
  "HassanJaberaman@gmail.com":  { lat: 26.2615, lng: 50.6465, area: "Amwaj Islands" },
  "Workoraaman@gmail.com":      { lat: 26.2310, lng: 50.5691, area: "Manama West" },
  "TariqAlHarthyaman@gmail.com":{ lat: 26.1820, lng: 50.5530, area: "Isa Town South" },
  "FixHubaman@gmail.com":       { lat: 26.2402, lng: 50.6351, area: "Hidd" },
  "MasterCrewaman@gmail.com":   { lat: 26.2054, lng: 50.4784, area: "Saar" },
  "BilalAhmadaman@gmail.com":   { lat: 26.2001, lng: 50.5648, area: "Zinj" },
  "AdnanMalikaman@gmail.com":   { lat: 26.2156, lng: 50.5931, area: "Seef" },
  "Fixoraaman@gmail.com":       { lat: 26.2401, lng: 50.6089, area: "Muharraq South" },
  "RamiHaddadaman@gmail.com":   { lat: 26.2183, lng: 50.4678, area: "Budaiya" },
  "HandyFlowProaman@gmail.com": { lat: 26.1950, lng: 50.4892, area: "Hamala" },
  "SamiZidanaman@gmail.com":    { lat: 26.1603, lng: 50.5337, area: "A'ali" },
  "TaskMatchaman@gmail.com":    { lat: 26.2173, lng: 50.5425, area: "Adliya" },
};

async function run() {
  // Sign in as admin user (use a client account that has Firestore write access)
  // We only need to sign in so Firestore rules allow the write
  // Use a client account or use Firebase Admin SDK for server-side scripts
  // For simplicity, we'll sign in as each contractor to update their own doc

  let updated = 0;
  let errors = 0;

  for (const [email, loc] of Object.entries(locationMap)) {
    try {
      // Sign in as this contractor
      const cred = await signInWithEmailAndPassword(auth, email, "Testtest1@");
      const uid = cred.user.uid;

      // Update their Firestore document with location
      await updateDoc(doc(db, "users", uid), {
        latitude: loc.lat,
        longitude: loc.lng,
        area: loc.area,
      });

      await signOut(auth);
      updated++;
      console.log(`[${updated}] UPDATED: ${email} → ${loc.area} (${loc.lat}, ${loc.lng})`);
    } catch (err) {
      errors++;
      console.log(`[ERROR] ${email}: ${err.message}`);
      try { await signOut(auth); } catch (_) {}
    }
  }

  console.log(`\n=== DONE === Updated: ${updated}, Errors: ${errors}`);
  process.exit(0);
}

run();
