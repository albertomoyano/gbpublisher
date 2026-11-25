#!/bin/bash
# El esquema de Crossref, compartido por revistas y libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Lo cargan con source revista_comun.sh (y por él generar_crossref_revista.sh
# y validar_sabor.sh) y generar_crossref_libro.sh, después de comun.sh. Estaba
# en revista_comun.sh; se mudó el 25/11/2026 para que el depósito del libro
# valide con el mismo esquema sin cargar las funciones del número
# (claude/crossref-libros.md, F2).
# ============================================================================

# EL ESQUEMA ES DEL PAQUETE, NO DE ~/.gbpublisher: UN «VÁLIDO» SOLO SE
# SOSTIENE CON EL ESQUEMA DEL SISTEMA (SC-11). LA CARPETA DE RECURSOS ES LA
# DE ESTE ARCHIVO, UN NIVEL ARRIBA: .hidden/ DESDE EL IDE,
# /usr/share/gbpublisher/ INSTALADO
DIR_RECURSOS_CROSSREF="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
# CROSSREF 5.4.0 (DECISIÓN DE ALBERTO, 18/11: LA 5.5.0 ES XSD 1.1 Y xmllint
# NO LA COMPILA, MEDIDO). SUS MÓDULOS IMPORTAN ESQUEMAS DE LA W3C POR URL
# (EL CATÁLOGO LOS RESUELVE) Y EL JATS 1.3 QUE TRAE PIDE standard-modules/
DIR_ESQUEMA_CROSSREF="$DIR_RECURSOS_CROSSREF/schemas/crossref"
XSD_CROSSREF="$DIR_ESQUEMA_CROSSREF/crossref5.4.0.xsd"
CATALOGO_CROSSREF="$DIR_ESQUEMA_CROSSREF/catalogo-crossref.xml"

# ============================================================================
# Función   : esquema_crossref_presente
# Propósito : Si están el esquema 5.4.0 de Crossref, su catálogo y los
#             módulos que importa por ruta relativa.
# Retorna   : 0 si están; 1 si falta algo
# ============================================================================
esquema_crossref_presente() {
    local f
    for f in "$XSD_CROSSREF" "$CATALOGO_CROSSREF" \
             "$DIR_ESQUEMA_CROSSREF/common5.4.0.xsd" \
             "$DIR_ESQUEMA_CROSSREF/standard-modules/xlink.xsd"; do
        [[ -f "$f" ]] || return 1
    done
    return 0
}

# ============================================================================
# Función   : validar_crossref
# Propósito : Valida un depósito contra crossref5.4.0.xsd, sin red.
# Parámetros: $1 ruta del archivo
# Retorna   : imprime los errores, una línea cada uno, sin la ruta del
#             archivo; nada si es válido
# Nota      : xmllint AVISA AL COMPILAR EL ESQUEMA QUE SALTEA IMPORTACIONES
#             REPETIDAS (EL MISMO ESPACIO DE NOMBRES POR DOS CAMINOS) Y QUE
#             LOS ESQUEMAS DECLARAN XML 1.1: SON DEL ESQUEMA DE CROSSREF, NO
#             DEL DEPÓSITO. SOLO SE CONSERVAN LOS ERRORES
# ============================================================================
validar_crossref() {
    local archivo="$1"
    XML_CATALOG_FILES="$CATALOGO_CROSSREF" xmllint --nonet --noout --schema "$XSD_CROSSREF" "$archivo" 2>&1 |
        grep -E 'error|failed to compile' |
        sed -E "s|^$archivo:||" | grep .
}
