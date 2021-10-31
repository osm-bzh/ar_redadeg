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
print(" Préparation des données phase 3 du secteur "+str(secteur)+" pour le millésime "+str(millesime))
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

  # longueur de découpage des tronçons de la phase 2
  longueur_densification = config.get('redadeg', 'longueur_densification')

  # ------------------------------------------------------
  print("  Suppression des données du secteur "+secteur)
  sql_delete = "DELETE FROM phase_3_troncons_pgr WHERE secteur_id = "+secteur +" ;"
  db_redadeg_cursor.execute(sql_delete)
  print("  fait")
  print("")


  # ------------------------------------------------------
  print("  Chargement de tronçons découpés tous les "+longueur_densification+" m depuis la couche des tronçons phase 2")
  
  # on charge, pour le secteur concerné des tronçons courts découpés tous les x mètres
  # (densification avec ST_LineSubstring )

  sql_insert = """
INSERT INTO phase_3_troncons_pgr (secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br, the_geom)
 SELECT
  secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br,
  ST_LineSubstring(the_geom, """+longueur_densification+"""*n/length,
  CASE
  WHEN """+longueur_densification+"""*(n+1) < length THEN """+longueur_densification+"""*(n+1)/length
  ELSE 1
  END) As the_geom
FROM
  (
  SELECT
    secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br,
    ST_Length(the_geom) AS length,
    the_geom
  FROM phase_2_trace_troncons
  WHERE secteur_id = """+secteur+""" 
  ) AS t
CROSS JOIN generate_series(0,10000) AS n
WHERE n*"""+longueur_densification+"""/length < 1;"""

  db_redadeg_cursor.execute(sql_insert)


  # calcul des attributs de support du calcul pour PGR
  sql_update_costs = """
UPDATE phase_3_troncons_pgr 
SET cost = round(st_length(the_geom)::numeric), reverse_cost = round(st_length(the_geom)::numeric)
WHERE secteur_id = """+secteur +"""  ;"""

  db_redadeg_cursor.execute(sql_update_costs)

  # optimisation
  db_redadeg_cursor.execute("VACUUM FULL phase_3_troncons_pgr ;")

  print("  fait")
  print("")


  # ------------------------------------------------------
  print("  Création / maj de la topologie pgRouting pour les tronçons nouvellement créés")
  
  sql_create_pgr_topology = "SELECT pgr_createTopology('phase_3_troncons_pgr', 0.001, rows_where:='true', clean:=true);"
  db_redadeg_cursor.execute(sql_create_pgr_topology)
  
  print("  fait")
  print("")


  # ------------------------------------------------------
  print("  Récupération id des nœuds de début et fin du secteur")

  # on commence par supprimer le secteur puis on y remet avec les infos de la table des secteurs
  sql_init_secteurs = """
DELETE FROM phase_3_secteurs WHERE secteur_id = """+secteur+""" ;
INSERT INTO phase_3_secteurs (secteur_id, nom_br, nom_fr, longueur_km_redadeg)
  SELECT id, nom_br, nom_fr, km_redadeg
  FROM secteur
  WHERE id = """+secteur+"""
  ORDER BY id ;"""
  db_redadeg_cursor.execute(sql_init_secteurs)

  
  # récupération id node début et fin de secteur
  secteurs_in_clause = secteur+","+str(int(secteur)+100)
  sql_get_nodes = """
  SELECT v.id, s.the_geom 
  FROM phase_2_pk_secteur s, phase_3_troncons_pgr_vertices_pgr v
  WHERE s.secteur_id IN ("""+secteurs_in_clause+""") AND ST_INTERSECTS(s.the_geom, v.the_geom)
  ORDER BY s.secteur_id;"""

  db_redadeg_cursor.execute(sql_get_nodes)

  # fetchone() fait passer d'un enregistrement à un autre
  # donc : nœud de début du secteur
  node_start = db_redadeg_cursor.fetchone()
  node_start_id = node_start[0]
  node_start_geom = node_start[1]
  # nœud de fin du secteur
  node_end = db_redadeg_cursor.fetchone()
  node_end_id = node_end[0]
  node_end_geom = node_end[1]


  # on maj les infos dans la table phase_3_secteurs
  sql_update_nodes_infos = "UPDATE phase_3_secteurs SET node_start = "+str(node_start_id)+", node_stop = "+str(node_end_id)+" WHERE secteur_id = "+secteur +" ;"
  db_redadeg_cursor.execute(sql_update_nodes_infos)
  print("  fait : "+str(node_start_id)+" -> "+str(node_end_id))


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


