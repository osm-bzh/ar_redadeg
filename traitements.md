# Traitements


## Phase 1 et 2 : obtenir un tracé calé sur le filaire de voies OSM

Le script `update_secteur.py` rassemble toutes les étapes nécessaires pour, à partir du tracé à main levé dans les cartes umap, obtenir un tracé recalé sur le filaire de voies OSM.

### Utilisation

* se placer à la racine du répertoire du projet et activer une session virtuelle python : `source .venv/bin/activate`
* se placer dans le répertoire `script_v2` : `cd script_v2`
* lancer le script en indiquant les paramètres : `update_secteur.py {millésime} {secteur} {phase_1 | phase_2 | phase_3 | tout}`

### Traitements

**Phase 1** : `phase_1.sh {millésime}`

* récupération des tracés des cartes umap phase 1 (calque `phase_1_trace`)
* chargement dans la base (tables `phase_1_trace_3857` et `phase_1_trace`)
* création de la couche `phase_1_trace_troncons` avec un découpage automatique tous les 1000 m (obsolète : à supprimer)
* exports : `phase_1_trace_4326.geojson`et `phase_1_pk_auto.geojson`


**Extraction d'un filaire de voie depuis les données OSM** : `create_osm_roads.sh {millésime} {secteur}`

* import du tracé phase 1 dans la base OSM
* dans la base OSM : extraction du réseau de voies (couche `planet_osm_line` à proximité du tracé manuel (zone tampon de 25 m) dans une couche `osm_roads_{millesime}`
* export
* chargement de cette couche dans la table `osm_roads_import` dans la base `redadeg_{millesime}`

La durée de cette étape varie selon le secteur : de 2 à 10 minutes.

Les données brutes OSM ne sont pas structurées pour pouvoir calculer un itinéraire, il faut donc enchaîner avec l'étape suivante.


**Création d'un filaire routable** : `update_osm_roads_pgr.sh {millesime} {secteur}`

1/ calcul d'un graphe routier topologique

* suppression des données du secteur des couches `osm_roads` et `osm_roads_pgr` 
* import du filaire de voirie à jour dans la couche topologique `osm_roads`
* calcul du graphe topologique (calcul de la connectivité entre chaque tronçon et chaque nœud). Cette étape permet aussi de corriger les erreurs de saisie.

2/ préparation de la couche support pour PGrouting

* import des données préparées à l'étape d'avant dans la couche `osm_roads_pgr`
* calcul des attributs de coût


**Phase 2**

* `phase_2_get_data.sh {millesime} {secteur}` : 
  * récupération et import des données phase 2 depuis les cartes umap : **PK secteurs** et **points de nettoyage** (tables `phase_2_pk_secteur_3857` et `phase_2_point_nettoyage_3857`)
* `phase_2_routing_prepare.sh {millesime} {secteur}` :
  * Patch de la couche osm_roads_pgr pour les cas particuliers : utilisation des couches `osm_roads_pgr_patch_mask` et `osm_roads_pgr_patch`
  * recalcul des attributs de coût (longueur)
  * recalcul des nœuds uniquement sur les zones de patch
  * recalcul de la topologie pgRouting uniquement sur les zones de patch
  * recalage des PK secteurs sur un nœud du réseau routable
  * recalage des points de nettoyage sur un nœud du réseau routable
  * recalcul des attributs de coût (type de voies et points de nettoyage)
* `python phase_2_routing_compute.py {millesime} {secteur}` :
  * vidage de la couche de routage pour le secteur : couche `phase_2_trace_pgr`
  * calcul d'un itinéraire entre les nœuds PK de début et fin du secteur
  * exports : `phase_2_trace_pgr.geojson`
* `phase_2_post_traitements.sh {millesime} {secteur}` :
  * création d'une ligne unique par secteur (couche `phase_2_trace_secteur`)
  * création couche de tronçons ordonnés de 1000 m de longueurs (couche `phase_2_trace_troncons`)
  * exports : `phase_2_trace_secteur.geojson`, `phase_2_trace_troncons.geojson`

C'est à cette étape que l'on gère les zones de patch manuellement. Voir [la procédure spécifique](patch_manuel_routes.md).

## Phase 3 : Calcul du positionnement des PK

Cette phase consiste à découper le tracé d'un secteur en n tronçons de la longueur définie dans la table de référence `secteur`.

**Cette phase doit être faire, en théorie, 1 seule fois.** Ou tout du moins jusqu'à une validation du positionnement des PK / de la longueur par secteur.
En phase de production, on passera directement de la phase 2 à la phase 5.

* `phase_3_prepare.py  {millesime} {secteur}` :
  * nettoyage de la couche `phase_3_troncons_pgr` des données du secteur
  * réinsertion des données pour le secteur dans la couche `phase_3_troncons_pgr` avec des tronçons venant de la couche `phase_2_trace_troncons`. Ces tronçons sont volontairement TRÈS courts pour permettre un découpage fin à l'étape suivante. La valeur de découpage est dans le fichier `config.ini`, valeur `longueur_densification` (10 m par défaut)
  * calcul des attributs de coût (longeur) sur la couche `phase_3_troncons_pgr`
  * création / maj de la topologie pgRouting pour les tronçons nouvellement créés
  * mise à jour des données de la table `secteur`pour le secteur concerné

* `phase_3_compute.py  {millesime} {secteur}` :
  * détermination du nombre théorique de PK pour ce secteur et ainsi la longueur réelle entre chaque PK
  * création des nouveaux PK dans la couche `phase_3_pk`



## Phase 4 : mise en production des données

Le script `phase_4.py {millesime}` sert 1 seule et unique fois et permet d'alimenter de verser les données de la phase 3 (les PK calculées automatiquement et le tracé) dans les tables de la phase 5.

Cela correspond au moment où les données rentrent en phase de production et les PK en phase de vente.

* depuis la couche `phase_3_pk` :
  * copie vers la table `phase_5_pk_ref` (table archives pour pouvoir faire les comparaisons ultérieures et traquer les déplacements de PK manuels)
  * copie vers la table `phase_5_pk`
* remplissage de la couche `phase_5_trace` depuis la couche `phase_2_trace_secteur` 

Il faut également créer les 2 couches phase 5 sur le GeoServer.
La couche des PK doit comporter un attribut `modulo`. La source SQL est donc :

```sql
SELECT
  *,
  CASE
    WHEN pk_id % 100 = 0 THEN 100
    WHEN pk_id % 50 = 0 THEN 50
    WHEN pk_id % 10 = 0 THEN 10
    ELSE NULL
  END as modulo
FROM phase_5_pk
```


## Phase 5 : maintenance en phase de production / vente

À partir de cette phase : les PK sont gérés manuellement.
Par contre : on peut toujours utiliser les traitements phase 1 et 2 pour récupérer et mettre à jour le filaire OpenStreetMap. Ou pour prendre en compte des modifications sur le tracé.

Les PK sont gérés à partir de cartes umap : 1 par secteur.
voir les liens listés sur [la page du millésime](https://ar-redadeg.openstreetmap.bzh/)

**On va donc utiliser les scripts de la phase 1, phase 2 et phase 5.**
Le script `update_secteur.py {millesime} {secteur}` permet d'enchaîner toutes les tâches des phase 1 et 2. Après vérification on peut lancer le script `phase_5.py {millesime}`.

### Utilisation

* se placer à la racine du répertoire du projet : `cd /data/projets/ar_redadeg/`
* activer une session virtuelle python : `source .venv/bin/activate`
* se placer dans le répertoire `scripts_v2` : `cd scripts_v2`
* lancer le script en indiquant les paramètres : `python phase_5.py {millésime}`

Exemple d'enchaînement phase 1 + phase 2 + phase 5 :

* `python update_secteur.py {millesime} {secteur} phase_1`
* `python update_secteur.py {millesime} {secteur} phase_2`
* `python phase_5.py {millesime}`
* ou, en une seule commande : `python update_secteur.py {millesime} {secteur} phase_1 ; python update_secteur.py {millesime} {secteur} phase_2 ; python phase_5.py {millesime}` 







