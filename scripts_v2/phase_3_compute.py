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
SELECT node, edge FROM t ORDER BY seq DESC LIMIT 1;"""
  
  #print(sql_routage)

  cursor = db_redadeg_pg_conn.cursor()
  cursor.execute(sql_routage)

  # on récupère l'id du nœud de fin
  data = cursor.fetchone()
  node_end = data[0]
  edge = data[1]
  cursor.close()
  
  return([node_end, edge])



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
print(" Calcul des PK et tronçons pour le secteur "+str(secteur)+" pour le millésime "+str(millesime))
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
  
  sql_get_infos_secteur = "SELECT node_start, node_stop, t.longueur_km_redadeg, nb_km_redadeg "
  sql_get_infos_secteur += "FROM phase_3_secteurs s JOIN phase_2_tdb t ON s.secteur_id = t.secteur_id "
  sql_get_infos_secteur += "WHERE s.secteur_id = "+secteur+" ;"

  db_redadeg_cursor.execute(sql_get_infos_secteur)
  infos_secteur = db_redadeg_cursor.fetchone()
  
  secteur_node_start = infos_secteur[0]
  secteur_node_stop = infos_secteur[1]
  secteur_longueur_km = infos_secteur[2]
  secteur_nb_km = int(infos_secteur[3])
  #secteur_nb_km = 10

  print("  fait")
  print("")

  print("  "+str(secteur_nb_km)+" km / pk à créer")
  print("")
  

  # ------------------------------------------------------
  print("  Calcul du 1er PK")

  # on a les infos -> on calcule la route qui va du 1er nœud de départ et qui fait la distance demandée
  # pour récupérer l'id du noeud de fin qui va devenir notre PK
  node_zero = secteur_node_start
  #edge_zero =  getPKfromRouting(node_zero,secteur_longueur_km)[1]

  print("  nœud du PK 1 : " + str(node_zero))
  #print("  nœud du PK 1 : "+ str(node_zero) + " | "+ str(edge_zero))
  print("")

  # ------------------------------------------------------
  print("  Calcul des autres PK")

  # maintenant on peut itérer jusqu'à la fin du secteur
  node_x = node_zero

  for i in range(1, secteur_nb_km):

    pk_data = getPKfromRouting(node_x,secteur_longueur_km)
    node_x = pk_data[0]
    previous_pk_edge = pk_data[1]

    # on met tt de suite en négatif l'info de routage du précédent tronçon afin de l'écarter du prochain calcul de routage
    sql_neutralisation = "UPDATE phase_3_troncons_pgr SET id = -"+str(previous_pk_edge)+" WHERE id = "+str(previous_pk_edge)+" ;"
    #print(sql_neutralisation)
    db_redadeg_cursor.execute(sql_neutralisation)

    #print("    nouveau nœud : " + str(node_x))
    #print("    previous_pk_edge : "+ str(previous_pk_edge))

    print("  nœud du PK "+str(i)+" : " + str(node_x))




  print("")
  print("  Fin de la boucle")
  print("")
  
  print("  RAZ de la neutralisation des infos de routage pour la boucle")
  sql_reset_neutralisation = "UPDATE phase_3_troncons_pgr SET id = -1*id WHERE id < 0 ;"
  db_redadeg_cursor.execute(sql_reset_neutralisation)

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


