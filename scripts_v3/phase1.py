
import sys
import logging
import time
from sqlalchemy import create_engine, text
import geopandas as gpd
import pandas as pd

import functions
import shared_data


def get_umap_data(secteur, conn):

    logging.info(f"Récupération des données du secteur {secteur} depuis umap")
    start_time = time.perf_counter()

    try:
        sql_get_umap_layers = f"SELECT * FROM umap_layers WHERE phase = 1 AND secteur = {secteur} ;"
        result = conn.execute(text(sql_get_umap_layers))
    except Exception as e:
        logging.error(f"impossible de requêter la table umap_layers : {e}")
        sys.exit(1)

    # si on a tapé un mauvais code de secteur
    if result.rowcount == 0:
        logging.error(f"ERREUR")
        logging.error(f"Il n'y a pas de secteur avec ce code !")
        logging.error(f"Vérifiez vos codes.")
        sys.exit(1)

    # Initialiser un GeoDataFrame vide
    combined_gdf = gpd.GeoDataFrame()

    for row in result:
        # l'URL vers umap
        geojson_url = f"https://umap.openstreetmap.fr/fr/datalayer/{row[2]}/"
        logging.info(f"URL des données umap = {geojson_url}")

        # on dump le contenu dans un fichier
        # on travaille le nom du fichier
        temp_file = f"tmp_files/{row[2].replace('/','-')}.geojson"
        functions.save_url_content_to_file(geojson_url,temp_file)
        logging.debug(f"sauvegarde du GeoJSON dans le fichier {temp_file}")

        # Charger le GeoJSON dans un GeoDataFrame
        gdf = gpd.read_file(temp_file)

        # Ajouter une colonne pour identifier la couche (optionnel)
        gdf["layer_id"] = row[2]

        # Combiner les GeoDataFrames
        combined_gdf = gpd.GeoDataFrame(pd.concat([combined_gdf, gdf], ignore_index=True))

    # Exploser les géométries MultiLineString en LineString
    exploded_gdf = combined_gdf.explode()

    # On force en 2D
    exploded_gdf['geometry'] = exploded_gdf['geometry'].apply(functions.to_2d)
    # Mettre à jour le GeoDataFrame avec les nouvelles géométries
    work_gdf = exploded_gdf.set_geometry('geometry')

    # WGS84 -> Lambert93
    work_gdf = work_gdf.to_crs(epsg=2154)

    # Ajouter une colonne 'longueur' avec la longueur de chaque LineString
    work_gdf['longueur'] = work_gdf.geometry.length
    # Arrondir les valeurs de la colonne 'longueur' pour qu'elles soient des entiers
    work_gdf['longueur'] = work_gdf['longueur'].round(0).astype(int)

    # Création du dataframe final
    final_gdf = work_gdf[['secteur_id','longueur','geometry']]

    # Renommer la colonne 'geometry' en 'geom'
    final_gdf = final_gdf.rename_geometry('geom')

    # Forçage du système de coordonnées
    final_gdf.set_crs(epsg=2154, inplace=True)


    # Sauvegarder le GeoDataFrame combiné dans un fichier si mode debug
    if shared_data.SharedData.debug_mode:
        tmp_file = f"tmp_files/phase_1_umap_secteur_{secteur}.geojson"
        logging.debug(f"sauvegarde des données umap dans {tmp_file}")
        final_gdf.to_file(tmp_file, driver="GeoJSON")

    # On vide la table cible
    try:
        sql_delete = f"DELETE FROM {shared_data.SharedData.db_schema}.phase_1_trace_umap WHERE secteur_id = {secteur} ;"
        conn.execute(text(sql_delete))
    except Exception as e:
        logging.error(f"impossible de supprimer le secteur {secteur} de la table phase_1_trace_umap :\n{e}")
        sys.exit(1)

    # On la remplit
    final_gdf.to_postgis('phase_1_trace_umap',conn, schema='redadeg', if_exists='append')

    logging.info(f"nb d'objets insérés dans phase_1_trace_umap : {final_gdf.shape[0]}")
    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    # purger
    del combined_gdf
    del exploded_gdf
    del work_gdf
    del final_gdf

    pass

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def transfert_trace_to_osm_db(secteur, conn, osm_conn):

    logging.info(f"Transfert du tracé du secteur vers la base de données OSM")
    start_time = time.perf_counter()

    # on charge le tracé dans un geodataframe
    try:
        sql_get_secteur = f"SELECT id, secteur_id, geom FROM {shared_data.SharedData.db_schema}.phase_1_trace_umap WHERE secteur_id = {secteur};"
        gdf = gpd.read_postgis(sql_get_secteur, conn, geom_col='geom')
    except Exception as e:
        logging.error(f"impossible de charger le secteur :\n{e}")
        sys.exit(1)

    # puis on l'écrit dans une table dans la base OSM
    try:
        gdf.to_postgis(f'phase_1_trace_{shared_data.SharedData.millesime}', osm_conn, if_exists='replace')
    except Exception as e:
        logging.error(f"impossible de remplacer la table phase_1_trace_{shared_data.SharedData.millesime} dans la BD OSM:\n{e}")
        sys.exit(1)

    # nettoyage
    del gdf

    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    pass

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def compute_osm_roads(osm_conn):

    logging.info(f"Création de la couche des tronçons de routes OSM")
    start_time = time.perf_counter()

    # on crée une table qui va accueillir le résultat de la sélection
    try:
        sql_create_table = f"""
DROP TABLE IF EXISTS osm_roads_{shared_data.SharedData.millesime} ;
CREATE TABLE osm_roads_{shared_data.SharedData.millesime}
(
  secteur_id integer NOT NULL,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  geom geometry
);
-- commentaires
COMMENT ON TABLE osm_roads_{shared_data.SharedData.millesime} IS 'Cette table contient les tronçons sélectionnés à partir des routes OSM.';
-- contraintes
ALTER TABLE osm_roads_{shared_data.SharedData.millesime} ADD CONSTRAINT osm_roads_{shared_data.SharedData.millesime}_pkey PRIMARY KEY (osm_id);
ALTER TABLE osm_roads_{shared_data.SharedData.millesime} ADD CONSTRAINT enforce_geom_dim CHECK (st_ndims(geom) = 2);
ALTER TABLE osm_roads_{shared_data.SharedData.millesime} ADD CONSTRAINT enforce_geom_srid CHECK (st_srid(geom) = 2154);
ALTER TABLE osm_roads_{shared_data.SharedData.millesime} ADD CONSTRAINT enforce_geom_type CHECK (geometrytype(geom) = 'LINESTRING'::text OR geometrytype(geom) = 'MULTILINESTRING'::text);
"""

        osm_conn.execute(text(sql_create_table))
        logging.debug(f"Table osm_roads_{shared_data.SharedData.millesime} créée avec succès.")

    except Exception as e:
        logging.error(f"impossible de créer la table osm_roads_{shared_data.SharedData.millesime} :\n{e}")
        sys.exit(1)

    #

    try:
        sql_extract = f"""
WITH trace_buffer AS (
  SELECT
    secteur_id,
    ST_Union(ST_Buffer(geom, 25, 'quad_segs=2')) AS the_geom
  FROM phase_1_trace_{shared_data.SharedData.millesime}
  WHERE secteur_id = {shared_data.SharedData.secteur}
  GROUP BY secteur_id
  ORDER BY secteur_id
)
INSERT INTO osm_roads_{shared_data.SharedData.millesime}
(
  SELECT
    t.secteur_id,
    osm_id,
    highway,
    CASE 
        WHEN highway IN ('motorway', 'trunk') THEN 'motorway' 
        WHEN highway IN ('primary', 'secondary') THEN 'mainroad' 
        WHEN highway IN ('motorway_link', 'trunk_link', 'primary_link', 'secondary_link', 'tertiary', 'tertiary_link', 'residential', 'unclassified', 'road', 'living_street') THEN 'minorroad' 
        WHEN highway IN ('service', 'track') THEN 'service' 
        WHEN highway IN ('path', 'cycleway', 'footway', 'pedestrian', 'steps', 'bridleway') THEN 'noauto' 
        ELSE 'other' 
    END AS type,
    oneway,
    ref,
    name AS name_fr,
    COALESCE(tags -> 'name:br'::text) as name_br,
    ST_Intersection(ST_Transform(o.way,2154), t.the_geom) AS the_geom
  FROM planet_osm_line o, trace_buffer t
  WHERE highway IS NOT NULL AND ST_INTERSECTS(t.the_geom, ST_Transform(o.way,2154))
) ;
"""
        osm_conn.execute(text(sql_extract))
        logging.debug(f"Table osm_roads_{shared_data.SharedData.millesime} remplie avec succès.")

    except Exception as e:
        logging.error(f"Impossible de remplir osm_roads_{shared_data.SharedData.millesime} :\n{e}")
        sys.exit(1)


    #

    logging.info(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    pass

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


def transfert_osm_roads_to_db(osm_conn, conn):

    logging.info(f"Transfert de la couche osm_roads vers la base de données redadeg_{shared_data.SharedData.millesime}")
    start_time = time.perf_counter()

    # on charge les routes depuis la base OSM dans un geodataframe
    try:
        sql_get_roads = f"""
SELECT secteur_id, osm_id, highway, \"type\", oneway, \"ref\", name_fr, name_br, geom
FROM osm_roads_{shared_data.SharedData.millesime}
WHERE secteur_id = {shared_data.SharedData.secteur};"""
        gdf = gpd.read_postgis(sql_get_roads, osm_conn, geom_col='geom')
    except Exception as e:
        logging.error(f"impossible de charger osm_roads_{shared_data.SharedData.millesime} :\n{e}")
        sys.exit(1)

    # on supprime les tronçons du secteur traité
    try:
        sql_delete = f"DELETE FROM {shared_data.SharedData.db_schema}.osm_roads WHERE secteur_id = {shared_data.SharedData.secteur} ;"
        conn.execute(text(sql_delete))
    except Exception as e:
        logging.error(f"impossible de supprimer des données du secteur {shared_data.SharedData.secteur} "
                      f"dans la table {shared_data.SharedData.db_schema}.phase_1_trace_troncons :\n{e}")
        sys.exit(1)

    # puis on remplace
    try:
        # on calcule un identifiant unique pour la clé primaire
        gdf['uid'] = gdf['secteur_id'].astype(str) + '_' + gdf['osm_id'].astype(str)
        gdf.to_postgis("osm_roads",con=conn, schema=shared_data.SharedData.db_schema, if_exists="append", index=False)
    except Exception as e:
        logging.error(f"impossible de remplir la table {shared_data.SharedData.db_schema}.osm_roads :\n{e}")
        sys.exit(1)

    # nettoyage
    del gdf

    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    pass


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def update_topology_osm_roads(conn):
    logging.info(f"Mise à jour de la topologie simple")
    start_time = time.perf_counter()

    try:
        sql_maj_topology = f"""
UPDATE {shared_data.SharedData.db_schema}.osm_roads
SET topo_geom = topology.toTopoGeom(geom, 'osm_roads_topo', (SELECT layer_id FROM topology.layer WHERE table_name = 'osm_roads'), 0.5)
WHERE secteur_id = {shared_data.SharedData.secteur} ;
        """
        conn.execute(text(sql_maj_topology))
    except Exception as e:
        logging.error(
            f"impossible de calculer la topologie sur la table {shared_data.SharedData.db_schema}.osm_roads :\n{e}")
        sys.exit(1)

    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    pass


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def compute_osm_roads_pgr(conn):
    logging.info(f"Mise à jour des couches de routage")
    start_time = time.perf_counter()

    # nettoyage
    try:
        sql_delete = f"DELETE FROM redadeg.osm_roads_pgr WHERE secteur_id = {shared_data.SharedData.secteur};"
        conn.execute(text(sql_delete))
        logging.debug("suppression du secteur de osm_roads_pgr OK")
    except Exception as e:
        logging.error(
            f"impossible d'effacer le secteur dans la table {shared_data.SharedData.db_schema}.osm_roads_pgr :\n{e}")
        sys.exit(1)

    # insertion depuis la topologie simple
    try:
        sql_maj_osm_pgr  = f"""
INSERT INTO osm_roads_pgr
(secteur_id, osm_id, highway, "type", oneway, "ref", name_fr, name_br, geom)
  SELECT 
    o.secteur_id,
    o.osm_id,
    o.highway,
    o.type,
    o.oneway,
    o.ref,
    o.name_fr,
    o.name_br,
    e.geom as the_geom
  FROM osm_roads_topo.edge e,
       osm_roads_topo.relation rel,
       osm_roads o
  WHERE 
    o.secteur_id = {shared_data.SharedData.secteur}
    AND e.edge_id = rel.element_id
    AND rel.topogeo_id = (o.topo_geom).id ;
"""
        conn.execute(text(sql_maj_osm_pgr))
        logging.debug("insertion des tronçons du secteur dans osm_roads_pgr OK")
    except Exception as e:
        logging.error(
            f"impossible d'insérer dans la table {shared_data.SharedData.db_schema}.osm_roads_pgr :\n{e}")
        sys.exit(1)

    # création / maj de la topologie PGR pour les nouveaux tronçons
    try:
        sql_create_pgr_topo = f"SELECT pgr_createTopology('osm_roads_pgr', 0.001, rows_where:='true', clean:=false);"
        conn.execute(text(sql_create_pgr_topo))
        logging.debug("calcul de la topologie PGR sur ces nouveaux tronçons OK")
    except Exception as e:
        logging.error(
            f"impossible de maj la topologie PGR {shared_data.SharedData.db_schema}.osm_roads_pgr :\n{e}")
        sys.exit(1)

    # calcul de la topologie PGR sur ces nouveaux tronçons
    try:
        sql_compute_costs = f"""
UPDATE osm_roads_pgr 
SET cost = round(st_length(geom)::numeric), reverse_cost = round(st_length(geom)::numeric)
WHERE secteur_id = {shared_data.SharedData.secteur} ;
"""
        conn.execute(text(sql_compute_costs))
        logging.debug("calcul des attributs de coût de routage sur ces nouveaux tronçons OK")
    except Exception as e:
        logging.error(
            f"impossible de calculer les attributs de coût sur {shared_data.SharedData.db_schema}.osm_roads_pgr :\n{e}")
        sys.exit(1)

    #

    logging.info(f"fait en {functions.get_chrono(start_time, time.perf_counter())}")
    logging.info("")

    pass

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


def run_phase1():
    logging.info(f"")
    start_time = time.perf_counter()

    logging.info(f"Phase 1")
    logging.info(f"")

    # lecture du fichier de configuration
    config = functions.get_configuration()
    # définition des variables
    db_host = config.get('database', 'host')
    db_port = config.get('database', 'port')
    db_user = config.get('database', 'user')
    db_name = f"redadeg_{shared_data.SharedData.millesime}"
    schema = 'redadeg'

    # création d'une connexion qui sera partagée
    engine = create_engine(
        f"postgresql://{db_user}@{db_host}:{db_port}/{db_name}"
        , isolation_level="AUTOCOMMIT"
    )
    try:
        conn = engine.connect()
        logging.debug(f"connexion à la base de données {db_name} : ok")
    except Exception as e:
        logging.error(f"impossible de se connecter à la base de données {db_name} :\n{e}")
        sys.exit(1)


    # idem pour la connexion vers la base OSM
    osm_db_host = config.get('database_osm', 'host')
    osm_db_port = config.get('database_osm', 'port')
    osm_db_user = config.get('database_osm', 'user')
    osm_db_name = config.get('database_osm', 'database')

    osm_engine = create_engine(
        f"postgresql://{osm_db_user}@{osm_db_host}:{osm_db_port}/{osm_db_name}"
        , isolation_level="AUTOCOMMIT"
    )
    try:
        osm_conn = osm_engine.connect()
        logging.debug(f"connexion à la base de données {osm_db_name} : ok")
    except Exception as e:
        logging.error(f"impossible de se connecter à la base de données {osm_db_name} :\n{e}")
        sys.exit(1)

    logging.debug(f"")

    #

    get_umap_data(shared_data.SharedData.secteur, conn)
    transfert_trace_to_osm_db(shared_data.SharedData.secteur, conn, osm_conn)
    compute_osm_roads(osm_conn)
    transfert_osm_roads_to_db(osm_conn, conn)
    update_topology_osm_roads(conn)
    compute_osm_roads_pgr(conn)

    #

    # fermeture des connexions aux bases de données
    conn.close()
    logging.debug(f"déconnexion de la base de données {db_name} : ok")
    osm_conn.close()
    logging.debug(f"déconnexion de la base de données {osm_db_name} : ok")
    logging.debug(f"")

    # chrono final
    final_chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps total phase 1 : {final_chrono}")
    logging.info("")

    pass
