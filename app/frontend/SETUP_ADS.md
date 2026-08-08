# 📚 Système d'Annonces - Guide d'Utilisation

## 📁 Structure

```
public/img_lbal/
├── Casquette/
│   ├── info.txt
│   └── images/*.jpg
├── polo lacoste/
├── shoes_nike/
└── ...

src/
├── data/
│   ├── defaultAds.json  (généré automatiquement)
│   └── index.ts         (fonctions utilitaires)
├── hooks/
│   └── useAds.ts        (hook React)
└── types/
    └── ad.types.ts      (interfaces TypeScript)
```

## 🔄 Génération des Annonces

### Depuis la ligne de commande

```bash
npm run generate:ads
```

Cela va :

1. Lire tous les dossiers de `public/img_lbal/`
2. Parser chaque `info.txt`
3. Générer des prix aléatoires entre 70-300 DH
4. Créer `src/data/defaultAds.json`

### Format du fichier `info.txt`

```
Titre du produit
▫️taille: L
▫️condition: 9,5/10
autres détails
```

> ⚠️ **Important** : La première ligne est le titre, les autres deviennent la description

## 🎯 Utilisation dans votre App

### 1️⃣ Obtenir toutes les annonces

```tsx
import { useAds } from "@/hooks";

function AdsPage() {
  const { ads, isLoading } = useAds();

  return (
    <div>
      {ads.map((ad) => (
        <div key={ad.id}>
          <h2>{ad.title}</h2>
          <p>{ad.price} DH</p>
        </div>
      ))}
    </div>
  );
}
```

### 2️⃣ Filtrer par catégorie

```tsx
import { useAds } from "@/hooks";

function CategoryPage({ categoryName }: { categoryName: string }) {
  const { getAdsByCategory } = useAds();
  const ads = getAdsByCategory(categoryName);

  return (
    <div>
      {ads.map((ad) => (
        <AdCard key={ad.id} ad={ad} />
      ))}
    </div>
  );
}
```

### 3️⃣ Importer directement les données

```tsx
import { getDefaultAds, getCategories } from "@/data";

const allAds = getDefaultAds();
const categories = getCategories();
```

## 🔧 Importer les Annonces en Base de Données

### Avec une API

```tsx
async function importAdsToDatabase() {
  const ads = getDefaultAds();

  for (const ad of ads) {
    try {
      await fetch("/api/ads", {
        method: "POST",
        body: JSON.stringify(ad),
        headers: { "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error(`Erreur import ${ad.id}:`, error);
    }
  }
}
```

## 📋 Annonces Générées

| ID   | Titre                     | Prix   | Catégorie          | Images |
| ---- | ------------------------- | ------ | ------------------ | ------ |
| ad-1 | New era Utah jazz 920 cap | 101 DH | Casquette          | 3      |
| ad-2 | Polo Lacoste              | 287 DH | polo lacoste       | 5      |
| ad-3 | polo_lacoste green        | 226 DH | polo_lacoste green | 2      |
| ad-4 | shoes nike                | 264 DH | shoes_nike         | 4      |
| ad-5 | shoes nike                | 76 DH  | shoes_nike_white   | 3      |
| ad-6 | T-shirt                   | 76 DH  | T-shirt            | 3      |
| ad-7 | veste nike                | 172 DH | veste              | 4      |

## 💡 Ajouter/Modifier une Annonce

1. Ajouter un dossier dans `public/img_lbal/NomCategorie/`
2. Y mettre un fichier `info.txt` avec le format
3. Ajouter les images (jpg, jpeg, png, gif)
4. Exécuter `npm run generate:ads`

## ✅ Checklist d'Intégration

- [ ] Script `generate:ads` ajouté au package.json
- [ ] Fichier `src/data/defaultAds.json` généré
- [ ] Fonctions utilitaires dans `src/data/index.ts`
- [ ] Hook `useAds` créé dans `src/hooks/useAds.ts`
- [ ] Export ajouté dans `src/hooks/index.ts`
- [ ] Annonces affichées dans votre page d'accueil/galerie

---

**Questions ?** Vérifiez que les chemins d'images sont corrects et que toutes les images sont présentes dans les dossiers.
