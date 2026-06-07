# Seed do Cardapio Real da Ray

Este seed cadastra as categorias e produtos reais da Lanchonete e Pastelaria da
Ray no Firestore, sem apagar pedidos e sem alterar regras Firebase.

## O que o seed faz

- Cria ou atualiza categorias em `categorias`.
- Cria ou atualiza produtos em `produtos`.
- Usa IDs estaveis para nao duplicar quando rodar mais de uma vez.
- Se ja existir categoria/produto com mesmo nome, o script atualiza o documento
  existente.
- Mantem todos os produtos cadastrados como `isActive: true` e
  `isAvailable: true`.
- Preenche `imageUrl` com as URLs esperadas do Firebase Storage.

## Categorias

1. Pastéis
2. Salgados
3. Bebidas
4. Caldo de Cana
5. Doces

## Antes de rodar

Instale as dependencias das Cloud Functions, que incluem `firebase-admin`:

```powershell
npm --prefix functions install
```

Autentique no Google/Firebase com uma conta que tenha permissao de escrita no
Firestore:

```powershell
gcloud auth application-default login
```

Tambem funciona com uma service account:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\caminho\para\service-account.json"
```

## Conferir sem gravar

```powershell
node scripts/seed-ray-menu.cjs --dry-run
```

## Gravar o cardapio real

```powershell
node scripts/seed-ray-menu.cjs
```

## Ocultar produtos antigos

Se ainda aparecerem produtos antigos ou de teste no app, rode:

```powershell
node scripts/seed-ray-menu.cjs --deactivate-missing
```

Isso nao apaga produtos nem pedidos. Apenas marca produtos fora deste cardapio
como `isActive: false` e `isAvailable: false`.

## Imagens

O seed usa URLs publicas esperadas em:

`produtos/ray-assets/`

Para subir as imagens reais ao Firebase Storage, use:

```powershell
.\scripts\upload-ray-assets.ps1 -ZipPath C:\Users\erickkkkk\Downloads\ray_assets_ready.zip
```

Enquanto as imagens do Storage nao estiverem publicadas, o Client usa os assets
locais em `apps/client/assets/ray/` como fallback visual.
