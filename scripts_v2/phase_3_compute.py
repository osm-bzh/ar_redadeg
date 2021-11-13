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

def getPKfromRouting(start, distance):

  sql_routage =  """  
WITH t AS (
SELECT * 
FROM pgr_drivingDistance('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr 
WHERE SOURCE IS NOT NULL AND id > 0',
"""+str(start)+""", """+str(distance)+""")
)
SELECT node, edge, round(agg_cost) FROM t ORDER BY seq DESC LIMIT 1;"""
  
  #print(sql_routage)

  cursor = db_redadeg_pg_conn.cursor()
  cursor.execute(sql_routage)

  # on récupère l'id du nœud de fin
  data = cursor.fetchone()
  node_end = data[0]
  edge = data[1]
  distance = data[2]
  cursor.close()
  
  return([node_end, edge, distance])


# ==============================================================================

def getPgrNodeInfos(node_id):

  # cette fonction va chercher les infos où il faut pour le PK
  cursor = db_redadeg_pg_conn.cursor()

  # géométrie…
  sql_get_from_pgr_node = """
SELECT
  the_geom,
  TRUNC(ST_X(the_geom)::numeric,1) AS x,
  TRUNC(ST_Y(the_geom)::numeric,1) AS y,
  TRUNC(ST_X(ST_Transform(the_geom,4326)::geometry(Point, 4326))::numeric,8) AS long,
  TRUNC(ST_Y(ST_Transform(the_geom,4326)::geometry(Point, 4326))::numeric,8) AS lat
FROM phase_3_troncons_pgr_vertices_pgr v WHERE id = """+ str(node_id) +""";"""
  #print(sql_get_from_pgr_node)

  cursor.execute(sql_get_from_pgr_node)
  data = cursor.fetchone()
  the_geom = data[0]
  x = data[1]
  y = data[2]
  long = data[3]
  lat = data[4]

  cursor.close()

  return([the_geom,x,y,long,lat])


# ==============================================================================

def getLongueurParcourue(node_start, node_end):

  # cette fonction sert à retourner la longueur parcourue entre 2 nœuds
  sql_get_longueur = "SELECT round(max(agg_cost))::integer "
  sql_get_longueur += "FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr "
  sql_get_longueur += "  WHERE SOURCE IS NOT NULL', " + str(node_start) + ", " + str(node_end) + ")"

  cursor = db_redadeg_pg_conn.cursor()
  cursor.execute(sql_get_longueur)
  data = cursor.fetchone()[0]

  return (data)


