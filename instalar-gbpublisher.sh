#!/usr/bin/env bash
#
# ============================================
# Script    : instalar-gbpublisher.sh
# Propósito : Instalación LIMPIA de la base de datos de gbpublisher.
#             BORRA la base existente y la recrea desde el archivo de
#             distribución (baseline).
# Uso       : ./instalar-gbpublisher.sh [-r RANGO]
#               -r RANGO  Rango de red de los clientes, para instalaciones
#                         cliente/servidor. Ejemplos: 192.168.128.%  10.0.%.%
#                         Si se omite, el script pregunta.
# Requisitos: MySQL/MariaDB instalado y en ejecución; permisos sudo;
#             el archivo 'gbpublisher-baseline-X.Y.Z.sql' en esta misma carpeta.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
DB_USER="app_user"
DB_PASS="AppUser2024!"
PATRON_BASELINE="gbpublisher-baseline-*.sql"

# VALORES ESPERADOS EN UN BASELINE ÍNTEGRO. SI LA IMPORTACIÓN NO LLEGA A
# ESTOS NÚMEROS, ALGO FALLÓ AUNQUE mysql NO HAYA DEVUELTO ERROR.
N_TABLAS_ESPERADAS=30
declare -A SEMILLA_ESPERADA=(
  [shortcodes]=77 [manual_ayudas]=36 [consultas]=82
  [cmb_biblatex]=120 [formatos_pdf]=45 [credit_roles]=14
)

RANGO_RED=""
while getopts "r:" opt; do
  case "$opt" in
    r) RANGO_RED="$OPTARG" ;;
    *) echo "Opción no reconocida. Ver el encabezado del script." >&2; exit 2 ;;
  esac
done

# COLORES SOLO SI LA SALIDA ES UNA TERMINAL
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

# UBICAR EL BASELINE JUNTO AL SCRIPT, SIN IMPORTAR DESDE DÓNDE SE INVOQUE
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Instalación de la base de datos de gbpublisher${RESET}"
echo "-----------------------------------------------"
echo "Este asistente prepara la base de datos en una máquina nueva."
echo

# --- 2. VERIFICACIONES PREVIAS ---

# 2.1 EL CLIENTE mysql DEBE ESTAR DISPONIBLE
if ! command -v mysql >/dev/null 2>&1; then
  error "No se encontró el programa 'mysql'."
  error "Verificá que MySQL o MariaDB estén instalados."
  exit 1
fi

# 2.2 LOCALIZAR EL BASELINE.
# SE BUSCA POR PATRÓN Y NO POR NOMBRE FIJO: ASÍ EL SCRIPT NO HAY QUE EDITARLO
# CADA VEZ QUE SALE UNA VERSIÓN NUEVA DEL ARCHIVO DE DISTRIBUCIÓN.
mapfile -t ENCONTRADOS < <(find "$DIR_SCRIPT" -maxdepth 1 -name "$PATRON_BASELINE" -type f | sort -V)

if [ "${#ENCONTRADOS[@]}" -eq 0 ]; then
  error "No se encontró ningún archivo de distribución."
  error "    Se buscaba: ${DIR_SCRIPT}/${PATRON_BASELINE}"
  echo
  error "Colocá el archivo del baseline en la misma carpeta que este script"
  error "y volvé a ejecutarlo."
  exit 1
fi

# SI HAY VARIOS, SE USA EL DE VERSIÓN MÁS ALTA Y SE AVISA CUÁL
RUTA_DUMP="${ENCONTRADOS[-1]}"
if [ "${#ENCONTRADOS[@]}" -gt 1 ]; then
  warn "Se encontraron ${#ENCONTRADOS[@]} archivos de distribución."
  warn "Se usará el más reciente: $(basename "$RUTA_DUMP")"
fi

# 2.3 EL ARCHIVO DEBE DECLARAR SU NIVEL DE ESQUEMA.
# UN .sql SUELTO O UN DUMP ANTIGUO NO LO HACE, Y NO SIRVE COMO BASELINE.
NIVEL_DECLARADO="$(grep -o "baseline-[0-9]\+\.[0-9]\+\.[0-9]\+" "$RUTA_DUMP" | head -1 || true)"
if [ -z "$NIVEL_DECLARADO" ]; then
  error "El archivo $(basename "$RUTA_DUMP") no declara un nivel de esquema."
  error "No parece un baseline válido de gbpublisher."
  exit 1
