// seed_contractors.js
// Run: node seed_contractors.js
// Creates 20 contractor accounts in Firebase Auth + Firestore

const { initializeApp } = require("firebase/app");
const {
  getAuth,
  createUserWithEmailAndPassword,
  updateProfile,
  signOut,
} = require("firebase/auth");
const {
  getFirestore,
  doc,
  setDoc,
  serverTimestamp,
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

const PASSWORD = "Testtest1@";

const contractors = [
  { name: "PrimeBuild", title: "Plumber", email: "PrimeBuildaman@gmail.com", color: "1565C0" },
  { name: "Serviq", title: "Electrician", email: "Serviqaman@gmail.com", color: "E65100" },
  { name: "Ali Kareem", title: "Painter", email: "AliKareemaman@gmail.com", color: "2E7D32" },
  { name: "EliteWorks", title: "HVAC Technician", email: "EliteWorksaman@gmail.com", color: "6A1B9A" },
  { name: "SolidHands", title: "Construction Worker", email: "SolidHandsaman@gmail.com", color: "D84315" },
  { name: "Omar Farooq", title: "Electrician", email: "OmarFarooqaman@gmail.com", color: "00838F" },
  { name: "Ibrahim Saeed", title: "Plumber", email: "IbrahimSaeedaman@gmail.com", color: "4527A0" },
  { name: "HandyFlow", title: "Interior Painter", email: "HandyFlowaman@gmail.com", color: "AD1457" },
  { name: "Hassan Jaber", title: "Maintenance Technician", email: "HassanJaberaman@gmail.com", color: "283593" },
  { name: "Workora", title: "General Contractor", email: "Workoraaman@gmail.com", color: "00695C" },
  { name: "Tariq Al-Harthy", title: "Roofer", email: "TariqAlHarthyaman@gmail.com", color: "BF360C" },
  { name: "FixHub", title: "Electrical Engineer", email: "FixHubaman@gmail.com", color: "0277BD" },
  { name: "MasterCrew", title: "Tile Installer", email: "MasterCrewaman@gmail.com", color: "558B2F" },
  { name: "Bilal Ahmad", title: "Carpenter", email: "BilalAhmadaman@gmail.com", color: "8D6E63" },
  { name: "Adnan Malik", title: "Handyman", email: "AdnanMalikaman@gmail.com", color: "EF6C00" },
  { name: "Fixora", title: "Smart Home Technician", email: "Fixoraaman@gmail.com", color: "5E35B1" },
  { name: "Rami Haddad", title: "Glass Installer", email: "RamiHaddadaman@gmail.com", color: "00897B" },
  { name: "HandyFlow Pro", title: "Waterproofing Specialist", email: "HandyFlowProaman@gmail.com", color: "C62828" },
  { name: "Sami Zidan", title: "Solar Technician", email: "SamiZidanaman@gmail.com", color: "F9A825" },
  { name: "TaskMatch", title: "Site Supervisor", email: "TaskMatchaman@gmail.com", color: "37474F" },
];

async function seed() {
  let created = 0;
  let skipped = 0;
  let errors = 0;

  for (const c of contractors) {
    const encodedName = encodeURIComponent(c.name);
    const photoUrl = `https://ui-avatars.com/api/?name=${encodedName}&size=256&background=${c.color}&color=ffffff&bold=true&format=png`;

    try {
      // Create Auth account (also signs in as this user)
      const cred = await createUserWithEmailAndPassword(auth, c.email, PASSWORD);
      const user = cred.user;

      // Update display name and photo
      await updateProfile(user, {
        displayName: c.name,
        photoURL: photoUrl,
      });

      // Create Firestore user document (signed in as this user, so create is allowed)
      await setDoc(doc(db, "users", user.uid), {
        uid: user.uid,
        full_name: c.name,
        display_name: c.name,
        email: c.email,
        role: "service_provider",
        title: c.title,
        categories: [c.title],
        photo_url: photoUrl,
        short_description: `Professional ${c.title} ready to help with your projects.`,
        phone_number: "",
        created_time: serverTimestamp(),
        last_active_time: serverTimestamp(),
        is_online: false,
        is_disabled: false,
        preferred_language: "en",
      });

      // Sign out so we can create the next account
      await signOut(auth);

      created++;
      console.log(`[${created}] CREATED: ${c.name} (${c.email}) - ${c.title}`);
    } catch (err) {
      if (err.code === "auth/email-already-in-use") {
        skipped++;
        console.log(`[SKIP] ${c.email} already exists`);
        try { await signOut(auth); } catch (_) {}
      } else {
        errors++;
        console.log(`[ERROR] ${c.email}: ${err.message}`);
        try { await signOut(auth); } catch (_) {}
      }
    }
  }

  console.log(`\n=== DONE ===`);
  console.log(`Created: ${created}, Skipped: ${skipped}, Errors: ${errors}`);
  process.exit(0);
}

seed();
