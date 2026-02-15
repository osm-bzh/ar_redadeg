

import sys
import argparse
import logging
import time

import functions

def setup_db_redadeg(millesime):
    logging.info(f"")
    start_time = time.perf_counter()

    # lecture du fichier de configuration
    config = functions.get_configuration()
    # définition des variables
    db_host = config.get('database', 'host')
    db_port = config.get('database', 'port')
    db_user = config.get('database', 'user')
    db_name = f"redadeg_{millesime}"
    schema = 'redadeg'

    logging.info(f"ATTENTION : la base de données {db_name} sur {db_host} va être supprimée !")
    logging.info(f"TOUTES les données seront supprimées !")

    while True:
        response = input("Voulez-vous continuer ? (oui/non) : ").strip().lower()
        if response == "oui":
            break
        elif response == "non":
            logging.info("ok : fin")
            exit(0)
        else:
            logging.info("Veuillez répondre par 'oui' ou 'non'.")


    logging.info("")

    # on continue
    logging.info(f"Création d'une base de données pour le millésime {millesime}.")

    from sqlalchemy import create_engine, text

    # Créer une connexion SQLAlchemy
    # dans la base postgres
    engine = create_engine(
        f"postgresql://{db_user}@{db_host}:{db_port}/postgres"
        ,isolation_level="AUTOCOMMIT"
    )

    with engine.connect() as conn:
        # 1 : fermeture des connexions la base de données
        try:
            close_conn_sql  = f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity\n"
            close_conn_sql += f"WHERE datname = '{db_name}' AND leader_pid IS NULL;"
            conn.execute(text(close_conn_sql))
            logging.info(f"Fermeture des connexions à la base")
        except Exception as e:
            logging.error(f"Impossible de supprimer la base de données {db_name} : {e}")
            sys.exit(1)

        # 2 : suppression de la base de données
        try:
            delete_db_sql = f"DROP DATABASE IF EXISTS {db_name} ;"
            conn.execute(text(delete_db_sql))
            logging.info(f"Base de données {db_name} supprimée avec succès")
        except Exception as e:
            logging.error(f"Impossible de supprimer la base de données {db_name} : {e}")
            sys.exit(1)

        # 3 : création de la base de données
        try:
            create_db_sql = f"CREATE DATABASE {db_name} WITH OWNER = {db_user} ENCODING = 'UTF8';"
            conn.execute(text(create_db_sql))
            logging.info(f"Base de données {db_name} créée avec succès")
        except Exception as e:
            logging.error(f"Impossible de créer la base de données {db_name} : {e}")
            sys.exit(1)

    del engine

    #

    # on passe maintenant dans la base qui vient d'être créée
    engine = create_engine(
        f"postgresql://{db_user}@{db_host}:{db_port}/{db_name}"
        , isolation_level="AUTOCOMMIT"
    )

    with engine.connect() as conn:
        # extensions
        try:
            sql_extensions =  f"CREATE EXTENSION postgis;"
            sql_extensions += f"CREATE EXTENSION postgis_topology;"
            sql_extensions += f"CREATE EXTENSION pgrouting;"
            conn.execute(text(sql_extensions))
            logging.info(f"Extensions créées avec succès")
        except Exception as e:
            logging.error(f"Impossible de créer les extensions : {e}")
            sys.exit(1)

        # schéma
        try:
            sql_schema= f"CREATE SCHEMA {schema} AUTHORIZATION {db_user};"
            conn.execute(text(sql_schema))
            logging.info(f"Schéma {schema} créé avec succès")
        except Exception as e:
            logging.error(f"Impossible de créer le schéma : {e}")
            sys.exit(1)

        # permissions spécifiques
        try:
            sql_permissions =  f"ALTER TABLE topology.layer OWNER TO {db_user};"
            sql_permissions += f"ALTER TABLE topology.topology OWNER TO {db_user};"
            conn.execute(text(sql_permissions))
            logging.info(f"Permissions spécifiques appliquées avec succès")
        except Exception as e:
            logging.error(f"Problèmes avec les permissions spécifiques : {e}")
            sys.exit(1)

        # création des tables
        try:
            sql_tables = open('sql/create_tables.sql', 'r').read()
            conn.execute(text(sql_tables))
            logging.info(f"Tables crées avec succès")
        except Exception as e:
            logging.error(f"Problèmes avec la création des tables : {e}")
            sys.exit(1)

    logging.info("")
    logging.info("F I N")

    # chrono final
    chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps écoulé : {chrono}")
    logging.info("")


# ==================================================================================================

