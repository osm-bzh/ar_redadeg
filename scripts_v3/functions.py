import configparser
import logging
import requests
from shapely.geometry import LineString

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


# ==============================================================================

def get_configuration():
    # lecture du fichier de configuration qui contient les infos de connection
    logging.debug("lecture du fichier de configuration")

    config = configparser.ConfigParser()
    config.read('config.ini', encoding='utf-8')

    logging.debug("fait\n")

    return config


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

