const admin = require("firebase-admin");
const fs = require("fs");

// Path to your service account key
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrate() {
  const cityName = "Kuopio";

  // 1. Find the city
  const citiesSnap = await db
    .collection("cities")
    .where("name", "==", cityName)
    .get();
  if (citiesSnap.empty) {
    console.error(`City "${cityName}" not found!`);
    process.exit(1);
  }
  const cityDoc = citiesSnap.docs[0];
  const cityId = cityDoc.id;

  // 2. Get all bars from the top-level 'bars' collection
  const barsSnap = await db.collection("bars").get();
  if (barsSnap.empty) {
    console.error("No bars found in top-level bars collection.");
    process.exit(1);
  }

  // 3. Move each bar to cities/{cityId}/bars and collect full bar objects
  const barObjects = [];
  for (const barDoc of barsSnap.docs) {
    const barData = barDoc.data();
    await db
      .collection("cities")
      .doc(cityId)
      .collection("bars")
      .doc(barDoc.id)
      .set(barData);
    barObjects.push({ ...barData, id: barDoc.id });
    console.log(`Moved bar ${barDoc.id} to cities/${cityId}/bars`);
  }

  // 4. Create a round under the city embedding all bar objects
  const roundData = {
    name: "Kuopion Klassikkokierros",
    description:
      "Kierrä Kuopion suosituimmat baarit tässä legendaarisessa pubirundissa!",
    bars: barObjects,
    cityId: cityId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isPublic: true,
    minutesPerBar: 30,
    estimatedDuration: "Noin 3 tuntia",
  };
  await db.collection("cities").doc(cityId).collection("rounds").add(roundData);
  console.log(`Created round with ${barObjects.length} bars.`);

  console.log("Migration complete!");
  process.exit(0);
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
