import os
import sys
import re
from pathlib import Path

def buscar_frase_en_archivos(directorio_base, frase):
    coincidencia_encontrada = False

    # Crear un patrón para buscar la frase completa
    patron = re.compile(re.escape(frase), re.IGNORECASE)  # Búsqueda insensible a mayúsculas

    # Construir la ruta a la carpeta articulos
    carpeta_articulos = Path(directorio_base) / "articulos"

    # Verificar que la carpeta articulos existe
    if not carpeta_articulos.exists():
        print(f"Error: No se encontró la carpeta 'articulos' en {directorio_base}")
        return

    if not carpeta_articulos.is_dir():
        print(f"Error: 'articulos' no es un directorio válido")
        return

    print(f"🔍 Buscando '{frase}' en archivos .md de la carpeta articulos...")
    print()

    # Buscar recursivamente archivos .md en la carpeta articulos
    archivos_md = list(carpeta_articulos.rglob("*.md"))

    if not archivos_md:
        print("No se encontraron archivos .md en la carpeta articulos")
        return

    print(f"Analizando {len(archivos_md)} archivo(s) .md...")
    print()

    for archivo_path in archivos_md:
        try:
            with open(archivo_path, 'r', encoding='utf-8') as f:
                for num_linea, linea in enumerate(f, 1):
                    if patron.search(linea):
                        # Mostrar ruta relativa desde la carpeta del proyecto
                        ruta_relativa = archivo_path.relative_to(directorio_base)
                        print(f"Encontrada en: {ruta_relativa}, línea {num_linea}")
                        print(f"   Contexto: {linea.strip()}")
                        print()
                        coincidencia_encontrada = True
        except Exception as e:
            ruta_relativa = archivo_path.relative_to(directorio_base)
            print(f"No se pudo leer el archivo {ruta_relativa}: {e}")

    if not coincidencia_encontrada:
        print(f"No se encontraron coincidencias para '{frase}' en los archivos .md")
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
