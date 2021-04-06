
# API Ar Redadeg


## À propos

Cette API sert à :
* lancer les scripts de traitements des données
* accéder à des informations sur les les traitements

API Flask copiée depuis [https://github.com/MaelREBOUX/simple_flask_api
](https://github.com/MaelREBOUX/simple_flask_api)


## Installation

### Installer les paquets requis

```bash
sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev libpcre3 libpcre3-dev python3-setuptools
```

### Créer un environnement virtuel Python


```bash
cd api
python3 -m venv venv
. venv/bin/activate
pip install flask uwsgi
```

Tester

```bash
python3 hello.py
```

Vérifier que l'on obtient bien quelque chose en allant sur la page http://localhost:5000/

Faire `ctrl + C` pour arrêter.


## Tester uWSGI

On teste maintenant si uWSGI et le socket fonctionnent bien en utilisant le fichier de configuration ```api_redadeg.ini``` :

```bash
uwsgi --ini api_redadeg.ini
```

aire ```ll /tmp/api_redadeg*``` pour voir si le socket a bien été créé par www-data.

Tester si on obtient bien toujours quelque chose sur la page [https://ar-redadeg.openstreetmap.bzh/api/](https://ar-redadeg.openstreetmap.bzh/api/)

À ce stade tout est fonctionnel mais il faut maintenant créer un daemon pour ne pas avoir une commande uwsgi dans le shell.

Sortir du mode venv en tapant : ```deactivate```.



### Configurer nginx

On rajoute les directives suivantes au fichier de conf nginx

```
    location = /api { rewrite ^ /api/; }
    location /api { try_files $uri @api; }
    location @api {
      include uwsgi_params;     
      uwsgi_pass unix:/tmp/api_redadeg.sock;
    }
```

On recharger la configuration de nginx : ```sudo service nginx reload```.

Tester si on obtient bien toujours quelque chose sur la page [https://ar-redadeg.openstreetmap.bzh/api/](https://ar-redadeg.openstreetmap.bzh/api/)

À ce stade tout est fonctionnel mais il faut maintenant créer un daemon pour ne pas avoir une commande uwsgi dans le shell.

Sortir du mode venv en tapant : ```deactivate```.


### Configurer un socket spécifique permanent sur la machine

```bash
cp api_redadeg.service /etc/systemd/system/
```

On n'oublie pas de mettre les permissions au serveur web sur les fichiers :

```bash
chown -R www-data:www-data /data/projets/ar_redadeg/api/
```

Et on crée le répertoire pour les logs (en option) :

```bash
mkdir -p /var/log/uwsgi/
```

Lancer et tester le service :

```bash
# enable
sudo systemctl enable api_redadeg
# start
sudo systemctl start api_redadeg
# check
sudo systemctl status api_redadeg
```

Faire ```ll /tmp/api_redadeg*``` pour voir si le socket a bien été créé par www-data.

Tester si on obtient bien toujours un "Hello There" sur la page   https://ar-redadeg.openstreetmap.bzh/api/


Si on veut supprimer le service :

```bash
systemctl stop api_redadeg
systemctl disable api_redadeg
rm /etc/systemd/system/api_redadeg.service
systemctl daemon-reload
systemctl reset-failed
```
