#!/bin/bash
# Remet les bonnes permissions après une modification des fichiers
# (les edits via root réinitialisent owner:group en root:root)
# Usage : ./fix-perms.sh  (s'auto-élève en sudo si besoin)
[ "$EUID" -ne 0 ] && exec sudo "$(readlink -f "$0")" "$@"

PROJECT=/var/www/sms-gateway

echo "Application des permissions sur $PROJECT..."

chown -R gauthi3r:www-data "$PROJECT"
find "$PROJECT" -type d -exec chmod 750 {} \;
find "$PROJECT" -type f -exec chmod 640 {} \;
find "$PROJECT/venv/bin" -type f -exec chmod 750 {} \;
chmod +x "$PROJECT/fix-perms.sh"

# Fichiers écrits par le service (www-data doit pouvoir écrire)
chmod 660 "$PROJECT/router_config.json"

echo "✅ Permissions OK"
echo "   Owner    : gauthi3r:www-data"
echo "   Dossiers : 750 (rwxr-x---)"
echo "   Fichiers : 640 (rw-r-----)"
echo "   router_config.json : 660 (rw-rw----)"
