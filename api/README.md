
# API Ar Redadeg


## À propos

Cette API sert à :
* lancer les scripts de traitements des données
* accéder à des informations sur les les traitements


## Installation

### Créer un environnement virtuel Python

Il faut installer des paquets permettant de builder les librairies requises :

```bash
sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev libpcre3 libpcre3-dev python3-setuptools
```


Après avoir bien entenud fait un git clone du dépôt :

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

Vérifier que l'on obtient bien un "Hello There" sur la page http://localhost:5000/

Faire `ctrl + C` pour arrêter.


### Configurer uWSGI

On utilise les fichiers wsgi.py et hello.ini

On teste si uWSGI et le socket fonctionne en utilisant le fichier de configuration :

```bash
uwsgi --ini hello.ini
```


### Configurer nginx

On rajoute les directives suivantes au fichier de conf nginx

```
    location = /hello { rewrite ^ /hello/; }
    location /hello { try_files $uri @hello; }
    location @hello {
      include uwsgi_params;
      uwsgi_pass unix:/tmp/hello.sock;
    }
```

On recharger la configuration de nginx : ```sudo service nginx reload```.

Tester si on obtient bien toujours un "Hello There" sur la page   http://localhost/hello/

Super ! Mais il faut que la commande ```uwsgi -s …``` qui crée le socket soit active dans le shell.

Pour sortir du mode venv, taper : ```deactivate```.



### Configurer un socket spécifique permanent sur la machine

Il s'agit ici de configurer un socket sépcifique qui sera démarré automatiquement au boot.

```navigateur --> nginx http://{host}/api/ :80 --> socket unix {localhost} :5001 --> programme.py```

En décodé : la route /api/ demandée à nginx sera routée vers un serveur Python local qui écoute sur le port 5001 de la machine pour servir le script python qui répondra.

On va supposer que l'on est sous Debian 10 ou Ubuntu Server 20.04 donc on va créer un démon sous system.d.

Créer un fichier "unit" :

```bash
sudo nano /etc/systemd/system/api_hello.service
```

avec les directives ci-dessous :

```
[Unit]
Description=uWSGI instance to serve Hello API
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/data/projets/ar_redadeg/api
Environment="PATH=/data/projets/ar_redadeg/api/venv/bin"
ExecStart=/data/projets/ar_redadeg/api/venv/bin/uwsgi --ini hello.ini

[Install]
WantedBy=multi-user.target
```

On n'oublie pas de mettre les permissions au serveur web sur les fichiers :

```bash
chown -R www-data:www-data /data/projets/ar_redadeg/api/
```

Et on crée le répertoire pour les logs :

```bash
mkdir -p /var/log/uwsgi/
```

Lancer et tester le service :

```bash
# enable
sudo systemctl enable api_hello
# start
sudo systemctl start api_hello
# check
sudo systemctl status api_hello
```

Faire ```ll /tmp/hello*``` pour voir si le socket a bien été créé par www-data.

Tester si on obtient bien toujours un "Hello There" sur la page   http://localhost/hello/


Si on veut supprimer le service :

```bash
systemctl stop api_hello
systemctl disable api_hello
rm /etc/systemd/system/api_hello.service
systemctl daemon-reload
systemctl reset-failed
```

## Sources

https://flask.palletsprojects.com/en/1.1.x/deploying/uwsgi/

https://www.vultr.com/docs/deploy-a-flask-website-on-nginx-with-uwsgi

https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uwsgi-and-nginx-on-ubuntu-20-04

https://medium.com/@ksashok/using-nginx-for-production-ready-flask-app-with-uwsgi-9da95d8ac0f9

https://uwsgi-docs.readthedocs.io/en/latest/Nginx.html

https://uwsgi-docs.readthedocs.io/en/latest/WSGIquickstart.html#putting-behind-a-full-webserver

https://uwsgi-docs.readthedocs.io/en/latest/WSGIquickstart.html#automatically-starting-uwsgi-on-boot
