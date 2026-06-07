param(
  [Parameter(Mandatory = $true)]
  [string]$ZipPath
)

$ErrorActionPreference = "Stop"

$bucket = "rayssa-delivery.firebasestorage.app"
$targetPrefix = "produtos/ray-assets"
$workDir = Join-Path (Get-Location) ".tmp\ray-assets-upload"

if (-not (Test-Path -LiteralPath $ZipPath)) {
  throw "Zip not found: $ZipPath"
}

New-Item -ItemType Directory -Force -Path $workDir | Out-Null
Expand-Archive -LiteralPath $ZipPath -DestinationPath $workDir -Force

$root = Join-Path $workDir "ray_assets_ready"
$files = @(
  "hero_1600x900\marca_ray_fachada_hero_1600x900.jpg",
  "hero_1600x900\produto_pastel_carne_hero_1600x900.jpg",
  "story_1080x1350\marca_ray_fachada_story_1080x1350.jpg",
  "cards_square_1080\produto_pastel_carne_square_1080.jpg",
  "cards_square_1080\produto_pastel_milho_queijo_square_1080.jpg",
  "cards_square_1080\produto_pizza_square_1080.jpg",
  "cards_square_1080\produto_panqueca_square_1080.jpg",
  "cards_square_1080\produto_doce_copo_square_1080.jpg",
  "cards_square_1080\produto_pudim_square_1080.jpg",
  "cards_square_1080\produto_caldo_cana_square_1080.jpg"
)

$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
$gsutil = Get-Command gsutil -ErrorAction SilentlyContinue

if (-not $gcloud -and -not $gsutil) {
  throw "Install Google Cloud SDK or gsutil, then run gcloud auth login before this script."
}

foreach ($relative in $files) {
  $source = Join-Path $root $relative
  $name = Split-Path $relative -Leaf
  $destination = "gs://$bucket/$targetPrefix/$name"

  if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing asset: $source"
  }

  if ($gcloud) {
    & gcloud storage cp $source $destination
  } else {
    & gsutil -h "Content-Type:image/jpeg" cp $source $destination
  }

  $encodedPath = [System.Uri]::EscapeDataString("$targetPrefix/$name")
  "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath`?alt=media"
}
