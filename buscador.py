import os
import sys
import re
from pathlib import Path

def buscar_frase_en_archivos(directorio_base, frase):
    coincidencia_encontrada = False

    # Crear patrón para búsqueda insensible a mayúsculas
    patron = re.compile(re.escape(frase), re.IGNORECASE)

    # Construir rutas de búsqueda
    carpeta_base = Path(directorio_base)
    carpeta_articulos = carpeta_base / "articulos"

    # Listar archivos a analizar (.md y .tex) en ambos lugares
    archivos_en_base = list(carpeta_base.glob("*.md")) + list(carpeta_base.glob("*.tex"))
    archivos_en_articulos = []
    if carpeta_articulos.exists() and carpeta_articulos.is_dir():
        archivos_en_articulos = list(carpeta_articulos.rglob("*.md")) + list(carpeta_articulos.rglob("*.tex"))

    # Unir ambos conjuntos
    archivos_a_analizar = archivos_en_base + archivos_en_articulos

    if not archivos_a_analizar:
        print("No se encontraron archivos .md ni .tex en la carpeta del proyecto ni en 'articulos'")
        return

    print(f"🔍 Buscando '{frase}' en archivos .md y .tex...")
    print(f"Analizando {len(archivos_a_analizar)} archivo(s)...\n")

    for archivo_path in archivos_a_analizar:
        try:
            with open(archivo_path, 'r', encoding='utf-8') as f:
                for num_linea, linea in enumerate(f, 1):
                    if patron.search(linea):
                        ruta_relativa = archivo_path.relative_to(directorio_base)
                        print(f"Encontrada en: {ruta_relativa}, línea {num_linea}")
                        print(f"   Contexto: {linea.strip()}\n")
                        coincidencia_encontrada = True
        except Exception as e:
            ruta_relativa = archivo_path.relative_to(directorio_base)
            print(f"No se pudo leer el archivo {ruta_relativa}: {e}")

    if not coincidencia_encontrada:
        print(f"No se encontraron coincidencias para '{frase}' en los archivos .md o .tex")
    else:
        print("Búsqueda completada")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: No se proporcionó ninguna frase para buscar.")
        print("Uso: python3 buscador.py <frase_a_buscar>")
        sys.exit(1)

    frase = " ".join(sys.argv[1:])  # Combinar todos los argumentos como una frase
    directorio_actual = os.getcwd()
    print(f"Directorio base: {directorio_actual}")
    buscar_frase_en_archivos(directorio_actual, frase)
