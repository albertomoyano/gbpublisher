#!/usr/bin/env bash
# ==============================================================================
# Script    : generar-baseline.sh
# Propósito : Genera el artefacto de distribución de la base de datos de
#             gbpublisher a partir de la base de desarrollo del autor.
#
#             Produce un archivo .sql limpio, portable y reproducible que
#             contiene:
#               - La estructura completa de todas las tablas.
#               - Los datos de las tablas SEMILLA únicamente.
#               - La tabla de control esquema_version con su nivel declarado.
#
#             Todo lo que no sea semilla se vuelca VACÍO: los datos de
#             trabajo del autor (proyectos, post-its, contadores, siglas,
#             credenciales de API) no viajan en la distribución.
#
# Uso       : ./generar-baseline.sh [opciones]
#
#   -h HOST      Host del servidor de origen        (por defecto: localhost)
#   -P PUERTO    Puerto                             (por defecto: 3306)
#   -S SOCKET    Ruta del socket Unix (alternativa a -h/-P)
#   -u USUARIO   Usuario con permiso de lectura     (por defecto: root)
#   -d BASE      Base de origen                     (por defecto: gbpublisher)
#   -V VERSION   Versión del baseline a generar     (por defecto: 2.0.0)
#   -o DIR       Directorio de salida               (por defecto: .)
#   -v           Verificar cargando el artefacto en una base temporal
#
# Origen recomendado (2.0.0): una base instalada desde cero con la cadena
#   completa (baseline 1.0.0 + actualizaciones hasta la 2.0.0), no la base
#   de trabajo. Así el baseline coincide con lo que tiene toda instalación
#   actualizada, sin los ajustes propios de una instalación (por ejemplo,
#   un formato de página desactivado).
#
# Correcciones que aplica automáticamente:
#   1. Normaliza la colación a utf8mb4_unicode_ci, la del proyecto: una
#      columna utf8mb4_0900_ai_ci comparada con una del proyecto da
#      «Illegal mix of collations» (GV-175).
#   2. Elimina las cláusulas DEFINER de triggers y rutinas, que apuntan a
#      un usuario que no existe en los servidores de destino.
#   3. Resetea los contadores AUTO_INCREMENT residuales.
#   4. Marca las consultas canónicas con consulta_sistema = 1.
#   5. Declara el nivel de esquema en esquema_version.
#
# Requisitos: mysqldump y mysql (MySQL 8; el proyecto no usa MariaDB).
#             El usuario necesita SELECT sobre la base, más SHOW VIEW y
#             TRIGGER para volcar triggers y rutinas.
# ==============================================================================

set -uo pipefail

# --- 1. VALORES POR DEFECTO Y PARSEO DE OPCIONES ---
DB_HOST="localhost"
DB_PORT="3306"
DB_SOCKET=""
DB_USER="root"
DB_NAME="gbpublisher"
VERSION="2.0.0"
OUT_DIR="."
VERIFICAR=0

# TABLAS SEMILLA: LAS ÚNICAS QUE VIAJAN CON DATOS.
# ESTA LISTA ES LA DEFINICIÓN OPERATIVA DE "QUÉ ES SEMILLA".
# TODA TABLA QUE NO ESTÉ ACÁ SE VUELCA VACÍA, INCLUIDAS LAS FUTURAS.
# shortcodes DEJÓ DE SER SEMILLA EN LA 1.7.0: LA TABLA SE RETIRÓ Y EL
# CATÁLOGO VIAJA COMO ARCHIVO EN EL PAQUETE (shortcodes/_catalogo.tsv).
# DESDE LA 2.0.0 LA LISTA INCLUYE LAS SEMILLAS QUE FUERON SUMANDO LAS
# ACTUALIZACIONES 1.x (idiomas, pais, licencias...) Y EL CATÁLOGO DE CAMPOS
# DE LA BIBLIOGRAFÍA. ES LA LISTA DE TABLAS CON DATOS EN UNA INSTALACIÓN
# NUEVA (MEDIDO EL 20/11/2026 SOBRE LA CADENA 1.0.0 → 2.0.0).
# manual_ayudas DEJÓ DE SER SEMILLA EN LA 2.5.0: LA TABLA SE BORRÓ Y LA
# AYUDA VIAJA COMO EL HTML DEL LIBRO l-AYUDA EN EL PAQUETE (manual/, SC-112).
TABLAS_SEMILLA=(
  consultas               # BIBLIOTECA DE CONSULTAS CANÓNICAS DEL EDITOR
  cmb_biblatex            # TIPOS DE ENTRADA BIBLATEX
  bibtex_campo_catalogo   # CAMPOS BIBLATEX DE LA BIBLIOGRAFÍA (2.0.0)
  formatos_pdf            # FORMATOS DE PÁGINA PREDEFINIDOS
  credit_roles            # TAXONOMÍA CRediT
  credit_rol_nombre       # NOMBRES DE LOS ROLES CRediT POR IDIOMA
  idiomas                 # IDIOMAS (ISO Y NOMBRE DE BABEL)
  pais                    # PAÍSES
  licencias               # LICENCIAS
  licencia_texto          # TEXTOS DE LICENCIA
  tipo_declaracion        # TIPOS DE DECLARACIÓN
)

