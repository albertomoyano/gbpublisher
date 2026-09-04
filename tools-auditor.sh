#!/bin/sh
# ============================================
# tools-auditor.sh
#
# Descarga e instala los juegos de DTD JATS Publishing que el auditor
# de XML externos necesita para validar archivos ajenos contra la
# gramática que cada uno declara.
#
# ============================================
# POR QUÉ HACE FALTA
#
# Los archivos JATS declaran su gramática con una dirección de
# internet. Sin copia local, xmllint sale a buscarla en cada archivo:
# tarda, depende de la red, y cuando falla el error PARECE del
# documento y no lo es. Es la fuente más común de falsos diagnósticos
# en el sector.
#
# Además hay que validar cada archivo contra la versión que ÉL declara.
# Validar un JATS 1.1 contra la DTD 1.3 produce cientos de errores que
# no son errores del documento.
#
# ============================================
# QUÉ INSTALA Y POR QUÉ ESAS VERSIONES
#
# Las cinco versiones de Publishing presentes en el corpus de
# referencia, de siete generadores distintos:
#
#   1.0    SciELO SPS 1.8
#   1.1    SciELO SPS 1.9
#   1.1d3  Marcalyc antiguo (borrador que nunca fue norma final)
#   1.2    OJS, plantillas derivadas de PLOS
#   1.3    Marcalyc actual, sistemas propios
#
# NO se instala Archiving: ningún archivo del corpus lo declara, y la
# 1.4 Archiving que usa el pipeline propio ya está en dtd/.
#
# De las cuatro variantes que publica NISO por versión se toma
# MathML2 sin OASIS: es el modelo de tabla XHTML, que es el que usan
# los archivos reales, y coincide con lo que ya hay para la 1.4.
# La TagLibrary es documentación y no se instala.
#
# Uso:  sudo sh tools-auditor.sh
# ============================================

set -u

BASE_URL="https://public.nlm.nih.gov/projects/jats/publishing"
DESTINO="/usr/share/gbpublisher/dtd"
VERSIONES="1.0 1.1 1.1d3 1.2 1.3"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ok=0
fallidas=""

echo
echo "  Instalación de DTD JATS Publishing para el auditor"
echo "  ────────────────────────────────────────────────────────────"
echo

# --- 1. PRECONDICIONES ---
for h in curl unzip; do
  if ! command -v "$h" >/dev/null 2>&1; then
    echo "  FALTA la herramienta: $h" >&2
    exit 1
  fi
done

if [ ! -d "$DESTINO" ]; then
  echo "  FALTA el directorio: $DESTINO" >&2
  echo "  ¿Está gbpublisher instalado?" >&2
  exit 1
fi

if [ ! -w "$DESTINO" ]; then
  echo "  SIN PERMISO de escritura en $DESTINO" >&2
  echo "  Ejecutar con sudo." >&2
  exit 1
fi

