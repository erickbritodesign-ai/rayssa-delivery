# Rayssa Delivery

Monorepo da plataforma de delivery **Rayssa Delivery** (Pedro Canário — ES).

## Estrutura

```
rayssa-delivery/
├── apps/
│   ├── client/     # App Flutter — clientes (Android/iOS)
│   └── admin/      # Painel Flutter Web — administradores
├── packages/
│   └── core/       # Modelos e enums compartilhados
├── functions/      # Cloud Functions (PIX / webhooks Mercado Pago)
├── docs/           # Documentação de implementação
├── firestore.rules
└── firebase.json
```

## Pré-requisitos

- [Flutter 3.24+](https://docs.flutter.dev/get-started/install)
- [Node.js 20+](https://nodejs.org/)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Conta Firebase e (futuro) Mercado Pago

## Configuração inicial

### 1. Git e dependências Node

```powershell
cd C:\Users\erickkkkk\Projects\rayssa-delivery
git init
cd functions
npm install
```

### 2. Plataformas Flutter (primeira vez)

O código Dart já está no repositório; gere as pastas de plataforma:

```powershell
cd apps\client
flutter create . --project-name rayssa_client
cd ..\admin
flutter create . --project-name rayssa_admin
```

### 3. Firebase

```powershell
firebase login
firebase use rayssa-delivery-dev
dart pub global activate flutterfire_cli
cd apps\client
flutterfire configure
cd ..\admin
flutterfire configure
```

Atualize `FirebaseBootstrap` para usar `DefaultFirebaseOptions.currentPlatform`.

### 4. Melos (opcional)

```powershell
dart pub global activate melos
melos bootstrap
```

### 5. Admin no Firestore

Crie um usuário no Firebase Auth e defina o documento em `usuarios/{uid}`:

```json
{
  "name": "Admin",
  "email": "admin@exemplo.com",
  "phone": "",
  "role": "admin"
}
```

### 6. Emuladores

```powershell
firebase emulators:start
```

## Executar apps

```powershell
# Cliente
cd apps\client
flutter run

# Admin (web)
cd apps\admin
flutter run -d chrome
```

## MVP (escopo atual)

- Login e cadastro (cliente)
- Categorias e produtos (listagem)
- Carrinho e checkout
- Pedidos com status em tempo real
- Painel admin: dashboard, CRUD categorias/produtos, pedidos
- PIX: estrutura + stub (sem chaves reais)

Detalhes: [docs/PRD-IMPLEMENTACAO.md](docs/PRD-IMPLEMENTACAO.md)

## Licença

Projeto privado — Rayssa Delivery.