# ==============================================================================
# ==============================================================================
# ==============================================================================
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
print(" Calcul des PK pour le secteur "+str(secteur)+" pour le millésime "+str(millesime))
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


  # ------------------------------------------------------
  print("  Récupération des infos du secteur")

  # PK de départ de la Redadeg (à cause de l'avant course)
  pk_start_redadeg = config.get('redadeg', 'pk_start')
  
  sql_get_infos_secteur = "SELECT pk_start, node_start, node_stop, longueur, longueur_km_redadeg "
  sql_get_infos_secteur += "FROM secteur "
  sql_get_infos_secteur += "WHERE id = "+secteur+" ;"

  db_redadeg_cursor.execute(sql_get_infos_secteur)
  infos_secteur = db_redadeg_cursor.fetchone()

  secteur_pk_start = infos_secteur[0]
  secteur_node_start = infos_secteur[1]
  secteur_node_stop = infos_secteur[2]
  secteur_longueur = infos_secteur[3]
  secteur_longueur_km_redadeg = infos_secteur[4]
  # pour test
  #secteur_longueur = 10000

  # longueur de découpage des tronçons de la phase 2
  longueur_densification = config.get('redadeg', 'longueur_densification')

  print("  fait")
  print("")

  # on détermine le nb théorique de PK pour ce secteur
  secteur_nb_pk = int(secteur_longueur / secteur_longueur_km_redadeg)
  # et la longueur réelle demandée au calculateur
  longueur_decoupage = int(secteur_longueur_km_redadeg)

  print("  " + str(secteur_nb_pk) + " KM redadeg de " + str(secteur_longueur_km_redadeg) + " m vont être créés")
  print("  pour une longeur réelle de " + str(secteur_longueur) + " m")
  print("")


  # cette variable pour stocker la requête SQL de création des PK
  # et la première requête sera de supprimer les données du secteur
  sql_insert_pks = "DELETE FROM phase_3_pk WHERE secteur_id = "+secteur+" ;\n"

  # ------------------------------------------------------
  print("  Calcul du 1er PK du secteur")

  # on a les infos -> on calcule la route qui va du 1er nœud de départ et qui fait la distance demandée
  # pour récupérer l'id du noeud de fin qui va devenir notre PK
  node_zero = secteur_node_start
  node_zero_data = getPgrNodeInfos(node_zero)

  sql_insert_pks += "INSERT INTO phase_3_pk (secteur_id, pk_id, the_geom, pk_x, pk_y, pk_long, pk_lat, length_theorical, length_real) VALUES ("
  sql_insert_pks += secteur + ", " + str(secteur_pk_start)
  sql_insert_pks += ",'" + node_zero_data[0] + "'"
  sql_insert_pks += "," + str(node_zero_data[1]) + "," + str(node_zero_data[2])
  sql_insert_pks += "," + str(node_zero_data[3]) + "," + str(node_zero_data[4])
  sql_insert_pks += f",{longueur_decoupage},0"
  sql_insert_pks += ");\n"

  print("  nœud du PK " + str(secteur_pk_start) + " : " + str(node_zero))
  print("")

  # ------------------------------------------------------
  print("  Calcul des autres PK")
  print("")

  # maintenant on peut itérer jusqu'à la fin du secteur
  node_x = node_zero

  # en sa basant sur la longueur des PK posés et la longueur totale du secteur
  longueur_parcourue = getLongueurParcourue(node_zero, node_x)
  if longueur_parcourue is None: longueur_parcourue = 0
  longueur_restante = secteur_longueur - longueur_parcourue

  # un compteur pour la boucle
  i = 1
  # début de l'id des PK qui commence avec le PK de début du secteur
  pk_id = secteur_pk_start

  # tant que la distance restante est supérieure à la distance de découpage
  # on boucle
  while longueur_restante >= longueur_decoupage:

    # incrément du compteur de la boucle
    i += 1
    # incrément du compteur de PK
    pk_id += 1

    # on va trouver le prochain PK
    pk_data = getPKfromRouting(node_x , longueur_decoupage)
    node_x = pk_data[0]
    previous_pk_edge = pk_data[1]
    longueur_km_redadeg = pk_data[2]
    longueur_parcourue = getLongueurParcourue(node_zero,node_x)
    longueur_restante = secteur_longueur - longueur_parcourue

    #print("    nouveau nœud : " + str(node_x))
    #print("    previous_pk_edge : "+ str(previous_pk_edge))

    # on sort une infos pour suivre si le traitement bosse
    if (i <= 5) or (i % 10 == 0) or (i >= secteur_nb_pk - 5):
      print("  PK " + str(pk_id))
      print("    id du nœud : " + str(node_x))
      print("    " + str(longueur_parcourue) + " m jusqu'à maintenant")
      print("    " + str(longueur_restante) + " m restant jusqu'à la fin du secteur")


    # ici on construit la requête avec les données du PK
    node_x_data = getPgrNodeInfos(node_x)

    # on fait une requête SQL d'insert de ce PK
    sql_insert_pks += "INSERT INTO phase_3_pk (secteur_id, pk_id, the_geom, pk_x, pk_y, pk_long, pk_lat, length_theorical, length_real) VALUES ("
    sql_insert_pks += secteur + "," + str(pk_id)
    sql_insert_pks += ",'" + node_x_data[0] + "'"
    sql_insert_pks += "," + str(node_x_data[1]) + "," + str(node_x_data[2])
    sql_insert_pks += "," + str(node_x_data[3]) + "," + str(node_x_data[4])
    sql_insert_pks += f",{longueur_decoupage},{longueur_km_redadeg}"
    sql_insert_pks += ");\n"

    # on met en négatif l'info de routage du précédent tronçon afin de l'écarter du prochain calcul de routage
    sql_neutralisation = "UPDATE phase_3_troncons_pgr SET id = -ABS("+str(previous_pk_edge)+") WHERE id = "+str(previous_pk_edge)+" ;"
    #print(sql_neutralisation)
    db_redadeg_cursor.execute(sql_neutralisation)

  print("")
  print("  Fin de la boucle")
  print("")

  print("  RAZ de la neutralisation des infos de routage pour la boucle")
  sql_reset_neutralisation = "UPDATE phase_3_troncons_pgr SET id = -1*id WHERE id < 0 ;"
  db_redadeg_cursor.execute(sql_reset_neutralisation)
  print("  fait")
  print("")

  print("  Écriture des PK dans la couche phase_3_pk")
  db_redadeg_cursor.execute(sql_insert_pks)
  print("  fait")
  print("")

  print("  sauvegarde du dernier PK calculé pour ce secteur")
  # on est sorti de la boucle alors on va écrire en base l'id du dernier PK calculé
  sql_update_pk_end = "UPDATE secteur SET pk_stop = " + str(pk_id)
  sql_update_pk_end += "WHERE id = " + secteur + " ;"
  db_redadeg_cursor.execute(sql_update_pk_end)
  print("  fait")
  print("")

  db_redadeg_cursor.close()

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