fi

info "Archivo de distribución: $(basename "$RUTA_DUMP")"
info "Nivel de esquema: ${NIVEL_DECLARADO}"

# 2.4 OBTENER PERMISOS DE ADMINISTRADOR (UNA SOLA VEZ)
info "Se pedirá tu contraseña del sistema para trabajar con la base de datos."
if ! sudo -v; then
  error "No se pudieron obtener permisos de administrador (sudo)."
  exit 1
fi

# 2.5 EL SERVIDOR DEBE RESPONDER
if ! sudo mysql -e "SELECT 1;" >/dev/null 2>&1; then
  error "No se pudo conectar al servidor de base de datos."
  error "Comprobá que el servicio esté activo, por ejemplo con:"
  error "    sudo systemctl status mariadb"
  exit 1
fi
ok "Todo listo para instalar."

# --- 3. TIPO DE INSTALACIÓN ---
# EN INSTALACIONES CLIENTE/SERVIDOR HAY QUE HABILITAR A app_user DESDE LA RED.
# SIN ESTO, LAS OTRAS MÁQUINAS NO PUEDEN CONECTARSE Y EL DIAGNÓSTICO ES LENTO.
if [ -z "$RANGO_RED" ]; then
  echo
  echo "¿Otras máquinas van a conectarse a esta base por la red?"
  echo "  - Respondé ${NEGRITA}no${RESET} si gbpublisher se usa solo en esta computadora."
  echo "  - Respondé ${NEGRITA}sí${RESET} si esta máquina es el servidor de una editorial."
  echo
  read -r -p "¿Es un servidor para otras máquinas? [s/N]: " ES_SERVIDOR
  if [[ "${ES_SERVIDOR,,}" =~ ^(s|si|sí)$ ]]; then
    echo
    echo "Indicá el rango de red de las máquinas cliente."
    echo "Ejemplos:  192.168.128.%   |   10.0.%.%   |   %  (cualquier origen)"
    read -r -p "Rango de red: " RANGO_RED
  fi
fi

# --- 4. CONFIRMACIÓN DE LA ACCIÓN DESTRUCTIVA ---
echo
warn "${NEGRITA}ATENCIÓN:${RESET} se BORRARÁ por completo la base de datos '${DB}'"
warn "junto con todos los datos de prueba que contenga. Esto no se puede deshacer."
echo
read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
if [ "$RESPUESTA" != "SI" ]; then
  echo
  info "Instalación cancelada. No se modificó nada."
  exit 0
fi

# --- 5. BORRAR LA BASE ANTERIOR ---
# NO SE RECREA ACÁ: EL PROPIO BASELINE TRAE SU 'CREATE DATABASE' CON LA
# CODIFICACIÓN Y EL COTEJAMIENTO CORRECTOS. ASÍ EL ARCHIVO DE DISTRIBUCIÓN ES
# LA ÚNICA FUENTE DE VERDAD SOBRE CÓMO DEBE CREARSE LA BASE.
echo
info "Eliminando la base de datos anterior (si existe)..."
sudo mysql -e "DROP DATABASE IF EXISTS \`${DB}\`;"

# --- 6. IMPORTAR EL BASELINE ---
# EL ARCHIVO YA RELAJA innodb_strict_mode POR SU CUENTA (LA TABLA 'articulos'
# TIENE 220 COLUMNAS Y EL CHEQUEO ESTRICTO DE MySQL 8 RECHAZARÍA SU CREATE
# AUNQUE EN ROW_FORMAT=DYNAMIC LA FILA ENTRE SIN PROBLEMA). NO HACE FALTA
# ANTEPONER NADA: SE IMPORTA TAL CUAL.
info "Importando estructura y datos de configuración..."
sudo mysql < "$RUTA_DUMP"
ok "Contenido importado."

# --- 7. USUARIO DE LA APLICACIÓN ---
info "Configurando el usuario de la aplicación..."
sudo mysql <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
ok "Usuario '${DB_USER}' habilitado en esta máquina."

