#!/usr/bin/env bash
# ============================================================================
# Script    : publicar.sh
# Propósito : Publica una versión de gbpublisher en GitHub: el .deb, el
#             paquete de la base y el instalador generado desde la plantilla,
#             con las notas de distribucion/release.txt (SC-107).
#
# USO (desde cualquier carpeta)
#   bash distribucion/publicar.sh                  publica la versión del .deb
#   bash distribucion/publicar.sh --ensayo <dir>   arma todo en <dir>, sin
#                                                  etiquetar ni subir: para
#                                                  probar el instalador antes
#   bash distribucion/publicar.sh --revision <N>   reemplaza solo instalador.sh
#                                                  en la versión ya publicada
#                                                  (un error del instalador
#                                                  con el .deb en regla)
#
# DE DÓNDE TOMA CADA COSA
#   El .deb: el único que haya en ~/Dropbox/ubuntu (o en GBP_DIR_DEB).
#   Las notas: distribucion/release.txt («PRERELEASE: no|si», «---» y las
#   notas). Les agrega el esquema que exige la versión y la línea para pegar.
#   El esquema exigido: el actualizar-esquema-*.sh más alto del repositorio.
#   El baseline: el gbpublisher-baseline-*.sql más alto.
#
# QUÉ CONTROLA ANTES (Y FRENA SI NO SE CUMPLE)
#   - Un solo .deb, con la versión de Version= en .project.
#   - El engine/ del .deb igual, archivo por archivo, a .hidden/engine del
#     repositorio: el instalador usa integridad.sh del .deb.
#   - El baseline con sus números de verificación.
#   - Salvo en --ensayo: el repositorio limpio y empujado, y la etiqueta
#     sin usar (o, con --revision, la versión ya publicada).
#
# QUÉ SUBE
#   <paquete>.deb, gbpublisher-base-X.Y.Z.tar.gz e instalador.sh. El nombre
#   del instalador es fijo: LEER-INSTALADOR.md apunta a
#   releases/latest/download/instalador.sh.
#
# SALIDA: 0 publicado (o ensayo armado); 1 algo frenó; 0 si se canceló.
# ============================================================================

set -uo pipefail

# --- 0. CONFIGURACIÓN ---
REPO="albertomoyano/gbpublisher"
DIR_DEB="${GBP_DIR_DEB:-${HOME}/Dropbox/ubuntu}"
DIR_DISTRIBUCION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_REPO="$(dirname "$DIR_DISTRIBUCION")"
PLANTILLA="${DIR_DISTRIBUCION}/instalador.sh.in"
RELEASE_TXT="${DIR_DISTRIBUCION}/release.txt"

if [ -t 1 ]; then
  ROJO=$'\e[0;31m'; VERDE=$'\e[0;32m'; AMBAR=$'\e[0;33m'; NEGRITA=$'\e[1m'; RESET=$'\e[0m'
else
  ROJO=""; VERDE=""; AMBAR=""; NEGRITA=""; RESET=""
fi

ok()    { echo "${VERDE}✔${RESET} $*"; }
aviso() { echo "${AMBAR}⚠${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

# ============================================
# Función   : frenar
# Propósito : Termina con un error
# Parámetros: $* — el motivo
# ============================================
frenar() {
  error "$*"
  exit 1
}

# --- 1. ARGUMENTOS ---
MODO="publicar"
ENSAYO_DIR=""
REVISION="0"
case "${1:-}" in
  "")         ;;
  --ensayo)   MODO="ensayo";   ENSAYO_DIR="${2:-}"; [ -n "$ENSAYO_DIR" ] || frenar "Uso: publicar.sh --ensayo <carpeta>" ;;
  --revision) MODO="revision"; REVISION="${2:-}"; [[ "$REVISION" =~ ^[1-9][0-9]*$ ]] || frenar "Uso: publicar.sh --revision <número, desde 1>" ;;
  *)          frenar "Opción desconocida: $1. Ver el encabezado del script." ;;
esac

for comando in git dpkg-deb sha256sum tar sed sort; do
  command -v "$comando" >/dev/null 2>&1 || frenar "Falta el programa «${comando}»."
done
if [ "$MODO" != "ensayo" ]; then
  command -v gh >/dev/null 2>&1 || frenar "Falta gh (GitHub CLI)."
fi

TMP="$(mktemp -d /tmp/gbp-publicar.XXXXXX)" || frenar "No se pudo crear una carpeta temporal."
trap 'rm -rf -- "$TMP"' EXIT

echo
echo "${NEGRITA}gbpublisher — publicación (${MODO})${RESET}"
echo

