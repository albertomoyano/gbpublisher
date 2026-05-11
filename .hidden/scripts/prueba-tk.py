# Script de prueba
import tkinter as tk
from tkinter import messagebox
# Crear ventana raíz y ocultarla
root = tk.Tk()
root.withdraw()
# Mostrar mensaje de prueba
messagebox.showinfo("Script de prueba", "Este es un script de prueba")
# Cerrar ventana raíz al finalizar
root.destroy()
