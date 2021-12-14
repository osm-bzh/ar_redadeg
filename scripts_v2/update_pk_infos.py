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
#from logguer import log_verif


# ==============================================================================

# répertoire courant
script_dir = os.path.dirname(os.path.abspath(__file__))

# jour courant
date = datetime.datetime.now()

# lecture du fichier de configuration qui contient les infos de connection
config = configparser.ConfigParser()
config.read( script_dir + '/config.ini')



#fichier_log = str(date.year)+str(date.month)+str(date.day)+"_"+str(date.hour)+str(date.minute)
fichier_log = str(date.year)+str(date.month)+str(date.day)


# ==============================================================================

def initConnRedadegDB():

  # connexion à la base postgresql
  try:
    global db_redadeg_pg_conn
    db_redadeg_pg_conn = psycopg2.connect(db_redadeg_conn_str)
    db_redadeg_pg_conn.set_session(autocommit=True)

    print("  Connexion à la base "+db_redadeg_db+" sur "+db_redadeg_host+" réussie ")


  except Exception as err:
    print("  Connexion à la base "+db_redadeg_db+" sur "+db_redadeg_host+ " impossible ")
    try:
      err.pgcode
      print("  PostgreSQL error code : " + err.pgcode)
      sys.exit()
    except:
      print("  " + str(err),0)
      sys.exit()


# ==============================================================================

def closeConnRedadegDB():

  try:
    db_redadeg_pg_conn.close()
    print("  Fermeture de la connexion à la base "+db_redadeg_db+" sur "+db_redadeg_host)
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

        # millesime ok : maintenant on teste la phase demandée
        if len(list_of_args[2]) != 1:
            print("Pas d'id phase en argument")
            sys.exit(1)
        else:
            test = list_of_args[2]
            if test == "3" or test == "5":
                phase = "phase_"+test
            else:
                print("Mauvais id en argument")
                sys.exit(1)

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
print(f" Mise à jour des informations OSM des PK pour le millésime {str(millesime)} et la phase {phase}")
print("")

print("  Lecture du fichier de configuration ")
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

    print("  Mise à jour des informations sur les géométries")

    sql_update_infos_geom = f"""
UPDATE {phase}_pk
SET
  pk_x = sub.x ,
  pk_y = sub.y ,
  pk_long = sub.long ,
  pk_lat = sub.lat
FROM (
  SELECT
    pk_id
    ,trunc(st_x(the_geom)::numeric,2) AS x
    ,trunc(st_y(the_geom)::numeric,2) AS y
    ,trunc(st_x(st_transform(the_geom,4326))::numeric,8) AS long
    ,trunc(st_y(st_transform(the_geom,4326))::numeric,8) AS lat
  FROM {phase}_pk
  ORDER BY pk_id 
) sub
WHERE {phase}_pk.pk_id = sub.pk_id ;"""

    db_redadeg_cursor.execute(sql_update_infos_geom)
    print("  fait")


    print("  Mise à jour des informations sur les voies")

    sql_update_infos_ways = f"""
UPDATE {phase}_pk
SET
  way_osm_id = sub.osm_id ,
  way_highway = sub.highway ,
  way_type = sub."type" ,
  way_oneway = sub.oneway ,
  way_ref = sub."ref" ,
  way_name_fr = sub.name_fr ,
  way_name_br = sub.name_br
FROM (
  SELECT
   pk.pk_id,
   t.osm_id, t.highway, t."type", t.oneway, t."ref", t.name_fr, t.name_br 
  FROM {phase}_pk pk, phase_3_troncons_pgr t
  WHERE ST_INTERSECTS(ST_BUFFER(pk.the_geom,1), t.the_geom)
  ORDER BY pk_id 
) sub
WHERE {phase}_pk.pk_id = sub.pk_id;"""

    db_redadeg_cursor.execute(sql_update_infos_ways)
    print("  fait")



    print("  Mise à jour des informations sur les communes")

    sql_update_infos_communes = f"""
UPDATE {phase}_pk
SET
  municipality_admincode = sub.insee ,
  municipality_name_fr = sub.name_fr ,
  municipality_name_br = sub.name_br
FROM (
  SELECT
   pk.pk_id,
   com.insee,
   com.name_fr,
   com.name_br
  FROM {phase}_pk pk, osm_communes com
  WHERE ST_INTERSECTS(pk.the_geom, com.the_geom)
  ORDER BY pk_id 
) sub
WHERE {phase}_pk.pk_id = sub.pk_id;"""

    db_redadeg_cursor.execute(sql_update_infos_communes)
    print("  fait")


    print("")
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