# --- 2. EL .deb Y SU VERSIÓN ---
mapfile -t DEBS < <(find "$DIR_DEB" -maxdepth 1 -name '*.deb' -type f | sort)
[ "${#DEBS[@]}" -eq 1 ] || frenar "Tiene que haber exactamente un .deb en ${DIR_DEB} (hay ${#DEBS[@]})."
DEB="${DEBS[0]}"
DEB_NOMBRE="$(basename "$DEB")"
# EL NOMBRE ES gbpublisher_0.0.454-0ubuntu1_all.deb: LA VERSIÓN ES EL SEGUNDO
# CAMPO SEPARADO POR _, HASTA EL GUION
VERSION="$(cut -d'_' -f2 <<< "$DEB_NOMBRE" | cut -d'-' -f1)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || frenar "No se pudo leer la versión de ${DEB_NOMBRE}."
TAG="v${VERSION}"
VERSION_PROYECTO="$(sed -n 's/^Version=//p' "${DIR_REPO}/.project")"
[ "$VERSION_PROYECTO" = "$VERSION" ] || frenar "El .deb es ${VERSION} y .project dice ${VERSION_PROYECTO}: el .deb no es de este repositorio."
ok "Paquete: ${DEB_NOMBRE}"

# --- 3. EL engine/ DEL .deb CONTRA EL REPOSITORIO ---
# UN .deb ARMADO ANTES DEL ÚLTIMO CAMBIO EN engine/ HARÍA FALLAR AL
# INSTALADOR (TRAE integridad.sh). SE COMPARAN LOS ARCHIVOS QUE SIGUE git, Y
# SE NOMBRA LO QUE EL .deb TRAE DE MÁS
dpkg-deb -x "$DEB" "${TMP}/deb" || frenar "No se pudo abrir el .deb."
DIR_ENGINE_DEB="${TMP}/deb/usr/share/gbpublisher/engine"
[ -d "$DIR_ENGINE_DEB" ] || frenar "El .deb no trae usr/share/gbpublisher/engine."
diferencias=()
while IFS= read -r rel; do
  r="${rel#.hidden/engine/}"
  if [ ! -f "${DIR_ENGINE_DEB}/${r}" ]; then
    diferencias+=("falta en el .deb: ${r}")
  elif ! cmp -s "${DIR_REPO}/${rel}" "${DIR_ENGINE_DEB}/${r}"; then
    diferencias+=("distinto: ${r}")
  fi
done < <(git -C "$DIR_REPO" ls-files .hidden/engine)
while IFS= read -r f; do
  r="${f#"${DIR_ENGINE_DEB}"/}"
  git -C "$DIR_REPO" ls-files --error-unmatch ".hidden/engine/${r}" >/dev/null 2>&1 \
    || diferencias+=("el .deb trae y el repositorio no sigue: ${r}")
done < <(find "$DIR_ENGINE_DEB" -type f | sort)
if [ "${#diferencias[@]}" -gt 0 ]; then
  error "El engine/ del .deb no es el del repositorio:"
  printf '    %s\n' "${diferencias[@]}" >&2
  frenar "Vuelva a generar el .deb desde el repositorio actual."
fi
ok "engine/ del .deb igual al del repositorio"

# --- 4. ESQUEMA, BASELINE Y PLANTILLA ---
ESQUEMA="$(cd "$DIR_REPO" && ls actualizar-esquema-*.sh | sed 's/^actualizar-esquema-//;s/\.sh$//' | sort -V | tail -n 1)"
BASELINE="$(cd "$DIR_REPO" && ls gbpublisher-baseline-*.sql | sed 's/^gbpublisher-baseline-//;s/\.sql$//' | sort -V | tail -n 1)"
[ -n "$ESQUEMA" ] && [ -n "$BASELINE" ] || frenar "No se encontraron los scripts de esquema o el baseline."
grep -q '^-- Verificación: tablas=[0-9]*$' "${DIR_REPO}/gbpublisher-baseline-${BASELINE}.sql" \
  || frenar "El baseline ${BASELINE} no declara sus números de verificación (generar-baseline.sh)."
[ -f "$PLANTILLA" ] || frenar "Falta la plantilla ${PLANTILLA}."
ok "Esquema exigido: ${ESQUEMA} (baseline ${BASELINE})"

# --- 5. LAS NOTAS ---
[ -f "$RELEASE_TXT" ] || frenar "Falta ${RELEASE_TXT}."
PRERELEASE_FLAG=""
if head -n 1 "$RELEASE_TXT" | tr '[:upper:]' '[:lower:]' | grep -q "prerelease: si"; then
  PRERELEASE_FLAG="--prerelease"
fi
NOTAS_PROPIAS="$(awk '/^---$/{f=1; next} f{print}' "$RELEASE_TXT")"
[ -n "$(tr -d '[:space:]' <<< "$NOTAS_PROPIAS")" ] || frenar "No hay notas en ${RELEASE_TXT} (¿falta el separador ---?)."

