
import logging
import time

import functions


def run_phase1(millesime):
    logging.info(f"")
    start_time = time.perf_counter()

    logging.info(f"Phase 1 en cours pour le millésime {millesime}. Complétez cette fonction avec le code spécifique à la phase 1.")

    # lecture du fichier de configuration
    config = functions.get_configuration()

    time.sleep(3)

    # chrono final
    final_chrono = functions.get_chrono(start_time, time.perf_counter())
    logging.info(f"Temps phase 1 : {final_chrono}")
    logging.info("")
