import os
import datetime

# module et classe permettant de partager des variables entre tous les modules

class SharedData:

    log_level = None
    debug_mode = None

    erreur_critique = None
    err_log_str = ""

    sqlalchemy_conn = None
    psycopg2_conn = None

    # répertoire courant
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # date du jour
    date = datetime.datetime.now()

    db_schema = ''
    millesime = 0
    secteur = 0