# --- 6. EL REPOSITORIO ---
COMMIT="$(git -C "$DIR_REPO" rev-parse HEAD)"
if [ "$MODO" != "ensayo" ]; then
  # LIMPIO: LO PUBLICADO TIENE QUE PODER RECONSTRUIRSE DESDE LA ETIQUETA
  [ -z "$(git -C "$DIR_REPO" status --porcelain)" ] || frenar "El repositorio tiene cambios sin commit (git status)."
  git -C "$DIR_REPO" fetch --quiet origin || frenar "No se pudo consultar el repositorio remoto."
  REMOTO="$(git -C "$DIR_REPO" rev-parse '@{u}' 2>/dev/null)" || frenar "La rama no sigue a una rama remota."
  [ "$COMMIT" = "$REMOTO" ] || frenar "La rama no está empujada, o le falta traer cambios (git push / git pull)."
  ok "Repositorio limpio y empujado (${COMMIT:0:10})"
  if [ "$MODO" = "publicar" ]; then
    if git -C "$DIR_REPO" rev-parse -q --verify "refs/tags/${TAG}" >/dev/null \
       || [ -n "$(git -C "$DIR_REPO" ls-remote --tags origin "refs/tags/${TAG}")" ]; then
      frenar "La etiqueta ${TAG} ya existe. Para corregir solo el instalador: --revision <N>."
    fi
  else
    gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1 || frenar "La versión ${TAG} no está publicada."
  fi
fi

# --- 7. LO QUE SE SUBE ---
SALIDA="${TMP}/salida"
mkdir -p "$SALIDA"
BASE_NOMBRE="gbpublisher-base-${VERSION}.tar.gz"

if [ "$MODO" = "revision" ]; then
  # UNA REVISIÓN NO CAMBIA EL .deb NI EL PAQUETE DE LA BASE: SE TOMAN LOS
  # PUBLICADOS, Y EL .deb DE DROPBOX TIENE QUE SER EL MISMO
  gh release download "$TAG" --repo "$REPO" --dir "$SALIDA" --pattern "$BASE_NOMBRE" --pattern "$DEB_NOMBRE" \
    || frenar "No se pudieron bajar los archivos publicados de ${TAG}."
  cmp -s "$DEB" "${SALIDA}/${DEB_NOMBRE}" || frenar "El .deb de ${DIR_DEB} no es el publicado en ${TAG}: una revisión solo cambia el instalador."
else
  cp "$DEB" "${SALIDA}/" || frenar "No se pudo copiar el .deb."
  # EL PAQUETE DE LA BASE: EL BASELINE, TODOS LOS SCRIPTS DE ESQUEMA Y
  # configurar-conexion.sh, BAJO UNA CARPETA CON LA VERSIÓN. tar CON ORDEN,
  # FECHA Y DUEÑO FIJOS: EL MISMO CONTENIDO DA EL MISMO ARCHIVO
  DIR_BASE="${TMP}/gbpublisher-base-${VERSION}"
  mkdir -p "$DIR_BASE"
  cp "${DIR_REPO}/gbpublisher-baseline-${BASELINE}.sql" "${DIR_REPO}"/actualizar-esquema-*.sh \
     "${DIR_REPO}/configurar-conexion.sh" "$DIR_BASE/" || frenar "No se pudo armar el paquete de la base."
  tar --sort=name --mtime='2000-01-01 00:00:00 UTC' --owner=0 --group=0 --numeric-owner \
      -C "$TMP" -cf - "gbpublisher-base-${VERSION}" | gzip -n > "${SALIDA}/${BASE_NOMBRE}" \
      || frenar "No se pudo comprimir el paquete de la base."
fi
DEB_SHA="$(sha256sum "${SALIDA}/${DEB_NOMBRE}" | cut -d' ' -f1)"
BASE_SHA="$(sha256sum "${SALIDA}/${BASE_NOMBRE}" | cut -d' ' -f1)"

# EL INSTALADOR: LA PLANTILLA CON LAS MARCAS REEMPLAZADAS. LOS VALORES SON
# NÚMEROS DE VERSIÓN, HUELLAS Y NOMBRES DE ARCHIVO: NO TIENEN «|»
sed -e "s|@VERSION@|${VERSION}|g" \
    -e "s|@REVISION@|${REVISION}|g" \
    -e "s|@DEB_NOMBRE@|${DEB_NOMBRE}|g" \
    -e "s|@DEB_SHA@|${DEB_SHA}|g" \
    -e "s|@BASE_NOMBRE@|${BASE_NOMBRE}|g" \
    -e "s|@BASE_SHA@|${BASE_SHA}|g" \
    -e "s|@ESQUEMA@|${ESQUEMA}|g" \
    -e "s|@BASELINE@|${BASELINE}|g" \
    -e "s|@GENERADO@|$(date '+%Y-%m-%d %H:%M') desde ${COMMIT:0:10}|g" \
    "$PLANTILLA" > "${SALIDA}/instalador.sh"
