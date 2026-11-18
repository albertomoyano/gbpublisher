#!/usr/bin/env bash
# ============================================================================
# Script    : instalar_packtools.sh
# Propósito : Instala packtools 4.18.2 (el validador de SciELO PS) en un
#             entorno de Python propio, en /opt/packtools. Lo usan
#             generar_scielo_revista.sh y la solapa «Validaciones» (tipo
#             SciELO), a través de engine/validar_sps.py.
# Por qué así: la versión de PyPI es la 2.6.4 (vieja, sin sps-1.9); la
#             4.18.2 solo se publica en GitHub y pide Python 3.11 o más.
#             Un entorno propio no toca el Python del sistema (sin
#             --break-system-packages) y fija las versiones de cada
#             dependencia: las mismas con que se probó (18/11/2026).
# Uso       : lo llama integridad.sh, ya como root (pkexec), con
#             GBP_ANIDADO=1. Corrido a mano por un usuario común, pide
#             la contraseña con sudo para escribir en /opt.
# Requisitos: python3 >= 3.11 con venv (python3-venv, dependencia del .deb);
#             red hacia github.com y pypi.org.
# Historia  : era instalar-packtools.sh, en la raíz del repositorio y fuera
#             del .deb. Se mudó a engine/ para que integridad.sh lo use sin
#             copiar la lista de versiones, y habla con el vocabulario de
#             comun.sh. La lógica es la misma.
# ============================================================================

set -euo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 0. CONFIGURACIÓN ---
VERSION="4.18.2"
DESTINO="/opt/packtools"
FUENTE="https://github.com/scieloorg/packtools/archive/refs/tags/${VERSION}.tar.gz"

# COMO root (integridad.sh) NO HACE FALTA sudo; A MANO, SÍ
SUDO=""
(( EUID == 0 )) || SUDO="sudo"

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

encabezado "packtools ${VERSION}"

# --- 1. PYTHON 3.11 O MÁS, CON venv ---
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
    morir "packtools ${VERSION} pide Python 3.11 o más; este sistema tiene $(python3 -V 2>&1)."
fi
if ! python3 -c 'import ensurepip, venv' 2>/dev/null; then
    morir "Falta el módulo venv de Python (paquete python3-venv). Reinstalá gbpublisher: es una de sus dependencias."
fi
ok "$(python3 -V)"

# --- 2. EL ENTORNO, DE CERO ---
# UNA INSTALACIÓN ANTERIOR SE REEMPLAZA: ASÍ QUEDAN LAS VERSIONES FIJADAS.
# TAMBIÉN LA QUE QUEDÓ ROTA PORQUE CAMBIÓ EL PYTHON DEL SISTEMA (UN SALTO DE
# VERSIÓN DE MINT): UN ENTORNO DE venv APUNTA AL INTÉRPRETE CON QUE SE CREÓ
TRABAJO="$(mktemp -d)"
trap 'rm -rf -- "$TRABAJO"' EXIT
tenue "creando el entorno en ${DESTINO}"
$SUDO rm -rf -- "${DESTINO:?}"
$SUDO mkdir -p "$DESTINO"
$SUDO chown "$(id -u):$(id -g)" "$DESTINO"
python3 -m venv "$DESTINO"
"$DESTINO/bin/pip" install --quiet --upgrade pip
ok "entorno creado"

# --- 3. packtools DESDE EL TAG, CON LAS DEPENDENCIAS FIJADAS ---
tenue "instalando packtools ${VERSION} desde GitHub (puede tardar unos minutos)"
printf '%s\n' "$RESTRICCIONES" > "$TRABAJO/restricciones.txt"
"$DESTINO/bin/pip" install --quiet -c "$TRABAJO/restricciones.txt" "$FUENTE" ||
    morir "pip no pudo instalar packtools ${VERSION}: el motivo está más arriba."

# --- 4. COMPROBACIÓN: LA VERSIÓN DEL CÓDIGO Y QUE CARGUE EL VALIDADOR ---
# packtools/version.py: LA VERSIÓN DE LA INSTALACIÓN LLEVA «rc» Y LA FECHA
# (tag_build Y tag_date EN SU setup.cfg)
instalada="$("$DESTINO/bin/python" -I -c 'import packtools.version as v; print(v.__version__)')"
if [[ "$instalada" != "$VERSION" ]]; then
    morir "Se instaló packtools «${instalada}» y se esperaba ${VERSION}."
fi
"$DESTINO/bin/python" -I -c 'from packtools import catalogs, stylechecker; from packtools.sps.models.sps_package import SPS_Package' ||
    morir "packtools se instaló pero no carga."

# EL ENTORNO QUEDA DE root Y LEGIBLE PARA TODOS: NADIE LO CAMBIA SIN sudo
$SUDO chown -R root:root "$DESTINO"
$SUDO chmod -R a+rX "$DESTINO"
ok "packtools ${VERSION} en ${DESTINO}"

terminar