# COLUMNAS ESPERADAS EN LA TABLA TESTIGO. SI NO COINCIDE, LA BASE DE ORIGEN
# NO ESTÁ EN EL ESTADO QUE ESTE BASELINE DICE REPRESENTAR.
# 2.0.0: bibtex QUEDA CON 6 COLUMNAS (EL RESTO PASÓ A bibtex_campo). UNA
# BASE SIN LA 2.0.0 TIENE 110 Y ABORTA ACÁ.
TABLA_TESTIGO="bibtex"
COLUMNAS_TESTIGO=6

while getopts "h:P:S:u:d:V:o:v" opt; do
  case "$opt" in
    h) DB_HOST="$OPTARG" ;;
    P) DB_PORT="$OPTARG" ;;
    S) DB_SOCKET="$OPTARG" ;;
    u) DB_USER="$OPTARG" ;;
    d) DB_NAME="$OPTARG" ;;
    V) VERSION="$OPTARG" ;;
    o) OUT_DIR="$OPTARG" ;;
    v) VERIFICAR=1 ;;
    *) echo "Opción no reconocida. Ver el encabezado del script." >&2; exit 2 ;;
  esac
done

SALIDA="$OUT_DIR/gbpublisher-baseline-${VERSION}.sql"

# --- 2. FUNCIONES AUXILIARES ---

abortar() {
  echo "" >&2
  echo "ABORTADO: $1" >&2
  exit 1
}

detectar_binarios() {
  command -v mysql > /dev/null 2>&1 || abortar "no se encontró el cliente mysql."
  command -v mysqldump > /dev/null 2>&1 || abortar "no se encontró mysqldump."
  CLI="mysql"
  DUMP="mysqldump"
}

sql_escalar() {
  "$CLI" --defaults-extra-file="$CNF" -N -B -e "$1" "$DB_NAME" 2>/dev/null
}

# ENVOLTORIO DE mysqldump QUE REINTENTA SIN --column-statistics.
# mysqldump 8 ACTIVA ESA OPCIÓN POR DEFECTO Y FALLA CONTRA SERVIDORES
# QUE NO LA SOPORTAN.
volcar() {
  if ! "$DUMP" --defaults-extra-file="$CNF" "$@" 2>/tmp/gbp-dump-err.log; then
    if grep -q "column-statistics\|COLUMN_STATISTICS" /tmp/gbp-dump-err.log; then
      "$DUMP" --defaults-extra-file="$CNF" --column-statistics=0 "$@" 2>/tmp/gbp-dump-err.log
    else
      return 1
    fi
  fi
}

# --- 3. PREPARACIÓN ---

detectar_binarios
mkdir -p "$OUT_DIR" || abortar "no se pudo crear el directorio de salida."

echo "=============================================="
echo " gbpublisher — generador de baseline $VERSION"
echo "=============================================="
echo " Origen : ${DB_SOCKET:-$DB_HOST:$DB_PORT} / $DB_NAME"
echo " Salida : $SALIDA"
echo ""

read -r -s -p "Clave de $DB_USER: " DB_PASS
echo ""

CNF="$(mktemp)"
chmod 600 "$CNF"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$CNF" "$TMP_DIR"' EXIT INT TERM

{
  echo "[client]"
  echo "user=$DB_USER"
  echo "password=$DB_PASS"
  if [ -n "$DB_SOCKET" ]; then
    echo "socket=$DB_SOCKET"
  else
    echo "host=$DB_HOST"
    echo "port=$DB_PORT"
  fi
} > "$CNF"
unset DB_PASS

"$CLI" --defaults-extra-file="$CNF" -e "SELECT 1" "$DB_NAME" > /dev/null 2>&1 \
  || abortar "no se pudo conectar a la base '$DB_NAME'."
echo "[ok] Conexión establecida."

# --- 4. PRECONDICIONES SOBRE LA BASE DE ORIGEN ---

