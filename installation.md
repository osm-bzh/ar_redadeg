# Installation

## Cloner ce dépôt

On commence par cloner ce dépôt.

Allez où vous voulez sur votre ordinateur, puis :

`git clone https://github.com/osm-bzh/ar_redadeg.git`


## Installer ogr2ogr

ogr2ogr servira pour charger des données dans la base.

ogr2ogr fait partie du paquet 'gdal-bin'

```
sudo apt-get install gdal-bin
ogr2ogr --version
```

## Python

À partir de la phase 4, on utilise un environnement virtuel Python 3.
Et à terme, tous les scripts seront en python.

Généralités pour Python3 :

```bash
sudo apt install libpq-dev python3-dev
sudo apt install python-is-python3
```

Création d'un environnement virtuel Python pour le projet :

```bash
python -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip setuptools
python -m pip install psycopg2 wget
```


## GeoServer

### Java

TODO


### Tomcat


### GeoServer


```
mkdir -p /data/projets/geoserver
cd /data/projets/geoserver/

wget https://sourceforge.net/projects/geoserver/files/GeoServer/2.22.2/geoserver-2.22.2-war.zip

unzip -q -d geoserver-2.22.2 geoserver-2.22.2-war.zip
```

/!\ sauvegarder le datadir existant si c'est une mise à jour de GeoServer car il n'est pas externalisé (je ne sais pas faire)

```
service tomcat9 stop

rm -rf webapps/geoserver/
cp -f geoserver-2.22.2/geoserver.war webapps/
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
wget https://build.geoserver.org/geoserver/2.22.x/community-latest/geoserver-2.22-SNAPSHOT-backup-restore-plugin.zip
unzip -q -d backup-restore-plugin geoserver-2.22-SNAPSHOT-backup-restore-plugin.zip
cp -n backup-restore-plugin/* webapps/geoserver/WEB-INF/lib/
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

TODO