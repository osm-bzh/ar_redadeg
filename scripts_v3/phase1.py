
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
    conn = engine.connect()
    logging.debug(f"connexion à la base de données {db_name} : ok\n")

    # get_umap_data(shared_data.SharedData.secteur, conn)
    transfert_trace_to_osm_db(shared_data.SharedData.secteur, conn)

    conn.close()
    logging.debug(f"déconnexion de la base de données {db_name} : ok\n")

    # chrono final
    final_chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps total phase 1 : {final_chrono}")
    logging.info("")

    pass
