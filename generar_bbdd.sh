#!/bin/bash
# ============================================================
# generar_bbdd.sh
# ============================================================
# DESCRIPCIÓN : Crea la base de datos MySQL gbpublisher desde
#               el dump de referencia incluido en la distribución.
#               OPERACIÓN DESTRUCTIVA: elimina cualquier base de
#               datos gbpublisher existente antes de crearla.
# USO         : bash generar_bbdd.sh
# REQUISITO   : El archivo gbpublisher.sql debe estar en el
#               mismo directorio que este script.
# NOTA        : No crea usuarios de la aplicación. Para crear
#               el primer usuario operativo, abrir gbpublisher,
#               ingresar a Administración del sistema y crear
#               al menos 1 usuario.
# ============================================================

# --- COLORES ---
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NEGRITA='\033[1m'
RESET='\033[0m'

# --- PARÁMETROS DE LA BASE DE DATOS ---
DB_NOMBRE="gbpublisher"
DB_USUARIO="app_user"
DB_CLAVE="AppUser2024!"
DB_HOST="localhost"
DB_PUERTO="3306"

# --- ARCHIVO DUMP ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_FILE="$SCRIPT_DIR/gbpublisher.sql"

# ============================================================
# FUNCIÓN: título de sección
# ============================================================
seccion() {
  echo ""
  echo -e "${NEGRITA}$1${RESET}"
  echo "  ────────────────────────────────────────────────────────────────────"
}

# ============================================================
# INICIO
# ============================================================
clear
echo ""
echo -e "${NEGRITA}  gbpublisher — Generación de base de datos${RESET}"
echo "  $(uname -n)  |  $(lsb_release -ds 2>/dev/null || echo Linux)  |  $(date '+%d/%m/%Y %H:%M')"
echo "  ════════════════════════════════════════════════════════════════════"

# ============================================================
# PASO 1 — VERIFICAR QUE MYSQL ESTÁ CORRIENDO
# ============================================================
seccion "  Paso 1: Verificando servicio MySQL"
if systemctl is-active --quiet mysql; then
  echo -e "  MySQL             ${VERDE}activo${RESET}"
else
  echo -e "  ${ROJO}ERROR: El servicio MySQL no está corriendo.${RESET}"
  echo ""
  echo "  Inicialo con:"
  echo "    sudo systemctl start mysql"
  echo ""
  exit 1
fi

# ============================================================
# PASO 2 — VERIFICAR ARCHIVO DUMP
# ============================================================
seccion "  Paso 2: Verificando archivo de base de datos"
if [ -f "$DUMP_FILE" ]; then
  LINEAS=$(wc -l < "$DUMP_FILE")
  echo -e "  gbpublisher.sql   ${VERDE}encontrado${RESET}  ($LINEAS líneas)"
else
  echo -e "  ${ROJO}ERROR: No se encontró el archivo gbpublisher.sql${RESET}"
  echo ""
  echo "  El archivo debe estar en el mismo directorio que este script:"
  echo "    $SCRIPT_DIR"
  echo ""
  exit 1
fi

# ============================================================
# PASO 3 — ADVERTENCIA Y CONFIRMACIÓN
# ============================================================
seccion "  Paso 3: Confirmación"
echo ""
echo -e "  ${AMARILLO}${NEGRITA}ATENCIÓN — OPERACIÓN DESTRUCTIVA${RESET}"
echo ""
echo "  Este proceso realizará las siguientes acciones:"
echo ""
echo "    1. Eliminar la base de datos '${DB_NOMBRE}' si existe"
echo "       (se perderán TODOS los datos de cualquier instalación"
echo "       o prueba previa de gbpublisher en este servidor)"
echo ""
echo "    2. Crear una base de datos '${DB_NOMBRE}' limpia"
echo "    3. Crear el usuario de conexión '${DB_USUARIO}'"
echo "    4. Cargar el esquema y datos de referencia"
echo ""
read -rp "  ¿Confirmar? Escribí 'si' para continuar: " CONFIRMAR
if [ "$CONFIRMAR" != "si" ]; then
  echo ""
  echo "  Operación cancelada."
  echo ""
  exit 0
fi

# ============================================================
# PASO 4 — CREAR BASE DE DATOS Y USUARIO
# ============================================================
seccion "  Paso 4: Creando base de datos y usuario"

sudo mysql <<EOF
-- ELIMINAR BASE DE DATOS ANTERIOR SI EXISTE
DROP DATABASE IF EXISTS \`${DB_NOMBRE}\`;

-- CREAR BASE DE DATOS CON CODIFICACIÓN CORRECTA
CREATE DATABASE \`${DB_NOMBRE}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- ELIMINAR USUARIO ANTERIOR SI EXISTE Y RECREAR
DROP USER IF EXISTS '${DB_USUARIO}'@'${DB_HOST}';
CREATE USER '${DB_USUARIO}'@'${DB_HOST}' IDENTIFIED BY '${DB_CLAVE}';

-- OTORGAR PERMISOS COMPLETOS SOBRE LA BASE
GRANT ALL PRIVILEGES ON \`${DB_NOMBRE}\`.* TO '${DB_USUARIO}'@'${DB_HOST}';
FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
  echo ""
  echo -e "  ${ROJO}ERROR: No se pudo crear la base de datos.${RESET}"
  echo "  Verificá que tenés permisos de administrador (sudo)."
  echo ""
  exit 1
fi

echo -e "  Base de datos     ${VERDE}creada${RESET}"
echo -e "  Usuario           ${VERDE}creado${RESET}  (${DB_USUARIO}@${DB_HOST})"

# ============================================================
# PASO 5 — CARGAR EL DUMP
# ============================================================
seccion "  Paso 5: Cargando esquema y datos de referencia"

sudo mysql "$DB_NOMBRE" < "$DUMP_FILE"

if [ $? -ne 0 ]; then
  echo ""
  echo -e "  ${ROJO}ERROR: Falló la carga del dump.${RESET}"
  echo "  La base de datos puede haber quedado en estado incompleto."
  echo "  Revisá el archivo gbpublisher.sql y volvé a ejecutar este script."
  echo ""
  exit 1
fi

# VERIFICAR QUE LAS TABLAS SE CREARON
TABLAS=$(sudo mysql -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NOMBRE}';" 2>/dev/null)
echo -e "  Tablas creadas    ${VERDE}${TABLAS} tablas${RESET}"

# ============================================================
# PASO 6 — RESUMEN FINAL
# ============================================================
echo ""
echo "  ════════════════════════════════════════════════════════════════════"
echo -e "  ${VERDE}${NEGRITA}Proceso completado con éxito.${RESET}"
echo "  ════════════════════════════════════════════════════════════════════"
echo ""
echo "  La base de datos '${DB_NOMBRE}' está lista."
echo ""
echo -e "  ${NEGRITA}Próximos pasos:${RESET}"
echo ""
echo "    1. Abrí gbpublisher"
echo "    2. En la pantalla principal, hacé clic en el ícono de"
echo "       administración (mano abierta con cubos) en la esquina"
echo "       inferior derecha"
echo "    3. Iniciá sesión con:  usuario: admin  /  contraseña: admin123"
echo "    4. Creá al menos 1 usuario operativo"
echo "    5. Cerrá Administración y logueate con ese usuario"
echo ""
echo -e "  ${AMARILLO}Nota: cambiá la contraseña del administrador después del primer acceso.${RESET}"
echo ""

exit 0
