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
import wget
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
print(" Phase 5 : création des PK consolidés pour le millésime "+str(millesime))
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

  print("  Vidage de la table d'import")
  sql_truncate = "TRUNCATE TABLE phase_5_pk_umap_4326 ;"
  #db_redadeg_cursor.execute(sql_truncate)
  print("  fait")
  print("")

  print("  Récupération et import des PK depuis umap")

  # on ouvre le fichier qui contient la liste des layers à récupérer
  f_layers = open(f"../data/{millesime}/umap_phase_5_layers.txt",'r')
  lines = f_layers.readlines()
  f_layers.close()

  # boucle
  for line in lines:
    # pb retour à la ligne intempestif (que sur mac ?)
    layer = line[:-1]

    layer_url = f"https://umap.openstreetmap.fr/fr/datalayer/{layer}/"
    layer_file = f"../data/{millesime}/umap_phase_5_pk_{layer}.geojson"

    # on récupère le fichier
    wget.download(layer_url, layer_file)

    # on l'importe avec gdal
    cmd = ["ogr2ogr", "-f",
           "PostgreSQL",
           f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
           f"../data/{millesime}/umap_phase_5_pk_{layer}.geojson",
           "-nln", "phase_5_pk_umap_4326",
           "-lco", "GEOMETRY_NAME=the_geom"]
    #print(cmd)
    #subprocess.call(cmd)

    # on efface le fichier aussitôt
    os.remove(layer_file)

  #print("  Chargement de la couche phase_5_pk_umap")
  sql_trunc_load = """
TRUNCATE TABLE phase_5_pk_umap ; 
INSERT INTO phase_5_pk_umap
SELECT pk_id, secteur_id, st_transform(the_geom, 2154) 
FROM phase_5_pk_umap_4326
ORDER BY pk_id ;"""

  db_redadeg_cursor.execute(sql_trunc_load)
  print("  fait")
  print("")

  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print("  Test : nb de pk par secteur")

  # on utilise la vue faite pour ça
  # normalement c'est impossible car pk_id est clé primaire

  sql_test_nb = "SELECT * FROM phase_5_pk_diff ;"
  db_redadeg_cursor.execute(sql_test_nb)
  controle_table = db_redadeg_cursor.fetchall()

  for record in controle_table:
    secteur_id = record[0]
    nb_ref = record[1]
    nb_umap = record[2]
    diff = record[3]

    # le test
    nb_pb = 0
    if nb_umap != nb_ref:
      nb_pb += 1
      print(f"    secteur {secteur_id} : PROBLEME : {diff} de différence")
    else:
      print(f"    secteur {secteur_id} : ok -> {nb_ref} PK")

    if nb_pb > 0:
      print("  ARRÊT : corriger puis relancer")
      sys.exit(1)




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


