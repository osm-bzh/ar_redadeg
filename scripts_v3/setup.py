

import sys
import argparse
import logging
import time

import functions

def setup_db_redadeg(millesime):
    logging.info(f"")
    start_time = time.perf_counter()

    logging.info(f"Création d'une base de données pour le millésime {millesime}.")

    # lecture du fichier de configuration
    config = functions.get_configuration()
    # définition des variables
    db_host = config.get('database', 'host')
    db_port = config.get('database', 'port')
    db_user = config.get('database', 'user')
    db_name = f"redadeg_{millesime}"
    schema = 'redadeg'

    from sqlalchemy import create_engine, text
    from sqlalchemy.orm import Session

    # Créer une connexion SQLAlchemy
    engine = create_engine(
        f"postgresql://{db_user}@{db_host}:{db_port}/postgres"
    )

    # on crée une session pour commiter manuellement
    session = Session(engine)

    # 1 : suppression de la base de données
    try:
        del_db_sql = f"DROP DATABASE IF EXISTS redadeg_{millesime} ;"
        session.execute(text(del_db_sql))
        session.commit()
        logging.info(f"Base de données redadeg_{millesime} supprimée avec succès")

    except Exception as e:
        print(f"Impossible de supprimer la base de données redadeg_{millesime} : {e}")

    # nettoyage
    session.close()

    time.sleep(1)

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

