
import sys
import logging
import time
from sqlalchemy import create_engine, text
import geopandas as gpd
import pandas as pd

import functions



def get_umap_data(conn):

    logging.info("")
    logging.info("Récupération des données depuis umap")

    try:
        sql_get_umap_layers = "SELECT * FROM umap_layers WHERE phase = 1 ORDER BY secteur ;"
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

    # Ajouter une colonne 'id' avec des valeurs incrémentales
    work_gdf['id'] = range(1, len(work_gdf) + 1)

    # Ajouter une colonne 'longueur' avec la longueur de chaque LineString
    work_gdf['longueur'] = work_gdf.geometry.length
    # Arrondir les valeurs de la colonne 'longueur' pour qu'elles soient des entiers
    work_gdf['longueur'] = work_gdf['longueur'].round(0).astype(int)

    # Création du dataframe final
    final_gdf = work_gdf[['id','secteur_id','longueur','geometry']]

    # Renommer la colonne 'geometry' en 'geom'
    final_gdf = final_gdf.rename(columns={'geometry': 'geom'})
    final_gdf = final_gdf.set_geometry('geom')
    # final_gdf.set_crs(epsg=2154, inplace=True)

    # Afficher le résultat
    print(final_gdf)


    # Sauvegarder le GeoDataFrame combiné dans un fichier
    final_gdf.to_file("tmp_files/phase_1_umap_layers.geojson", driver="GeoJSON")


    # On vide la table cible
    try:
        sql_truncate = "TRUNCATE TABLE phase_1_trace_umap ;"
        conn.execute(text(sql_truncate))
    except Exception as e:
        logging.error(f"impossible de vider la table phase_1_trace_umap : {e}")
        sys.exit(1)

    # On la remplit
    final_gdf.to_postgis('phase_1_trace_umap',conn, schema='redadeg', if_exists='append')


    # purger
    del combined_gdf
    del exploded_gdf
    del work_gdf

    logging.info("fait")

    pass




def run_phase1(millesime):
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
    db_name = f"redadeg_{millesime}"
    schema = 'redadeg'

    # création d'une connexion qui sera partagée
    engine = create_engine(
        f"postgresql://{db_user}@{db_host}:{db_port}/{db_name}"
        , isolation_level="AUTOCOMMIT"
    )
    conn = engine.connect()
    logging.debug(f"connexion à la base de données {db_name} : ok")

    get_umap_data(conn)

    conn.close()

    # chrono final
    final_chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps total phase 1 : {final_chrono}")
    logging.info("")

    pass
