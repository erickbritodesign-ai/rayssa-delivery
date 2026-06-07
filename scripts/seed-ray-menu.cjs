const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const functionsRequire = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);

const CATEGORIES_COLLECTION = 'categorias';
const PRODUCTS_COLLECTION = 'produtos';
const PROJECT_ID = 'rayssa-delivery';
const STORAGE_BUCKET = 'rayssa-delivery.firebasestorage.app';
const STORAGE_PREFIX = 'produtos/ray-assets';

const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run');
const deactivateMissing = args.has('--deactivate-missing');

function argValue(name) {
  const index = process.argv.indexOf(name);
  if (index === -1 || index === process.argv.length - 1) return null;
  return process.argv[index + 1];
}

function loadAdmin(subpath) {
  try {
    return require(`firebase-admin/${subpath}`);
  } catch (_) {
    try {
      return functionsRequire(`firebase-admin/${subpath}`);
    } catch (error) {
      throw new Error(
        `firebase-admin/${subpath} was not found. Run "npm --prefix functions install" first. Original error: ${error.message}`,
      );
    }
  }
}

function storageUrl(fileName) {
  const encodedPath = encodeURIComponent(`${STORAGE_PREFIX}/${fileName}`);
  return `https://firebasestorage.googleapis.com/v0/b/${STORAGE_BUCKET}/o/${encodedPath}?alt=media`;
}

const imageUrls = {
  pastel: storageUrl('produto_pastel_carne_square_1080.jpg'),
  pastelMilho: storageUrl('produto_pastel_milho_queijo_square_1080.jpg'),
  pizza: storageUrl('produto_pizza_square_1080.jpg'),
  panqueca: storageUrl('produto_panqueca_square_1080.jpg'),
  doce: storageUrl('produto_doce_copo_square_1080.jpg'),
  pudim: storageUrl('produto_pudim_square_1080.jpg'),
  caldoCana: storageUrl('produto_caldo_cana_square_1080.jpg'),
};

function readSeed() {
  const seedPath = path.join(__dirname, 'ray-menu.seed.json');
  return JSON.parse(fs.readFileSync(seedPath, 'utf8'));
}

async function resolveCategoryId(db, category) {
  const collection = db.collection(CATEGORIES_COLLECTION);
  const stableDoc = await collection.doc(category.id).get();
  if (stableDoc.exists) return category.id;

  const byName = await collection.where('name', '==', category.name).limit(1).get();
  if (!byName.empty) return byName.docs[0].id;

  return category.id;
}

async function resolveProductId(db, product, categoryId) {
  const collection = db.collection(PRODUCTS_COLLECTION);
  const stableDoc = await collection.doc(product.id).get();
  if (stableDoc.exists) return product.id;

  const byName = await collection
    .where('name', '==', product.name)
    .where('categoryId', '==', categoryId)
    .limit(1)
    .get();

  if (!byName.empty) return byName.docs[0].id;

  return product.id;
}

async function main() {
  const seed = readSeed();
  const projectId =
    argValue('--project') ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    PROJECT_ID;

  const { initializeApp, applicationDefault, getApps } = loadAdmin('app');
  const { getFirestore } = loadAdmin('firestore');

  const appOptions = { projectId };

  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    appOptions.credential = applicationDefault();
  }

  const app = getApps().length ? getApps()[0] : initializeApp(appOptions);
  const db = getFirestore(app);
  const batch = db.batch();
  const categoryIds = new Map();
  const productDocIds = new Set();
  let writes = 0;

  for (const category of seed.categories) {
    const targetId = await resolveCategoryId(db, category);
    categoryIds.set(category.id, targetId);

    const data = {
      name: category.name,
      sortOrder: category.sortOrder,
      isActive: true,
      imageUrl: imageUrls[category.imageKey] || null,
    };

    if (dryRun) {
      console.log(`[dry-run] upsert category ${targetId}`, data);
    } else {
      batch.set(db.collection(CATEGORIES_COLLECTION).doc(targetId), data, {
        merge: true,
      });
    }

    writes += 1;
  }

  for (const product of seed.products) {
    const categoryId = categoryIds.get(product.categoryId);

    if (!categoryId) {
      throw new Error(`Missing category for product ${product.name}`);
    }

    const targetId = await resolveProductId(db, product, categoryId);
    productDocIds.add(targetId);

    const data = {
      name: product.name,
      description: product.description,
      price: product.price,
      categoryId,
      imageUrl: imageUrls[product.imageKey] || null,
      isAvailable: true,
      isActive: true,
    };

    if (dryRun) {
      console.log(`[dry-run] upsert product ${targetId}`, data);
    } else {
      batch.set(db.collection(PRODUCTS_COLLECTION).doc(targetId), data, {
        merge: true,
      });
    }

    writes += 1;
  }

  if (deactivateMissing) {
    const existingProducts = await db.collection(PRODUCTS_COLLECTION).get();

    for (const doc of existingProducts.docs) {
      if (productDocIds.has(doc.id)) continue;

      const data = { isActive: false, isAvailable: false };

      if (dryRun) {
        console.log(`[dry-run] deactivate product ${doc.id}`, data);
      } else {
        batch.set(doc.ref, data, { merge: true });
      }

      writes += 1;
    }
  }

  if (!dryRun) {
    await batch.commit();
  }

  console.log(
    `${dryRun ? 'Dry run completed' : 'Seed completed'}: ${seed.categories.length} categories, ${seed.products.length} products, ${writes} planned writes.`,
  );

  if (!deactivateMissing) {
    console.log(
      'Tip: run with --deactivate-missing if old sample products should be hidden without deleting them.',
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});