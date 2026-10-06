#!/usr/bin/env bash
# Descarga las fuentes de la casa en TTF (misma táctica que el generador del reporte
# de la web: a un agente que no reconoce, Google Fonts le entrega TTF, no woff2).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/fonts
UA="curl/8"
bajar() {
  local familia="$1" peso="$2" nombre="$3"
  local css; css=$(curl -fsSL -A "$UA" "https://fonts.googleapis.com/css2?family=${familia}:wght@${peso}")
  local url; url=$(echo "$css" | grep -o 'https://[^)]*\.ttf' | head -1)
  curl -fsSL "$url" -o "assets/fonts/${nombre}.ttf"
  echo "$nombre: $(wc -c < "assets/fonts/${nombre}.ttf" | tr -d ' ') bytes"
}
bajar Poppins 500 Poppins-Medium
bajar Poppins 600 Poppins-SemiBold
bajar Poppins 700 Poppins-Bold
bajar Poppins 800 Poppins-ExtraBold
bajar Hanken+Grotesk 400 HankenGrotesk-Regular
bajar Hanken+Grotesk 500 HankenGrotesk-Medium
bajar Hanken+Grotesk 600 HankenGrotesk-SemiBold
bajar Hanken+Grotesk 700 HankenGrotesk-Bold
