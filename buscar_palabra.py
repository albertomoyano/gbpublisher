import os
import sys
import re

def buscar_frase_en_archivos(directorio, frase):
    coincidencia_encontrada = False
    # Crear un patrón para buscar la frase completa
    patron = re.compile(re.escape(frase))  # Escapar cualquier carácter especial en la frase

    for root, dirs, files in os.walk(directorio):
        for file in files:
            if file.endswith(".tex"):
                ruta_archivo = os.path.join(root, file)
                try:
                    with open(ruta_archivo, 'r', encoding='utf-8') as f:
                        for num_linea, linea in enumerate(f, 1):
                            if patron.search(linea):  # Usar la búsqueda del patrón
                                print(f"Encontrada en: {ruta_archivo}, línea {num_linea}")
                                coincidencia_encontrada = True
                except Exception as e:
                    print(f"No se pudo leer el archivo {ruta_archivo}: {e}")

    if not coincidencia_encontrada:
        print("No se encontraron coincidencias para la búsqueda.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No se proporcionó ninguna frase para buscar.")
        sys.exit(1)

    frase = " ".join(sys.argv[1:])  # Combinar todos los argumentos como una frase

    directorio_actual = os.getcwd()
    buscar_frase_en_archivos(directorio_actual, frase)