# --- 2. DESCARGA E INSTALACIÓN, VERSIÓN POR VERSIÓN ---
# Cada versión va a su propio subdirectorio. Así agregar una versión
# futura es correr este script con el número nuevo, sin tocar nada de
# lo instalado.
for v in $VERSIONES; do

  printf "  JATS %-7s " "$v"

  # 2.1 NOMBRE DEL ARCHIVO
  # NISO cambió la convención de nombres entre versiones. Desde la 1.1
  # el zip es 'JATS-Publishing-1-1-MathML2-DTD.zip', con la versión
  # separada por guiones; la 1.0, que es anterior a esa convención, se
  # llama 'jats-publishing-dtd-1.0.zip'.
  case "$v" in
    1.0)
      zip="jats-publishing-dtd-1.0.zip"
      ;;
    *)
      vguion=$(echo "$v" | tr '.' '-')
      zip="JATS-Publishing-${vguion}-MathML2-DTD.zip"
      ;;
  esac
  url="$BASE_URL/$v/$zip"

  # 2.2 DESCARGA
  if ! curl -sfL -o "$TMP/$zip" "$url" 2>/dev/null; then
    echo "no se pudo descargar"
    echo "           $url"
    fallidas="$fallidas $v"
    continue
  fi

  tam=$(du -h "$TMP/$zip" | cut -f1)

  # 2.3 DESCOMPRESIÓN A UN DIRECTORIO PROPIO
  dir="$DESTINO/jats-$v"
  rm -rf "$dir"
  mkdir -p "$dir"

  if ! unzip -q -o "$TMP/$zip" -d "$dir" 2>/dev/null; then
    echo "descargado pero no se pudo descomprimir"
    fallidas="$fallidas $v"
    continue
  fi

  # 2.4 APLANADO
  # Algunos zip traen todo dentro de una carpeta y otros no. Se
  # normaliza para que el catálogo encuentre los archivos siempre en
  # el mismo lugar.
  interior=$(find "$dir" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -n "$interior" ] && [ "$(find "$dir" -maxdepth 1 -name '*.dtd' | wc -l)" -eq 0 ]; then
    mv "$interior"/* "$dir"/ 2>/dev/null
    rmdir "$interior" 2>/dev/null
  fi

  # 2.5 VERIFICACIÓN: ¿QUEDÓ LA DTD PRINCIPAL Y UN CATÁLOGO?
  dtd=$(find "$dir" -maxdepth 2 -name 'JATS-journalpublishing*.dtd' | head -1)

  # SE PREFIERE SIEMPRE LA VARIANTE 'no-base'. La 'with-base' trae un
  # marcador de posición literal en el atributo xml:base -"put a real
  # base here, such as file:///C:/MyWork/..."- que hay que reemplazar
  # a mano; sin reemplazarlo NO resuelve ninguna entrada y la
  # validación falla con 'failed to load external entity'.
  # Se excluyen además los catálogos de prueba: algunas versiones traen
  # un 'catalog-test-...' que apunta a una DTD de ejemplo y no a la de
  # publicación.
  cat=$(find "$dir" -maxdepth 2 -name 'catalog*no-base*.xml' ! -name '*test*' | head -1)
  if [ -z "$cat" ]; then
    cat=$(find "$dir" -maxdepth 2 -name 'catalog*.xml' ! -name '*test*' | head -1)
  fi
  if [ -z "$cat" ]; then
    cat=$(find "$dir" -maxdepth 2 -name 'catalog*.xml' | head -1)
  fi

  if [ -z "$dtd" ]; then
    echo "instalado pero SIN la DTD principal"
    fallidas="$fallidas $v"
    continue
  fi

  if [ -z "$cat" ]; then
    echo "instalado ($tam) · SIN CATÁLOGO, hay que armarlo a mano"
    fallidas="$fallidas $v"
    continue
  fi

  # 2.5b RUTAS DE MARCADOR DE POSICIÓN
  # Algunos catálogos de NISO traen las entradas dentro de <group> con
  # un xml:base de ejemplo sin resolver -"file:///C:/Work/Tasks/..."-
  # que hay que reemplazar a mano. Sin quitarlo, las uri se resuelven
  # contra un directorio de Windows inexistente y NADA resuelve: el
  # documento pasa la validación sin haberse validado.
  #
  # En las versiones 1.1 en adelante eso distingue a la variante
  # 'with-base' de la 'no-base' y se evita eligiendo la segunda. En la
  # 1.0, anterior a esa convención, el único catálogo de publicación
  # lo trae igual, así que hay que limpiarlo.
  if grep -q 'xml:base="file:///C:/' "$cat" 2>/dev/null; then
    sed -i 's| xml:base="file:///C:/[^"]*"||g' "$cat"
  fi

  # 2.6 ¿RESUELVE DE VERDAD?
  # No se analiza el catálogo: se prueba. Cualquier lectura del
  # archivo es indirecta y se equivoca, porque los catálogos de NISO
  # traen entradas genéricas -'journalpublishing88.dtd', donde 88
  # significa "cualquier versión"- que aparecen primero y apuntan a
  # archivos que no se distribuyen. Analizando el texto, todas las
  # versiones parecen rotas; probando, todas funcionan salvo las que
  # de verdad fallan.
  #
  # Se arma un XML mínimo que declara el publicId de esta versión y se
  # valida con el catálogo recién instalado. Si xmllint no puede
  # resolver la DTD lo dice explícitamente.
  publico=$(grep -o 'publicId="[^"]*Journal Publishing DTD v'"$v"'[^"]*"' "$cat" |
            head -1 | cut -d'"' -f2)

  if [ -z "$publico" ]; then
    echo "instalado ($tam) · el catálogo no declara la DTD de esta versión"
    fallidas="$fallidas $v(catálogo)"
    continue
  fi

  cat > "$TMP/sonda.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE article PUBLIC "$publico" "JATS-journalpublishing1.dtd">
<article/>
XML

  salida=$(XML_CATALOG_FILES="$cat" xmllint --noout --valid --nonet "$TMP/sonda.xml" 2>&1)

  if echo "$salida" | grep -q "failed to load\|no DTD found"; then
    echo "instalado ($tam) · el catálogo NO resuelve la DTD"
    fallidas="$fallidas $v(catálogo)"
    continue
  fi


  # 2.7 INSTALACIÓN CORRECTA
  echo "instalado ($tam) · $(basename "$cat")"
  ok=$((ok + 1))

done

# --- 3. CATÁLOGO MAESTRO ---
# Encadena los catálogos de cada versión. Es lo único que el auditor
# necesita conocer: xmllint resuelve solo el identificador público que
# declara cada archivo y encuentra la DTD que corresponde.
echo
printf "  Catálogo maestro  "

maestro="$DESTINO/catalog-auditor.xml"
{
  echo '<?xml version="1.0"?>'
  echo '<catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog" prefer="public">'
  echo '  <!-- Encadena los catálogos de cada versión de JATS Publishing.'
  echo '       Generado por tools-auditor.sh: no editar a mano. -->'
  for v in $VERSIONES; do
    c=$(cd "$DESTINO" 2>/dev/null && find "jats-$v" -maxdepth 2 -name 'catalog*no-base*.xml' ! -name '*test*' 2>/dev/null | head -1)
    if [ -z "$c" ]; then
      c=$(cd "$DESTINO" 2>/dev/null && find "jats-$v" -maxdepth 2 -name 'catalog*.xml' ! -name '*test*' 2>/dev/null | head -1)
    fi
    if [ -z "$c" ]; then
      c=$(cd "$DESTINO" 2>/dev/null && find "jats-$v" -maxdepth 2 -name 'catalog*.xml' 2>/dev/null | head -1)
    fi
    [ -n "$c" ] && echo "  <nextCatalog catalog=\"$c\"/>"
  done
  echo '</catalog>'
} > "$maestro"

entradas=$(grep -c "nextCatalog" "$maestro")
echo "$entradas versiones encadenadas"
echo "                    $maestro"

# --- 4. INFORME ---
echo
echo "  ────────────────────────────────────────────────────────────"
echo "  Instaladas: $ok de $(echo $VERSIONES | wc -w)"

if [ -n "$fallidas" ]; then
  echo "  Con problemas:$fallidas"
  echo
  echo "  Las versiones que falten no se validan. El auditor sigue"
  echo "  funcionando y lo declara en el bloque de alcance del informe,"
  echo "  pero los archivos que las declaren quedan sin comprobar"
  echo "  contra su gramática."
fi

echo
echo "  Comprobación rápida, con un XML que declare alguna de estas"
echo "  versiones:"
echo
echo "    XML_CATALOG_FILES=$maestro \\"
echo "      xmllint --noout --valid --nonet archivo.xml"
echo
echo "  Si informa errores de validez y NO dice 'failed to load"
echo "  external entity', el catálogo está resolviendo bien."
echo
