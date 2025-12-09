while inotifywait -e create /dev/pts; do
    sh ~/.cache/update_terminals.sh
done
