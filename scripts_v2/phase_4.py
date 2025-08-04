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
import subprocess
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


#
# Functions
#

#
# Start processing
#

startTime = time.perf_counter()

# on récupère les arguments passés
list_of_args = sys.argv

millesime=""
secteur=""
typemaj=""

# et on fait des tests

try:
  if len(list_of_args[1]) != 4:
    print("Pas de millésime en argument")
    sys.exit()
  else:
    millesime = list_of_args[1]

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
print(" Export des données phase 3 pour la phase 5 pour le millésime "+str(millesime))
print("")

print(" Lecture du fichier de configuration ")
print("")

# BD Ar Redadeg
global db_redadeg_host
global db_redadeg_db
db_redadeg_host  = config.get('redadeg_database', 'host')
db_redadeg_port = config.get('redadeg_database', 'port')
db_redadeg_db = config.get('redadeg_database', 'db')+"_"+str(millesime)
db_redadeg_user = config.get('redadeg_database', 'user')
db_redadeg_passwd = config.get('redadeg_database', 'passwd')
# chaîne de connection
global db_redadeg_conn_str
db_redadeg_conn_str = "host="+db_redadeg_host+" port="+db_redadeg_port+" dbname="+db_redadeg_db+" user="+db_redadeg_user+" password="+db_redadeg_passwd


initConnRedadegDB()

# le cursor
db_redadeg_cursor = db_redadeg_pg_conn.cursor()

print("")

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

try:

  print("  Export des PK en geojson par secteur (pour les cartes umap phase 5)")

  # on commence par chercher la table des secteurs pour récupérer les id
  # puis boucler dessus

  sql_get_secteurs = """
SELECT id
FROM secteur
WHERE id > 0 AND id <> 999
ORDER BY id ;"""

  db_redadeg_cursor.execute(sql_get_secteurs)
  secteur_ids = db_redadeg_cursor.fetchall()

  # on boucle
  for secteur in secteur_ids:
    # on fait la commande d'export
    export_cmd = ["ogr2ogr", "-f", "GeoJSON",
                 f"../data/{millesime}/export/phase_4_pk_{secteur[0]}.geojson",
                 f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                 "-sql", f"SELECT pk_id, secteur_id, the_geom FROM phase_3_pk_4326 WHERE secteur_id = {secteur[0]} ;"]
    # on exporte
    subprocess.check_output(export_cmd)
    print(f"  secteur {secteur[0]} : fait")

  print("  exports GeoJSON terminé")
  print("")

  print("  Import des PK dans la table phase_5_pk_ref")
  sql_transfert = "TRUNCATE TABLE phase_5_pk_ref ; "
  sql_transfert += "INSERT INTO phase_5_pk_ref SELECT * FROM phase_3_pk ORDER BY pk_id ;"
  db_redadeg_cursor.execute(sql_transfert)
  print("  fait")

  print("  Import des PK dans la table phase_5_pk")
  sql_transfert = "TRUNCATE TABLE phase_5_pk ; "
  sql_transfert += "INSERT INTO phase_5_pk SELECT * FROM phase_3_pk ORDER BY pk_id ;"
  db_redadeg_cursor.execute(sql_transfert)
  print("  fait")


  print("  Remplissage de la couche phase_5_trace depuis phase_2_trace_secteur")
  sql_truncate = "TRUNCATE TABLE phase_5_trace ;"
  db_redadeg_cursor.execute(sql_truncate)

  sql_load = """
INSERT INTO phase_5_trace
  SELECT
    secteur_id,
    the_geom
  FROM phase_3_trace_secteurs ;"""
  db_redadeg_cursor.execute(sql_load)
  print("  fait")

  print("  Vacuum")
  sql_vacuum = "VACUUM FULL phase_5_trace ;"
  db_redadeg_cursor.execute(sql_vacuum)
  print("  fait")
  print("")

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
#print(f"Exécuté en {stopTime - startTime:0.4f} secondes")

# version en h min s
hours, rem = divmod(stopTime - startTime, 3600)
minutes, seconds = divmod(rem, 60)
print("Exécuté en {:0>2}:{:0>2}:{:05.2f}".format(int(hours),int(minutes),seconds))


