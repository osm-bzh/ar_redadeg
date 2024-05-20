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


# ============================================================================================================

def closeConnRedadegDB():

  try:
    db_redadeg_pg_conn.close()
    print("  Fermeture de la connexion à la base "+db_redadeg_db+" sur "+db_redadeg_host)
  except:
    pass

# ============================================================================================================



# ============================================================================================================
# ============================================================================================================
#
# Functions
#

#
# Start processing
#

startTime = time.perf_counter()

# on récupère les arguments passés
list_of_args = sys.argv

millesime = ""
secteur = ""

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
print(" Phase X : remise en ordre des segments")
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
global db_redadeg_cursor
db_redadeg_cursor = db_redadeg_pg_conn.cursor()

print("")

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# on fait un recordset avec l'ensemble des points de débuts et fin de chaque segment
sql_get_segments = f"""
SELECT
   secteur_id, path_seq
  ,ST_AsText(ST_ReducePrecision(ST_StartPoint(the_geom)::geometry, 1.0)) AS start_point
  ,ST_AsText(ST_ReducePrecision(ST_EndPoint(the_geom)::geometry, 1.0)) AS end_point
FROM public.phase_2_trace_pgr
WHERE secteur_id = {secteur} 
ORDER BY path_seq ASC ;"""

db_redadeg_cursor.execute(sql_get_segments)
segments = db_redadeg_cursor.fetchall()
nb_total_segments = db_redadeg_cursor.rowcount

print(f"  Il y a {nb_total_segments} segments à analyser")

cpt_segment = 1
cpt_segment_reversed = 0

previous_end_point = ""

# on itère donc sur chaque segment
for segment in segments:

  try:
    # print(cpt_segment)

    # infos d'identification
    secteur_id = segment[0]
    path_seq = segment[1]
    # vertex de début
    start_point = segment[2]
    # vertex de fin
    end_point = segment[3]

    # print(start_point)
    # print(end_point)

    #print(f"  {secteur_id}-{path_seq} :")

    # on teste si le point de début du segment courant correspond au point de fin du segment précédent
    # sauf si on c'est le premier segment
    if cpt_segment == 1:
      print(f"  {secteur_id}-{path_seq} : premier segment")
      pass
    else:
      if start_point == previous_end_point:
        # print(f"  {secteur_id}-{path_seq} : ce segment est à l'endroit")
        pass
      else:
        # print(f"  {secteur_id}-{path_seq} : ce segment est à l'envers")
        # on va donc le remettre à l'endroit
        sql_update_segment = f"""
UPDATE public.phase_2_trace_pgr
	SET the_geom  = 
	(
		SELECT ST_Reverse(the_geom)
		FROM public.phase_2_trace_pgr
		WHERE secteur_id = {secteur_id} AND path_seq = {path_seq}
	)
WHERE secteur_id = -1 AND path_seq = 3 ;
"""
        db_redadeg_cursor.execute(sql_update_segment)
        cpt_segment_reversed += 1
        # print("  remis à l'endroit !")

    # on est à la fin donc on enregistre le vertex de fin du segment courant
    # pour pouvoir le comparer dans la prochaine itération
    previous_end_point = end_point

    cpt_segment += 1

    if cpt_segment % 200 == 0:
      print(f"  {cpt_segment}...")

  except Exception as err:
    print("  ERREUR : " + str(err))
    closeConnRedadegDB()
    sys.exit()

print("")
print(f"  {cpt_segment_reversed} segments traités pour le secteur {secteur}, soit {round((cpt_segment_reversed/cpt_segment)*100, 1)} %")

del segments

print("")

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


