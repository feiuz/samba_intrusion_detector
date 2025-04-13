#!/bin/bash

# Détecteur d'intrusion Samba - Version simplifiée
LOG_DIR="/var/log/samba"
REPORT_FILE="$HOME/samba_intrusion_report.txt"
IP_BLACKLIST="$HOME/samba_ip_blacklist.txt"
SMB_CONF="/etc/samba/smb.conf"
SMB_HOSTS_DENY="/etc/samba/hosts.deny"
MAX_ATTEMPTS=5

# Vérifier les permissions
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root."
    echo "Essayez avec sudo: sudo $0"
    exit 1
fi

echo "===== Rapport de sécurité Samba $(date) =====" > $REPORT_FILE
touch $IP_BLACKLIST

# Sauvegarder la configuration Samba actuelle
cp $SMB_CONF ${SMB_CONF}.bak
echo "Configuration Samba sauvegardée dans ${SMB_CONF}.bak"

# Compter les tentatives d'authentification échouées par IP
echo "Analyse des tentatives d'authentification échouées..."
grep -r "failed" $LOG_DIR | grep -o -E "client [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | \
sort | uniq -c | sort -nr | while read count ip; do
    ip=$(echo $ip | sed 's/client //')
    echo "$count tentatives échouées depuis $ip" >> $REPORT_FILE
    
    # Si plus de MAX_ATTEMPTS tentatives, ajouter à la blacklist
    if [ $count -ge $MAX_ATTEMPTS ]; then
        echo "$ip" >> $IP_BLACKLIST
        echo "IP $ip ajoutée à la blacklist!" >> $REPORT_FILE
    fi
done

# Préparer la liste des IPs à bloquer
sort -u $IP_BLACKLIST -o $IP_BLACKLIST
BLACKLIST_STRING=$(cat $IP_BLACKLIST | tr '\n' ' ')

# Créer le fichier hosts.deny
echo "hosts deny = $BLACKLIST_STRING" > $SMB_HOSTS_DENY
echo "Fichier de liste noire créé: $SMB_HOSTS_DENY"

# Méthode simple pour modifier smb.conf
# Créer un fichier temporaire avec les modifications
TEMP_CONF=$(mktemp)

# Vérifier si [global] existe déjà
if grep -q "

$$
global
$$

" "$SMB_CONF"; then
    # Ajouter les directives après [global]
    echo "Section [global] trouvée, ajout des directives..."
    
    # Lire ligne par ligne et ajouter nos directives après [global]
    while IFS= read -r line; do
        echo "$line" >> "$TEMP_CONF"
        if [[ "$line" == "[global]" ]]; then
            echo "include = $SMB_HOSTS_DENY" >> "$TEMP_CONF"
            echo "hosts allow = 127.0.0.1/8 192.168.1.0/24" >> "$TEMP_CONF"
        fi
    done < "$SMB_CONF"
else
    # Créer la section [global]
    echo "Section [global] non trouvée, création..."
    echo "[global]" >> "$TEMP_CONF"
    echo "include = $SMB_HOSTS_DENY" >> "$TEMP_CONF"
    echo "hosts allow = 127.0.0.1/8 192.168.1.0/24" >> "$TEMP_CONF"
    
    # Ajouter le reste du fichier
    cat "$SMB_CONF" >> "$TEMP_CONF"
fi

# Remplacer le fichier original
cp "$TEMP_CONF" "$SMB_CONF"
rm "$TEMP_CONF"

echo "Configuration Samba mise à jour."
echo "===== Fin du rapport =====" >> $REPORT_FILE

# Redémarrer Samba
systemctl restart smbd nmbd
echo "Services Samba redémarrés pour appliquer les changements."

# Résumé
echo ""
echo "==== RÉSUMÉ DES ACTIONS ===="
ip_count=$(wc -l < $IP_BLACKLIST)
echo "- $ip_count IPs ont été bloquées"
echo "- Configuration Samba mise à jour: $SMB_CONF"
echo "- Liste noire enregistrée dans: $SMB_HOSTS_DENY" 
echo "- Rapport complet sauvegardé dans: $REPORT_FILE"
echo ""
echo "Pour voir le rapport complet: cat $REPORT_FILE"

# Afficher brièvement le rapport
echo ""
echo "Extrait du rapport (5 premières lignes):"
head -n 5 $REPORT_FILE
