// update_contractors.js
// Run: node update_contractors.js
// Updates the 20 existing contractor accounts with new categories, titles & descriptions

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

// Category distribution (2-3 per category, some contractors in multiple categories):
// Contractors & Handymen: SolidHands, Hassan Jaber, Workora, FixHub (secondary)
// Plumbers:               PrimeBuild, Ibrahim Saeed
// Electricians:           Serviq, Omar Farooq, FixHub
// Heating:                EliteWorks, Bilal Ahmad, Fixora
// Air Conditioning:       EliteWorks, Bilal Ahmad, Fixora
// Locksmiths:             Adnan Malik, Rami Haddad
// Painters:               Ali Kareem, HandyFlow
// Tree Services:          Tariq Al-Harthy, Sami Zidan
// Movers:                 MasterCrew, HandyFlow Pro, TaskMatch

const contractors = [
  {
    email: "PrimeBuildaman@gmail.com",
    name: "PrimeBuild",
    title: "Expert Plumber",
    categories: ["Plumbers"],
    desc: "Specializing in pipe repairs, installations, and all plumbing needs for residential and commercial properties.",
  },
  {
    email: "Serviqaman@gmail.com",
    name: "Serviq",
    title: "Licensed Electrician",
    categories: ["Electricians"],
    desc: "Certified electrician offering wiring, panel upgrades, and electrical safety inspections.",
  },
  {
    email: "AliKareemaman@gmail.com",
    name: "Ali Kareem",
    title: "Professional Painter",
    categories: ["Painters"],
    desc: "Skilled painter delivering premium interior and exterior painting with flawless finishes.",
  },
  {
    email: "EliteWorksaman@gmail.com",
    name: "EliteWorks",
    title: "Heating & AC Specialist",
    categories: ["Heating", "Air Conditioning"],
    desc: "Full-service HVAC expert offering heating and air conditioning installation, repair, and maintenance.",
  },
  {
    email: "SolidHandsaman@gmail.com",
    name: "SolidHands",
    title: "General Contractor",
    categories: ["Contractors & Handymen"],
    desc: "Reliable contractor for all home repairs, renovations, and handyman tasks.",
  },
  {
    email: "OmarFarooqaman@gmail.com",
    name: "Omar Farooq",
    title: "Electrician",
    categories: ["Electricians"],
    desc: "Experienced electrician with 10+ years handling residential and commercial electrical systems.",
  },
  {
    email: "IbrahimSaeedaman@gmail.com",
    name: "Ibrahim Saeed",
    title: "Plumber",
    categories: ["Plumbers"],
    desc: "Fast and dependable plumbing services including leak repairs, drain cleaning, and pipe installations.",
  },
  {
    email: "HandyFlowaman@gmail.com",
    name: "HandyFlow",
    title: "Painting Contractor",
    categories: ["Painters"],
    desc: "Interior and exterior painting specialist with a keen eye for detail and lasting results.",
  },
  {
    email: "HassanJaberaman@gmail.com",
    name: "Hassan Jaber",
    title: "Handyman",
    categories: ["Contractors & Handymen"],
    desc: "Your go-to handyman for all household maintenance, repairs, and improvement projects.",
  },
  {
    email: "Workoraaman@gmail.com",
    name: "Workora",
    title: "General Contractor & Handyman",
    categories: ["Contractors & Handymen"],
    desc: "Versatile contractor handling everything from minor fixes to full-scale home renovations.",
  },
  {
    email: "TariqAlHarthyaman@gmail.com",
    name: "Tariq Al-Harthy",
    title: "Tree Services Specialist",
    categories: ["Tree Services"],
    desc: "Expert tree trimming, pruning, and removal. Keeping your property safe and looking its best.",
  },
  {
    email: "FixHubaman@gmail.com",
    name: "FixHub",
    title: "Electrician & Handyman",
    categories: ["Electricians", "Contractors & Handymen"],
    desc: "Multi-skilled professional providing electrical repairs and handyman services for homes and businesses.",
  },
  {
    email: "MasterCrewaman@gmail.com",
    name: "MasterCrew",
    title: "Professional Mover",
    categories: ["Movers"],
    desc: "Reliable moving crew for residential and commercial relocations, handled with care and efficiency.",
  },
  {
    email: "BilalAhmadaman@gmail.com",
    name: "Bilal Ahmad",
    title: "HVAC Technician",
    categories: ["Air Conditioning", "Heating"],
    desc: "Skilled technician specializing in air conditioning and heating system installation, servicing, and repair.",
  },
  {
    email: "AdnanMalikaman@gmail.com",
    name: "Adnan Malik",
    title: "Locksmith",
    categories: ["Locksmiths"],
    desc: "Available 24/7 for lock installations, key cutting, and emergency lockout services.",
  },
  {
    email: "Fixoraaman@gmail.com",
    name: "Fixora",
    title: "AC & Heating Technician",
    categories: ["Air Conditioning", "Heating"],
    desc: "Expert in cooling and heating solutions. Fast diagnosis and reliable repairs for all HVAC systems.",
  },
  {
    email: "RamiHaddadaman@gmail.com",
    name: "Rami Haddad",
    title: "Locksmith",
    categories: ["Locksmiths"],
    desc: "Trusted locksmith providing security upgrades, lock replacements, and smart lock installations.",
  },
  {
    email: "HandyFlowProaman@gmail.com",
    name: "HandyFlow Pro",
    title: "Moving & Relocation Expert",
    categories: ["Movers"],
    desc: "Full-service moving company offering packing, transport, and unpacking for stress-free moves.",
  },
  {
    email: "SamiZidanaman@gmail.com",
    name: "Sami Zidan",
    title: "Tree Care Professional",
    categories: ["Tree Services"],
    desc: "Certified arborist offering tree pruning, removal, stump grinding, and landscape maintenance.",
  },
  {
    email: "TaskMatchaman@gmail.com",
    name: "TaskMatch",
    title: "Moving Coordinator",
    categories: ["Movers"],
    desc: "Professional moving service for local and long-distance relocations with careful handling.",
  },
];

async function update() {
  let updated = 0;
  let errors = 0;

  for (const c of contractors) {
    try {
      const cred = await signInWithEmailAndPassword(auth, c.email, PASSWORD);

      const q = query(collection(db, "users"), where("email", "==", c.email));
      const snap = await getDocs(q);

      if (snap.empty) {
        console.log(`[SKIP] ${c.email} - no Firestore doc found`);
        await signOut(auth);
        continue;
      }

      const docRef = snap.docs[0].ref;

      await updateDoc(docRef, {
        title: c.title,
        categories: c.categories,
        short_description: c.desc,
      });

      await signOut(auth);
      updated++;
      console.log(`[${updated}] UPDATED: ${c.name} → [${c.categories.join(", ")}]`);
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
