#!/bin/bash

# ╔══════════════════════════════════════════════════════════╗
# ║            🔥 FIREWALLD - APERTURA DE PUERTOS TCP/UDP              ║
# ║            👾 Autor: ChristopherAGT - Guatemalteco 🇬🇹              ║
# ╚══════════════════════════════════════════════════════════╝

# 🛑 Requiere permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo -e "\n\033[1;31m🚫 Este script debe ejecutarse como root o con sudo.\033[0m"
  exit 1
fi

# 🎨 Colores
verde="\033[1;32m"
rojo="\033[1;31m"
azul="\033[1;34m"
amarillo="\033[1;33m"
neutro="\033[0m"

# 🔄 Spinner animado
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  tput civis
  while ps -p $pid &>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  tput cnorm
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${azul}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄  ACTUALIZANDO LISTA DE PAQUETES DEL SISTEMA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

apt-get update -y &> /dev/null &
spinner $!
echo -e "${verde}✔ Lista de paquetes actualizada.${neutro}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${azul}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦  VERIFICANDO INSTALACIÓN DE FIREWALLD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

if ! command -v firewall-cmd &> /dev/null; then
  echo -e "${amarillo}📦 firewalld no está instalado. Instalando...${neutro}"
  apt-get install -y firewalld &> /dev/null &
  spinner $!
  if ! command -v firewall-cmd &> /dev/null; then
    echo -e "${rojo}❌ La instalación de firewalld falló. Abortando.${neutro}"
    exit 1
  fi
  echo -e "${verde}✔ firewalld instalado correctamente.${neutro}"
else
  echo -e "${verde}✔ firewalld ya está instalado.${neutro}"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${azul}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀  INICIANDO Y HABILITANDO FIREWALLD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

systemctl enable firewalld &> /dev/null
systemctl start firewalld

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${amarillo}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  ¡ATENCIÓN! APERTURA TOTAL DE PUERTOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"
echo -e "🔐 Estás a punto de abrir *TODOS* los puertos TCP y UDP (1-65535).\n"
while true; do
  read -p "¿Deseas continuar? [s/n]: " confirm
  case "$confirm" in
    [sS]) break ;;  # Continua el script
    [nN]|"") echo -e "${rojo}❌ Operación cancelada por el usuario.${neutro}"; exit 1 ;;
    *) echo -e "${amarillo}⚠️ Respuesta no válida. Ingresa 's' para sí o 'n' para no.${neutro}" ;;
  esac
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${azul}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍  VERIFICANDO PUERTOS ACTUALMENTE ABIERTOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

if firewall-cmd --zone=public --list-ports | grep -q "1-65535/tcp"; then
  echo -e "${amarillo}⚠️ Los puertos TCP ya están abiertos.${neutro}"
else
  echo -e "${amarillo}🔓 Abriendo puertos TCP...${neutro}"
  firewall-cmd --zone=public --permanent --add-port=1-65535/tcp
fi

if firewall-cmd --zone=public --list-ports | grep -q "1-65535/udp"; then
  echo -e "${amarillo}⚠️ Los puertos UDP ya están abiertos.${neutro}"
else
  echo -e "${amarillo}🔓 Abriendo puertos UDP...${neutro}"
  firewall-cmd --zone=public --permanent --add-port=1-65535/udp
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${azul}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "♻️  REINICIANDO CONFIGURACIÓN FIREWALLD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

firewall-cmd --reload

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${verde}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋  PUERTOS ABIERTOS EN ZONA 'public'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

firewall-cmd --zone=public --list-ports

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${verde}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅  CONFIGURACIÓN COMPLETADA CON ÉXITO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${amarillo}⚠️ Recuerda: abrir todos los puertos es riesgoso. Úsalo sólo en entornos seguros.${neutro}\n"
