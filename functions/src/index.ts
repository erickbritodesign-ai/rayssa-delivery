import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import {
  createPixPaymentStub,
  handleMercadoPagoWebhook,
} from "./payments/mercadoPago";

initializeApp();

const db = getFirestore();

/**
 * Cria intenção de pagamento PIX (stub até credenciais Mercado Pago).
 * POST { orderId: string }
 */
export const createPixPayment = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const orderId = req.body?.orderId as string | undefined;
  if (!orderId) {
    res.status(400).json({ error: "orderId é obrigatório" });
    return;
  }

  const orderRef = db.collection("pedidos").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    res.status(404).json({ error: "Pedido não encontrado" });
    return;
  }

  const order = orderSnap.data()!;
  const payload = await createPixPaymentStub({
    orderId,
    amount: order.total as number,
  });

  await orderRef.update({
    mercadoPagoPaymentId: payload.paymentId,
    paymentStatus: "pending",
    updatedAt: FieldValue.serverTimestamp(),
  });

  res.json(payload);
});

/**
 * Webhook Mercado Pago — validação e atualização de pedido (stub).
 */
export const mercadoPagoWebhook = onRequest(async (req, res) => {
  try {
    const result = await handleMercadoPagoWebhook(req.headers, req.body);
    if (result.orderId && result.paymentStatus) {
      await db.collection("pedidos").doc(result.orderId).update({
        paymentStatus: result.paymentStatus,
        status: result.paymentStatus === "approved" ? "confirmed" : "received",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    res.status(200).send("OK");
  } catch (error) {
    console.error("[mercadoPagoWebhook]", error);
    res.status(400).send("Invalid webhook");
  }
});

/**
 * Ao criar pedido, registra log de auditoria (MVP).
 */
export const onOrderCreated = onDocumentCreated("pedidos/{orderId}", async (event) => {
  const orderId = event.params.orderId;
  console.info(`[pedidos] Novo pedido ${orderId}`, event.data?.data());
});
