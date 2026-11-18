#!/usr/bin/env bash
#
# ============================================
# Script    : instalar-packtools.sh
# Propósito : Instala packtools 4.18.2 (el validador de SciELO PS) en un
#             entorno de Python propio, en /opt/packtools. Lo usan
#             generar_scielo_revista.sh y la solapa «Validaciones» (tipo
#             SciELO), a través de engine/validar_sps.py.
# Por qué así: la versión de PyPI es la 2.6.4 (vieja, sin sps-1.9); la
#             4.18.2 solo se publica en GitHub y pide Python 3.11 o más.
#             Un entorno propio no toca el Python del sistema (sin
#             --break-system-packages) y fija las versiones de cada
#             dependencia: las mismas con que se probó (18/11/2026).
# Uso       : ./instalar-packtools.sh
# Requisitos: python3 >= 3.11 con venv (paquete python3-venv); red hacia
#             github.com y pypi.org; permisos sudo para /opt.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
VERSION="4.18.2"
DESTINO="/opt/packtools"
FUENTE="https://github.com/scieloorg/packtools/archive/refs/tags/${VERSION}.tar.gz"

# LAS DEPENDENCIAS, FIJADAS: LAS DEL ENTORNO DONDE SE PROBÓ (pip freeze).
# lxml 6.1 OBLIGA A validar_sps.py (VER SU ENCABEZADO)
read -r -d '' RESTRICCIONES <<'FIJAS' || true
aiohappyeyeballs==2.7.1
aiohttp==3.14.5
aiosignal==1.4.0
attrs==26.1.0
babel==2.18.0
certifi==2026.10.23
charset-normalizer==3.5.2
citeproc-py==0.12.3
et_xmlfile==2.0.0
frozenlist==1.8.0
idna==3.20
langcodes==3.5.1
langdetect==1.0.9
lxml==6.1.3
mathml2omml==0.0.2
multidict==7.2.1
openpyxl==3.1.5
picles.plumber==0.11
pillow==13.0.0
propcache==0.5.4
python-docx==1.2.0
requests==2.34.2
six==1.17.0
tenacity==9.2.1
typing_extensions==4.16.0
urllib3==2.8.0
yarl==1.25.1
FIJAS

if [ -t 1 ]; then
  ROJO=$'\e[0;31m'; VERDE=$'\e[0;32m'; AZUL=$'\e[0;34m'; RESET=$'\e[0m'
else
  ROJO=""; VERDE=""; AZUL=""; RESET=""
fi
info()  { echo "${AZUL}➜${RESET} $*"; }
ok()    { echo "${VERDE}✔${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

# --- 1. PYTHON 3.11 O MÁS, CON venv ---
info "Verificando Python"
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
  error "packtools ${VERSION} pide Python 3.11 o más; este sistema tiene $(python3 -V 2>&1)."
  exit 1
fi
if ! python3 -c 'import ensurepip, venv' 2>/dev/null; then
  error "Falta el módulo venv de Python: sudo apt install python3-venv"
  exit 1
fi
ok "$(python3 -V)"

# --- 2. EL ENTORNO, DE CERO ---
# UNA INSTALACIÓN ANTERIOR SE REEMPLAZA: ASÍ QUEDAN LAS VERSIONES FIJADAS
TRABAJO="$(mktemp -d)"
trap 'rm -rf -- "$TRABAJO"' EXIT
info "Creando el entorno en ${DESTINO}"
sudo rm -rf -- "${DESTINO:?}"
sudo mkdir -p "$DESTINO"
sudo chown "$(id -u):$(id -g)" "$DESTINO"
python3 -m venv "$DESTINO"
"$DESTINO/bin/pip" install --quiet --upgrade pip

# --- 3. packtools DESDE EL TAG, CON LAS DEPENDENCIAS FIJADAS ---
info "Instalando packtools ${VERSION} desde GitHub"
printf '%s\n' "$RESTRICCIONES" > "$TRABAJO/restricciones.txt"
"$DESTINO/bin/pip" install --quiet -c "$TRABAJO/restricciones.txt" "$FUENTE"

# --- 4. COMPROBACIÓN: LA VERSIÓN DEL CÓDIGO Y QUE CARGUE EL VALIDADOR ---
# packtools/version.py: LA VERSIÓN DE LA INSTALACIÓN LLEVA «rc» Y LA FECHA
# (tag_build Y tag_date EN SU setup.cfg)
instalada="$("$DESTINO/bin/python" -I -c 'import packtools.version as v; print(v.__version__)')"
if [[ "$instalada" != "$VERSION" ]]; then
  error "Se instaló packtools «${instalada}» y se esperaba ${VERSION}."
  exit 1
fi
"$DESTINO/bin/python" -I -c 'from packtools import catalogs, stylechecker; from packtools.sps.models.sps_package import SPS_Package' ||
  { error "packtools se instaló pero no carga."; exit 1; }

# EL ENTORNO QUEDA DE root Y LEGIBLE PARA TODOS: NADIE LO CAMBIA SIN sudo
sudo chown -R root:root "$DESTINO"
sudo chmod -R a+rX "$DESTINO"
ok "packtools ${VERSION} en ${DESTINO}"