def setup_referentiel_communal(millesime):
    logging.info(f"")
    start_time = time.perf_counter()

    # lecture du fichier de configuration
    config = functions.get_configuration()
    # définition des variables
    db_host = config.get('database', 'host')
    db_port = config.get('database', 'port')
    db_user = config.get('database', 'user')
    db_name = f"redadeg_{millesime}"
    schema = 'redadeg'

    logging.info(f"ATTENTION : le référentiel communal va être mise à jour dans la base {db_name} sur {db_host} !")
    logging.info(f"")

    # on s'assure que le répertoire pour les fichiers temporaires existe
    if not functions.verify_path_existence('tmp_files'):
        functions.ensure_directory('tmp_files')

    # des fonctions

    from pathlib import Path

    def get_single_gpkg_file(directory='tmp_files'):
        """
        Liste les fichiers .gpkg dans le répertoire.
        Lève une erreur si 0 ou plus de 1 fichier existe.

        Returns:
            Path: Le chemin du fichier .gpkg unique
        """
        gpkg_files = list(Path(directory).glob('*.gpkg'))

        if len(gpkg_files) == 0:
            raise FileNotFoundError(f"❌ Aucun fichier .gpkg trouvé dans le répertoire '{directory}/'")

        if len(gpkg_files) > 1:
            files_list = '\n  - '.join([f.name for f in gpkg_files])
            raise ValueError(
                f"❌ Plusieurs fichiers .gpkg trouvés dans '{directory}' :\n  - {files_list}"
            )

        return gpkg_files[0]

    def load_pkg_to_postgis(gpkg_file):

        # lecture du fichier de configuration
        config = functions.get_configuration()
        # définition des variables
        db_host = config.get('database', 'host')
        db_port = config.get('database', 'port')
        db_user = config.get('database', 'user')
        db_name = f"redadeg_{millesime}"
        schema = 'redadeg'

        ogr2ogr_cmd = [
            'ogr2ogr',
            '-f', 'PostgreSQL',
            f'PG:host={db_host} port={db_port} dbname={db_name} user={db_user}',
            '-nln', 'communes_ign',
            '-lco', 'GEOMETRY_NAME=geom',
            '-lco', 'FID=gid',
            '-t_srs', 'EPSG:2154',
            '-overwrite',
            str(gpkg_file),
            'commune'
        ]

        try:
            import subprocess
            subprocess.call(ogr2ogr_cmd)
        except Exception as e:
            logging.error(f"  ❌ {e}")
            sys.exit(1)

    def process_gpkg():
        try:
            # Récupérer le fichier unique
            gpkg_file = get_single_gpkg_file('tmp_files')
            # Utiliser le fichier
            # print(f"Traitement de : {gpkg_file}")
            # print(f"Nom du fichier : {gpkg_file.name}")
            # print(f"Chemin complet : {gpkg_file.absolute()}")
            logging.info(f"  ✅ le fichier {gpkg_file} a été trouvé")

            logging.info(f"  Chargement de la couche des communes dans la base de données…")
            load_pkg_to_postgis(gpkg_file)
            logging.info(f"  ✅ fait !")

            # TODO

        except FileNotFoundError as e:
            logging.error(f"{e}")
            sys.exit(1)
        except ValueError as e:
            logging.error(f"{e}")
            sys.exit(1)


    logging.info(f"Traitement du Geopackage ADMIN EXPRESS")
    process_gpkg()


    #
    logging.info(f"")

    logging.info(f"Test de la présence du fichier open data de Kerofis")

    #

    # on va regarder dans le répertoire des fichiers temporaires si on a un
    logging.info(f"")

    #

    logging.info("")
    logging.info("F I N")

    # chrono final
    chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps écoulé : {chrono}")
    logging.info("")


# ==================================================================================================

def main():

    parser = argparse.ArgumentParser(description="Initialisation d'un millésime Ar Redadeg.")
    parser.add_argument("--millesime", type=int, required=True, help="Millésime du projet (année).")
    parser.add_argument("--db", action='store_true', help="Configure la base de données.")
    parser.add_argument("--ref_communal", action='store_true', help="Met à jour le référentiel communal.")
    parser.add_argument("--debug", action='store_true', help="si 'oui' : mode verbeux pour voir plus de messages")

    args = parser.parse_args()

    # par défaut
    log_level = logging.INFO
    log_format = '%(message)s'

    # on regarde les arguments passés

    if '--help' in sys.argv:
        parser.print_help()
        sys.exit(0)
    if '--debug' in sys.argv:
        log_level = logging.DEBUG
        # log_format = '%(asctime)s [%(levelname)-7s] %(message)s'
        # log_format = '%(levelname)s: %(message)s'
        log_format = '%(message)s'

    # =========================================
    # configuration du logguer
    logging.basicConfig(
        level=log_level,
        format=log_format,
    )

    # test mode debug
    logging.debug("\n/!\ Le script va s'exécuter en mode verbeux\n")

    # welcome message
    logging.info("""
    _           ____          _           _            
   / \   _ __  |  _ \ ___  __| | __ _  __| | ___  __ _ 
  / _ \ | '__| | |_) / _ \/ _` |/ _` |/ _` |/ _ \/ _` |
 / ___ \| |    |  _ <  __/ (_| | (_| | (_| |  __/ (_| |
/_/   \_\_|    |_| \_\___|\__,_|\__,_|\__,_|\___|\__, |
                                                 |___/ 
    """)

    # on regarde ce qui est demandé
    if '--db' in sys.argv:
        logging.info(f"Une base de donnée pour le millésime {args.millesime} va être créée.")
        setup_db_redadeg(args.millesime)
    elif '--ref_communal' in sys.argv:
        logging.info(f"Le référentiel communal va être implanté.")
        setup_referentiel_communal(args.millesime)
    else:
        logging.error(f"Aucune demande faite !")

if __name__ == "__main__":
    main()

