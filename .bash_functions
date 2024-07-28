#! /bin/bash
# shellcheck disable=SC1091
source /etc/environment

if [[ -z "$DOMAIN" ]]; then
  domain="127.0.0.1"
  is_domain=false
  port="80"
else
  domain="$DOMAIN"
  is_domain=true
  port="8000"
fi

if [[ -z "$APP_NAME" ]]; then
  app_name="POA"
else
  app_name=$APP_NAME
fi

app_dir="/root/$app_name"
interpreter_path="/root/POA/.venv/bin/python3.10"

print_env() {
  echo "domain: $domain"
  echo "port: $port"
  echo "app_name: $app_name"
}
caddy_start() {
  caddy start --config /etc/caddy/Caddyfile
}

caddy_run() {
  caddy run --config /etc/caddy/Caddyfile
}

caddy_stop() {
  caddy stop
}

flush() {
  pm2 flush
}

monitor() {
  pm2 logs
}

list() {
  pm2 list
}

quit() {
  if [[ $is_domain == true ]]; then
    caddy_stop
  fi

  pm2 delete "$app_name"
}

activate() {
  source "$app_dir/.venv/bin/activate"
}

pm2_start() {
  pm2 start "$1" --interpreter "$interpreter_path"
}

start() {
  quit
  if [[ $is_domain == true ]]; then
    caddy_start
  fi

  flush
  pm2 start "$app_dir/run.py" --name "$app_name" --interpreter "$interpreter_path" -- --port="$port"
}

download_poa() {
  git clone https://github.com/sinsadongjin/JINGU "$app_dir"
}

download_pocketbase() {
  n=0; while [ $n -lt 5 ] && ! wget "https://github.com/pocketbase/pocketbase/releases/download/v0.16.6/pocketbase_0.16.6_linux_amd64.zip" -O /root/pocketbase.zip || ! unzip -j /root/pocketbase.zip pocketbase -d /root/db; do echo "명령어 실행에 실패했습니다. 5초 후 재시도합니다..."; sleep 5; n=$((n+1)); done
  rm -rf /root/pocketbase.zip
}

download() {
  git clone https://github.com/sinsadongjin/JINGU "$app_dir"
}

remove() {
  cd /root
  quit
  rm -rf "$app_dir"
}

install() {
  download
  python3.10 -m venv "$app_dir/.venv"
  $interpreter_path -m pip install -r "$app_dir"/requirements.txt
}

reinstall() {
  cp -f "$app_dir"/.env /root
  cp -f "$app_dir"/store.db /root
  remove
  install
  cp -f "/root/.env" "$app_dir/.env"
  cp -f "/root/store.db" "$app_dir/store.db"
  rm -rf "/root/.env"
  rm -rf "/root/store.db"
}

update() {
  quit
  cd "$app_dir"
  git pull --rebase
  cd /root
  start
}

print_env

export -f print_env
export -f caddy_start
export -f caddy_run
export -f caddy_stop
export -f flush
export -f monitor
export -f list
export -f quit
export -f activate
export -f pm2_start
export -f start
export -f download_poa
export -f download_pocketbase
export -f download
export -f remove
export -f install
export -f reinstall
export -f update
