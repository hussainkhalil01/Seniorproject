// update_contractors.js
// Run: node update_contractors.js
// Updates the 20 existing contractor accounts with new categories & titles

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

const PASSWORD = "Testtest1@";

// 20 accounts: 4 per category with proper professional titles
const contractors = [
  // HVAC (Air Conditioning) - 4 accounts
  { email: "PrimeBuildaman@gmail.com",      title: "HVAC (Air Conditioning)",              name: "PrimeBuild",       desc: "Expert in AC installation, maintenance, and central cooling systems." },
  { email: "EliteWorksaman@gmail.com",      title: "HVAC (Air Conditioning)",              name: "EliteWorks",       desc: "Specializing in split AC units, duct cleaning, and HVAC repairs." },
  { email: "HassanJaberaman@gmail.com",     title: "HVAC (Air Conditioning)",              name: "Hassan Jaber",     desc: "Professional air conditioning technician for residential and commercial projects." },
  { email: "Fixoraaman@gmail.com",          title: "HVAC (Air Conditioning)",              name: "Fixora",           desc: "Certified HVAC specialist with expertise in smart climate control systems." },

  // Electrical Services - 4 accounts
  { email: "Serviqaman@gmail.com",          title: "Electrical Services",                  name: "Serviq",           desc: "Licensed electrician for wiring, panel upgrades, and electrical safety inspections." },
  { email: "OmarFarooqaman@gmail.com",      title: "Electrical Services",                  name: "Omar Farooq",      desc: "Expert in residential and commercial electrical installations." },
  { email: "FixHubaman@gmail.com",          title: "Electrical Services",                  name: "FixHub",           desc: "Electrical engineer specializing in smart home wiring and lighting solutions." },
  { email: "SamiZidanaman@gmail.com",       title: "Electrical Services",                  name: "Sami Zidan",       desc: "Professional electrician for power systems, outlets, and circuit repairs." },

  // Plumbing - 4 accounts
  { email: "IbrahimSaeedaman@gmail.com",    title: "Plumbing",                             name: "Ibrahim Saeed",    desc: "Licensed plumber for pipe installation, leak repairs, and water heater services." },
  { email: "HandyFlowaman@gmail.com",       title: "Plumbing",                             name: "HandyFlow",        desc: "Expert in bathroom plumbing, drain cleaning, and fixture installation." },
  { email: "AdnanMalikaman@gmail.com",      title: "Plumbing",                             name: "Adnan Malik",      desc: "Reliable plumbing professional for emergency repairs and new installations." },
  { email: "RamiHaddadaman@gmail.com",      title: "Plumbing",                             name: "Rami Haddad",      desc: "Specializing in kitchen plumbing, water filtration, and sewer line services." },

  // General Construction & Renovation - 4 accounts
  { email: "SolidHandsaman@gmail.com",      title: "General Construction & Renovation",    name: "SolidHands",       desc: "Full-service contractor for home building, additions, and major renovations." },
  { email: "Workoraaman@gmail.com",         title: "General Construction & Renovation",    name: "Workora",          desc: "General contractor specializing in villa construction and structural renovations." },
  { email: "TariqAlHarthyaman@gmail.com",   title: "General Construction & Renovation",    name: "Tariq Al-Harthy",  desc: "Experienced in roofing, foundations, and complete building renovations." },
  { email: "TaskMatchaman@gmail.com",       title: "General Construction & Renovation",    name: "TaskMatch",        desc: "Site supervisor and project manager for construction and renovation projects." },

  // Interior Finishing - 4 accounts
  { email: "AliKareemaman@gmail.com",       title: "Interior Finishing",                   name: "Ali Kareem",       desc: "Professional painter and interior finishing expert for walls, ceilings, and trim." },
  { email: "MasterCrewaman@gmail.com",      title: "Interior Finishing",                   name: "MasterCrew",       desc: "Tile installation, flooring, and interior finishing specialist." },
  { email: "BilalAhmadaman@gmail.com",      title: "Interior Finishing",                   name: "Bilal Ahmad",      desc: "Skilled carpenter for custom cabinetry, doors, and wood finishing." },
  { email: "HandyFlowProaman@gmail.com",    title: "Interior Finishing",                   name: "HandyFlow Pro",    desc: "Expert in gypsum board, false ceilings, and decorative wall finishes." },
];

async function update() {
  let updated = 0;
  let errors = 0;

  for (const c of contractors) {
    try {
      // Sign in as this contractor to get auth (needed for Firestore read)
      const cred = await signInWithEmailAndPassword(auth, c.email, PASSWORD);

      // Find the user document by email
      const q = query(collection(db, "users"), where("email", "==", c.email));
      const snap = await getDocs(q);

      if (snap.empty) {
        console.log(`[SKIP] ${c.email} - no Firestore doc found`);
        await signOut(auth);
        continue;
      }

      const docRef = snap.docs[0].ref;

      // Update title, categories, and description
      await updateDoc(docRef, {
        title: c.title,
        categories: [c.title],
        short_description: c.desc,
      });

      await signOut(auth);
      updated++;
      console.log(`[${updated}] UPDATED: ${c.name} -> ${c.title}`);
    } catch (err) {
      errors++;
      console.log(`[ERROR] ${c.email}: ${err.message}`);
      try { await signOut(auth); } catch (_) {}
    }
  }

  console.log(`\n=== DONE ===`);
  console.log(`Updated: ${updated}, Errors: ${errors}`);
  process.exit(0);
}

update();
