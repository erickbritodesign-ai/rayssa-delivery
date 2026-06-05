# PRD de Implementação — Rayssa Delivery

Documento unificado para desenvolvimento (MVP). Baseado nos PRDs originais + arquitetura profissional (Clean Architecture, produção).

---

## 1. Visão do produto

| Item | Definição |
|------|-----------|
| **Nome** | Rayssa Delivery |
| **Região** | Pedro Canário — Espírito Santo — Brasil |
| **Objetivo** | Digitalizar pedidos, reduzir WhatsApp, centralizar pagamentos |
| **Canais MVP** | App mobile (cliente) + painel web (admin) |

### Personas

- **Cliente** — cadastro, cardápio, carrinho, checkout, acompanhamento de pedido
- **Administrador** — produtos, categorias, pedidos, dashboard
- **Entregador** — fora do MVP (V3)

---

## 2. Stack técnica

| Camada | Tecnologia |
|--------|------------|
| Mobile / Web UI | Flutter 3+, Riverpod, GoRouter |
| Arquitetura | Clean Architecture (`presentation` / `domain` / `data` / `core`) |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Serverless | Cloud Functions (Node 20, TypeScript) |
| Pagamentos | Mercado Pago (PIX no MVP — stub até credenciais) |
| Mapas | Google Maps (V2+) |
| Monorepo | Melos + `packages/core` |

---

## 3. Escopo MVP (implementado na estrutura inicial)

### Cliente (`apps/client`)

- [x] Login e cadastro (e-mail/senha)
- [x] Listagem de categorias e produtos (Firestore streams)
- [x] Carrinho local (Riverpod)
- [x] Checkout (endereço, delivery/retirada, taxa fixa R$ 5,00)
- [x] Criação de pedido com status `received`
- [x] Listagem e detalhe de pedidos (tempo real)
- [x] UI PIX stub (integração real via Functions)

### Admin (`apps/admin`)

- [x] Login restrito a `role: admin`
- [x] Dashboard (pedidos do dia)
- [x] CRUD categorias
- [x] CRUD produtos
- [x] Listagem de pedidos + alteração de status

### Backend

- [x] `firestore.rules` e `storage.rules`
- [x] Índices compostos (`firestore.indexes.json`)
- [x] Functions: `createPixPayment`, `mercadoPagoWebhook`, `onOrderCreated` (stub MP)

### Fora do MVP (roadmap)

| Versão | Itens |
|--------|--------|
| **V2** | Cartão crédito/débito, cupons, promoções, faturamento no dashboard |
| **V3** | Entregadores, rastreamento, fidelidade, Google Maps (taxa por zona) |

---

## 4. Arquitetura do monorepo

```
apps/client/lib/
  core/           → theme, router, firebase bootstrap
  features/
    auth/         → presentation | domain | data
    menu/
    cart/
    checkout/
    orders/

apps/admin/lib/
  features/       → auth, dashboard, categories, products, orders
  shared/         → AdminShell, AdminFirestoreService

packages/core/    → modelos Firestore, enums, coleções
functions/src/    → HTTPS + triggers + payments/
```

### Princípios

- **SOLID** — repositórios abstratos no `domain`, implementação no `data`
- **Riverpod** — providers por feature
- **GoRouter** — rotas declarativas + redirect por auth
- **Sem secrets no repo** — `.env`, `firebase_options.dart`, tokens MP via Secrets

---

## 5. Modelo de dados (Firestore)

### Coleção `usuarios/{uid}`

```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "client | admin",
  "addresses": [{ "street", "number", "neighborhood", "city", "state", "zipCode", "complement", "reference", "label" }],
  "createdAt": "timestamp"
}
```

### Coleção `categorias/{id}`

```json
{
  "name": "string",
  "sortOrder": 0,
  "isActive": true,
  "imageUrl": "string | null"
}
```

### Coleção `produtos/{id}`

```json
{
  "name": "string",
  "description": "string",
  "price": 0.0,
  "categoryId": "string",
  "imageUrl": "string | null",
  "isAvailable": true,
  "isActive": true
}
```

### Coleção `pedidos/{id}`

