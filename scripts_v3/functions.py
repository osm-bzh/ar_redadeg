import sys
import os
import shutil
import logging
import requests
import configparser
from sqlalchemy import create_engine
import psycopg2
from shapely.geometry import LineString

# import du module permettant de partager des variables entre tous les modules
from shared import SharedData


# ==============================================================================

def get_chrono_hms(start_time, stop_time):
    # version en h min s
    hours, rem = divmod(stop_time - start_time, 3600)
    minutes, seconds = divmod(rem, 60)

    elapsed_time = "{:0>2}:{:0>2}:{:05.2f}".format(int(hours), int(minutes), seconds)
    return elapsed_time


# ==============================================================================

def get_chrono(start_time, stop_time):
    # Calcul du temps écoulé
    total_seconds = stop_time - start_time
    minutes, seconds = divmod(total_seconds, 60)

    # Formatage uniquement en minutes et secondes
    elapsed_time = "{:02}:{:02}".format(int(minutes), int(seconds))
    return elapsed_time


# ====================================================================================================================

def get_configuration():
    # lecture du fichier de configuration qui contient les infos de connection
    # logging.debug("lecture du fichier de configuration")

    config = configparser.ConfigParser()
    config.read('config.ini', encoding='utf-8')

    # logging.debug("fait")

    return config


# ====================================================================================================================

def ensure_directory(directory_path):
    """
    Ensure that a directory exists. If it exists, delete it and all its contents.
    Then, create the directory.

    :param directory_path: Path to the directory.
    """
    if os.path.exists(directory_path):
        # Delete the directory and all its contents
        shutil.rmtree(directory_path)
        logging.debug(f"  Directory '{directory_path}' and all its contents have been deleted.")

    # Create the directory
    os.makedirs(directory_path)
    logging.debug(f"  Directory '{directory_path}' has been created.")


# ====================================================================================================================

def clear_directory(directory_path):
    """
    Ensure that a directory is cleared of all contents except specified files.
    If it exists, delete all its contents except files listed in the exclusion list.
    The directory itself is not deleted.

    :param directory_path: Path to the directory.
    """
    # List of files to exclude from deletion
    exclusion_list = ["A LIRE.txt", "_A LIRE.txt", "A LIRE.md", "_A LIRE.md", "README.md"]

    if os.path.exists(directory_path):
        # Iterate over all the items in the directory
        for filename in os.listdir(directory_path):
            file_path = os.path.join(directory_path, filename)
            try:
                # Check if the file is not in the exclusion list before deletion
                if filename not in exclusion_list:
                    if os.path.isfile(file_path) or os.path.islink(file_path):
                        os.unlink(file_path)
                    elif os.path.isdir(file_path):
                        shutil.rmtree(file_path)
            except Exception as e:
                logging.error(f"Failed to delete {file_path}. Reason: {e}")

        logging.debug(f"All contents of directory '{directory_path}' have been deleted except for {exclusion_list}.")
    else:
        # Optionally, create the directory if it doesn't exist
        os.makedirs(directory_path)
        logging.debug(f"Directory '{directory_path}' did not exist and has been created.")


# ====================================================================================================================

def init_conn_database_sql_alchemy():
    # connexion à la base PostgreSQL
    # definit une connexion partagée dans la classe SharedData

    config = get_configuration()
    target_host = config.get('target_database', 'host')
    target_port = config.get('target_database', 'port')
    target_db = config.get('target_database', 'db')
    target_user = config.get('target_database', 'user')

    # création d'une connexion qui sera partagée
    engine = create_engine(
        f"postgresql://{target_user}@{target_host}:{target_port}/{target_db}",
        isolation_level="AUTOCOMMIT"
    )

    try:
        # stockage de la connection dans une variable partagée
        SharedData.sqlalchemy_conn = engine.connect()
        logging.debug(f"Connexion à la base de données {target_db} : ok (SQLAlchemy)")
        logging.debug("")

    except Exception as e:
        logging.error(f"impossible de se connecter à la base de données {target_db} :\n{e}")
        sys.exit(1)


# ====================================================================================================================

def close_conn_database_sql_alchemy():
    # fermeture de la connexion à la base PostgreSQL

    try:
        SharedData.sqlalchemy_conn.close()
        logging.debug(f"Fermeture de la connexion à la base réussie : ok (SQLAlchemy)")
        logging.debug("")
    except Exception as e:
        logging.error(f"impossible de se déconnecter de la base de données :\n{e}")
        pass


# ====================================================================================================================

def init_conn_database_psycopg2():
    # connexion à la base PostgreSQL
    # definit une connexion partagée dans la classe SharedData

    config = get_configuration()
    target_host = config.get('target_database', 'host')
    target_port = config.get('target_database', 'port')
    target_db = config.get('target_database', 'db')
    target_user = config.get('target_database', 'user')

    # création d'une connexion qui sera partagée
    pg_target_conn_str = f"host={target_host} port={target_port} dbname={target_db} user={target_user}"

    try:
        SharedData.psycopg2_conn = psycopg2.connect(pg_target_conn_str)
        SharedData.psycopg2_conn.set_session(autocommit=True)

        logging.debug(f"Connexion à la base de données {target_db} : ok (psycopg2)")
        logging.debug("")

    except Exception as e:
        logging.error(f"impossible de se connecter à la base de données {target_db} :\n{e}")
        sys.exit(1)


# ====================================================================================================================

def close_conn_database_psycopg2():
    # fermeture de la connexion à la base PostgreSQL

    try:
        SharedData.psycopg2_conn.close()
        logging.debug(f"Fermeture de la connexion à la base réussie : ok (psycopg2)")
        logging.debug("")
    except Exception as e:
        logging.error(f"impossible de se déconnecter de la base de données :\n{e}")
        pass


# ====================================================================================================================

def print_psycopg2_exception(err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occurred
    line_num = traceback.tb_lineno

    # print the connect() error
    logging.error(f"  PostgreSQL ERREUR !")
    logging.error(f"  PG error code : {err.pgcode}")
    logging.error(f"  PG error message : {err.pgerror} ligne {line_num}")

    pass


# ====================================================================================================================

def verify_file_existence(file_path: str):
    logging.debug(f"      vérification si {file_path} existe")

    from pathlib import Path

    file_test = Path(file_path)
    if file_test.is_file():
        logging.debug(f"        le fichier existe")
        return True
    else:
        logging.debug(f"        le fichier n'existe pas")
        return False


# ====================================================================================================================

def verify_path_existence(dir_path: str):
    logging.debug(f"      vérification si {dir_path} existe")

    from pathlib import Path

    dir_test = Path(dir_path)
    if dir_test.is_dir():
        logging.debug(f"        le répertoire existe")
        return True
    else:
        logging.debug(f"        le répertoire n'existe pas")
        return False


# ==============================================================================

def save_url_content_to_file(url, file_path):
    try:
        # Effectuer une requête GET pour obtenir le contenu de l'URL
        response = requests.get(url)

        # Vérifier si la requête a réussi
        response.raise_for_status()

        # Écrire le contenu dans un fichier texte
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(response.text)

        logging.debug(f"Contenu de l'URL sauvegardé dans {file_path}\n")

    except requests.exceptions.RequestException as e:
        print(f"Erreur lors de la récupération du contenu de l'URL : {e}")


# ==============================================================================

def to_2d(geom):
    # Fonction pour convertir une LineString Z en LineString 2D

    if geom.is_empty:
        return geom
    if geom.has_z:
        return LineString([xy[:2] for xy in geom.coords])
    return geom

# ==============================================================================

