/* eslint-disable no-console */
// Uso:
//   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\caminho\service-account.json"
//   node tools/maintenance/clear_test_orders.js
//
// A rotina usa as credenciais locais do Firebase/Google e só continua após
// a confirmação textual exata. Produtos, categorias, usuários e fidelidade
// não são alterados.

const readline = require("node:readline");
const { initializeApp, applicationDefault } = require(
  "../../functions/node_modules/firebase-admin/app",
);
const { getFirestore, FieldValue } = require(
  "../../functions/node_modules/firebase-admin/firestore",
);

initializeApp({
  credential: applicationDefault(),
  projectId: "rayssa-delivery",
});

const db = getFirestore();
const confirmationText = "CONFIRMAR_LIMPEZA_PEDIDOS_TESTE";

function saoPauloDateKey() {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Sao_Paulo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}${values.month}${values.day}`;
}

function ask(question) {
  const input = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    input.question(question, (answer) => {
      input.close();
      resolve(answer.trim());
    });
  });
}

async function deleteDocuments(snapshot) {
  for (let start = 0; start < snapshot.docs.length; start += 400) {
    const batch = db.batch();
    for (const doc of snapshot.docs.slice(start, start + 400)) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
}

async function resetTables(snapshot) {
  for (let start = 0; start < snapshot.docs.length; start += 400) {
    const batch = db.batch();
    for (const doc of snapshot.docs.slice(start, start + 400)) {
      batch.set(
        doc.ref,
        {
          status: "free",
          currentSessionId: null,
          currentTotal: 0,
          openedAt: null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

async function main() {
  const dateKey = saoPauloDateKey();
  const [orders, sessions, tables] = await Promise.all([
    db.collection("pedidos").get(),
    db.collection("table_sessions").get(),
    db.collection("tables").get(),
  ]);

  console.log("\nResumo da limpeza:");
  console.log(`Pedidos afetados: ${orders.size}`);
  console.log(`Sessões de mesa afetadas: ${sessions.size}`);
  console.log(`Mesas liberadas: ${tables.size}`);
  console.log(`Contador resetado: order_counters/${dateKey} -> 0`);
  console.log("\nEsta ação apaga pedidos e sessões de teste permanentemente.");

  const answer = await ask(
    `Digite ${confirmationText} para continuar: `,
  );
  if (answer !== confirmationText) {
    console.log("Confirmação inválida. Nenhuma alteração realizada.");
    return;
  }

  await deleteDocuments(orders);
  await deleteDocuments(sessions);
  await resetTables(tables);
  await db.collection("order_counters").doc(dateKey).set({
    current: 0,
    updatedAt: FieldValue.serverTimestamp(),
  });

  console.log("Limpeza concluída com segurança.");
}

main().catch((error) => {
  console.error("Falha na limpeza:", error);
  process.exitCode = 1;
});
