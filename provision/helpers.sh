is_installed() {
  dpkg -s "$1" &>/dev/null
}
