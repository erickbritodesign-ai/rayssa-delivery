# Ray Assets - Upload Manual

O upload automatico nao foi executado neste ambiente porque o Firebase CLI nao
esta autenticado. Use este guia para publicar as fotos reais no Firebase
Storage e preencher os campos visuais sem alterar regras ou estrutura de dados.

## Origem

Arquivo local:

`C:\Users\erickkkkk\Downloads\ray_assets_ready.zip`

Se mover o arquivo para o workspace, coloque em:

`C:\Users\erickkkkk\Projects\rayssa-delivery\ray_assets_ready.zip`

## Destinos no Firebase Storage

Bucket:

`rayssa-delivery.firebasestorage.app`

Pasta:

`produtos/ray-assets/`

| Uso | Imagem no ZIP | Destino no Storage | URL usada pelo app |
| --- | --- | --- | --- |
| heroImageUrl | `hero_1600x900/marca_ray_fachada_hero_1600x900.jpg` | `produtos/ray-assets/marca_ray_fachada_hero_1600x900.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fmarca_ray_fachada_hero_1600x900.jpg?alt=media` |
| storyImageUrl | `story_1080x1350/marca_ray_fachada_story_1080x1350.jpg` | `produtos/ray-assets/marca_ray_fachada_story_1080x1350.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fmarca_ray_fachada_story_1080x1350.jpg?alt=media` |
| categoryImages.Pasteis | `cards_square_1080/produto_pastel_carne_square_1080.jpg` | `produtos/ray-assets/produto_pastel_carne_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_pastel_carne_square_1080.jpg?alt=media` |
| categoryImages.Pizzas | `cards_square_1080/produto_pizza_square_1080.jpg` | `produtos/ray-assets/produto_pizza_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_pizza_square_1080.jpg?alt=media` |
| categoryImages.Panquecas | `cards_square_1080/produto_panqueca_square_1080.jpg` | `produtos/ray-assets/produto_panqueca_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_panqueca_square_1080.jpg?alt=media` |
| categoryImages.Doces | `cards_square_1080/produto_doce_copo_square_1080.jpg` | `produtos/ray-assets/produto_doce_copo_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_doce_copo_square_1080.jpg?alt=media` |
| categoryImages.Bebidas | `cards_square_1080/produto_caldo_cana_square_1080.jpg` | `produtos/ray-assets/produto_caldo_cana_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_caldo_cana_square_1080.jpg?alt=media` |
| categoryImages.Caldo de Cana | `cards_square_1080/produto_caldo_cana_square_1080.jpg` | `produtos/ray-assets/produto_caldo_cana_square_1080.jpg` | `https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_caldo_cana_square_1080.jpg?alt=media` |
| Produto Pastel de Carne | `cards_square_1080/produto_pastel_carne_square_1080.jpg` | `produtos/ray-assets/produto_pastel_carne_square_1080.jpg` | preencher `produtos/{id}.imageUrl` |
| Produto Pastel de Frango | `cards_square_1080/produto_pastel_carne_square_1080.jpg` | `produtos/ray-assets/produto_pastel_carne_square_1080.jpg` | preencher `produtos/{id}.imageUrl` temporariamente |
| Produto Pizza | `cards_square_1080/produto_pizza_square_1080.jpg` | `produtos/ray-assets/produto_pizza_square_1080.jpg` | preencher `produtos/{id}.imageUrl` |
| Produto Panqueca | `cards_square_1080/produto_panqueca_square_1080.jpg` | `produtos/ray-assets/produto_panqueca_square_1080.jpg` | preencher `produtos/{id}.imageUrl` |
| Produto Doce/Sobremesa | `cards_square_1080/produto_doce_copo_square_1080.jpg` | `produtos/ray-assets/produto_doce_copo_square_1080.jpg` | preencher `produtos/{id}.imageUrl` |
| Produto Caldo de Cana | `cards_square_1080/produto_caldo_cana_square_1080.jpg` | `produtos/ray-assets/produto_caldo_cana_square_1080.jpg` | preencher `produtos/{id}.imageUrl` |

## Passo a Passo

1. Faça login no Firebase/Google Cloud.

```powershell
gcloud auth login
```

2. Publique as imagens usando o script do projeto.

```powershell
.\scripts\upload-ray-assets.ps1 -ZipPath C:\Users\erickkkkk\Downloads\ray_assets_ready.zip
```

3. No Firebase Console, abra Firestore e atualize somente o campo `imageUrl`
dos produtos reais.

4. Para `Pastel de Carne`, use:

`https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_pastel_carne_square_1080.jpg?alt=media`

5. Para `Pastel de Frango`, use temporariamente a mesma foto de pastel:

`https://firebasestorage.googleapis.com/v0/b/rayssa-delivery.firebasestorage.app/o/produtos%2Fray-assets%2Fproduto_pastel_carne_square_1080.jpg?alt=media`

6. As imagens institucionais ficam documentadas como `heroImageUrl`,
`storyImageUrl` e `categoryImages`, mas o app atual usa constantes visuais em
`apps/client/lib/core/branding/ray_photos.dart` para nao alterar a estrutura de
dados do Firestore.
