#!/usr/bin/env bash
#
# ============================================
# Script    : limpiar-hidden-bloque3.sh
# Propósito : Bloque 3 de la limpieza (SC-97): borra de .hidden/ los recursos
#             que nada usa. Se corre UNA vez, desde la raíz del repositorio, y
#             después se puede borrar. No toca el sistema ni ~/.gbpublisher.
# Uso       : bash limpiar-hidden-bloque3.sh
# Qué borra :
#   - xslt/: las hojas de los envíos viejos y la de prueba
#   - filters/: table-to-end.lua y postprocesar_jats.py
#   - dtd/: la Tag Library y los zips de DTD, RNG y XSD (se usan los
#     archivos sueltos, no los zips)
#   - schematron/: el clon de jats-schematrons y el jar de SchXslt
#   - schemas/crossref/: los XSD que la validación no alcanza. La lista de
#     los que SE QUEDAN es explícita: los veinte que alcanza crossref5.4.0.xsd
#     siguiendo sus include e import, con el catálogo
# Qué NO borra: scripts/ (espacio del usuario), schematron/iso (generadores),
#   schematron/schxslt-xslt (GV-26, se decide en el bloque 3a)
# ============================================

set -euo pipefail

if [ -t 1 ]; then
  ROJO=$'\e[0;31m'; VERDE=$'\e[0;32m'; AMBAR=$'\e[0;33m'
  AZUL=$'\e[0;34m'; NEGRITA=$'\e[1m'; RESET=$'\e[0m'
else
  ROJO=""; VERDE=""; AMBAR=""; AZUL=""; NEGRITA=""; RESET=""
fi
info()  { echo "${AZUL}➜${RESET} $*"; }
ok()    { echo "${VERDE}✔${RESET} $*"; }
warn()  { echo "${AMBAR}⚠${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

# --- 1. ¿ESTAMOS EN LA RAÍZ DEL REPOSITORIO? ---
if [ ! -f .project ] || [ ! -d .hidden ]; then
  error "Correlo desde la raíz del repositorio de gbpublisher (donde están .project y .hidden)."
  exit 1
fi
H=".hidden"

# --- 2. LA LISTA FIJA ---
FIJOS=(
  "$H/xslt/jats-to-crossref.xsl"
  "$H/xslt/jats-to-doaj.xsl"
  "$H/xslt/jats-to-redalyc.xsl"
  "$H/xslt/jats-to-scielo.xsl"
  "$H/xslt/prueba-saxon.xslt"
  "$H/filters/table-to-end.lua"
  "$H/filters/postprocesar_jats.py"
  "$H/dtd/Green-1_4-HTML.zip"
  "$H/dtd/JATS-Archiving-1-4-MathML2-DTD.zip"
  "$H/dtd/JATS-Archiving-1-4-MathML3-DTD.zip"
  "$H/dtd/JATS-Archiving-1-4-OASIS-MathML2-DTD.zip"
  "$H/dtd/JATS-Archiving-1-4-OASIS-MathML3-DTD.zip"
  "$H/dtd/rng"
  "$H/dtd/xsd"
  "$H/schematron/jats-schematrons"
  "$H/schematron/schxslt"
)

# --- 3. schemas/crossref: TODO MENOS LO QUE ALCANZA LA VALIDACIÓN ---
# LOS VEINTE QUE ALCANZA crossref5.4.0.xsd (MÁS EL CATÁLOGO). standard-modules/
# SE QUEDA ENTERA: SUS TRES ARCHIVOS ESTÁN EN EL ALCANCE
QUEDAN=(
  catalogo-crossref.xml
  crossref5.4.0.xsd common5.4.0.xsd fundingdata5.4.0.xsd fundref.xsd
  languages5.4.0.xsd mediatypes5.4.0.xsd relations.xsd
  AccessIndicators.xsd clinicaltrials.xsd
  JATS-journalpublishing1-3d2-mathml3.xsd JATS-journalpublishing1-3d2-mathml3-elements.xsd
  mathml3.xsd mathml3-common.xsd mathml3-content.xsd
  mathml3-presentation.xsd mathml3-strict-content.xsd xml.xsd
)
CROSSREF=()
if [ -d "$H/schemas/crossref" ]; then
  while IFS= read -r -d '' f; do
    nombre="$(basename "$f")"
    queda=0
    for k in "${QUEDAN[@]}"; do [ "$nombre" = "$k" ] && queda=1 && break; done
    [ "$queda" -eq 0 ] && CROSSREF+=("$f")
  done < <(find "$H/schemas/crossref" -maxdepth 1 -type f -print0)
  # LOS QUE SE QUEDAN TIENEN QUE ESTAR: SI FALTA ALGUNO, ALGO NO ES COMO SE MIDIÓ
  for k in "${QUEDAN[@]}"; do
    if [ ! -f "$H/schemas/crossref/$k" ]; then
      error "Falta $H/schemas/crossref/$k, que la validación de Crossref necesita. No se borró nada."
      exit 1
    fi
  done
fi

# --- 4. LO QUE EXISTE DE VERDAD, Y CUÁNTO PESA ---
BORRAR=()
for p in "${FIJOS[@]}" "${CROSSREF[@]}"; do
  [ -e "$p" ] && BORRAR+=("$p")
done
if [ "${#BORRAR[@]}" -eq 0 ]; then
  ok "No hay nada que borrar: el bloque 3 ya está aplicado."
  exit 0
fi

echo
echo "${NEGRITA}Bloque 3: recursos de .hidden sin uso${RESET}"
echo "--------------------------------------"
for p in "${FIJOS[@]}"; do
  [ -e "$p" ] && printf '  %8s  %s\n' "$(du -sh "$p" | cut -f1)" "$p"
done
if [ "${#CROSSREF[@]}" -gt 0 ]; then
  printf '  %8s  %s\n' "$(du -ch "${CROSSREF[@]}" | tail -n 1 | cut -f1)" "$H/schemas/crossref/: ${#CROSSREF[@]} XSD que la validación no alcanza"
fi
echo
info "En total: $(du -ch "${BORRAR[@]}" | tail -n 1 | cut -f1)"
read -r -p "Para borrar, escribí SI en mayúsculas: " RESPUESTA
if [ "$RESPUESTA" != "SI" ]; then
  warn "Cancelado. No se borró nada."
  exit 0
fi

# --- 5. EL BORRADO ---
rm -rf -- "${BORRAR[@]}"
ok "Borrados ${#BORRAR[@]} archivos y carpetas."
info "Las copias viejas en ~/.gbpublisher (dtd, schemas, schematron, xslt) no se tocan: no estorban."