```json
{
  "userId": "string",
  "items": [{ "productId", "name", "unitPrice", "quantity", "imageUrl" }],
  "subtotal": 0.0,
  "deliveryFee": 0.0,
  "total": 0.0,
  "status": "received | confirmed | preparing | out_for_delivery | delivered | cancelled",
  "deliveryType": "delivery | pickup",
  "paymentMethod": "pix",
  "paymentStatus": "pending | approved | rejected | cancelled",
  "address": { ... } | null,
  "notes": "string | null",
  "mercadoPagoPaymentId": "string | null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Coleções futuras

- `cupons` — V2
- `configuracoes` — taxas, horário da loja

Categorias seed sugeridas: Hambúrgueres, Pizzas, Bebidas, Açaí, Sobremesas (`scripts/seed-firestore.example.json`).

---

## 6. Fluxos principais

### Cliente — compra

1. Cadastro/login → perfil em `usuarios`
2. Home → categorias + produtos
3. Adicionar ao carrinho
4. Checkout → endereço (se delivery) → confirmar
5. Pedido criado (`received`, `paymentStatus: pending`)
6. Chamar `createPixPayment` (quando MP ativo) → QR / copia-e-cola
7. Webhook MP → `paymentStatus: approved`, `status: confirmed`
8. Admin atualiza preparo/entrega → cliente vê em tempo real

### Admin

1. Login (role `admin`)
2. CRUD categorias/produtos
3. Monitorar pedidos e alterar status

---

## 7. Segurança

- Regras Firestore: cliente lê só seus pedidos; admin acesso total a gestão
- Storage: upload de imagens de produto apenas admin
- Cloud Functions: secrets para `MERCADO_PAGO_ACCESS_TOKEN`
- Nunca commitar: `.env`, `google-services.json`, `firebase_options.dart`

---

## 8. Performance (metas PRD)

| Métrica | Meta |
|---------|------|
| Carregamento inicial | < 3 s |
| Checkout | < 30 s |
| Disponibilidade | > 99 % (Firebase SLA) |

---

## 9. Design

- **Estilo:** moderno, limpo, mobile first
- **Cores:** vermelho `#E53935`, branco, preto
- **Tipografia:** Inter (via `google_fonts`)

---

## 10. Integrações

| Serviço | MVP | Observação |
|---------|-----|------------|
| Firebase Auth | Sim | E-mail/senha; Google na V2 |
| Firestore | Sim | Streams em tempo real |
| Storage | Preparado | Imagens de produtos |
| FCM | V2 | Notificações de status |
| Mercado Pago | Stub | `functions/src/payments/mercadoPago.ts` |
| Google Maps | V3 | Taxa por distância/zona |

### Ativar Mercado Pago

1. Criar app no [Mercado Pago Developers](https://www.mercadopago.com.br/developers)
2. `firebase functions:secrets:set MERCADO_PAGO_ACCESS_TOKEN`
3. Implementar criação de pagamento PIX na API v1
4. Configurar webhook apontando para `mercadoPagoWebhook`
5. Substituir `PixPaymentStub` no app por dados reais da Function

---

## 11. Critérios de aceite (MVP)

- [ ] Cliente conclui pedido completo (cadastro → checkout → pedido no Firestore)
- [ ] Admin gerencia produtos e categorias
- [ ] Admin visualiza e atualiza status dos pedidos
- [ ] Pedidos atualizam em tempo real no app cliente
- [ ] App compila em Android e iOS (após `flutter create`)
- [ ] PIX: estrutura Functions + UI stub (confirmação automática na integração MP)

---

## 12. Comandos úteis

```powershell
# Deploy rules
firebase deploy --only firestore:rules,storage

# Deploy functions
cd functions && npm run build && firebase deploy --only functions

# Analyze
cd apps/client && flutter analyze
```

---

## 13. Referência de arquivos-chave

| Arquivo | Função |
|---------|--------|
| `packages/core/lib/rayssa_core.dart` | Export dos modelos |
| `apps/client/lib/core/router/app_router.dart` | Rotas cliente |
| `apps/admin/lib/shared/data/admin_firestore_service.dart` | CRUD admin |
| `functions/src/index.ts` | Endpoints e triggers |
| `firestore.rules` | Autorização |

---

*Última atualização: estrutura inicial do monorepo — MVP em desenvolvimento.*