# CUENTA ADICIONAL PARA LOS CLIENTES DE LA RED.
# EN MySQL LA IDENTIDAD ES usuario@host: 'app_user'@'localhost' Y
# 'app_user'@'192.168.1.%' SON CUENTAS DISTINTAS, NO UN PERMISO QUE SE EXTIENDE.
if [ -n "$RANGO_RED" ]; then
  sudo mysql <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'${RANGO_RED}' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'${RANGO_RED}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB}\`.* TO '${DB_USER}'@'${RANGO_RED}';
FLUSH PRIVILEGES;
SQL
  ok "Usuario '${DB_USER}' habilitado para el rango ${RANGO_RED}."
fi

# --- 8. VERIFICACIÓN ---
echo
info "Verificando la instalación..."
FALLOS=0

N_TABLAS="$(sudo mysql -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables
   WHERE table_schema='${DB}' AND table_type='BASE TABLE';")"

if [ "${N_TABLAS:-0}" -eq "$N_TABLAS_ESPERADAS" ]; then
  ok "Tablas creadas: ${N_TABLAS}"
else
  error "Se crearon ${N_TABLAS:-0} tablas y se esperaban ${N_TABLAS_ESPERADAS}."
  FALLOS=$((FALLOS + 1))
fi

# LOS DATOS SEMILLA SON LO QUE HACE USABLE LA APLICACIÓN RECIÉN INSTALADA:
# SIN SHORTCODES NI AYUDAS, LA BASE ESTÁ "CREADA" PERO NO SIRVE.
for TABLA in "${!SEMILLA_ESPERADA[@]}"; do
  N="$(sudo mysql -N -B -e "SELECT COUNT(*) FROM \`${DB}\`.\`${TABLA}\`;" 2>/dev/null || echo 0)"
  if [ "${N:-0}" -eq "${SEMILLA_ESPERADA[$TABLA]}" ]; then
    ok "${TABLA}: ${N} registros"
  else
    error "${TABLA}: ${N:-0} registros, se esperaban ${SEMILLA_ESPERADA[$TABLA]}."
    FALLOS=$((FALLOS + 1))
  fi
done

NIVEL_INSTALADO="$(sudo mysql -N -B -e \
  "SELECT parche FROM \`${DB}\`.esquema_version ORDER BY aplicado_en LIMIT 1;" 2>/dev/null || true)"
if [ -n "$NIVEL_INSTALADO" ]; then
  ok "Nivel de esquema registrado: ${NIVEL_INSTALADO}"
else
  error "La base no registró su nivel de esquema."
  FALLOS=$((FALLOS + 1))
fi

if [ "$FALLOS" -gt 0 ]; then
  echo
  error "La instalación terminó con ${FALLOS} problema(s). Revisá los mensajes."
  exit 1
fi

# --- 9. AVISO SOBRE LA ESCUCHA EN RED ---
# SI SE HABILITÓ UN RANGO DE RED PERO EL SERVIDOR SOLO ESCUCHA EN LOOPBACK,
# LOS CLIENTES VAN A RECIBIR "Can't connect ... (111)" Y EL PERMISO NO TIENE
# NADA QUE VER. SE AVISA ACÁ PARA NO PERDER TIEMPO BUSCANDO DONDE NO ES.
if [ -n "$RANGO_RED" ]; then
  if sudo grep -rqs "^bind-address\s*=\s*127.0.0.1" /etc/mysql/ 2>/dev/null; then
    echo
    warn "${NEGRITA}Falta un paso para que los clientes puedan conectarse.${RESET}"
    warn "El servidor solo acepta conexiones locales (bind-address = 127.0.0.1)."
    warn "Para habilitar la red hay que editar la configuración de MySQL:"
    warn "    bind-address = 0.0.0.0"
    warn "y después reiniciar el servicio:"
    warn "    sudo systemctl restart mysql"
  fi
fi

# --- 10. CIERRE ---
echo
echo "${VERDE}${NEGRITA}Instalación completada.${RESET}"
echo "Ya podés abrir gbpublisher."
if [ -n "$RANGO_RED" ]; then
  echo
  echo "Las máquinas cliente deben apuntar a la IP de este servidor."
fi
echo
