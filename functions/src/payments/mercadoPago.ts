/**
 * Integração Mercado Pago — estrutura preparada, sem chaves reais.
 *
 * Quando tiver credenciais:
 * 1. firebase functions:secrets:set MERCADO_PAGO_ACCESS_TOKEN
 * 2. Implementar POST https://api.mercadopago.com/v1/payments (payment_method_id: pix)
 * 3. Validar assinatura do webhook com MERCADO_PAGO_WEBHOOK_SECRET
 */

export interface PixPaymentStubResponse {
  paymentId: string;
  status: "pending";
  qrCodeBase64: string | null;
  qrCodeCopyPaste: string | null;
  message: string;
}

export async function createPixPaymentStub(input: {
  orderId: string;
  amount: number;
}): Promise<PixPaymentStubResponse> {
  const token = process.env.MERCADO_PAGO_ACCESS_TOKEN;

  if (!token) {
    return {
      paymentId: `stub_${input.orderId}`,
      status: "pending",
      qrCodeBase64: null,
      qrCodeCopyPaste: null,
      message:
        "MERCADO_PAGO_ACCESS_TOKEN não configurado. Configure o secret no Firebase.",
    };
  }

  // TODO: chamar API Mercado Pago quando o token estiver disponível.
  return {
    paymentId: `mp_pending_${input.orderId}`,
    status: "pending",
    qrCodeBase64: null,
    qrCodeCopyPaste: null,
    message: "Integração Mercado Pago pendente de implementação.",
  };
}

export async function handleMercadoPagoWebhook(
  headers: Record<string, unknown>,
  body: unknown,
): Promise<{ orderId?: string; paymentStatus?: string }> {
  const secret = process.env.MERCADO_PAGO_WEBHOOK_SECRET;
  if (!secret) {
    console.warn("[MercadoPago] Webhook secret não configurado — modo stub");
    return {};
  }

  // TODO: validar x-signature / x-request-id conforme documentação MP.
  const payload = body as { data?: { id?: string }; metadata?: { order_id?: string } };
  const orderId = payload.metadata?.order_id;
  return {
    orderId,
    paymentStatus: "approved",
  };
}
