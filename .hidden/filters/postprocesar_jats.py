#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Postproceso de archivos JATS XML
Aplica transformaciones de marcas LaTeX a JATS y corrige à corrupta
"""

import sys
import re

def reconstruir_a_grave(contenido):
    """
    Reconstruye 'à' (a con acento grave) corrupta

    Problema: byte 0xC3 (parte de à = 0xC3 0xA0) perdió su segundo byte
    Contexto: P\xC3 mpols → Pàmpols
    """

    # Convertir a bytes para trabajar a nivel binario
    contenido_bytes = bytearray(contenido.encode('utf-8', errors='surrogateescape'))

    i = 0
    while i < len(contenido_bytes):
        # Buscar byte 0xC3 seguido de espacio (0x20)
        if i + 1 < len(contenido_bytes):
            if contenido_bytes[i] == 0xC3 and contenido_bytes[i + 1] == 0x20:
                # Reemplazar 0xC3 0x20 por 0xC3 0xA0 (à)
                contenido_bytes[i + 1] = 0xA0
                print(f"✓ Carácter à reconstruido en posición {i}")
                i += 2
                continue
        i += 1

    return contenido_bytes.decode('utf-8', errors='replace')

def limpiar_bytes_utf8_huerfanos(contenido):
    """
    Limpia cualquier byte 0xC3 huérfano que no se pudo reconstruir
    """
    contenido_bytes = contenido.encode('utf-8', errors='surrogateescape')
    resultado = bytearray()

    i = 0
    while i < len(contenido_bytes):
        byte_actual = contenido_bytes[i]

        if byte_actual == 0xC3:
            if i + 1 < len(contenido_bytes):
                byte_siguiente = contenido_bytes[i + 1]

                # Verificar si es una secuencia UTF-8 válida
                if 0x80 <= byte_siguiente <= 0xBF:
                    # Secuencia válida, mantener
                    resultado.append(byte_actual)
                    resultado.append(byte_siguiente)
                    i += 2
                    continue
                else:
                    # Byte 0xC3 corrupto, eliminar
                    print(f"⚠ Byte corrupto 0xC3 eliminado (seguido de 0x{byte_siguiente:02X})")
                    i += 1
                    continue
            else:
                print(f"⚠ Byte corrupto 0xC3 eliminado (final de archivo)")
                i += 1
                continue
        else:
            resultado.append(byte_actual)
            i += 1

    return resultado.decode('utf-8', errors='replace')

def aplicar_transformaciones(contenido):
    """Aplica todas las transformaciones al contenido XML"""

    # ====================================================
    # 1. RECONSTRUIR à CORRUPTA (PRIMERO)
    # ====================================================
    contenido = reconstruir_a_grave(contenido)

    # ====================================================
    # 2. LIMPIAR BYTES UTF-8 HUÉRFANOS RESTANTES
    # ====================================================
    contenido = limpiar_bytes_utf8_huerfanos(contenido)

    # ====================================================
    # 3. MARCAS LATEX → JATS (FORMATO DE TEXTO)
    # ====================================================

    # \enquote{texto} → "texto"
    contenido = re.sub(r'\\enquote\{([^{}]+)\}', r'"\1"', contenido)

    # \emph{texto} → <italic>texto</italic>
    contenido = re.sub(r'\\emph\{([^{}]+)\}', r'<italic>\1</italic>', contenido)

    # \textit{texto} → <italic>texto</italic>
    contenido = re.sub(r'\\textit\{([^{}]+)\}', r'<italic>\1</italic>', contenido)

    # \textbf{texto} → <bold>texto</bold>
    contenido = re.sub(r'\\textbf\{([^{}]+)\}', r'<bold>\1</bold>', contenido)

    # ====================================================
    # 4. CARACTERES ESPECIALES LATEX
    # ====================================================

    # \& → &amp; (ampersand escapado en XML)
    contenido = re.sub(r'\\&', '&amp;', contenido)

    # ====================================================
    # 5. PUNTOS SUSPENSIVOS Y ESPACIOS ESPECIALES
    # ====================================================

    # \dots \ → ... (tres puntos + espacio)
    contenido = re.sub(r'\\dots\s*\\\s*', '... ', contenido)

    # \dots sin espacio → ...
    contenido = re.sub(r'\\dots', '...', contenido)

    # ~ → espacio (espacio no rompible en LaTeX)
    contenido = re.sub(r'~', ' ', contenido)

    # ====================================================
    # 6. COMILLAS TIPOGRÁFICAS LATEX
    # ====================================================

    # `` → " (comillas de apertura)
    contenido = re.sub(r'``', '"', contenido)

    # '' → " (comillas de cierre)
    contenido = re.sub(r"''", '"', contenido)

    # ====================================================
    # 7. GUIONES ESPECIALES LATEX
    # ====================================================

    # --- → — (em-dash)
    contenido = re.sub(r'---', '—', contenido)

    # -- → – (en-dash)
    contenido = re.sub(r'--', '–', contenido)

    return contenido

def main():
    if len(sys.argv) != 2:
        print("Uso: postprocesar_jats.py <archivo.xml>", file=sys.stderr)
        sys.exit(1)

    archivo = sys.argv[1]

    try:
        # Leer archivo en modo binario
        with open(archivo, 'rb') as f:
            contenido_bytes = f.read()

        # Decodificar con manejo de errores
        contenido = contenido_bytes.decode('utf-8', errors='surrogateescape')

        # Aplicar transformaciones
        contenido_procesado = aplicar_transformaciones(contenido)

        # Guardar archivo
        with open(archivo, 'w', encoding='utf-8') as f:
            f.write(contenido_procesado)

        print(f"✓ Postproceso completado: {archivo}")
        sys.exit(0)

    except Exception as e:
        print(f"✗ Error en postproceso: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
