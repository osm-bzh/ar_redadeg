
import sys
import argparse
import logging

from phase1 import run_phase1
from phase2 import run_phase2
from shared_data import SharedData


# ==================================================================================================

def main():

    parser = argparse.ArgumentParser(description="Gestion des phases d'un projet.")
    parser.add_argument("--millesime", type=int, required=True, help="Millésime du projet (année).")
    parser.add_argument("--phase", type=int, required=True, choices=[1, 2], help="Phase du projet.")
    parser.add_argument("--debug", action='store_true', help="si 'oui' : mode verbeux pour voir plus de messages")


    args = parser.parse_args()

    # par défaut
    log_level = logging.INFO
    log_format = '%(message)s'
    # pour request
    logging.getLogger("urllib3").setLevel(logging.WARNING)

    # on regarde les arguments passés

    if '--help' in sys.argv:
        parser.print_help()
        sys.exit(0)
    if '--debug' in sys.argv:
        SharedData.debug_mode = True
        log_level = logging.DEBUG
        # log_format = '%(asctime)s [%(levelname)-7s] %(message)s'
        # log_format = '%(levelname)s: %(message)s'
        log_format = '%(message)s'
        # pour request
        logging.getLogger("urllib3").setLevel(logging.DEBUG)

    # =========================================
    # configuration du logguer
    logging.basicConfig(
        level=log_level,
        format=log_format,
    )

    # test mode debug
    logging.debug("\n/!\ Le script va s'exécuter en mode verbeux")

    # welcome message
    logging.info("""
    _           ____          _           _            
   / \   _ __  |  _ \ ___  __| | __ _  __| | ___  __ _ 
  / _ \ | '__| | |_) / _ \/ _` |/ _` |/ _` |/ _ \/ _` |
 / ___ \| |    |  _ <  __/ (_| | (_| | (_| |  __/ (_| |
/_/   \_\_|    |_| \_\___|\__,_|\__,_|\__,_|\___|\__, |
                                                 |___/ 
    """)


    if args.phase == 1:
        # logging.info(f"Exécution de la phase 1 pour le millésime {args.millesime}.")
        run_phase1(args.millesime)
    elif args.phase == 2:
        # logging.info(f"Exécution de la phase 2 pour le millésime {args.millesime}.")
        run_phase2(args.millesime)

    logging.info("")
    logging.info("F I N")

if __name__ == "__main__":
    main()