

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

    logging.info(f"ATTENTION : la base de données {db_name} va être supprimée !")
    logging.info(f"TOUTES les données seront supprimées !")

    while True:
        response = input("Voulez-vous continuer ? (oui/non) : ").strip().lower()
        if response == "oui":
            break
        elif response == "non":
            print("ok : fin")
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
            print(f"Impossible de supprimer la base de données {db_name} : {e}")
            sys.exit(1)

        # 2 : suppression de la base de données
        try:
            delete_db_sql = f"DROP DATABASE IF EXISTS {db_name} ;"
            conn.execute(text(delete_db_sql))
            logging.info(f"Base de données {db_name} supprimée avec succès")
        except Exception as e:
            print(f"Impossible de supprimer la base de données {db_name} : {e}")
            sys.exit(1)

        # 3 : création de la base de données
        try:
            create_db_sql = f"CREATE DATABASE {db_name} WITH OWNER = {db_user} ENCODING = 'UTF8';"
            conn.execute(text(create_db_sql))
            logging.info(f"Base de données {db_name} créée avec succès")
        except Exception as e:
            print(f"Impossible de créer la base de données {db_name} : {e}")
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
            print(f"Impossible de créer les extensions : {e}")
            sys.exit(1)

        # schéma
        try:
            sql_schema= f"CREATE SCHEMA {schema} AUTHORIZATION {db_user};"
            conn.execute(text(sql_schema))
            logging.info(f"Schéma {schema} créé avec succès")
        except Exception as e:
            print(f"Impossible de créer le schéma : {e}")
            sys.exit(1)

        # permissions
        try:
            sql_permissions =  f"ALTER TABLE topology.layer OWNER TO {db_user};"
            sql_permissions += f"ALTER TABLE topology.topology OWNER TO {db_user};"
            conn.execute(text(sql_permissions))
            logging.info(f"Permissions appliquées avec succès")
        except Exception as e:
            print(f"Problèmes avec les permissions : {e}")
            sys.exit(1)

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
    parser.add_argument("--debug", type =str, required=False, choices=['oui'], help="si 'oui' : mode verbeux pour voir plus de messages")

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

    setup_db_redadeg(args.millesime)

if __name__ == "__main__":
    main()