if grep -nE '@[A-Z_]+@' "${SALIDA}/instalador.sh" >&2; then
  frenar "Quedaron marcas sin reemplazar en el instalador."
fi
bash -n "${SALIDA}/instalador.sh" || frenar "El instalador generado tiene un error de sintaxis."
chmod 755 "${SALIDA}/instalador.sh"

# LAS NOTAS: LAS DE release.txt, EL ESQUEMA Y LA LÍNEA PARA PEGAR. LA LÍNEA
# APUNTA A ESTA VERSIÓN, NO A latest: LAS NOTAS DE UNA VERSIÓN VIEJA TIENEN
# QUE SEGUIR INSTALANDO ESA VERSIÓN
{
  printf '%s\n' "$NOTAS_PROPIAS"
  echo
  echo "### Instalación"
  echo
  echo "Lea antes [LEER-INSTALADOR.md](https://github.com/${REPO}/blob/${TAG}/LEER-INSTALADOR.md). Después, en una terminal, pegue esta línea:"
  echo
  echo '```'
  echo "curl -fsSLo instalador.sh https://github.com/${REPO}/releases/download/${TAG}/instalador.sh && bash instalador.sh"
  echo '```'
  echo
  echo "El instalador lleva la base al esquema ${ESQUEMA}. Actualiza solo bases en la 2.0.0 o posterior."
} > "${SALIDA}/notas.md"

ok "Instalador generado (revisión ${REVISION}) y paquete de la base armado"

# --- 8. RESUMEN Y CONFIRMACIÓN ---
echo
echo "=========================================="
echo "  ${NEGRITA}${TAG}${RESET} — ${MODO}"
echo "=========================================="
echo "  .deb      : ${DEB_NOMBRE}"
echo "  base      : ${BASE_NOMBRE}"
echo "  instalador: instalador.sh (revisión ${REVISION})"
echo "  esquema   : ${ESQUEMA} (baseline ${BASELINE})"
echo "  commit    : ${COMMIT:0:10}"
if [ -n "$PRERELEASE_FLAG" ]; then echo "  tipo      : PRE-RELEASE"; else echo "  tipo      : ESTABLE"; fi
echo
echo "  Notas:"
sed 's/^/    /' "${SALIDA}/notas.md"
echo "=========================================="
echo

if [ "$MODO" = "ensayo" ]; then
  mkdir -p "$ENSAYO_DIR" || frenar "No se pudo crear ${ENSAYO_DIR}."
  cp "${SALIDA}"/* "$ENSAYO_DIR/" || frenar "No se pudo copiar a ${ENSAYO_DIR}."
  ok "Ensayo armado en ${ENSAYO_DIR}"
  echo
  echo "  Copie esa carpeta a la máquina de prueba y, ahí, ejecute:"
  echo "    bash instalador.sh"
  echo "  El instalador usa los archivos que están a su lado y no los descarga."
  exit 0
fi

read -r -p "¿Publicar? [s/n]: " CONFIRMAR
case "${CONFIRMAR,,}" in
  s|si|sí) ;;
  *) echo "No se publicó nada."; exit 0 ;;
esac

# --- 9. PUBLICACIÓN ---
if [ "$MODO" = "publicar" ]; then
  # LA ETIQUETA SE CREA EN EL COMMIT CONTROLADO, NO EN LA PUNTA DE LA RAMA
  # PRINCIPAL DE ESE MOMENTO
  gh release create "$TAG" \
     "${SALIDA}/${DEB_NOMBRE}" "${SALIDA}/${BASE_NOMBRE}" "${SALIDA}/instalador.sh" \
     --repo "$REPO" --title "gbpublisher ${TAG}" --notes-file "${SALIDA}/notas.md" \
     --target "$COMMIT" $PRERELEASE_FLAG \
     || frenar "La publicación falló: el motivo está más arriba."
else
  # --clobber BORRA EL instalador.sh PUBLICADO Y SUBE EL NUEVO. LA REVISIÓN
  # QUEDA ESCRITA ADENTRO Y EN EL REGISTRO DE CADA INSTALACIÓN
  gh release upload "$TAG" "${SALIDA}/instalador.sh" --repo "$REPO" --clobber \
     || frenar "No se pudo reemplazar el instalador: el motivo está más arriba."
fi

echo
ok "${TAG} publicado."
