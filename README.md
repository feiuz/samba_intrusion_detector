# Détecteur d'Intrusion Samba

Ce script automatisé améliore la sécurité de votre serveur Samba en détectant et bloquant proactivement les tentatives d'intrusion. Il analyse les journaux, identifie les adresses IP suspectes et met à jour la configuration pour protéger votre système contre les attaques.

## Fonctionnalités

- 🛡️ **Détection automatique** des tentatives d'authentification échouées  
- 🚫 **Blocage** des adresses IP ayant dépassé le seuil de tentatives  
- 📊 **Génération de rapports détaillés** sur les tentatives d'intrusion  
- 🔄 **Configuration automatique** des paramètres de sécurité Samba  
- 💾 **Sauvegarde des configurations** avant modification  

## Installation

### Téléchargez le script sur votre serveur :

```bash
git clone https://github.com/feiuz/samba_intrusion_detector.git
```

### Rendez le script exécutable :
```bash
chmod +x samba_intrusion_detector.sh
```

### Utilisation
Exécutez le script avec les privilèges administrateur :

```bash
sudo ./samba_intrusion_detector.sh
```

### Comment ça fonctionne
Analyse des journaux : Le script parcourt les fichiers de journaux Samba à la recherche d'échecs d'authentification.
Identification des IP suspectes : Les adresses IP dépassant un nombre défini de tentatives échouées sont identifiées.
Création d'une liste noire : Ces IP sont ajoutées à un fichier hosts.deny.
Configuration de Samba : Le script met à jour automatiquement la configuration Samba pour utiliser cette liste noire.
Rapport de sécurité : Un rapport détaillé est généré pour référence future.
Mise en place d'une exécution automatique régulière
Pour programmer l'exécution automatique du script :

```bash
sudo crontab -e
```

Ajoutez la ligne suivante pour l'exécuter toutes les 3 heures :

```cron
0 */3 * * * /home/feiuz/samba_intrusion_detector.sh >/dev/null 2>&1
```
### Configuration

Vous pouvez personnaliser les paramètres suivants dans le script :

MAX_ATTEMPTS : Nombre maximum de tentatives échouées avant blocage (défaut : 5)
LOG_DIR : Répertoire des journaux Samba (défaut : "/var/log/samba")
REPORT_FILE : Emplacement du rapport (défaut : "$HOME/samba_intrusion_report.txt")

Exemple de sortie
```diff
==== RÉSUMÉ DES ACTIONS ====
- 7 IPs ont été bloquées
- Configuration Samba mise à jour: /etc/samba/smb.conf
- Liste noire enregistrée dans: /etc/samba/hosts.deny
- Rapport complet sauvegardé dans: /root/samba_intrusion_report.txt
```

### Recommandations complémentaires de sécurité
Changez régulièrement les mots de passe des utilisateurs Samba
Limitez l'accès en spécifiant des utilisateurs valides pour chaque partage
Configurez des règles de pare-feu restrictives
Effectuez des audits de sécurité réguliers

### Dépannage
Si vous rencontrez des problèmes :

Vérifiez que le script est exécuté avec les privilèges root
Assurez-vous que les chemins vers les fichiers de journaux sont corrects
Vérifiez la syntaxe de votre configuration Samba avec testparm

### Contributions
Les contributions sont les bienvenues ! N'hésitez pas à soumettre des pull requests ou à ouvrir des issues pour améliorer ce script.

### Licence
Ce script est distribué sous licence MIT.

Note : Pour tout serveur Samba exposé sur Internet, ce script devrait faire partie d'une stratégie de sécurité plus large incluant un pare-feu correctement configuré, des mises à jour régulières, et des audits de sécurité.
