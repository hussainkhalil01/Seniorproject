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
    desc: "PrimeBuild specializes in residential and commercial plumbing services.\nBrings 8+ years of experience in pipe and fixture work.\nHandles leak repair, drain cleaning, and full plumbing installation.\nUses durable materials and clean installation methods.\nIdeal for urgent plumbing fixes and long-term maintenance.",
  },
  {
    email: "Serviqaman@gmail.com",
    name: "Serviq",
    title: "Licensed Electrician",
    categories: ["Electricians"],
    desc: "Serviq specializes in safe and reliable electrical solutions.\nBrings 9+ years of experience in wiring and panel upgrades.\nHandles lighting, outlets, breakers, and electrical troubleshooting.\nFollows strict safety standards on every project.\nIdeal for homes and businesses needing dependable electrical work.",
  },
  {
    email: "AliKareemaman@gmail.com",
    name: "Ali Kareem",
    title: "Professional Painter",
    categories: ["Painters"],
    desc: "Ali Kareem specializes in interior and exterior painting projects.\nBrings 7+ years of experience in residential and commercial painting.\nHandles wall preparation, repainting, and finishing with precision.\nUses premium paints for smooth and durable results.\nIdeal for modern makeovers and complete color transformations.",
  },
  {
    email: "EliteWorksaman@gmail.com",
    name: "EliteWorks",
    title: "Heating & AC Specialist",
    categories: ["Heating", "Air Conditioning"],
    desc: "EliteWorks specializes in heating and air conditioning services.\nBrings 10+ years of experience in HVAC installation and maintenance.\nHandles AC repair, heating diagnostics, and system optimization.\nUses efficient equipment and professional technical practices.\nIdeal for year-round indoor comfort and energy savings.",
  },
  {
    email: "SolidHandsaman@gmail.com",
    name: "SolidHands",
    title: "General Contractor",
    categories: ["Contractors & Handymen"],
    desc: "SolidHands specializes in construction and renovation projects.\nBrings 8+ years of experience in building and remodeling.\nManages projects from start to finish professionally.\nUses quality materials and skilled workers.\nIdeal for large-scale and complex jobs.",
  },
  {
    email: "OmarFarooqaman@gmail.com",
    name: "Omar Farooq",
    title: "Electrician",
    categories: ["Electricians"],
    desc: "Omar Farooq specializes in residential and commercial electrical services.\nBrings 10+ years of experience in advanced electrical systems.\nHandles rewiring, load balancing, and panel troubleshooting.\nApplies safe and code-compliant installation standards.\nIdeal for reliable upgrades and long-term electrical performance.",
  },
  {
    email: "IbrahimSaeedaman@gmail.com",
    name: "Ibrahim Saeed",
    title: "Plumber",
    categories: ["Plumbers"],
    desc: "Ibrahim Saeed specializes in practical plumbing maintenance services.\nBrings 7+ years of experience in leak and drainage solutions.\nHandles pipe replacement, fixture fitting, and emergency repairs.\nWorks with clean methods and durable plumbing parts.\nIdeal for quick response and affordable plumbing work.",
  },
  {
    email: "HandyFlowaman@gmail.com",
    name: "HandyFlow",
    title: "Painting Contractor",
    categories: ["Painters"],
    desc: "HandyFlow specializes in detailed interior and exterior painting.\nBrings 6+ years of experience in finishing and repainting projects.\nHandles wall correction, texture prep, and final coat application.\nUses quality paint systems for durable visual results.\nIdeal for homes needing a clean and fresh new look.",
  },
  {
    email: "HassanJaberaman@gmail.com",
    name: "Hassan Jaber",
    title: "Handyman",
    categories: ["Contractors & Handymen"],
    desc: "Hassan Jaber specializes in handyman and home maintenance services.\nBrings 8+ years of experience in repairs and installations.\nHandles fittings, minor renovations, and everyday household fixes.\nWorks efficiently with practical and cost-effective solutions.\nIdeal for fast and dependable home support tasks.",
  },
  {
    email: "Workoraaman@gmail.com",
    name: "Workora",
    title: "General Contractor & Handyman",
    categories: ["Contractors & Handymen"],
    desc: "Workora specializes in contracting and all-around renovation work.\nBrings 9+ years of experience in property improvement projects.\nHandles repairs, upgrades, and full remodeling execution.\nMaintains structured workflow from planning to handover.\nIdeal for clients needing complete and organized project delivery.",
  },
  {
    email: "TariqAlHarthyaman@gmail.com",
    name: "Tariq Al-Harthy",
    title: "Tree Services Specialist",
    categories: ["Tree Services"],
    desc: "Tariq Al-Harthy specializes in tree care and landscape safety services.\nBrings 8+ years of experience in pruning and tree removal.\nHandles shaping, trimming, and risk-control maintenance work.\nUses safe cutting methods and professional field tools.\nIdeal for healthy trees and secure outdoor environments.",
  },
  {
    email: "FixHubaman@gmail.com",
    name: "FixHub",
    title: "Electrician & Handyman",
    categories: ["Electricians", "Contractors & Handymen"],
    desc: "FixHub specializes in electrical and handyman service solutions.\nBrings 8+ years of experience in maintenance and repair work.\nHandles wiring, lighting setup, and small property fixes.\nApplies safe methods with efficient task completion.\nIdeal for quick home and business maintenance needs.",
  },
  {
    email: "MasterCrewaman@gmail.com",
    name: "MasterCrew",
    title: "Professional Mover",
    categories: ["Movers"],
    desc: "MasterCrew specializes in residential and office moving services.\nBrings 9+ years of experience in relocation operations.\nHandles packing, transport, loading, and safe item placement.\nUses organized workflow and protective handling standards.\nIdeal for smooth and stress-free moving projects.",
  },
  {
    email: "BilalAhmadaman@gmail.com",
    name: "Bilal Ahmad",
    title: "HVAC Technician",
    categories: ["Air Conditioning", "Heating"],
    desc: "Bilal Ahmad specializes in air conditioning and heating systems.\nBrings 10+ years of experience in HVAC servicing and repair.\nHandles installation, diagnostics, and preventive maintenance.\nUses accurate testing tools for efficient system performance.\nIdeal for reliable climate control in all seasons.",
  },
  {
    email: "AdnanMalikaman@gmail.com",
    name: "Adnan Malik",
    title: "Locksmith",
    categories: ["Locksmiths"],
    desc: "Adnan Malik specializes in locksmith and access security services.\nBrings 9+ years of experience in lock systems and key work.\nHandles lock installation, replacement, and emergency lockout support.\nUses precise fitting methods for strong and reliable security.\nIdeal for homes and businesses requiring secure entry solutions.",
  },
  {
    email: "Fixoraaman@gmail.com",
    name: "Fixora",
    title: "AC & Heating Technician",
    categories: ["Air Conditioning", "Heating"],
    desc: "Fixora specializes in complete AC and heating system care.\nBrings 8+ years of experience in HVAC troubleshooting and repair.\nHandles diagnostics, installation, and performance upgrades.\nUses efficient practices to improve comfort and energy usage.\nIdeal for dependable residential and commercial HVAC support.",
  },
  {
    email: "RamiHaddadaman@gmail.com",
    name: "Rami Haddad",
    title: "Locksmith",
    categories: ["Locksmiths"],
    desc: "Rami Haddad specializes in locksmith and security upgrade services.\nBrings 7+ years of experience in lock replacement and smart locks.\nHandles key duplication, lock repair, and access control setup.\nUses modern hardware with accurate installation methods.\nIdeal for secure and practical property protection needs.",
  },
  {
    email: "HandyFlowProaman@gmail.com",
    name: "HandyFlow Pro",
    title: "Moving & Relocation Expert",
    categories: ["Movers"],
    desc: "HandyFlow Pro specializes in full-service moving and relocation.\nBrings 10+ years of experience in coordinated transport operations.\nHandles packing, loading, delivery, and unpacking assistance.\nUses trained crews and protective methods for valuables.\nIdeal for complete relocation with minimal downtime.",
  },
  {
    email: "SamiZidanaman@gmail.com",
    name: "Sami Zidan",
    title: "Tree Care Professional",
    categories: ["Tree Services"],
    desc: "Sami Zidan specializes in professional tree care services.\nBrings 9+ years of experience in pruning and removal operations.\nHandles stump work, tree shaping, and maintenance planning.\nUses safe equipment and controlled cutting techniques.\nIdeal for clean, healthy, and safe outdoor landscapes.",
  },
  {
    email: "TaskMatchaman@gmail.com",
    name: "TaskMatch",
    title: "Moving Coordinator",
    categories: ["Movers"],
    desc: "TaskMatch specializes in organized moving and relocation coordination.\nBrings 8+ years of experience in local and distance moves.\nHandles planning, transport scheduling, and move-day logistics.\nUses structured processes for timely and safe delivery.\nIdeal for homes and companies needing reliable move management.",
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
