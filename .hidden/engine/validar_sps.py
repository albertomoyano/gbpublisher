#!/usr/bin/env python3
# ==============================================================================
# SCRIPT    : validar_sps.py
# PROPÓSITO : VALIDA XML SciELO PS (sps-1.9) CON packtools 4.18.2 SIN RED.
# POR QUÉ   : stylechecker --nonetwork FALLA CON lxml >= 6.1 SOBRE CUALQUIER
#             DOCUMENTO, INCLUIDOS LOS DE EJEMPLO DE SciELO («Entity
#             'journalpubcustom-modules.ent' not defined»): EL PARSER DE
#             packtools NO RESUELVE LAS ENTIDADES PARAMÉTRICAS DEL DTD.
#             VERIFICADO EL 18/11/2026: CON resolve_entities=True EL MISMO
#             DOCUMENTO SE LEE Y packtools VALIDA DTD Y ESTILO SPS.
#             ESTE SCRIPT HACE ESO Y NADA MÁS: LAS REGLAS SON LAS DE packtools.
# USO       : validar_sps.py ARCHIVO.xml [...]
#             TAMBIÉN, CON LAS FUNCIONES DE packtools: QUE EL ARCHIVO SE LLAME
#             COMO packtools ARMA EL NOMBRE DEL PAQUETE (SPS_Package.
#             package_name) Y QUE LOS ARCHIVOS QUE NOMBRA EL XML ESTÉN EN SU
#             CARPETA (lookup_assets).
# SALIDA    : UNA LÍNEA TSV POR HALLAZGO:
#               archivo TAB tipo TAB linea TAB mensaje
#             tipo: dtd | sps (errores), nombre_ok | nombre (el nombre),
#             activo_ok | activo (un archivo nombrado), ok (válido),
#             error (no se pudo validar)
# RETORNA   : 0 SI TODOS SON VÁLIDOS; 1 SI ALGUNO NO; 2 SI FALTA packtools
# ==============================================================================
import os
import sys

try:
    import packtools
    from packtools import catalogs, stylechecker
    from packtools.sps.models.sps_package import SPS_Package
    from lxml import etree
except ImportError as e:
    print("-\terror\t0\tpacktools no disponible: %s" % e)
    sys.exit(2)

# --- 1. EL CATÁLOGO DE packtools: LOS DTD SALEN DEL PAQUETE, NO DE LA RED ---
os.environ["XML_CATALOG_FILES"] = catalogs.XML_CATALOG

# --- 2. EL PARSER: resolve_entities=True ES LA CORRECCIÓN ---
parser = etree.XMLParser(remove_blank_text=True, load_dtd=True,
                         no_network=True, resolve_entities=True)


def limpio(s):
    # UNA LÍNEA TSV NO ADMITE TABULADORES NI SALTOS EN EL MENSAJE
    return " ".join(str(s).split())


hay_error = False
for ruta in sys.argv[1:]:
    nombre = os.path.basename(ruta)
    # --- 3. LECTURA Y VALIDACIÓN, UN ARCHIVO POR VEZ ---
    try:
        arbol = etree.parse(ruta, parser)
        validador = packtools.XMLValidator.parse(arbol)
        # assets_basedir ES UN CONTENEDOR («asset in base», domain.py,
        # lookup_assets), NO UNA RUTA: CON UNA CADENA HARÍA UNA BÚSQUEDA DE
        # SUBCADENA. VA LA LISTA DE ARCHIVOS DE LA CARPETA, COMO stylechecker
        carpeta = os.listdir(os.path.dirname(os.path.abspath(ruta)))
        resumen = stylechecker.summarize(validador, assets_basedir=carpeta)
    except Exception as e:
        print("%s\terror\t0\t%s" % (nombre, limpio(e)))
        hay_error = True
        continue

    # --- 4. LOS HALLAZGOS ---
    for e in resumen.get("dtd_errors", []):
        print("%s\tdtd\t%s\t%s" % (nombre, e.get("apparent_line") or 0, limpio(e.get("message"))))
    for grupo, errores in resumen.get("style_errors", {}).items():
        for e in errores:
            print("%s\tsps\t%s\t%s" % (nombre, e.get("apparent_line") or 0, limpio(e.get("message"))))
    # --- 5. EL NOMBRE: EL QUE ARMA packtools CON ISSN, ACRÓNIMO, VOLUMEN,
    # NÚMERO Y PÁGINA (O e-location); SciELO IDENTIFICA EL PAQUETE POR ÉL ---
    try:
        esperado = SPS_Package(os.path.abspath(ruta)).package_name
    except Exception as e:
        esperado = "(no se pudo calcular: %s)" % limpio(e)
    actual = os.path.splitext(nombre)[0]
    if esperado == actual:
        print("%s\tnombre_ok\t0\t%s" % (nombre, esperado))
    else:
        print("%s\tnombre\t0\t%s" % (nombre, esperado))
        hay_error = True

    # --- 6. LOS ARCHIVOS QUE NOMBRA (IMÁGENES, SUPLEMENTOS) ---
    for activo, presente in resumen.get("assets", []):
        print("%s\t%s\t0\t%s" % (nombre, "activo_ok" if presente else "activo", activo))
        if not presente:
            hay_error = True

    if resumen.get("is_valid"):
        print("%s\tok\t0\tválido" % nombre)
    else:
        hay_error = True

sys.exit(1 if hay_error else 0)
