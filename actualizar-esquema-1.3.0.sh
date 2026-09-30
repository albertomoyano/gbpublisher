#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.3.0.sh
# Propósito : Actualización 1.3.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Catálogo de idiomas:
#               1. tabla idiomas (código BCP 47, nombre, nombre de babel…)
#               2. filas iniciales: los 386 locales de babel, 12 activos
#               3. columnas de idioma de un solo valor ensanchadas a
#                  VARCHAR(20): hay códigos de babel de hasta 16 caracteres
#                  (sr-Latn-ijekavsk) y las columnas eran VARCHAR(10)
#             Al final emite un INFORME DE CONTROL, solo de lectura, con los
#             valores de idioma que no están en el catálogo o están inactivos.
# Uso       : ./actualizar-esquema-1.3.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5. IDEMPOTENTE; respaldo verificado; verificación
#             posterior; sin efecto si ya está aplicado.
# Fuente de las filas: generar-idiomas-babel.sh, corrido en la máquina de
# composición:
#   Fuente: /usr/share/texlive/texmf-dist/tex/generic/babel/locale
#   babel: 2024/01/07 v24.1 The Babel package
#   Locales: 386; activos por omisión: es pt en fr de it ca gl eu la gn qu
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.3.0"
DESCRIPCION="Catálogo de idiomas: tabla idiomas; columnas de idioma a VARCHAR(20)"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
FILAS_CATALOGO=386
ANCHO=20

# COLUMNAS DE IDIOMA DE UN SOLO VALOR (tabla.columna). articulos.idioma_principal
# YA ES VARCHAR(50) Y NO SE TOCA: SOLO SE ENSANCHA LO QUE ES MÁS CHICO QUE 20
COLUMNAS_IDIOMA="
articulos.idioma_titulo_traducido
articulos.idioma_resumen_1
articulos.idioma_resumen_2
articulos.idioma_resumen_3
articulos.idioma_kwd_1
articulos.idioma_kwd_2
articulos.idioma_kwd_3
capitulos.idioma_titulo_traducido
capitulos.idioma_capitulo
capitulos.idioma_resumen_1
capitulos.idioma_resumen_2
capitulos.idioma_resumen_3
capitulos.idioma_kwd_1
capitulos.idioma_kwd_2
capitulos.idioma_kwd_3
libros_md.idioma_titulo_original
libros_md.idioma_principal
libros_md.idioma_resumen_traducido
"

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

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

mysql_adm() {
  $SUDO mysql --default-character-set=utf8mb4 "$@"
}

valor() {
  mysql_adm -N -B -e "$1"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.3.0${RESET}"
echo "-------------------------------------------------"
echo "Crea el catálogo de idiomas y ensancha las columnas de idioma a ${ANCHO}"
echo "caracteres. No borra ni modifica valores existentes."
echo

# --- 2. VERIFICACIONES PREVIAS ---
if ! command -v mysql >/dev/null 2>&1 || ! command -v mysqldump >/dev/null 2>&1; then
  error "Faltan los clientes mysql o mysqldump."
  exit 1
fi

if [ -n "$SUDO" ] && ! sudo -v; then
  error "No se pudieron obtener permisos de administrador (sudo)."
  exit 1
fi

if ! mysql_adm -e "SELECT 1;" >/dev/null 2>&1; then
  error "No se pudo conectar al servidor con la cuenta administrativa."
  exit 1
fi

if [ "$(valor "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${DB}';")" != "1" ]; then
  error "No existe la base '${DB}'."
  exit 1
fi

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.3.0 VA SOBRE 1.2.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.2.0';")" != "1" ]; then
  error "Falta la actualización 1.2.0. Aplicala primero (actualizar-esquema-1.2.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='idiomas';"
}

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='idiomas';"
}

filas_tabla() {
  valor "SELECT COUNT(*) FROM \`${DB}\`.idiomas;"
}

# CONDICIÓN SQL SOBRE information_schema.COLUMNS PARA LAS COLUMNAS DE LA LISTA
condicion_columnas() {
  local c t col primero=1
  for c in $COLUMNAS_IDIOMA; do
    t="${c%%.*}"; col="${c##*.}"
    if [ $primero -eq 1 ]; then primero=0; else printf " OR "; fi
    printf "(TABLE_NAME='%s' AND COLUMN_NAME='%s')" "$t" "$col"
  done
}
COND_COLUMNAS="$(condicion_columnas)"

columnas_angostas() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND DATA_TYPE='varchar' AND CHARACTER_MAXIMUM_LENGTH < ${ANCHO} AND (${COND_COLUMNAS});"
}

columnas_encontradas() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND (${COND_COLUMNAS});"
}

TOTAL_COLUMNAS=$(echo $COLUMNAS_IDIOMA | wc -w)
if [ "$(columnas_encontradas)" != "$TOTAL_COLUMNAS" ]; then
  error "No se encontraron las ${TOTAL_COLUMNAS} columnas de idioma esperadas: el esquema no es el previsto."
  exit 1
fi

FALTA_TABLA=0; FALTAN_FILAS=0
if [ "$(existe_tabla)" = "0" ]; then
  FALTA_TABLA=1
  FALTAN_FILAS=$FILAS_CATALOGO
elif [ "$(filas_tabla)" -lt "$FILAS_CATALOGO" ]; then
  FALTAN_FILAS=$((FILAS_CATALOGO - $(filas_tabla)))
fi
ANGOSTAS="$(columnas_angostas)"

if [ "$FALTA_TABLA" -eq 0 ] && [ "$FALTAN_FILAS" -eq 0 ] && [ "$ANGOSTAS" = "0" ]; then
  ok "El esquema ya tiene todo lo de 1.3.0. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente:"
  [ "$FALTA_TABLA" -eq 1 ] && echo "    - tabla idiomas"
  [ "$FALTAN_FILAS" -gt 0 ] && echo "    - filas del catálogo (hay $([ "$FALTA_TABLA" -eq 1 ] && echo 0 || filas_tabla) de ${FILAS_CATALOGO})"
  [ "$ANGOSTAS" != "0" ] && echo "    - ${ANGOSTAS} columnas de idioma a VARCHAR(${ANCHO})"
  echo

  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.3.0-$(date '+%Y%m%d-%H%M%S').sql"
  info "Respaldo en ${RESPALDO}"

  $SUDO mysqldump --single-transaction --routines --triggers --events \
    --default-character-set=utf8mb4 "$DB" > "$RESPALDO"

  if [ ! -s "$RESPALDO" ]; then
    error "El respaldo quedó vacío. No se modificó nada."
    exit 1
  fi
  if ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
    error "El respaldo no terminó completo (falta la marca final). No se modificó nada."
    exit 1
  fi
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---

  # 5.1 TABLA. codigo ÚNICO; LA COLACIÓN _ci SIRVE A LA BÚSQUEDA POR NOMBRE
  # (m_Idiomas.Normalizar); LAS COMPARACIONES DE CÓDIGO EXACTO SE HACEN BINARIAS
  if [ "$FALTA_TABLA" -eq 1 ]; then
    mysql_adm "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS `idiomas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Etiqueta BCP 47 (tag.bcp47 de babel): es, pt-BR',
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre en el propio idioma (name.local de babel)',
  `nombre_ingles` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'name.english de babel',
  `babel` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nombre para \\usepackage[...]{babel}',
  `nivel` tinyint DEFAULT NULL COMMENT 'Cobertura del locale según babel (level)',
  `activo` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Aparece en los combos de idioma',
  `orden` int NOT NULL DEFAULT '1000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_idiomas_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de idiomas, generado desde babel (actualización 1.3.0)';
