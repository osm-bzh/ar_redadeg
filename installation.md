# Installation

## Créer un groupe 'redadeg'

```bash
sudo groupadd redadeg
```

Y ajouter les comptes utilisateurs qui vont bien :

```bash
sudo usermod -aG redadeg {user}
```

Vérifier : 

```bash
groups {user}
```


## Cloner ce dépôt

On commence par cloner ce dépôt.


```bash
cd /data/projets/
git clone https://github.com/osm-bzh/ar_redadeg.git
```

Positionner les permissions pour le groupe 'redadeg'.

```bash
chown -R {user}:redadeg /data/projets/ar_redadeg/
```


## Installer ogr2ogr

ogr2ogr servira pour charger des données dans la base.

ogr2ogr fait partie du paquet 'gdal-bin'

```
sudo apt install gdal-bin
ogr2ogr --version
```

## Python

À partir de la phase 4, on utilise un environnement virtuel Python 3.
Et à terme, tous les scripts seront en python.

Généralités pour Python3 :

```bash
sudo apt install libpq-dev python3-dev <<< vérifier 2023-09 : pas utile
sudo apt install python-is-python3
```

Création d'un environnement virtuel Python pour le projet :

```bash
python -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip setuptools
python -m pip install wget psycopg2-binary
```


## GeoServer

### Java

```bash
apt install openjdk-11-jdk
```


### Tomcat

```bash
apt install tomcat9
```


### GeoServer


```
mkdir -p /data/projets/geoserver
cd /data/projets/geoserver/

wget https://sourceforge.net/projects/geoserver/files/GeoServer/2.23.2/geoserver-2.23.2-war.zip

unzip -q -d geoserver-2.23.2 geoserver-2.23.2-war.zip
```

/!\ sauvegarder le datadir existant si c'est une mise à jour de GeoServer car il n'est pas externalisé (je ne sais pas faire)

```
service tomcat9 stop

rm -rf webapps/geoserver/
cp -f geoserver-2.23.2/geoserver.war webapps/
cp: overwrite 'webapps/geoserver.war'? y

service tomcat9 start
```

Surveiller la charge avec htop. Quand ça se calme aller vérifier si [https://ar-redadeg.openstreetmap.bzh/geoserver](https://ar-redadeg.openstreetmap.bzh/geoserver) est accessible.

Si oui, on réinstalle le datadir.


```
service tomcat9 stop

cd webapps/geoserver/
mv data data_org

cp -R /data/projets/geoserver/data/ ./data
chown -R tomcat:tomcat data/

service tomcat9 start
```

### plugin backup

https://docs.geoserver.org/latest/en/user/community/backuprestore/installation.html

```bash
cd /data/projets/geoserver/
wget https://build.geoserver.org/geoserver/2.23.x/community-latest/geoserver-2.23-SNAPSHOT-backup-restore-plugin.zip
unzip -q -d backup-restore-plugin geoserver-2.23-SNAPSHOT-backup-restore-plugin.zip
cp -n backup-restore-plugin/* /var/lib/tomcat9/webapps/geoserver/WEB-INF/lib/
service tomcat9 restart
```

### Configurations GeoServer

#### Erreur 400 `Origin does not correspond to request`

* ouvrir le fichier `WEB-INF/web.xml` de GeoServer
* chercher `PROXY_BASE_URL ` et compléter / décommenter pour arriver à ceci :

```xml
    <context-param>
      <param-name>PROXY_BASE_URL</param-name>
      <param-value>https://ar-redadeg.openstreetmap.bzh/geoserver</param-value>
    </context-param>
```

* juste en-dessous, rajouter ce bloc :

```xml
    <context-param>
      <param-name>GEOSERVER_CSRF_WHITELIST</param-name>
      <param-value>ar-redadeg.openstreetmap.bzh</param-value>
    </context-param>
```


https://dev.to/iamtekson/using-nginx-to-put-geoserver-https-4204



## nginx

TODO



## mviewer

```
cd /data/projets/
sudo git clone https://github.com/mviewer/mviewer.git
sudo chown -R mreboux:redadeg mviewer/
```

Tester avec [https://ar-redadeg.openstreetmap.bzh/mviewer/demo/](https://ar-redadeg.openstreetmap.bzh/mviewer/demo/)

Puis on (re)fait les liens symboliques vers les fichiers de configurations xml.

```
cd /data/projets/mviewer/apps
ln -s /data/projets/ar_redadeg/data/2024/mviewer/kartenn_kontroll.xml ar-redadeg-2024
```
