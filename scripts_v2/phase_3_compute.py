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
print(" Calcul des PK pour le secteur " + str(secteur) + " pour le millésime " + str(millesime))
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

    # ------------------------------------------------------
    print("  Récupération des infos du secteur")

    sql_get_infos_secteur = "SELECT pk_start, pk_stop, node_start, node_stop, longueur "
    sql_get_infos_secteur += "FROM secteur "
    sql_get_infos_secteur += "WHERE id = " + secteur + " ;"

    db_redadeg_cursor.execute(sql_get_infos_secteur)
    infos_secteur = db_redadeg_cursor.fetchone()

    secteur_pk_start = infos_secteur[0]
    secteur_pk_stop = infos_secteur[1]
    secteur_node_start = infos_secteur[2]
    secteur_node_stop = infos_secteur[3]
    secteur_longueur = infos_secteur[4]
    # pour test
    # secteur_longueur = 10000

    print("  fait")
    print("")

    # on détermine le nb théorique de PK pour ce secteur
    secteur_nb_pk = (secteur_pk_stop - secteur_pk_start) + 1
    # et ainsi la longueur réelle entre chaque PK
    longueur_decoupage = math.ceil(secteur_longueur / secteur_nb_pk)

    print("  " + str(secteur_nb_pk) + " KM redadeg de " + str(longueur_decoupage) + " m vont être créés")
    print("  pour une longeur réelle de " + '{:,}'.format(secteur_longueur).replace(',', ' ') + " m")
    print("")

    # ------------------------------------------------------
    print("  Suppression des PK du secteur")

    sql_delete_pks = f"DELETE FROM phase_3_pk WHERE secteur_id = {secteur} ;"
    db_redadeg_cursor.execute(sql_delete_pks)
    print("  fait")
    print("")

    # ------------------------------------------------------
    print("  Création des nouveaux PK du secteur tous les " + str(longueur_decoupage) + " m")

    sql_generate_pks = f"""
WITH linemeasure AS (
  WITH line AS (
  -- on récupère un itinéraire calculée par pgRouting
  SELECT ST_Union(the_geom) AS the_geom
  FROM pgr_drivingDistance('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr 
  WHERE SOURCE IS NOT NULL AND secteur_id = {secteur}',
  {secteur_node_start},{secteur_longueur}) a
  JOIN phase_3_troncons_pgr b ON a.edge = b.id 
  )
SELECT
  generate_series(0, (ST_Length(line.the_geom))::int, {longueur_decoupage}) AS i,
  ST_AddMeasure(the_geom,0,ST_length(the_geom)) AS the_geom
FROM line
)
INSERT INTO phase_3_pk (pk_id,secteur_id,length_real,length_total,the_geom)
SELECT
  ROW_NUMBER() OVER() + ({secteur_pk_start}-1)
  ,{secteur}
  ,{longueur_decoupage}
  ,i
  ,ST_Force_2D((ST_Dump(ST_GeometryN(ST_LocateAlong(the_geom, i), 1))).geom) AS the_geom
FROM linemeasure ;
"""

    db_redadeg_cursor.execute(sql_generate_pks)
    print("  fait")
    print("")

    # ------------------------------------------------------
    print("  sauvegarde de la longueur de découpage pour ce secteur")
    sql_update_secteur = "UPDATE secteur SET longueur_km_redadeg = " + str(longueur_decoupage)
    sql_update_secteur += f"WHERE id = {secteur} ;"
    db_redadeg_cursor.execute(sql_update_secteur)
    print("  fait")
    print("")


    db_redadeg_cursor.close()

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


