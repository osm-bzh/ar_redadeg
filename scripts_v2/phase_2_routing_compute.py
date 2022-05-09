#!/usr/bin/python
# -*- coding: utf-8 -*-

#
# Libraries
#

import os
import sys
import datetime
import time
import configparser
import psycopg2
import math

# from logguer import log_verif


# ==============================================================================

# répertoire courant
script_dir = os.path.dirname(os.path.abspath(__file__))

# jour courant
date = datetime.datetime.now()

# lecture du fichier de configuration qui contient les infos de connection
config = configparser.ConfigParser()
config.read(script_dir + '/config.ini')

# fichier_log = str(date.year)+str(date.month)+str(date.day)+"_"+str(date.hour)+str(date.minute)
fichier_log = str(date.year) + str(date.month) + str(date.day)


# ==============================================================================

def initConnRedadegDB():
    # connexion à la base postgresql
    try:
        global db_redadeg_pg_conn
        db_redadeg_pg_conn = psycopg2.connect(db_redadeg_conn_str)
        db_redadeg_pg_conn.set_session(autocommit=True)

        print("  Connexion à la base " + db_redadeg_db + " sur " + db_redadeg_host + " réussie ")


    except Exception as err:
        print("  Connexion à la base " + db_redadeg_db + " sur " + db_redadeg_host + " impossible ")
        try:
            err.pgcode
            print("  PostgreSQL error code : " + err.pgcode)
            sys.exit()
        except:
            print("  " + str(err), 0)
            sys.exit()


# ==============================================================================

def closeConnRedadegDB():
    try:
        db_redadeg_pg_conn.close()
        print("  Fermeture de la connexion à la base " + db_redadeg_db + " sur " + db_redadeg_host)
    except:
        pass


# ==============================================================================


# ==============================================================================
# ==============================================================================
# ==============================================================================
# Start processing
#

startTime = time.perf_counter()

# on récupère les arguments passés
list_of_args = sys.argv

millesime = ""
secteur = ""
typemaj = ""

# et on fait des tests

try:
    if len(list_of_args[1]) != 4:
        print("Pas de millésime en argument")
        sys.exit()
    else:
        millesime = list_of_args[1]

        # millesime ok : on passe au secteur
        if len(list_of_args[2]) != 3:
            print("Pas d'id secteur en argument")
            sys.exit()
        else:
            secteur = list_of_args[2]

            # ok : tout est bon on peut commencer
            # sortie des tests


except SystemExit:
    print("Erreur dans les arguments --> stop")
    sys.exit()
except:
    print("oups : vérifiez vos arguments passés au script !")
    print("stop")
    sys.exit()

print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("")
print(f" Calcul d'un l'itinéraire pour le secteur {secteur} pour le millésime {millesime}")
print("")

print(" Lecture du fichier de configuration ")
print("")

# BD Ar Redadeg
global db_redadeg_host
global db_redadeg_db
db_redadeg_host = config.get('redadeg_database', 'host')
db_redadeg_port = config.get('redadeg_database', 'port')
db_redadeg_db = config.get('redadeg_database', 'db') + "_" + str(millesime)
db_redadeg_user = config.get('redadeg_database', 'user')
db_redadeg_passwd = config.get('redadeg_database', 'passwd')
# chaîne de connection
global db_redadeg_conn_str
db_redadeg_conn_str = "host=" + db_redadeg_host + " port=" + db_redadeg_port + " dbname=" + db_redadeg_db + " user=" + db_redadeg_user + " password=" + db_redadeg_passwd

initConnRedadegDB()

# le cursor
db_redadeg_cursor = db_redadeg_pg_conn.cursor()

print("")

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

try:

    print(f"  vidage de la couche de routage pour le secteur {secteur}")
    sql_truncate_secteur = f"DELETE FROM phase_2_trace_pgr WHERE secteur_id = {secteur} ;"
    db_redadeg_cursor.execute(sql_truncate_secteur)
    print("  fait")

    #

    print("  Recherche du node_id du PK de début et du node_id du PK de fin")
    sql_get_nodes = """
SELECT id, secteur_id, pgr_node_id 
FROM phase_2_pk_secteur 
WHERE secteur_id >= 900
ORDER BY id
LIMIT 2;"""
    db_redadeg_cursor.execute(sql_get_nodes)
    start_node = db_redadeg_cursor.fetchone()[2]
    end_node = db_redadeg_cursor.fetchone()[2]
    # print(start_node, end_node)
    print("  fait")

    #

    print(f"  calcul d'un itinéraire entre les nœuds {start_node} et {end_node}")
    sql_route = f"""
INSERT INTO phase_2_trace_pgr
SELECT
  {secteur} AS secteur_id,
  -- info de routage
  a.path_seq,
  a.node,
  a.cost,
  a.agg_cost,
  -- infos OSM
  b.osm_id,
  b.highway,
  b."type",
  b.oneway,
  b.ref,
  CASE
  WHEN b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
ELSE b.name_fr
  END AS name_fr,
  CASE
  WHEN b.name_br IS NULL AND b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
WHEN b.name_br IS NULL AND b.name_fr IS NOT NULL THEN '# da dreiñ e brezhoneg #'
ELSE b.name_br
  END AS name_br,
  b.the_geom
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr', {start_node}, {end_node}) as a
JOIN osm_roads_pgr b ON a.edge = b.id ;"""

    db_redadeg_cursor.execute(sql_route)

    # ménage pour les performances
    db_redadeg_cursor.execute("VACUUM FULL phase_2_trace_pgr ;")

    # on fait une requête pour voir la longueur insérée
    # en fait : la longueur totale - la longueur totale lors du précédent calcul
    sql_controle = f"""
SELECT 
  CASE 
    WHEN trunc(SUM(ST_Length(the_geom))/1000) IS NULL THEN 0
    ELSE trunc(SUM(ST_Length(the_geom))/1000)
  END AS longueur
FROM phase_2_trace_pgr WHERE secteur_id = {secteur};"""

    db_redadeg_cursor.execute(sql_controle)
    result_controle = db_redadeg_cursor.fetchone()

    if result_controle == 0:
        print("  >>> aucun itinéraire n'a pu être calculé <<<")
        print("STOP")
        sys.exit(1)
    else:
        print(f"  fait : {result_controle[0]} km calculés pour le secteur {secteur}")

    #

    print("")

except Exception as err:
    print("  ERREUR : " + str(err))
    closeConnRedadegDB()
    sys.exit()

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

db_redadeg_cursor.close()

closeConnRedadegDB()

# pour connaître le temps d'exécution
print("")
print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("F I N")
print("")

stopTime = time.perf_counter()

# version simple en secondes
# print(f"Exécuté en {stopTime - startTime:0.4f} secondes")

# version en h min s
hours, rem = divmod(stopTime - startTime, 3600)
minutes, seconds = divmod(rem, 60)
print("Exécuté en {:0>2}:{:0>2}:{:05.2f}".format(int(hours), int(minutes), seconds))


