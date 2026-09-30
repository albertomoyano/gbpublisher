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
#   -V VERSION   Versión del baseline a generar     (por defecto: 1.0.0)
#   -o DIR       Directorio de salida               (por defecto: .)
#   -v           Verificar cargando el artefacto en una base temporal
#
# Correcciones que aplica automáticamente:
#   1. Normaliza la colación de formatos_pdf (venía utf8mb4_0900_ai_ci,
#      que MariaDB no reconoce y hace fallar la carga completa).
#   2. Elimina las cláusulas DEFINER de triggers y rutinas, que apuntan a
#      un usuario que no existe en los servidores de destino.
#   3. Resetea los contadores AUTO_INCREMENT residuales.
#   4. Marca las consultas canónicas con consulta_sistema = 1.
#   5. Declara el nivel de esquema en esquema_version.
#
# Requisitos: mysqldump/mariadb-dump y mysql/mariadb en el PATH.
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
VERSION="1.0.0"
OUT_DIR="."
VERIFICAR=0

# TABLAS SEMILLA: LAS ÚNICAS QUE VIAJAN CON DATOS.
# ESTA LISTA ES LA DEFINICIÓN OPERATIVA DE "QUÉ ES SEMILLA".
# TODA TABLA QUE NO ESTÉ ACÁ SE VUELCA VACÍA, INCLUIDAS LAS FUTURAS.
TABLAS_SEMILLA=(
  shortcodes      # ACTIVO DE LA APLICACIÓN, SOLO LECTURA, ACOPLADO AL FILTRO LUA
  manual_ayudas   # MANUAL CONTEXTUAL, SOLO LECTURA EN PRODUCCIÓN
  consultas       # BIBLIOTECA DE CONSULTAS CANÓNICAS DEL EDITOR
  cmb_biblatex    # TIPOS DE ENTRADA BIBLATEX
  formatos_pdf    # FORMATOS DE PÁGINA PREDEFINIDOS
  credit_roles    # TAXONOMÍA CRediT
)

# COLUMNAS ESPERADAS EN LA TABLA TESTIGO. SI NO COINCIDE, LA BASE DE ORIGEN
# NO ESTÁ EN EL ESTADO QUE ESTE BASELINE DICE REPRESENTAR.
TABLA_TESTIGO="libros_md"
COLUMNAS_TESTIGO=72

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
  if command -v mysql > /dev/null 2>&1; then
    CLI="mysql"
  elif command -v mariadb > /dev/null 2>&1; then
    CLI="mariadb"
  else
    abortar "no se encontró el cliente (mysql o mariadb)."
  fi

  if command -v mysqldump > /dev/null 2>&1; then
    DUMP="mysqldump"
  elif command -v mariadb-dump > /dev/null 2>&1; then
    DUMP="mariadb-dump"
  else
    abortar "no se encontró mysqldump ni mariadb-dump."
  fi
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

-- La tabla articulos tiene 220 columnas. El chequeo estricto de InnoDB
-- (innodb_strict_mode, activo por defecto en MySQL 8) rechaza su CREATE
-- calculando el peor caso teórico del tamaño de fila, aunque en
-- ROW_FORMAT=DYNAMIC los VARCHAR y TEXT grandes se almacenan fuera de la
-- fila y la tabla funciona sin problema. Relajar el chequeo durante la
-- restauración es el mecanismo previsto para tablas anchas legítimas; no
-- altera el comportamiento posterior de la base.
/*!50500 SET @OLD_INNODB_STRICT_MODE=@@SESSION.innodb_strict_mode */;
/*!50500 SET SESSION innodb_strict_mode=0 */;

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
/*!50500 SET SESSION innodb_strict_mode=@OLD_INNODB_STRICT_MODE */;
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

# 1. COLACIÓN: utf8mb4_0900_ai_ci ES DE MySQL 8 Y MariaDB NO LA RECONOCE.
# 2. DEFINER: LOS TRIGGERS APUNTAN A UN USUARIO QUE NO EXISTE EN DESTINO.
# 3. AUTO_INCREMENT: CONTADORES RESIDUALES QUE ARRANCARÍAN LOS IDs FUERA DE 1.
# 4. ROW_FORMAT: mysqldump OMITE ROW_FORMAT CUANDO COINCIDE CON EL DEFAULT DEL
#    SERVIDOR DE ORIGEN. SI EL DESTINO TIENE OTRO DEFAULT (p. ej. COMPACT), LAS
#    TABLAS ANCHAS (articulos, con 220 columnas) NO ENTRAN EN EL LÍMITE DE FILA
#    DE 8126 BYTES Y LA CARGA FALLA CON "Row size too large". FORZAR DYNAMIC
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

comprobar "sin colaciones incompatibles con MariaDB" \
          "$(grep -qc 'utf8mb4_0900' "$SALIDA" && echo 0 || echo 1)"

comprobar "sin cláusulas DEFINER" \
          "$(grep -q 'DEFINER=' "$SALIDA" && echo 0 || echo 1)"

comprobar "sin contadores AUTO_INCREMENT residuales" \
          "$(grep -q 'AUTO_INCREMENT=' "$SALIDA" && echo 0 || echo 1)"

comprobar "declara el nivel baseline-$VERSION" \
          "$(grep -q "baseline-$VERSION" "$SALIDA" && echo 1 || echo 0)"

# SIN ESTA LÍNEA, LA RESTAURACIÓN FALLA CON ERROR 1118 EN CUALQUIER SERVIDOR
# CON innodb_strict_mode ACTIVO (EL DEFAULT EN MySQL 8).
comprobar "relaja innodb_strict_mode para la restauración" \
          "$(grep -q 'innodb_strict_mode=0' "$SALIDA" && echo 1 || echo 0)"

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
