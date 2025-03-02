
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

    # Initialiser un GeoDataFrame vide
    combined_gdf = gpd.GeoDataFrame()

    for row in result:
        # l'URL vers umap
        geojson_url = f"https://umap.openstreetmap.fr/fr/datalayer/{row[2]}/"
        logging.debug("")
        logging.debug(geojson_url)

        # on dump le contenu dans un fichier
        # on travaille le nom du fichier
        temp_file = f"tmp_files/{row[2].replace('/','-')}.geojson"
        functions.save_url_content_to_file(geojson_url,temp_file)

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
        sql_delete = f"DELETE FROM phase_1_trace_umap WHERE secteur_id = {secteur} ;"
        conn.execute(text(sql_delete))
    except Exception as e:
        logging.error(f"impossible de supprimer le secteur {secteur} de la table phase_1_trace_umap : {e}")
        sys.exit(1)

    # On la remplit
    final_gdf.to_postgis('phase_1_trace_umap',conn, schema='redadeg', if_exists='append')

    logging.info(f"nb d'objets insérés dans phase_1_trace_umap : {final_gdf.shape[0]}")
    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}\n")
    logging.info("")

    # purger
    del combined_gdf
    del exploded_gdf
    del work_gdf
    del final_gdf

    pass

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def transfert_trace_to_osm_db(secteur, conn, osm_conn):

    logging.info(f"Transfert du tracé du {secteur} vers la base de données OSM")
    start_time = time.perf_counter()

    # on charge le tracé dans un geodataframe
    try:
        sql_get_secteur = f"SELECT id, secteur_id, geom FROM phase_1_trace_umap WHERE secteur_id = {secteur};"
        gdf = gpd.read_postgis(sql_get_secteur, conn, geom_col='geom')
    except Exception as e:
        logging.error(f"impossible de charger le secteur : {e}")
        sys.exit(1)

    # puis on l'écrit dans une table dans la base OSM
    try:
        gdf.to_postgis(f'phase_1_trace_{shared_data.SharedData.millesime}', osm_conn, if_exists='replace')
    except Exception as e:
        logging.error(f"impossible de remplacer la table phase_1_trace_{shared_data.SharedData.millesime} dans la BD OSM: {e}")
        sys.exit(1)

    # nettoyage
    del gdf

    logging.debug(f"fait en {functions.get_chrono(start_time, time.perf_counter())}\n")
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
        logging.error(f"impossible de se connecter à la base de données {db_name} : {e}")
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
        logging.debug(f"connexion à la base de données {db_name} : ok")
    except Exception as e:
        logging.error(f"impossible de se connecter à la base de données {osm_db_name} : {e}")
        sys.exit(1)

    logging.debug(f"")

    #

    # get_umap_data(shared_data.SharedData.secteur, conn)
    transfert_trace_to_osm_db(shared_data.SharedData.secteur, conn, osm_conn)

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
