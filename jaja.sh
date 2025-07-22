#!/bin/bash

# ╔════════════════════════════════════════════════════════════════════╗
# ║       🚀 ZIVPN UDP MODULE INSTALLER                                            ║
# ║       👤 Autor: Zahid Islam                                                    ║
# ║       👤 Remasterización: ChristopherAGT                                       ║
# ║       🛠️ Instala y configura el servicio UDP de ZIVPN                          ║
# ╚════════════════════════════════════════════════════════════════════╝

# Colores para presentación
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
MAGENTA="\033[1;35m"
RESET="\033[0m"

# Función para imprimir sección con borde
print_section() {
  local title="$1"
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${MAGENTA}║  $title${RESET}$(printf ' %.0s' {1..$(($(tput cols)-${#title}-4))})${MAGENTA}║${RESET}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${RESET}"
}

# Función para mostrar spinner y manejar errores
run_with_spinner() {
  local msg="$1"
  local cmd="$2"

  echo -ne "${CYAN}${msg}...${RESET}"
  bash -c "$cmd" &>/tmp/zivpn_spinner.log &
  local pid=$!

  local delay=0.1
  local spinstr='|/-\'
  while kill -0 $pid 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  wait $pid
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo -e " ${GREEN}✔️${RESET}"
  else
    echo -e " ${RED}❌ Error${RESET}"
    echo -e "${RED}🛑 Ocurrió un error al ejecutar:${RESET} ${YELLOW}$msg${RESET}"
    echo -e "${RED}📄 Detalles del error:${RESET}"
    cat /tmp/zivpn_spinner.log
    exit 1
  fi
  rm -f /tmp/zivpn_spinner.log
}

# ╔════════════════════════════════════════════════════════════════╗
print_section "🔍 VERIFICANDO INSTALACIÓN PREVIA DE ZIVPN UDP"
if [ -f /usr/local/bin/zivpn ] || [ -f /etc/systemd/system/zivpn.service ]; then
  echo -e "${YELLOW}⚠️  ZIVPN UDP parece estar ya instalado en este sistema.${RESET}"
  echo -e "${YELLOW}Por seguridad, la instalación se detendrá para evitar sobrescribir.${RESET}"
  exit 1
fi

# ╔════════════════════════════════════════════════════════════════╗
print_section "📦 ACTUALIZANDO EL SISTEMA"
run_with_spinner "🔄 Actualizando paquetes del sistema" "sudo apt-get update && sudo apt-get upgrade -y"

# ╔════════════════════════════════════════════════════════════════╗
print_section "⬇️ DESCARGANDO ZIVPN UDP"
echo -e "${CYAN}📥 Descargando binario de ZIVPN...${RESET}"
systemctl stop zivpn.service &>/dev/null
wget -q https://github.com/ChristopherAGT/zivpn-tunnel-udp/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn

echo -e "${CYAN}📁 Preparando configuración...${RESET}"
mkdir -p /etc/zivpn
wget -q https://raw.githubusercontent.com/ChristopherAGT/zivpn-tunnel-udp/main/config.json -O /etc/zivpn/config.json

# ╔════════════════════════════════════════════════════════════════╗
print_section "🔐 GENERANDO CERTIFICADOS SSL"
run_with_spinner "🔐 Generando certificados SSL" "openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj '/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn' -keyout /etc/zivpn/zivpn.key -out /etc/zivpn/zivpn.crt"

# ╔════════════════════════════════════════════════════════════════╗
print_section "⚙️ OPTIMIZANDO PARÁMETROS DEL SISTEMA"
sysctl -w net.core.rmem_max=16777216 &>/dev/null
sysctl -w net.core.wmem_max=16777216 &>/dev/null

# ╔════════════════════════════════════════════════════════════════╗
print_section "🧩 CREANDO SERVICIO SYSTEMD"
if [ -f /etc/systemd/system/zivpn.service ]; then
    echo -e "${YELLOW}⚠️ El servicio ZIVPN ya existe. Se omitirá su creación.${RESET}"
else
    echo -e "${CYAN}🔧 Configurando servicio systemd...${RESET}"
    cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
fi

# ╔════════════════════════════════════════════════════════════════╗
: '
# ╔════════════════════════════════════════════════════════════════╗
# print_section "🔑 CONFIGURANDO CONTRASEÑAS"
# echo -e "${YELLOW}🔑 Ingresa las contraseñas separadas por comas (Ej: pass1,pass2)"
# read -p "🔐 Contraseñas (por defecto: zivpn): " input_config

# if [ -n "$input_config" ]; then
#     IFS=',' read -r -a config <<< "$input_config"
#     [ ${#config[@]} -eq 1 ] && config+=("${config[0]}")
# else
#     config=("zivpn")
# fi

# new_config_str="\"config\": [$(printf "\"%s\"," "${config[@]}" | sed 's/,$//')]"
# sed -i -E "s/\"config\": ?.*/${new_config_str}/g" /etc/zivpn/config.json
'

# ╔════════════════════════════════════════════════════════════════╗
print_section "🚀 INICIANDO Y HABILITANDO SERVICIO"
systemctl enable zivpn.service
systemctl start zivpn.service

# ╔════════════════════════════════════════════════════════════════╗
print_section "🌐 CONFIGURANDO IPTABLES Y FIREWALL"
iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
if ! iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 &>/dev/null; then
    iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
else
    echo -e "${YELLOW}⚠️ La regla iptables ya existe. Se omite agregarla nuevamente.${RESET}"
fi

ufw allow 6000:19999/udp
ufw allow 5667/udp

# ╔════════════════════════════════════════════════════════════════╗
print_section "⬇️ INSTALANDO PANEL DE GESTIÓN"
run_with_spinner "⬇️ Descargando panel de gestión (menu-zivpn)" "wget -q https://raw.githubusercontent.com/ChristopherAGT/zivpn-tunnel-udp/main/panel-udp-zivpn.sh -O /usr/local/bin/menu-zivpn && chmod +x /usr/local/bin/menu-zivpn"

# ╔════════════════════════════════════════════════════════════════╗
print_section "✅ FINALIZADO"
rm -f install-amd.sh install-amd.tmp install-amd.log &>/dev/null
echo -e "${GREEN}✅ ZIVPN UDP instalado correctamente.${RESET}"
echo -e "${GREEN}🔰 Usa el comando ${CYAN}menu-zivpn${GREEN} para abrir el panel de gestión.${RESET}"
