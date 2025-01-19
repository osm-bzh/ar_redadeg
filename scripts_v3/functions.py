
import configparser
import logging


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

    logging.debug("fait")

    return config

# ==============================================================================
