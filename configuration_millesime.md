## Configuration d'un nouveau millésime


### Création du répertoire des données

Créer un répertoire de données pour le millésime.

`mkdir -p data/{millesime}/backup`

Et lui positionner les bonnes permissions.

`chmod -R g+s data/{millesime}/`

Ce répertoire recevra tous les fichiers temporaires nécessaires : exports GEOJSON depuis / vers umap, dumps SQL, etc.


### Fichier de configuration

Modifier le fichier `config.ini` dans le répertoire `scripts_v2` pour y mettre les informations de connexion aux bases de données (la base OpenStreetMap et les bases redadeg).



### Créer la base de données

Se déplacer dans le répertoire des scripts : `cd scripts_v2/`

Utiliser le script suivant avec un compte linux qui dispose d'un rôle 'superuser' sur la base PostgreSQL. Donc idéalement, à exécuter avec le user postgres.

[scripts/create_database.sh](scripts/create_database.sh)

`su postgres
./create_database.sh {millesime}`

Il va créer :
* un compte (rôle) `redadeg`
* une base `redadeg_{millesime}` 
* les extensions `postgis`, `postgis_topology` et `pgrouting`
* et mettre le rôle `redadeg` en propriétaire de tout ça


Note : l'extension `postgis_topology` crée forcément un schéma *topology* dans la base de données.


### Créer les tables

Il faut au préalable créer un fichier `update_infos_secteurs.sql` dans le répertoire du millésime et le remplir à minima avec le secteur d'avant départ et un secteur de test.

`nano ../data/{millesime}/update_infos_secteurs.sql`

```sql
-- id | nom_br | nom_fr | objectif_km | km_redadeg
TRUNCATE TABLE secteur ;
INSERT INTO secteur VALUES (0, 'Rak-loc''han', 'Pré-départ', 0, 0);
INSERT INTO secteur VALUES (999, 'test', 'test', NULL, NULL);
```

On exécute ensuite le script qui va créer toutes les tables :

`./create_tables.sh {millesime}`


Note : le principe est de travailler dans le système de projection IGN Lambert93. Les tables / couches dans ce système ne sont pas suffixé. Les tables d'import depuis umap sont suffixées en "3857" et les tables ou vues d'export sont suffixées en "4326".

```
import depuis umap -> traitements -> export pour umap /stal / merour
    EPSG:3857      ->  EPSG:2154  ->    EPSG:4326
```


### couche des communes

`./load_communes_osm.sh {millesime}`

Ce script va récupérer une couche des communes de France (source OpenStreetMap) et la charger dans la base de données dans la table `osm_communes`.

**Attention !** changer le millésime à utiliser ligne 26 : `millesimeSHP=20220101` si nécessaire.


### Cartes umap