SQL
    ok "Tabla idiomas creada."
  fi

  # 5.2 FILAS. INSERT IGNORE SOBRE codigo: UNA FILA EXISTENTE (QUIZÁS CON
  # activo U orden CAMBIADOS A MANO) NO SE PISA
  if [ "$FALTAN_FILAS" -gt 0 ]; then
    mysql_adm "$DB" <<'SQL'
INSERT IGNORE INTO `idiomas` (`codigo`, `nombre`, `nombre_ingles`, `babel`, `nivel`, `activo`, `orden`) VALUES
('aa', 'Qafar', 'Afar', 'afar', 1, 0, 1000),
('ab', 'Аԥсшәа', 'Abkhazian', 'abkhazian', 1, 0, 1000),
('ae', '𐬎𐬞𐬀𐬯𐬙𐬀𐬎𐬎𐬀𐬐𐬀𐬉𐬥𐬀', 'Avestan', 'avestan', 1, 0, 1000),
('af', 'Afrikaans', 'Afrikaans', 'afrikaans', 1, 0, 1000),
('agq', 'Aghem', 'Aghem', 'aghem', 1, 0, 1000),
('ak', 'Akan', 'Akan', 'akan', 1, 0, 1000),
('akk', '𒀝𒅗𒁺𒌑', 'Akkadian', 'akkadian', 1, 0, 1000),
('alt', 'Southern Altai', 'Southern Altai', 'southernaltai', 1, 0, 1000),
('am', 'አማርኛ', 'Amharic', 'amharic', 1, 0, 1000),
('ar', 'العربية', 'Arabic', 'arabic', 1, 0, 1000),
('ar-DZ', 'العربية', 'Arabic', 'arabic-algeria', 1, 0, 1000),
('ar-EG', 'العربية', 'Arabic', 'arabic-egypt', 1, 0, 1000),
('ar-IQ', 'العربية', 'Arabic', 'arabic-iraq', 1, 0, 1000),
('ar-JO', 'العربية', 'Arabic', 'arabic-jordan', 1, 0, 1000),
('ar-LB', 'العربية', 'Arabic', 'arabic-lebanon', 1, 0, 1000),
('ar-MA', 'العربية', 'Arabic', 'arabic-morocco', 1, 0, 1000),
('ar-PS', 'العربية', 'Arabic', 'arabic-palestinianterritories', 1, 0, 1000),
('ar-SA', 'العربية', 'Arabic', 'arabic-saudiarabia', 1, 0, 1000),
('ar-SY', 'العربية', 'Arabic', 'arabic-syria', 1, 0, 1000),
('ar-TN', 'العربية', 'Arabic', 'arabic-tunisia', 1, 0, 1000),
('arc', '𐡀𐡓𐡌𐡉𐡀', 'Aramaic', 'aramaic', 1, 0, 1000),
('arc-Nbat', 'Aramaic', 'Aramaic', 'aramaic-nabataean', 1, 0, 1000),
('arc-Palm', 'Aramaic', 'Aramaic', 'aramaic-palmyrene', 1, 0, 1000),
('arz', 'مصرى', 'Egyptian Arabic', 'egyptianarabic', 1, 0, 1000),
('as', 'অসমীয়া', 'Assamese', 'assamese', 1, 0, 1000),
('asa', 'Kipare', 'Asu', 'asu', 1, 0, 1000),
('ast', 'asturianu', 'Asturian', 'asturian', 1, 0, 1000),
('awa', 'अवधी', 'Awadhi', 'awadhi', 1, 0, 1000),
('ay', 'aymar aru', 'Aymara', 'aymara', 1, 0, 1000),
('az', 'azərbaycan', 'Azerbaijani', 'azerbaijani', 1, 0, 1000),
('az-Cyrl', 'азәрбајҹан', 'Azerbaijani', 'azerbaijani-cyrillic', 1, 0, 1000),
('az-Latn', 'azərbaycan', 'Azerbaijani', 'azerbaijani-latin', 1, 0, 1000),
('ba', 'башҡорт теле', 'Bashkir', 'bashkir', 1, 0, 1000),
('bal', 'بلۆچی', 'Baluchi', 'baluchi', 1, 0, 1000),
('ban', 'Basa Bali', 'Balinese', 'balinese', 1, 0, 1000),
('bar', 'Boarisch', 'Bavarian', 'bavarian', 1, 0, 1000),
('bas', 'Ɓàsàa', 'Basaa', 'basaa', 1, 0, 1000),
('bbc', 'ᯂᯖ ᯅᯖᯂ᯲ ᯖᯬᯅ', 'Batak Toba', 'bataktoba', 1, 0, 1000),
('be', 'беларуская', 'Belarusian', 'belarusian', 1, 0, 1000),
('bem', 'Ichibemba', 'Bemba', 'bemba', 1, 0, 1000),
('bez', 'Hibena', 'Bena', 'bena', 1, 0, 1000),
('bg', 'български', 'Bulgarian', 'bulgarian', 1, 0, 1000),
('bgc', 'हरियाणवी', 'Haryanvi', 'haryanvi', 1, 0, 1000),
('bho', 'भोजपुरी', 'Bhojpuri', 'bhojpuri', 1, 0, 1000),
('bm', 'bamanakan', 'Bambara', 'bambara', 1, 0, 1000),
('bn', 'বাংলা', 'Bangla', 'bangla', 1, 0, 1000),
('bo', 'བོད་སྐད་', 'Tibetan', 'tibetan', 1, 0, 1000),
('br', 'brezhoneg', 'Breton', 'breton', 1, 0, 1000),
('brx', 'बर’', 'Bodo', 'bodo', 1, 0, 1000),
('bs', 'bosanski', 'Bosnian', 'bosnian', 1, 0, 1000),
('bs-Cyrl', 'босански', 'Bosnian', 'bosnian-cyrillic', 1, 0, 1000),
('bs-Latn', 'bosanski', 'Bosnian', 'bosnian-latin', 1, 0, 1000),
('bua', 'Буряад', 'Buriat', 'buriat', 1, 0, 1000),
('byn', 'ብሊን', 'Blin', 'blin', 1, 0, 1000),
('ca', 'català', 'Catalan', 'catalan', 1, 1, 70),
('cch', 'Atsam', 'Atsam', 'atsam', 1, 0, 1000),
('ccp', '𑄌𑄋𑄴𑄟𑄳𑄦', 'Chakma', 'chakma', 1, 0, 1000),
('ce', 'нохчийн', 'Chechen', 'chechen', 1, 0, 1000),
('ceb', 'Cebuano', 'Cebuano', 'cebuano', 1, 0, 1000),
('cgg', 'Rukiga', 'Chiga', 'chiga', 1, 0, 1000),
('chr', 'ᏣᎳᎩ', 'Cherokee', 'cherokee', 1, 0, 1000),
('ckb', 'کوردیی ناوەندی', 'Central Kurdish', 'sorani', 1, 0, 1000),
('ckb-Arab', 'کوردیی ناوەندی', 'Central Kurdish', 'sorani', 1, 0, 1000),
('ckb-Latn', 'Kurdîy nawendî', 'Central Kurdish', 'sorani', 1, 0, 1000),
('co', 'corsu', 'Corsican', 'corsican', 1, 0, 1000),
('cop', 'ϯⲙⲉⲧⲣⲉⲙⲛ̀ⲭⲏⲙⲓ', 'Coptic', 'coptic', 1, 0, 1000),
('cs', 'čeština', 'Czech', 'czech', 1, 0, 1000),
('cu', 'црькъвьнословѣньскъ ѩзыкъ', 'Church Slavic', 'churchslavic', 1, 0, 1000),
('cu-Cyrs', 'словѣ́ньскъ ѩꙁꙑ́къ', 'Church Slavic', 'churchslavic-oldcyrillic', 1, 0, 1000),
('cu-Glag', 'ⰔⰎⰑⰂⰡⰐⰠⰔⰍⰟ ⰧⰈⰟⰊⰍⰟ', 'Church Slavic', 'churchslavic-glagolitic', 0, 0, 1000),
('cv', 'чӑваш', 'Chuvash', 'chuvash', 1, 0, 1000),
('cy', 'Cymraeg', 'Welsh', 'welsh', 1, 0, 1000),
('da', 'dansk', 'Danish', 'danish', 1, 0, 1000),
('dav', 'Kitaita', 'Taita', 'taita', 1, 0, 1000),
('de', 'Deutsch', 'German', 'ngerman', 1, 1, 50),
('de-1901', 'Deutsch', 'German', 'german', 1, 0, 1000),
('de-1996', 'Deutsch', 'German', 'ngerman', 1, 0, 1000),
('de-AT', 'Österreichisches Deutsch', 'Austrian German', 'austrian', 1, 0, 1000),
('de-AT-1901', 'Österreichisches Deutsch', 'Austrian German', 'austrian-traditional', 1, 0, 1000),
('de-AT-1996', 'Österreichisches Deutsch', 'Austrian German', 'austrian', 1, 0, 1000),
('de-CH', 'Schweizer Hochdeutsch', 'Swiss High German', 'german-switzerland', 1, 0, 1000),
('de-CH-1901', 'Schweizer Hochdeutsch', 'Swiss High German', 'german-switzerland-traditional', 1, 0, 1000),
('de-CH-1996', 'Schweizer Hochdeutsch', 'Swiss High German', 'german-switzerland', 1, 0, 1000),
('dje', 'Zarmaciine', 'Zarma', 'zarma', 1, 0, 1000),
('doi', 'डोगरी', 'Dogri', 'dogri', 1, 0, 1000),
('dsb', 'dolnoserbšćina', 'Lower Sorbian', 'lowersorbian', 1, 0, 1000),
('dua', 'duálá', 'Duala', 'duala', 1, 0, 1000),
('dv', 'ދިވެހިބަސް', 'Divehi', 'divehi', 1, 0, 1000),
('dyo', 'joola', 'Jola-Fonyi', 'jolafonyi', 1, 0, 1000),
('dz', 'རྫོང་ཁ', 'Dzongkha', 'dzongkha', 1, 0, 1000),
('ebu', 'Kĩembu', 'Embu', 'embu', 1, 0, 1000),
('ee', 'Eʋegbe', 'Ewe', 'ewe', 1, 0, 1000),
('egy', '𓂋𓏺𓈖 𓆎𓅓𓏏𓊖', 'Ancient Egyptian', 'ancientegyptian', 1, 0, 1000),
('el', 'Ελληνικά', 'Greek', 'greek', 1, 0, 1000),
('el-polyton', 'Ἐλληνικά', 'Polytonic Greek', 'polytonicgreek', 1, 0, 1000),
('en', 'English', 'English', 'english', 1, 1, 30),
('en-AU', 'Australian English', 'Australian English', 'english-australia', 1, 0, 1000),
('en-CA', 'Canadian English', 'Canadian English', 'canadian', 1, 0, 1000),
('en-GB', 'British English', 'British English', 'british', 1, 0, 1000),
('en-NZ', 'English', 'English', 'english-newzealand', 1, 0, 1000),
('en-US', 'American English', 'American English', 'american', 1, 0, 1000),
('eo', 'esperanto', 'Esperanto', 'esperanto', 1, 0, 1000),
('es', 'español', 'Spanish', 'spanish', 1, 1, 10),
('es-MX', 'español de México', 'Mexican Spanish', 'mexican', 1, 0, 1000),
('et', 'eesti', 'Estonian', 'estonian', 1, 0, 1000),
('eu', 'euskara', 'Basque', 'basque', 1, 1, 90),
('ewo', 'ewondo', 'Ewondo', 'ewondo', 1, 0, 1000),
('fa', 'فارسی', 'Persian', 'persian', 1, 0, 1000),
('ff', 'Pulaar', 'Fulah', 'fulah', 1, 0, 1000),
('fi', 'suomi', 'Finnish', 'finnish', 1, 0, 1000),
('fil', 'Filipino', 'Filipino', 'filipino', 1, 0, 1000),
('fo', 'føroyskt', 'Faroese', 'faroese', 1, 0, 1000),
('fr', 'français', 'French', 'french', 1, 1, 40),
('fr-BE', 'français', 'French', 'french-belgium', 1, 0, 1000),
('fr-CA', 'français canadien', 'Canadian French', 'canadien', 1, 0, 1000),
('fr-CH', 'français suisse', 'Swiss French', 'french-switzerland', 1, 0, 1000),
('fr-LU', 'français', 'French', 'french-luxembourg', 1, 0, 1000),
('fr-x-acadian', 'acadien', 'Acadian', 'acadian', 1, 0, 1000),
('frr', 'Nordfriisk', 'Northern Frisian', 'northernfrisian', 1, 0, 1000),
('fur', 'furlan', 'Friulian', 'friulian', 1, 0, 1000),
('fy', 'Frysk', 'Western Frisian', 'westernfrisian', 1, 0, 1000),
('ga', 'Gaeilge', 'Irish', 'irish', 1, 0, 1000),
('gaa', 'Gã', 'Ga', 'ga', 1, 0, 1000),
('gd', 'Gàidhlig', 'Scottish Gaelic', 'scottishgaelic', 1, 0, 1000),
('gez', 'ግዕዝኛ', 'Geez', 'geez', 1, 0, 1000),
('gl', 'galego', 'Galician', 'galician', 1, 1, 80),
('gn', 'avañe’ẽ', 'Guarani', 'guarani', 1, 1, 110),
('got', '𐌲𐌿𐍄𐌹𐍃𐌺', 'Gothic', 'gothic', 1, 0, 1000),
('grc', 'Αρχαία ελληνικά', 'Ancient Greek', 'ancientgreek', 1, 0, 1000),
('gsw', 'Schwiizertüütsch', 'Swiss German', 'swissgerman', 1, 0, 1000),
('gu', 'ગુજરાતી', 'Gujarati', 'gujarati', 1, 0, 1000),
('guz', 'Ekegusii', 'Gusii', 'gusii', 1, 0, 1000),
('gv', 'Gaelg', 'Manx', 'manx', 1, 0, 1000),
('ha', 'Hausa', 'Hausa', 'hausa', 1, 0, 1000),
('ha-GH', 'Hausa', 'Hausa', 'hausa-ghana', 1, 0, 1000),
('ha-NE', 'Hausa', 'Hausa', 'hausa-niger', 1, 0, 1000),
('haw', 'ʻŌlelo Hawaiʻi', 'Hawaiian', 'hawaiian', 1, 0, 1000),
('he', 'עברית', 'Hebrew', 'hebrew', 1, 0, 1000),
('hi', 'हिन्दी', 'Hindi', 'hindi', 1, 0, 1000),
('hnj', '𞄀𞄄𞄰𞄩𞄍𞄜𞄰', 'Hmong Njua', 'hmongnjua', 1, 0, 1000),
('hr', 'hrvatski', 'Croatian', 'croatian', 1, 0, 1000),
('hsb', 'hornjoserbšćina', 'Upper Sorbian', 'uppersorbian', 1, 0, 1000),
('hu', 'magyar', 'Hungarian', 'hungarian', 1, 0, 1000),
('hy', 'հայերեն', 'Armenian', 'armenian', 1, 0, 1000),
('ia', 'Interlingua', 'Interlingua', 'interlingua', 1, 0, 1000),
('id', 'Indonesia', 'Indonesian', 'indonesian', 1, 0, 1000),
('ig', 'Igbo', 'Igbo', 'igbo', 1, 0, 1000),
('ii', 'ꆈꌠꉙ', 'Sichuan Yi', 'sichuanyi', 1, 0, 1000),
('inh', 'гӀалгӀай мотт', 'Ingush', 'ingush', 1, 0, 1000),
('is', 'íslenska', 'Icelandic', 'icelandic', 1, 0, 1000),
('it', 'italiano', 'Italian', 'italian', 1, 1, 60),
('iu', 'ᐃᓄᒃᑎᑐᑦ', 'Inuktitut', 'inuktitut', 1, 0, 1000),
('ja', '日本語', 'Japanese', 'japanese', 1, 0, 1000),
('jgo', 'Ndaꞌa', 'Ngomba', 'ngomba', 1, 0, 1000),
('jmc', 'Kimachame', 'Machame', 'machame', 1, 0, 1000),
('jv', 'Jawa', 'Javanese', 'javanese', 1, 0, 1000),
('ka', 'ქართული', 'Georgian', 'georgian', 1, 0, 1000),
('kab', 'Taqbaylit', 'Kabyle', 'kabyle', 1, 0, 1000),
('kaj', 'Kaje', 'Jju', 'jju', 1, 0, 1000),
('kam', 'Kikamba', 'Kamba', 'kamba', 1, 0, 1000),
('kcg', 'Katab', 'Tyap', 'tyap', 1, 0, 1000),
('kde', 'Chimakonde', 'Makonde', 'makonde', 1, 0, 1000),
('kea', 'kabuverdianu', 'Kabuverdianu', 'kabuverdianu', 1, 0, 1000),
('kgp', 'kanhgág', 'Kaingang', 'kaingang', 1, 0, 1000),
('khb', 'ᦅᧄᦺᦑᦟᦹᧉ', 'Lü', 'lu', 1, 0, 1000),
('khq', 'Koyra ciini', 'Koyra Chiini', 'koyrachiini', 1, 0, 1000),
('ki', 'Gikuyu', 'Kikuyu', 'kikuyu', 1, 0, 1000),
('kk', 'қазақ тілі', 'Kazakh', 'kazakh', 1, 0, 1000),
('kkj', 'kakɔ', 'Kako', 'kako', 1, 0, 1000),
('kl', 'kalaallisut', 'Kalaallisut', 'kalaallisut', 1, 0, 1000),
('kln', 'Kalenjin', 'Kalenjin', 'kalenjin', 1, 0, 1000),
('km', 'ខ្មែរ', 'Khmer', 'khmer', 1, 0, 1000),
('kmr', 'Kurmancî', 'Northern Kurdish', 'kurmanji', 1, 0, 1000),
('kmr-Arab', 'کورمانجی', 'Northern Kurdish', 'kurmanji', 1, 0, 1000),
('kmr-Latn', 'Kurmancî', 'Northern Kurdish', 'kurmanji', 1, 0, 1000),
('kn', 'ಕನ್ನಡ', 'Kannada', 'kannada', 1, 0, 1000),
('ko', '한국어', 'Korean', 'korean', 1, 0, 1000),
('kok', 'कोंकणी', 'Konkani', 'konkani', 1, 0, 1000),
('ks', 'کٲشُر', 'Kashmiri', 'kashmiri', 1, 0, 1000),
('ksb', 'Kishambaa', 'Shambala', 'shambala', 1, 0, 1000),
('ksf', 'rikpa', 'Bafia', 'bafia', 1, 0, 1000),
('ksh', 'Kölsch', 'Colognian', 'colognian', 1, 0, 1000),
('kv', 'коми кыв', 'Komi', 'komi', 1, 0, 1000),
('kw', 'kernewek', 'Cornish', 'cornish', 1, 0, 1000),
('ky', 'кыргызча', 'Kyrgyz', 'kyrgyz', 1, 0, 1000),
('la', 'Latin', 'Latin', 'latin', 1, 1, 100),
('la-x-classic', 'Classical Latin', 'Classical Latin', 'classicallatin', 1, 0, 1000),
('la-x-ecclesia', 'Ecclesiastical Latin', 'Ecclesiastical Latin', 'ecclesiasticallatin', 1, 0, 1000),
('la-x-medieval', 'Medieval Latin', 'Medieval Latin', 'medievallatin', 1, 0, 1000),
('lab', 'Linear A', 'Linear A', 'lineara', 1, 0, 1000),
('lad', 'Ladino', 'Ladino', 'ladino', 1, 0, 1000),
('lag', 'Kɨlaangi', 'Langi', 'langi', 1, 0, 1000),
('lb', 'Lëtzebuergesch', 'Luxembourgish', 'luxembourgish', 1, 0, 1000),
('lep', 'ᰛᰩᰵᰛᰧᰵᰶ', 'Lepcha', 'lepcha', 1, 0, 1000),
('lg', 'Luganda', 'Ganda', 'ganda', 1, 0, 1000),
('lif', 'लिम्बु भाषा', 'Limbu', 'limbu', 1, 0, 1000),
('lif-Limb', 'ᤕᤠᤰᤌᤢᤱ ᤐᤠᤴ', 'Limbu', 'limbu-limbu', 1, 0, 1000),
('lij', 'ligure', 'Ligurian', 'ligurian', 1, 0, 1000),
('lkt', 'Lakȟólʼiyapi', 'Lakota', 'lakota', 1, 0, 1000),
('lmo', 'lombard', 'Lombard', 'lombard', 1, 0, 1000),
('ln', 'lingála', 'Lingala', 'lingala', 1, 0, 1000),
('lo', 'ລາວ', 'Lao', 'lao', 1, 0, 1000),
('lrc', 'لۊری شومالی', 'Northern Luri', 'northernluri', 1, 0, 1000),
('lt', 'lietuvių', 'Lithuanian', 'lithuanian', 1, 0, 1000),
('lu', 'Tshiluba', 'Luba-Katanga', 'lubakatanga', 1, 0, 1000),
('luo', 'Dholuo', 'Luo', 'luo', 1, 0, 1000),
('luy', 'Luluhia', 'Luyia', 'luyia', 1, 0, 1000),
('lv', 'latviešu', 'Latvian', 'latvian', 1, 0, 1000),
('mai', 'मैथिली', 'Maithili', 'maithili', 1, 0, 1000),
('mak', 'basa Mangkasaraʼ', 'Makasar', 'makasar', 1, 0, 1000),
('mak-Bugi', 'ᨅᨔ ᨆᨀᨔᨑ', 'Makasar', 'makasar-buginese', 1, 0, 1000),
('mas', 'Maa', 'Masai', 'masai', 1, 0, 1000),
('mer', 'Kĩmĩrũ', 'Meru', 'meru', 1, 0, 1000),
('mfe', 'kreol morisien', 'Morisyen', 'morisyen', 1, 0, 1000),
('mg', 'Malagasy', 'Malagasy', 'malagasy', 1, 0, 1000),
('mgh', 'Makua', 'Makhuwa-Meetto', 'makhuwameetto', 1, 0, 1000),
('mgo', 'metaʼ', 'Metaʼ', 'meta', 1, 0, 1000),
('mi', 'Māori', 'Māori', 'maori', 1, 0, 1000),
('mk', 'македонски', 'Macedonian', 'macedonian', 1, 0, 1000),
('ml', 'മലയാളം', 'Malayalam', 'malayalam', 1, 0, 1000),
('mn', 'монгол', 'Mongolian', 'mongolian', 1, 0, 1000),
('mni', 'মৈতৈলোন্', 'Manipuri', 'manipuri', 1, 0, 1000),
('mr', 'मराठी', 'Marathi', 'marathi', 1, 0, 1000),
('ms', 'Melayu', 'Malay', 'malay', 1, 0, 1000),
('ms-BN', 'Bahasa Melayu', 'Malay', 'malay-brunei', 1, 0, 1000),
('ms-SG', 'Bahasa Melayu', 'Malay', 'malay-singapore', 1, 0, 1000),
('mt', 'Malti', 'Maltese', 'maltese', 1, 0, 1000),
('mua', 'Mundaŋ', 'Mundang', 'mundang', 1, 0, 1000),
('mus', 'Mvskoke', 'Muscogee', 'muscogee', 1, 0, 1000),
('my', 'မြန်မာ', 'Burmese', 'burmese', 1, 0, 1000),
('myv', 'эрзянь кель', 'Erzya', 'erzya', 1, 0, 1000),
('myz', 'ࡓࡀࡈࡍࡀ', 'Classical Mandaic', 'classicalmandaic', 1, 0, 1000),
('mzn', 'مازرونی', 'Mazanderani', 'mazanderani', 1, 0, 1000),
('naq', 'Khoekhoegowab', 'Nama', 'nama', 1, 0, 1000),
('nb', 'norsk bokmål', 'Norwegian Bokmål', 'norwegianbokmal', 1, 0, 1000),
('nd', 'isiNdebele', 'North Ndebele', 'northndebele', 1, 0, 1000),
('nds', 'Neddersass’sch', 'Low German', 'lowgerman', 1, 0, 1000),
('ne', 'नेपाली', 'Nepali', 'nepali', 1, 0, 1000),
('new', 'नेवाः भाय्', 'Newari', 'newari', 1, 0, 1000),
('nl', 'Nederlands', 'Dutch', 'dutch', 1, 0, 1000),
('nmg', 'Kwasio', 'Kwasio', 'kwasio', 1, 0, 1000),
('nn', 'norsk nynorsk', 'Norwegian Nynorsk', 'nynorsk', 1, 0, 1000),
('nnh', 'Shwóŋò ngiembɔɔn', 'Ngiemboon', 'ngiemboon', 1, 0, 1000),
('no', 'norsk', 'Norwegian', 'norsk', 1, 0, 1000),
('non', 'norrǿnt mál', 'Old Norse', 'oldnorse', 1, 0, 1000),
('nqo', 'ߒߞߏ', 'N’Ko', 'nko', 1, 0, 1000),
('nr', 'isiNdebele', 'South Ndebele', 'southndebele', 1, 0, 1000),
('nso', 'Sesotho sa Leboa', 'Northern Sotho', 'northernsotho', 1, 0, 1000),
('nus', 'Thok Nath', 'Nuer', 'nuer', 1, 0, 1000),
('nv', 'Diné Bizaad', 'Navajo', 'navajo', 1, 0, 1000),
('ny', 'Nyanja', 'Nyanja', 'nyanja', 1, 0, 1000),
('nyn', 'Runyankore', 'Nyankole', 'nyankole', 1, 0, 1000),
('oc', 'Occitan', 'Occitan', 'occitan', 1, 0, 1000),
('om', 'Oromoo', 'Oromo', 'oromo', 1, 0, 1000),
('or', 'ଓଡ଼ିଆ', 'Odia', 'odia', 1, 0, 1000),
('os', 'ирон', 'Ossetic', 'ossetic', 1, 0, 1000),
('pa', 'ਪੰਜਾਬੀ', 'Punjabi', 'punjabi', 1, 0, 1000),
('pa-Arab', 'پنجابی', 'Punjabi', 'punjabi-arabic', 1, 0, 1000),
('pa-Guru', 'ਪੰਜਾਬੀ', 'Punjabi', 'punjabi-gurmukhi', 1, 0, 1000),
('pap', 'Papiamentu', 'Papiamento', 'papiamento', 1, 0, 1000),
('pcm', 'Naijíriá Píjin', 'Nigerian Pidgin', 'nigerianpidgin', 1, 0, 1000),
('phn', '𐤃𐤁𐤓𐤉𐤌 𐤊𐤍𐤏𐤍𐤉𐤌', 'Phoenician', 'phoenician', 1, 0, 1000),
('pl', 'polski', 'Polish', 'polish', 1, 0, 1000),
('pms', 'Piedmontese', 'Piedmontese', 'piedmontese', 1, 0, 1000),
('prg', 'prūsiskan', 'Prussian', 'prussian', 1, 0, 1000),
('ps', 'پښتو', 'Pashto', 'pashto', 1, 0, 1000),
('pt', 'português', 'Portuguese', 'portuguese', 1, 1, 20),
('pt-BR', 'português', 'Brazilian Portuguese', 'brazilian', 1, 0, 1000),
('pt-PT', 'português europeu', 'European Portuguese', 'portuguese', 1, 0, 1000),
('qu', 'Runasimi', 'Quechua', 'quechua', 1, 1, 120),
('raj', 'राजस्थानी', 'Rajasthani', 'rajasthani', 1, 0, 1000),
('rm', 'rumantsch', 'Romansh', 'romansh', 1, 0, 1000),
('rmo', 'Sintitikes', 'Sinte Romani', 'sinteromani', 1, 0, 1000),
('rn', 'Ikirundi', 'Rundi', 'rundi', 1, 0, 1000),
('ro', 'română', 'Romanian', 'romanian', 1, 0, 1000),
('ro-MD', 'română', 'Moldavian', 'moldavian', 1, 0, 1000),
('rof', 'Kihorombo', 'Rombo', 'rombo', 1, 0, 1000),
('ru', 'русский', 'Russian', 'russian', 1, 0, 1000),
('rw', 'Kinyarwanda', 'Kinyarwanda', 'kinyarwanda', 1, 0, 1000),
('rwk', 'Kiruwa', 'Rwa', 'rwa', 1, 0, 1000),
('sa', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sa-Beng', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sa-Deva', 'संस्कृत', 'Sanskrit', 'sanskrit', 1, 0, 1000),
('sa-Gujr', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sa-Knda', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sa-Mlym', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sa-Telu', 'Sanskrit', 'Sanskrit', 'sanskrit', 0, 0, 1000),
('sah', 'саха тыла', 'Sakha', 'sakha', 1, 0, 1000),
('saq', 'Kisampur', 'Samburu', 'samburu', 1, 0, 1000),
('sat', 'ᱥᱟᱱᱛᱟᱲᱤ', 'Santali', 'santali', 1, 0, 1000),
('sbp', 'Ishisangu', 'Sangu', 'sangu', 1, 0, 1000),
('sc', 'sardu', 'Sardinian', 'sardinian', 1, 0, 1000),
('scn', 'sicilianu', 'Sicilian', 'sicilian', 1, 0, 1000),
('sd', 'سنڌي', 'Sindhi', 'sindhi', 1, 0, 1000),
('sd-Deva', 'सिन्धी', 'Sindhi', 'sindhi-devanagari', 1, 0, 1000),
('sd-Khoj', 'Sindhi', 'Sindhi', 'sindhi-khojki', 1, 0, 1000),
('sd-Sind', 'Sindhi', 'Sindhi', 'sindhi-khudawadi', 1, 0, 1000),
('se', 'davvisámegiella', 'Northern Sami', 'northernsami', 1, 0, 1000),
('seh', 'sena', 'Sena', 'sena', 1, 0, 1000),
('ses', 'Koyraboro senni', 'Koyraboro Senni', 'koyraborosenni', 1, 0, 1000),
('sg', 'Sängö', 'Sango', 'sango', 1, 0, 1000),
('shi', 'ⵜⴰⵛⵍⵃⵉⵜ', 'Tachelhit', 'tachelhit', 1, 0, 1000),
('shi-Latn', 'Tashelḥiyt', 'Tachelhit', 'tachelhit-latin', 1, 0, 1000),
('shi-Tfng', 'ⵜⴰⵛⵍⵃⵉⵜ', 'Tachelhit', 'tachelhit-tifinagh', 1, 0, 1000),
('si', 'සිංහල', 'Sinhala', 'sinhala', 1, 0, 1000),
('sk', 'slovenčina', 'Slovak', 'slovak', 1, 0, 1000),
('skr', 'سرائیکی', 'Saraiki', 'saraiki', 1, 0, 1000),
('sl', 'slovenščina', 'Slovenian', 'slovene', 1, 0, 1000),
('smn', 'anarâškielâ', 'Inari Sami', 'inarisami', 1, 0, 1000),
('smp', 'ࠏࠁࠓࠉࠕ', 'Samaritan', 'samaritan', 1, 0, 1000),
('sn', 'chiShona', 'Shona', 'shona', 1, 0, 1000),
('so', 'Soomaali', 'Somali', 'somali', 1, 0, 1000),
('sq', 'shqip', 'Albanian', 'albanian', 1, 0, 1000),
('sr', 'српски', 'Serbian', 'serbianc', 1, 0, 1000),
('sr-Cyrl', 'српски', 'Serbian', 'serbian-cyrillic', 1, 0, 1000),
('sr-Cyrl-BA', 'српски', 'Serbian', 'serbian-cyrillic-bosniaherzegovina', 1, 0, 1000),
('sr-Cyrl-ME', 'српски', 'Montenegrin', 'serbian-cyrillic-montenegro', 1, 0, 1000),
('sr-Cyrl-XK', 'српски', 'Serbian', 'serbian-cyrillic-kosovo', 1, 0, 1000),
('sr-Latn', 'srpski', 'Serbian', 'serbian-latin', 1, 0, 1000),
('sr-Latn-BA', 'srpski', 'Serbian', 'serbian-latin-bosniaherzegovina', 1, 0, 1000),
('sr-Latn-ME', 'srpski', 'Montenegrin', 'serbian-latin-montenegro', 1, 0, 1000),
('sr-Latn-XK', 'srpski', 'Serbian', 'serbian-latin-kosovo', 1, 0, 1000),
('sr-Latn-ijekavsk', 'srpski', 'Serbian', 'serbian-latin-ijekavsk', 1, 0, 1000),
('sr-ijekavsk', 'српски', 'Serbian', 'serbian-ijekavsk', 1, 0, 1000),
('ss', 'siSwati', 'Swati', 'swati', 1, 0, 1000),
('ssy', 'Saho', 'Saho', 'saho', 1, 0, 1000),
('st', 'Sesotho', 'Southern Sotho', 'southernsotho', 1, 0, 1000),
('su', 'Basa Sunda', 'Sundanese', 'sundanese', 1, 0, 1000),
('sv', 'svenska', 'Swedish', 'swedish', 1, 0, 1000),
('sw', 'Kiswahili', 'Swahili', 'swahili', 1, 0, 1000),
('syr', 'ܠܫܢܐ ܣܘܪܝܝܐ', 'Syriac', 'syriac', 1, 0, 1000),
('szl', 'ślōnski', 'Silesian', 'silesian', 1, 0, 1000),
('ta', 'தமிழ்', 'Tamil', 'tamil', NULL, 0, 1000),
('tdd', 'ᥖᥭᥰ ᥘᥫᥴ', 'Tai Nüa', 'tainua', 1, 0, 1000),
('te', 'తెలుగు', 'Telugu', 'telugu', 1, 0, 1000),
('teo', 'Kiteso', 'Teso', 'teso', 1, 0, 1000),
('tg', 'тоҷикӣ', 'Tajik', 'tajik', 1, 0, 1000),
('th', 'ไทย', 'Thai', 'thai', 1, 0, 1000),
('ti', 'ትግርኛ', 'Tigrinya', 'tigrinya', 1, 0, 1000),
('tig', 'ትግረ', 'Tigre', 'tigre', 1, 0, 1000),
('tk', 'türkmen dili', 'Turkmen', 'turkmen', 1, 0, 1000),
('tn', 'Setswana', 'Tswana', 'tswana', 1, 0, 1000),
('to', 'lea fakatonga', 'Tongan', 'tongan', 1, 0, 1000),
('tpi', 'Tok Pisin', 'Tok Pisin', 'tokpisin', 1, 0, 1000),
('tr', 'Türkçe', 'Turkish', 'turkish', 1, 0, 1000),
('trv', 'patas Taroko', 'Taroko', 'taroko', 1, 0, 1000),
('ts', 'Xitsonga', 'Tsonga', 'tsonga', 1, 0, 1000),
('tt', 'татар', 'Tatar', 'tatar', 1, 0, 1000),
('twq', 'Tasawaq senni', 'Tasawaq', 'tasawaq', 1, 0, 1000),
('txg', '𗼇𗟲', 'Tangut', 'tangut', 1, 0, 1000),
('tzm', 'Tamaziɣt n laṭlaṣ', 'Central Atlas Tamazight', 'centralatlastamazight', 1, 0, 1000),
('ug', 'ئۇيغۇرچە', 'Uyghur', 'uyghur', 1, 0, 1000),
('uk', 'українська', 'Ukrainian', 'ukrainian', 1, 0, 1000),
('ur', 'اردو', 'Urdu', 'urdu', 1, 0, 1000),
('uz', 'o‘zbek', 'Uzbek', 'uzbek', 1, 0, 1000),
('uz-Arab', 'اوزبیک', 'Uzbek', 'uzbek-arabic', 1, 0, 1000),
('uz-Cyrl', 'ўзбекча', 'Uzbek', 'uzbek-cyrillic', 1, 0, 1000),
('uz-Latn', 'o‘zbek', 'Uzbek', 'uzbek-latin', 1, 0, 1000),
('vai', 'ꕙꔤ', 'Vai', 'vai', 1, 0, 1000),
('vai-Latn', 'Vai', 'Vai', 'vai-latin', 1, 0, 1000),
('vai-Vaii', 'ꕙꔤ', 'Vai', 'vai-vai', 1, 0, 1000),
('ve', 'Tshivenḓa', 'Venda', 'venda', 1, 0, 1000),
('vi', 'Tiếng Việt', 'Vietnamese', 'vietnamese', 1, 0, 1000),
('vo', 'Volapük', 'Volapük', 'volapuk', 1, 0, 1000),
('vun', 'Kyivunjo', 'Vunjo', 'vunjo', 1, 0, 1000),
('wae', 'Walser', 'Walser', 'walser', 1, 0, 1000),
('wal', 'ወላይታቱ', 'Wolaytta', 'wolaytta', 1, 0, 1000),
('war', 'Waray', 'Waray', 'waray', 1, 0, 1000),
('wo', 'Wolof', 'Wolof', 'wolof', 1, 0, 1000),
('xh', 'IsiXhosa', 'Xhosa', 'xhosa', 1, 0, 1000),
('xog', 'Olusoga', 'Soga', 'soga', 1, 0, 1000),
('yav', 'nuasue', 'Yangben', 'yangben', 1, 0, 1000),
('yi', 'ייִדיש', 'Yiddish', 'yiddish', 1, 0, 1000),
('yo', 'Èdè Yorùbá', 'Yoruba', 'yoruba', 1, 0, 1000),
('yrl', 'nheẽgatu', 'Nheengatu', 'nheengatu', 1, 0, 1000),
('yue', '粵語', 'Cantonese', 'cantonese', 1, 0, 1000),
('zgh', 'ⵜⴰⵎⴰⵣⵉⵖⵜ', 'Standard Moroccan Tamazight', 'standardmoroccantamazight', 1, 0, 1000),
('zh', '中文', 'Chinese', 'chinese', 1, 0, 1000),
('zh-Hans', '简体中文', 'Simplified Chinese', 'chinese-simplified', 1, 0, 1000),
('zh-Hans-HK', '简体中文', 'Simplified Chinese', 'chinese-simplified-hongkongsarchina', 1, 0, 1000),
('zh-Hans-MO', '简体中文', 'Simplified Chinese', 'chinese-simplified-macausarchina', 1, 0, 1000),
('zh-Hans-SG', '简体中文', 'Simplified Chinese', 'chinese-simplified-singapore', 1, 0, 1000),
('zh-Hant', '繁體中文', 'Traditional Chinese', 'chinese-traditional', 1, 0, 1000),
('zh-Hant-HK', '繁體中文', 'Traditional Chinese', 'chinese-traditional-hongkongsarchina', 1, 0, 1000),
('zh-Hant-MO', '繁體中文', 'Traditional Chinese', 'chinese-traditional-macausarchina', 1, 0, 1000),
('zu', 'isiZulu', 'Zulu', 'zulu', 1, 0, 1000);
SQL
    ok "Filas del catálogo cargadas."
  fi

  # 5.3 ENSANCHE. EL ALTER SE ARMA DESDE information_schema PARA CONSERVAR
  # COLACIÓN, NULL, DEFAULT Y COMENTARIO DE CADA COLUMNA (UN MODIFY SIN
  # COMMENT BORRA EL COMENTARIO). AGRANDAR UN VARCHAR NO TOCA LOS DATOS
  if [ "$ANGOSTAS" != "0" ]; then
    # -r (raw): SIN ÉL, EL MODO -B DUPLICA LAS BARRAS QUE QUOTE() PONE EN UN
    # COMENTARIO CON APÓSTROFO Y EL ALTER SALE MAL FORMADO
    SENTENCIAS="$(mysql_adm -N -B -r -e "SELECT CONCAT('ALTER TABLE \`', TABLE_NAME, '\` MODIFY \`', COLUMN_NAME, '\` VARCHAR(${ANCHO}) COLLATE ', COLLATION_NAME, IF(IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'), IF(COLUMN_DEFAULT IS NULL, '', CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT))), IF(COLUMN_COMMENT = '', '', CONCAT(' COMMENT ', QUOTE(COLUMN_COMMENT))), ';') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND DATA_TYPE='varchar' AND CHARACTER_MAXIMUM_LENGTH < ${ANCHO} AND (${COND_COLUMNAS}) ORDER BY TABLE_NAME, ORDINAL_POSITION;")"
    echo "$SENTENCIAS" | mysql_adm "$DB"
    ok "Columnas de idioma ensanchadas a VARCHAR(${ANCHO})."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0
  [ "$(existe_tabla)" = "1" ]   || { error "Falta la tabla idiomas."; FALLAS=1; }
  [ "$(columnas_tabla)" = "8" ] || { error "La tabla idiomas no tiene 8 columnas."; FALLAS=1; }
  [ "$(filas_tabla)" -ge "${FILAS_CATALOGO}" ] || { error "Faltan filas del catálogo."; FALLAS=1; }
  [ "$(columnas_angostas)" = "0" ] || { error "Quedaron columnas de idioma sin ensanchar."; FALLAS=1; }
  # EL DEFAULT 'es' DE libros_md.idioma_principal TIENE QUE SOBREVIVIR AL MODIFY
  DEF_LIBRO="$(valor "SELECT IFNULL(COLUMN_DEFAULT, '') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND COLUMN_NAME='idioma_principal';")"
  [ "$DEF_LIBRO" = "es" ] || { error "libros_md.idioma_principal perdió su DEFAULT 'es' (quedó: '${DEF_LIBRO}')."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    error "Para volver atrás: sudo mysql ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: tabla con 8 columnas, $(filas_tabla) idiomas, columnas a VARCHAR(${ANCHO})."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# CÓDIGO EXACTO (BINARIO): LOS COMBOS SON ReadOnly Y UN VALOR QUE NO COINCIDE
# LETRA POR LETRA CON UNO DE LA LISTA SE PIERDE AL ABRIR EL FORMULARIO.
# LOS CAMPOS DE VARIOS IDIOMAS SE PARTEN POR COMA. LOS CAST LLEVAN COLLATE
# EXPLÍCITO: SIN ÉL TOMAN LA COLACIÓN DE LA CONEXIÓN Y EL UNION FALLA
echo
info "Informe de control: valores de idioma fuera del catálogo o inactivos"
mysql_adm "$DB" -t <<'SQL'
WITH RECURSIVE
simples AS (
  SELECT 'articulos' AS tabla, id_articulo AS id, 'idioma_principal' AS campo, idioma_principal AS valor FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_titulo_traducido', idioma_titulo_traducido FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_resumen_1', idioma_resumen_1 FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_resumen_2', idioma_resumen_2 FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_resumen_3', idioma_resumen_3 FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_kwd_1', idioma_kwd_1 FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_kwd_2', idioma_kwd_2 FROM articulos
  UNION ALL SELECT 'articulos', id_articulo, 'idioma_kwd_3', idioma_kwd_3 FROM articulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_capitulo', idioma_capitulo FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_titulo_traducido', idioma_titulo_traducido FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_resumen_1', idioma_resumen_1 FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_resumen_2', idioma_resumen_2 FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_resumen_3', idioma_resumen_3 FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_kwd_1', idioma_kwd_1 FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_kwd_2', idioma_kwd_2 FROM capitulos
  UNION ALL SELECT 'capitulos', id_capitulo, 'idioma_kwd_3', idioma_kwd_3 FROM capitulos
  UNION ALL SELECT 'libros_md', id_libro, 'idioma_principal', idioma_principal FROM libros_md
  UNION ALL SELECT 'libros_md', id_libro, 'idioma_titulo_original', idioma_titulo_original FROM libros_md
  UNION ALL SELECT 'libros_md', id_libro, 'idioma_resumen_traducido', idioma_resumen_traducido FROM libros_md
),
listas AS (
  SELECT 'articulos' AS tabla, id_articulo AS id, 'idiomas_adicionales' AS campo, CAST(idiomas_adicionales AS CHAR(2000)) COLLATE utf8mb4_unicode_ci AS lista FROM articulos
  UNION ALL SELECT 'libros_md', id_libro, 'idiomas_publicacion', idiomas_publicacion FROM libros_md
  UNION ALL SELECT 'revistas_md', id_revista, 'idiomas_publicacion', idiomas_publicacion FROM revistas_md
),
partes AS (
  SELECT tabla, id, campo, lista,
         CAST(TRIM(SUBSTRING_INDEX(lista, ',', 1)) AS CHAR(2000)) COLLATE utf8mb4_unicode_ci AS valor,
         CAST(IF(LOCATE(',', lista) > 0, SUBSTRING(lista, LOCATE(',', lista) + 1), NULL) AS CHAR(2000)) COLLATE utf8mb4_unicode_ci AS resto
  FROM listas WHERE COALESCE(TRIM(lista), '') <> ''
  UNION ALL
  SELECT tabla, id, campo, lista,
         TRIM(SUBSTRING_INDEX(resto, ',', 1)),
         IF(LOCATE(',', resto) > 0, SUBSTRING(resto, LOCATE(',', resto) + 1), NULL)
  FROM partes WHERE resto IS NOT NULL
),
todos AS (
  SELECT tabla, id, campo, valor, NULL AS lista FROM simples WHERE COALESCE(TRIM(valor), '') <> ''
  UNION ALL
  SELECT tabla, id, campo, valor, lista FROM partes WHERE valor <> ''
)
SELECT t.tabla, t.id, t.campo, LEFT(t.valor, 30) AS valor, LEFT(t.lista, 40) AS lista_completa,
  CASE
    WHEN i.codigo IS NULL THEN 'fuera del catálogo'
    ELSE 'inactivo: activarlo o el combo lo pierde'
  END AS motivo
FROM todos t
LEFT JOIN idiomas i ON CAST(i.codigo AS BINARY) = CAST(TRIM(t.valor) AS BINARY)
WHERE i.codigo IS NULL OR (i.activo = 0 AND t.lista IS NULL)
ORDER BY t.tabla, t.id, t.campo;
SQL
echo "Si la tabla no aparece, no hay discordancias. El informe no modifica nada:"
echo "los campos de un idioma se corrigen desde el formulario (o con UPDATE),"
echo "los de varios idiomas llevan códigos separados por coma (es, en, pt)."
echo
ok "${NEGRITA}Actualización 1.3.0 lista.${RESET}"