# LA BASE DE ORIGEN DEBE ESTAR AL DÍA. GENERAR UN BASELINE DESDE UNA BASE
# ATRASADA PRODUCIRÍA UN ARTEFACTO QUE MIENTE SOBRE SU PROPIO NIVEL.
cols_testigo=$(sql_escalar "
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLA_TESTIGO';")

if [ "$cols_testigo" != "$COLUMNAS_TESTIGO" ]; then
  abortar "$TABLA_TESTIGO tiene $cols_testigo columnas y se esperaban $COLUMNAS_TESTIGO.
         La base de origen no está en el estado que el baseline $VERSION declara."
fi
echo "[ok] Precondición: $TABLA_TESTIGO con $cols_testigo columnas."

# ENUMERAR TODAS LAS TABLAS BASE (EXCLUYE VISTAS).
# esquema_version SE EXCLUYE A PROPÓSITO: NO SE COPIA DEL ORIGEN SINO QUE
# LA GENERA ESTE SCRIPT CON EL NIVEL QUE CORRESPONDE AL BASELINE.
mapfile -t TODAS < <(sql_escalar "
  SELECT TABLE_NAME FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
    AND TABLE_NAME <> 'esquema_version'
  ORDER BY TABLE_NAME;")

[ "${#TODAS[@]}" -gt 0 ] || abortar "no se encontraron tablas en '$DB_NAME'."
echo "[ok] $(( ${#TODAS[@]} )) tablas detectadas."

# VERIFICAR QUE TODA TABLA SEMILLA DECLARADA EXISTA REALMENTE.
# UNA SEMILLA MAL ESCRITA PASARÍA INADVERTIDA Y SALDRÍA VACÍA.
for t in "${TABLAS_SEMILLA[@]}"; do
  encontrada=0
  for u in "${TODAS[@]}"; do [ "$t" = "$u" ] && encontrada=1 && break; done
  [ "$encontrada" -eq 1 ] || abortar "la tabla semilla '$t' no existe en la base de origen."
done
echo "[ok] Las ${#TABLAS_SEMILLA[@]} tablas semilla existen."

# --- 5. VOLCADO DE ESTRUCTURA ---

echo "[..] Volcando estructura de todas las tablas"

volcar --no-data --routines --triggers --compact --skip-set-charset \
       --ignore-table="$DB_NAME.esquema_version" \
       "$DB_NAME" > "$TMP_DIR/estructura.sql" \
  || { cat /tmp/gbp-dump-err.log >&2; abortar "falló el volcado de estructura."; }

[ -s "$TMP_DIR/estructura.sql" ] || abortar "el volcado de estructura quedó vacío."

# --- 6. VOLCADO DE DATOS SEMILLA ---

echo "[..] Volcando datos de las tablas semilla"

volcar --no-create-info --skip-triggers --compact --skip-set-charset \
       --complete-insert --skip-extended-insert \
       "$DB_NAME" "${TABLAS_SEMILLA[@]}" > "$TMP_DIR/semilla.sql" \
  || { cat /tmp/gbp-dump-err.log >&2; abortar "falló el volcado de datos semilla."; }

[ -s "$TMP_DIR/semilla.sql" ] || abortar "el volcado de datos semilla quedó vacío."

# --- 7. ENSAMBLADO DEL ARTEFACTO ---

echo "[..] Ensamblando $SALIDA"

FECHA="$(date '+%Y-%m-%d %H:%M:%S')"

{
  cat <<CABECERA
-- ==============================================================================
-- gbpublisher — Base de datos de distribución
-- Baseline: $VERSION
-- Generado: $FECHA por generar-baseline.sh
--
-- Este archivo crea la base gbpublisher completa y lista para usar.
-- Contiene la estructura de todas las tablas y los datos semilla de la
-- aplicación. No contiene datos editoriales de ninguna instalación.
--
-- Instalación:
--   mysql -u root -p < gbpublisher-baseline-$VERSION.sql
--
-- Después de restaurar hay que crear el usuario de aplicación. Ver el
-- capítulo de despliegue en la documentación.
--
-- El nivel de esquema queda declarado en la tabla esquema_version. Los
-- parches posteriores consultan esa tabla para decidir si corresponde
-- aplicarse.
-- ==============================================================================

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Este baseline carga con innodb_strict_mode activo (el default de
-- MySQL 8): la tabla que lo hacía fallar con el error 1118 (articulos,
-- 220 columnas) se retiró en la 1.32.0 y la más ancha que quedaba
-- (bibtex, 110) pasó a pares campo/valor en la 2.0.0 (GV-67).

CREATE DATABASE IF NOT EXISTS \`gbpublisher\`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE \`gbpublisher\`;

-- ------------------------------------------------------------------
-- 1. ESTRUCTURA
-- ------------------------------------------------------------------
CABECERA

  cat "$TMP_DIR/estructura.sql"

  cat <<'SEMILLA_CAB'

-- ------------------------------------------------------------------
-- 2. DATOS SEMILLA
--    Solo contenido propio de la aplicación. Las tablas no listadas
--    acá se instalan vacías a propósito.
-- ------------------------------------------------------------------
SEMILLA_CAB

  cat "$TMP_DIR/semilla.sql"

  cat <<CONTROL

-- ------------------------------------------------------------------
-- 3. CORRECCIONES DE CONSISTENCIA
-- ------------------------------------------------------------------

-- LAS CONSULTAS CANÓNICAS DEBEN QUEDAR MARCADAS COMO DEL SISTEMA PARA
-- QUE LOS PARCHES FUTUROS PUEDAN DISTINGUIRLAS DE LAS QUE GUARDE EL
-- EDITOR EN CADA INSTALACIÓN.
UPDATE \`consultas\` SET \`consulta_sistema\` = 1;

-- ------------------------------------------------------------------
-- 4. CONTROL DE VERSIÓN DE ESQUEMA
-- ------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS \`esquema_version\` (
  \`parche\`      VARCHAR(50)  NOT NULL,
  \`aplicado_en\` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  \`descripcion\` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (\`parche\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO \`esquema_version\` (\`parche\`, \`descripcion\`)
VALUES ('baseline-$VERSION', 'Esquema de distribución inicial');

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- Baseline $VERSION generado el $FECHA — fin del archivo.
CONTROL

} > "$SALIDA.tmp"

# --- 8. CORRECCIONES DE PORTABILIDAD SOBRE EL TEXTO GENERADO ---

echo "[..] Aplicando correcciones de portabilidad"

# 1. COLACIÓN: utf8mb4_0900_ai_ci NO ES LA DEL PROYECTO (GV-175).
# 2. DEFINER: LOS TRIGGERS APUNTAN A UN USUARIO QUE NO EXISTE EN DESTINO.
# 3. AUTO_INCREMENT: CONTADORES RESIDUALES QUE ARRANCARÍAN LOS IDs FUERA DE 1.
# 4. ROW_FORMAT: mysqldump OMITE ROW_FORMAT CUANDO COINCIDE CON EL DEFAULT DEL
#    SERVIDOR DE ORIGEN. SI EL DESTINO TIENE OTRO DEFAULT (p. ej. COMPACT), LAS
#    TABLAS ANCHAS (libros_md, 89 COLUMNAS) PUEDEN NO ENTRAR EN EL LÍMITE DE
#    FILA DE 8126 BYTES Y LA CARGA FALLA CON "Row size too large". FORZAR DYNAMIC
#    EXPLÍCITO HACE LA CARGA INDEPENDIENTE DEL DEFAULT DEL DESTINO.
#    NOTA: NO SE AGREGA A TABLAS QUE YA DECLARAN UN ROW_FORMAT PROPIO.
sed -e 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' \
    -e 's/DEFINER=[^*]*\*/\*/g' \
    -e 's/ AUTO_INCREMENT=[0-9]*//g' \
    -e '/ROW_FORMAT=/! s/) ENGINE=InnoDB\([^;]*\);/) ENGINE=InnoDB\1 ROW_FORMAT=DYNAMIC;/' \
    "$SALIDA.tmp" > "$SALIDA"

rm -f "$SALIDA.tmp"

# --- 9. VERIFICACIÓN DEL ARTEFACTO ---

echo "[..] Verificando el artefacto"

fallos=0
comprobar() {
  if [ "$2" -eq 0 ]; then
    echo "     [!] $1"
    fallos=$((fallos + 1))
  else
    echo "     [ok] $1"
  fi
}

[ -s "$SALIDA" ] || abortar "el artefacto quedó vacío."

# EL ARTEFACTO DEBE TRAER LAS TABLAS DEL ORIGEN MÁS esquema_version,
# QUE ESTE SCRIPT AGREGA.
esperadas=$(( ${#TODAS[@]} + 1 ))
n_tablas=$(grep -c "^CREATE TABLE" "$SALIDA")
comprobar "estructura: $n_tablas tablas (esperadas $esperadas)" \
          "$([ "$n_tablas" -eq "$esperadas" ] && echo 1 || echo 0)"

# SOLO utf8mb4_0900_ai_ci: LAS COLUMNAS utf8mb4_0900_as_ci Y _as_cs DE SIGLAS
# E ÍNDICES SON DELIBERADAS (DISTINGUEN TILDES O MAYÚSCULAS) Y SE CONSERVAN
comprobar "sin la colación utf8mb4_0900_ai_ci" \
          "$(grep -q 'utf8mb4_0900_ai_ci' "$SALIDA" && echo 0 || echo 1)"

comprobar "sin cláusulas DEFINER" \
          "$(grep -q 'DEFINER=' "$SALIDA" && echo 0 || echo 1)"

comprobar "sin contadores AUTO_INCREMENT residuales" \
          "$(grep -q 'AUTO_INCREMENT=' "$SALIDA" && echo 0 || echo 1)"

comprobar "declara el nivel baseline-$VERSION" \
          "$(grep -q "baseline-$VERSION" "$SALIDA" && echo 1 || echo 0)"

# DESDE LA 2.0.0 EL BASELINE CARGA CON EL CHEQUEO ESTRICTO ACTIVO (GV-67):
# RELAJARLO ESCONDERÍA UNA TABLA DEMASIADO ANCHA EN VEZ DE AVISAR
comprobar "no relaja innodb_strict_mode" \
          "$(grep -q 'innodb_strict_mode=0' "$SALIDA" && echo 0 || echo 1)"

# NINGUNA TABLA QUE NO SEA SEMILLA DEBE TRAER INSERT
for t in "${TODAS[@]}"; do
  es_semilla=0
  for s in "${TABLAS_SEMILLA[@]}"; do [ "$t" = "$s" ] && es_semilla=1 && break; done
  if [ "$es_semilla" -eq 0 ]; then
    if grep -q "INSERT INTO \`$t\`" "$SALIDA"; then
      echo "     [!] la tabla '$t' NO es semilla y trae datos"
      fallos=$((fallos + 1))
    fi
  fi
done
[ "$fallos" -eq 0 ] && echo "     [ok] ninguna tabla de trabajo trae datos"

# --- 10. VERIFICACIÓN POR CARGA (OPCIONAL) ---

if [ "$VERIFICAR" -eq 1 ]; then
  echo "[..] Verificando por carga en base temporal"
  TMP_DB="gbp_verif_$$"

  # SE CARGA EN UNA BASE CON OTRO NOMBRE: HAY QUE NEUTRALIZAR EL USE
  sed -e "s/^USE \`gbpublisher\`;/USE \`$TMP_DB\`;/" \
      -e "s/^CREATE DATABASE IF NOT EXISTS \`gbpublisher\`/CREATE DATABASE IF NOT EXISTS \`$TMP_DB\`/" \
      "$SALIDA" > "$TMP_DIR/verif.sql"

  "$CLI" --defaults-extra-file="$CNF" -e "DROP DATABASE IF EXISTS \`$TMP_DB\`;" 2>/dev/null

  if "$CLI" --defaults-extra-file="$CNF" < "$TMP_DIR/verif.sql" 2>"$TMP_DIR/carga.err"; then
    echo "     [ok] carga sin errores"
    "$CLI" --defaults-extra-file="$CNF" -N -B -e "
      SELECT CONCAT('     [ok] ', COUNT(*), ' tablas creadas')
        FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = '$TMP_DB' AND TABLE_TYPE = 'BASE TABLE';"
    for t in "${TABLAS_SEMILLA[@]}"; do
      n=$("$CLI" --defaults-extra-file="$CNF" -N -B -e "SELECT COUNT(*) FROM \`$TMP_DB\`.\`$t\`;")
      echo "     [ok] $t: $n filas"
    done
  else
    echo "     [!] la carga falló:"
    head -5 "$TMP_DIR/carga.err"
    fallos=$((fallos + 1))
  fi

  "$CLI" --defaults-extra-file="$CNF" -e "DROP DATABASE IF EXISTS \`$TMP_DB\`;" 2>/dev/null
fi

# --- 11. RESULTADO ---

echo ""
echo "=============================================="
if [ "$fallos" -eq 0 ]; then
  echo " BASELINE $VERSION GENERADO"
  echo "=============================================="
  echo " Archivo : $SALIDA"
  echo " Tamaño  : $(du -h "$SALIDA" | cut -f1)"
  echo ""
  echo " Instalación en destino:"
  echo "   mysql -u root -p < $(basename "$SALIDA")"
  exit 0
else
  echo " GENERADO CON $fallos ADVERTENCIA(S)"
  echo "=============================================="
  echo " Revisar antes de distribuir: $SALIDA"
  exit 1
fi