Se connecter à [uMap](http://umap.openstreetmap.fr/fr/user/osm-bzh/) avec le compte "OSM e Bzh". Pour cela choisir une authentification par OpenStreetMap. L'adresse e-mail est `osm@breizhpositive.bzh`.

Pour les cartes phase 1, 2 et 5 :

* en choisir une de l'ancienne édition
* entrer en mode édition
* Paramètres > Actions avancées : Cloner
* Paramètres > Nom : changer le nom pour respecter le motif `arredadeg_{millesime}_{phase}_{secteur}`
* Pour chaque couche de données qui le nécessite : Gérer les calques > {un calque} > Actions avancées : Vider
* Ne pas oublier d'enregistrer la carte pour finir


### Fichiers contenant les identifiants des couches umap

Il faut ensuite repérer les identifiants des couches des tracés pour les stocker dans un fichier `umap_phase_1_layers.txt`. Ce fichier est important car les scripts vont s'en servir pour aller récupérer les données des cartes umap.

Pour faire cela, par exemple pour les cartes de la phase 1 :

* ouvrir une carte umap
* ouvrir les outils de développements web (souvent F12 avec les navigateurs sous Windows)
* aller sur l'onglet "Réseau"
* rafraîchir / recharger la page
* repérer / filter les url contenant `datalayer` : il y en a une pour chaque couche configuée dans la carte umap
* pour les cartes phase 1 : repérer la plus lourde : il s'agit de la couche du tracé manuel
* copier l'identifiant. Exemple : `2656876 ` dans `https://umap.openstreetmap.fr/fr/datalayer/2656876/`
* le coller dans le fichier texte

Bien entendu, pour le fichier `umap_phase_1_layers.txt`, l'ordre des identifiants = l'ordre des secteurs.


### Page HTML du millésime

* Dupliquer un fichier d'un millésime précédent dans le répertoire `www/`
* Le nommer correctement
* Remplacer les anciens liens par les bons liens vers les différentes ressources


### Configuration nginx

Modifier la configuration du vhost nginx pour rajouter un millésime. Cette configuration permet de lister le contenu du dossier `data`. Important pour stal et merour.
une sauvegarde de ce fichier est dans le répertoire `nginx`.

`sudo nano /etc/nginx/sites-enabled/bzh_openstreetmap_ar_redadeg`

```
    location ~/2024/(.*)$ {
        alias /data/projets/ar_redadeg/data/2024/$1 ;
    }
```

Test de la configuration : `sudo nginx -t`.

Rechargement de la config nginx : `sudo service nginx reload`

Test : [https://ar-redadeg.openstreetmap.bzh/2024/](https://ar-redadeg.openstreetmap.bzh/2024/)


### Couches GeoServer

#### Par l'interface d'administration

Dans l'interface de GeoServer : 

Espace de travail > Ajouter un nouvel espace de travail nommé `redadeg_xxxx` et avec l'url `https://ar-redadeg.openstreetmap.bzh/geoserver/redadeg_xxxx`.

Entrepôts > Ajouter un nouvel entrepôt :

*  type = PostGIS
*  espace de travail = `redadeg_xxxx`
*  nom = `redadeg_xxxx`
*  connexion : localhost + 5432 + redadeg_xxxx + redadeg + {lemdp}
*  Expose primary keys


Ensuite, publier les couches 1 à 1 (et ouais…).



#### par duplication du workspace

**/!\ ci-dessous ne marche pas !!!!**

Dans l'interface de GeoServer, créer un nouveau workspace nommé `redadeg_new`


```
cd /var/lib/tomcat9/webapps/geoserver/data/workspaces/

cp -r --preserve redadeg_2022/ redadeg_2024

```

On met le bon nom de workspace dans les fichiers principaux :

```
cd redadeg_2024/

find *.xml -type f | xargs sed -i 's/redadeg_2022/redadeg_2024/g'
```

on renomme le datastore : `mv redadeg_2022/ redadeg_2024/`

on applique ce renommage dans tous les fichiers : `find ./ -name "*.xml" | xargs sed -i 's/redadeg_2022/redadeg_2024/g'`

on peut vérifier le datastore : `nano redadeg_2024/datastore.xml`



Ensuite on repère 2 choses : 

* l'id du workspace tel qu'il est, qui doit être encore identique à celui de l'édition précédente : `cat workspace.xml`=> `<id>WorkspaceInfoImpl--26e11ea9:1783d521a27:-7fff</id>`

* l'id du workspace `redadeg_new` que l'on a créé précédemment : `cat ../redadeg_new/workspace.xml` => `<id>WorkspaceInfoImpl--2b9f8ffe:186b0a72551:-7ff6</id>`


find ./ -name "*.xml" | xargs sed -i 's/26e11ea9:1783d521a27/2b9f8ffe:186b0a72551/g

à ce stade, il reste à changer les id des couches qui sont identiques à celle de l'édition précédentes

nano redadeg_2024/phase_1_trace_3857/featuretype.xml
123c3cee

find ./ -name "featuretype.xml" | xargs sed -i 's/123c3cee/redadeg_2024/g'




### Carte mviewer de contrôle

TODO


### Projet QGIS de contrôle

TODO


### sauvegardes

Modifier le crontab : `crontab -e`

```
# sauvegarde des bases postgresql : tous les jours à 12h00
00 12 * * * cd /data/projets/ar_redadeg/scripts_v2/ ; ./backup.sh 2024 > /data/projets/ar_redadeg/data/2024/backup/backup.log
```