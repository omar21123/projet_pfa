const fs = require("fs");
const path = require("path");

// Générer un prix aléatoire entre 70 et 300
const getRandomPrice = () => Math.floor(Math.random() * (300 - 50 + 1)) + 50;

// Lire les dossiers d'images et générer les annonces
const imgPath = path.join(process.cwd(), "public/img_lbal");
const categories = fs.readdirSync(imgPath);

const ads = [];
let adIndex = 1;

categories.forEach((category) => {
  const categoryPath = path.join(imgPath, category);
  const stats = fs.statSync(categoryPath);

  if (!stats.isDirectory()) return;

  const files = fs.readdirSync(categoryPath);
  const infoFile = files.find((f) => f === "info.txt");

  if (!infoFile) return;

  const infoPath = path.join(categoryPath, infoFile);
  const infoContent = fs.readFileSync(infoPath, "utf-8").trim();

  // Parser le contenu du fichier info
  const lines = infoContent.split("\n").filter((line) => line.trim());
  const title = lines.length > 0 ? lines[0].replace(/^[🔴▫️\s]+/, "").trim() : category;
  const description = lines.length > 1 ? lines.slice(1).join("\n") : `Catégorie: ${category}`;

  // Récupérer les images (exclure info.txt)
  const images = files
    .filter((f) => f !== "info.txt" && /\.(jpg|jpeg|png|gif)$/i.test(f))
    .map((f) => `/img_lbal/${encodeURIComponent(category)}/${encodeURIComponent(f)}`);

  if (images.length === 0) return;

  const ad = {
    id: `ad-${adIndex++}`,
    title: title,
    description: description,
    price: getRandomPrice(),
    category: category,
    images: images,
    userId: "admin",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  ads.push(ad);
});

// Écrire le fichier JSON
const outputPath = path.join(process.cwd(), "src/data/defaultAds.json");
const outputDir = path.dirname(outputPath);

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.writeFileSync(outputPath, JSON.stringify(ads, null, 2));
console.log(`✅ ${ads.length} annonces générées dans ${outputPath}`);

