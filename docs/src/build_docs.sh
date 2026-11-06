#!/usr/bin/env bash
# Genera los PDF de documentación en la raíz del proyecto.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

COMMON=(
  --standalone
  --pdf-engine=xelatex
  --include-in-header=docs/src/preamble.tex
  --number-sections
  -V geometry:margin=2.4cm
  -V fontsize=10pt
  -V mainfont="Latin Modern Roman"
  -V sansfont="Latin Modern Sans"
  -V monofont="Latin Modern Mono"
)

echo "==> Manual de usuario"
pandoc docs/src/manual_usuario.md \
  "${COMMON[@]}" \
  --include-before-body=docs/src/title_manual.tex \
  -o "Manual_de_Usuario_Royal_Express.pdf"

echo "==> Memoria técnica"
pandoc docs/src/memoria_tecnica.md \
  "${COMMON[@]}" \
  --include-before-body=docs/src/title_memoria.tex \
  -o "Memoria_Tecnica_Royal_Express.pdf"

echo "==> PDF generados en $ROOT"
ls -lh "Manual_de_Usuario_Royal_Express.pdf" "Memoria_Tecnica_Royal_Express.pdf"
