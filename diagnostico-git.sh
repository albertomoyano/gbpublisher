#!/bin/bash
# ============================================
# Script   : diagnostico-git.sh
# Propósito: Verificar requisitos git/SSH en Linux Mint
# Uso      : chmod +x diagnostico-git.sh && ./diagnostico-git.sh
# ============================================

OK="\e[32m✔\e[0m"
FAIL="\e[31m✘\e[0m"
WARN="\e[33m⚠\e[0m"

echo ""
echo "═══════════════════════════════════════════"
echo "  DIAGNÓSTICO GIT / SSH"
echo "═══════════════════════════════════════════"
echo ""

# --- 1. Git instalado ---
echo "1) Git"
echo "   ────────────────────────────────"
if command -v git &>/dev/null; then
    version=$(git --version 2>/dev/null)
    echo -e "   $OK Instalado: $version"
    ruta=$(which git)
    echo "     Ruta: $ruta"
else
    echo -e "   $FAIL No encontrado"
    echo "     Instalar con: sudo apt install git"
fi

echo ""

# --- 2. Clave SSH ---
echo "2) Clave SSH"
echo "   ────────────────────────────────"
ssh_dir="$HOME/.ssh"
if [ -d "$ssh_dir" ]; then
    # BUSCAR CLAVES PRIVADAS (ed25519, rsa, ecdsa, dsa)
    claves=$(find "$ssh_dir" -maxdepth 1 -type f \( -name "id_*" ! -name "*.pub" \) 2>/dev/null)
    if [ -n "$claves" ]; then
        while IFS= read -r clave; do
            nombre=$(basename "$clave")
            pub="${clave}.pub"
            if [ -f "$pub" ]; then
                tipo=$(head -1 "$pub" | awk '{print $1}')
                echo -e "   $OK $nombre (${tipo})"
            else
                echo -e "   $WARN $nombre (sin .pub asociado)"
            fi
        done <<< "$claves"

        # VERIFICAR CONEXIÓN A GITHUB
        echo ""
        echo "   Probando conexión SSH a GitHub..."
        resultado=$(ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new git@github.com 2>&1)
        if echo "$resultado" | grep -q "successfully authenticated"; then
            usuario_gh=$(echo "$resultado" | grep -oP '(?<=Hi ).*(?=!)')
            echo -e "   $OK Autenticado en GitHub como: $usuario_gh"
        else
            echo -e "   $FAIL No se pudo autenticar en GitHub"
            echo "     Respuesta: $resultado"
        fi
    else
        echo -e "   $FAIL No se encontraron claves privadas en $ssh_dir"
        echo "     Generar con: ssh-keygen -t ed25519 -C \"tu@email.com\""
    fi
else
    echo -e "   $FAIL No existe el directorio $ssh_dir"
    echo "     Generar clave con: ssh-keygen -t ed25519 -C \"tu@email.com\""
fi

echo ""

# --- 3. Usuario git configurado ---
echo "3) Configuración de usuario Git"
echo "   ────────────────────────────────"
nombre=$(git config --global user.name 2>/dev/null)
email=$(git config --global user.email 2>/dev/null)

if [ -n "$nombre" ]; then
    echo -e "   $OK user.name:  $nombre"
else
    echo -e "   $FAIL user.name no configurado"
    echo "     Configurar con: git config --global user.name \"Tu Nombre\""
fi

if [ -n "$email" ]; then
    echo -e "   $OK user.email: $email"
else
    echo -e "   $FAIL user.email no configurado"
    echo "     Configurar con: git config --global user.email \"tu@email.com\""
fi

# --- 4. Protocolo del remote origin ---
echo ""
echo "4) Protocolo del remote (HTTPS vs SSH)"
echo "   ────────────────────────────────"

# DETECTAR SI ESTAMOS DENTRO DE UN REPOSITORIO GIT
if git rev-parse --is-inside-work-tree &>/dev/null; then
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        echo "   Remote actual: $remote_url"
        if echo "$remote_url" | grep -q "^https://"; then
            echo -e "   $FAIL El remote usa HTTPS (por eso pide usuario/clave)"
            # EXTRAER USUARIO Y REPO PARA ARMAR LA URL SSH CORRECTA
            usuario_repo=$(echo "$remote_url" | sed -E 's|https://github\.com/||; s|\.git$||')
            echo ""
            echo "     Corregir con:"
            echo "     git remote set-url origin git@github.com:${usuario_repo}.git"
        elif echo "$remote_url" | grep -q "^git@"; then
            echo -e "   $OK El remote usa SSH (correcto)"
        else
            echo -e "   $WARN Protocolo no reconocido: $remote_url"
        fi
    else
        echo -e "   $WARN No hay remote 'origin' configurado"
    fi
else
    echo -e "   $WARN No estás dentro de un repositorio Git"
    echo "     Ejecutá este script desde la carpeta de tu proyecto"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  FIN DEL DIAGNÓSTICO"
echo "═══════════════════════════════════════════"
echo ""
