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


# ============================================================================================================

def closeConnRedadegDB():

  try:
    db_redadeg_pg_conn.close()
    print("  Fermeture de la connexion à la base "+db_redadeg_db+" sur "+db_redadeg_host)
  except:
    pass

# ============================================================================================================

def truncate_reload_pk():

  print("  Vidage de la table d'import des PK umap")
  sql_truncate = "TRUNCATE TABLE phase_5_pk_umap_4326 ;"
  db_redadeg_cursor.execute(sql_truncate)
  print("  fait")

  print("  Récupération et import des PK depuis umap")

  # on ouvre le fichier qui contient la liste des layers à récupérer
  f_layers = open(f"../data/{millesime}/umap_phase_5_layers.txt",'r')
  lines = f_layers.readlines()
  f_layers.close()

  # boucle
  for line in lines:
    # pb retour à la ligne intempestif (que sur mac ?)
    umap_map = line[:-1].split('/')[0]
    umap_layer = line[:-1].split('/')[1]

    layer_url = f"https://umap.openstreetmap.fr/fr/datalayer/{umap_map}/{umap_layer}/"
    layer_file = f"../data/{millesime}/import/umap_phase_5_pk_{umap_layer}.geojson"

    # on récupère le fichier
    wget.download(layer_url, layer_file)

    # on l'importe avec gdal
    cmd = ["ogr2ogr", "-f",
           "PostgreSQL",
           f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
           f"../data/{millesime}/import/umap_phase_5_pk_{umap_layer}.geojson",
           "-nln", "phase_5_pk_umap_4326",
           "-lco", "GEOMETRY_NAME=the_geom"]
    #print(cmd)
    subprocess.call(cmd)

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

  print("  Vacuum")
  sql_vacuum = "VACUUM FULL phase_5_pk_umap ;"
  db_redadeg_cursor.execute(sql_vacuum)
  print("  fait")
  print("")


# ============================================================================================================

def truncate_reload_trace():

  print("  Vidage de la couche phase_5_trace")
  sql_truncate = "TRUNCATE TABLE phase_5_trace ;"
  db_redadeg_cursor.execute(sql_truncate)
  print("  fait")

  print("  Remplissage de la couche phase_5_trace depuis phase_2_trace_secteur")
  sql_load = """
INSERT INTO phase_5_trace
  SELECT
    secteur_id,
    the_geom
  FROM phase_2_trace_secteur ;"""
  db_redadeg_cursor.execute(sql_load)
  print("  fait")

  print("  Vacuum")
  sql_vacuum = "VACUUM FULL phase_5_trace ;"
  db_redadeg_cursor.execute(sql_vacuum)
  print("  fait")
  print("")

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

global millesime
global secteur
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
print(" Phase 5 : création des données consolidées pour le millésime "+str(millesime))
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

try:

  # mise à jour de la couche du tracé
  truncate_reload_trace()

  # mise à jour des données PK pour travail dessus
  truncate_reload_pk()

  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print("  Test : nb de pk par secteur")

  # on utilise la vue faite pour ça
  # normalement c'est impossible car pk_id est clé primaire

  sql_test_nb = "SELECT * FROM phase_5_pk_diff_secteur ;"
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


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print("  Test : nb de pk déplacés par secteur")

  sql_tdb_mouvements = """
WITH secteurs AS (
  SELECT id FROM secteur 
  WHERE id > 0 AND id < 999
  ORDER BY id
),
test AS (
SELECT r.secteur_id, COUNT(*)
FROM phase_5_pk_ref r FULL OUTER JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 
GROUP BY r.secteur_id 
)
SELECT
  secteurs.id,
  test.count
FROM secteurs FULL OUTER JOIN test ON secteurs.id = test.secteur_id
"""

  db_redadeg_cursor.execute(sql_tdb_mouvements)
  controle_table = db_redadeg_cursor.fetchall()
  total_pk_deplaces = 0

  for record in controle_table:
    secteur_id = record[0]
    nb_pk_deplaces = record[1]

    if nb_pk_deplaces is None :
      nb_pk_deplaces = 0
      print(f"    aucun PK déplacé pour le secteur {secteur_id}")
    else:
      print(f"    {nb_pk_deplaces} PK déplacés pour le secteur {secteur_id}")

    total_pk_deplaces += nb_pk_deplaces

  print(f"    {total_pk_deplaces} PK déplacés au total")
  print("")


  # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print("  Recalage des PK déplacés")

  # on commence par supprimer les attributs, par sécurité
  sql_clear_attibutes = """
WITH pk_deplaces AS (
  -- table des PK déplacés
  SELECT
    r.pk_id
    ,ST_Distance(r.the_geom, u.the_geom) AS distance
    ,u.the_geom 
  FROM phase_5_pk_ref r FULL OUTER JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 
  ORDER BY r.pk_id 
)
UPDATE phase_5_pk ph5
SET (pk_x, pk_y, pk_long, pk_lat, length_real, length_theorical, length_total,
municipality_admincode, municipality_postcode, municipality_name_fr, municipality_name_br, 
way_osm_id, way_highway, way_type, way_oneway, way_ref, way_name_fr, way_name_br)
= (NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
FROM pk_deplaces
WHERE ph5.pk_id = pk_deplaces.pk_id"""
  db_redadeg_cursor.execute(sql_clear_attibutes)

  #

  # recalage par projection du PK déplacé sur le filaire de voie
  sql_recalage = """
 WITH pk_recales AS (
  WITH candidates AS (
    WITH pt AS (
      -- table des PK déplacés
      SELECT
        r.pk_id
        ,ST_Distance(r.the_geom, u.the_geom) AS distance
        ,u.the_geom 
      FROM phase_5_pk_ref r FULL OUTER JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
      WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 
      ORDER BY r.pk_id 
    )
    -- place un point projeté sur la ligne la plus proche
    SELECT
      ROW_NUMBER() OVER(PARTITION BY pt.pk_id ORDER BY pt.distance DESC) AS RANK,
      pt.pk_id,
      round(pt.distance) AS distance,
      ST_ClosestPoint(lines.the_geom, pt.the_geom) AS the_geom
    FROM pt, phase_2_trace_pgr lines
    WHERE ST_DWithin(pt.the_geom, lines.the_geom, 20)
  )
  SELECT 
    pk_id, distance, the_geom 
  FROM candidates
  WHERE RANK = 1
  ORDER BY pk_id
)
UPDATE phase_5_pk
SET the_geom = pk_recales.the_geom
FROM pk_recales
WHERE phase_5_pk.pk_id = pk_recales.pk_id ;"""

  db_redadeg_cursor.execute(sql_recalage)
  print("  fait")

  #

  print("  Mise à jour des informations sur les géométries")

  sql_update_infos_geom = f"""
  UPDATE phase_5_pk
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
    FROM phase_5_pk
    ORDER BY pk_id 
  ) sub
  WHERE phase_5_pk.pk_id = sub.pk_id ;"""

  db_redadeg_cursor.execute(sql_update_infos_geom)
  print("  fait")

  #

  print("  Mise à jour de la distance théorique")

  sql_update_length_theorical = f"""
  UPDATE phase_5_pk
  SET
    length_theorical = sub.length_theorical
  FROM (
    SELECT
      pk.pk_id
      ,pk.secteur_id
      ,s.longueur_km_redadeg AS length_theorical
    FROM phase_5_pk pk JOIN secteur s ON pk.secteur_id = s.id
    ORDER BY pk_id
  ) sub
  WHERE phase_5_pk.pk_id = sub.pk_id ;"""

  db_redadeg_cursor.execute(sql_update_length_theorical)
  print("  fait")

  #

  print("  Mise à jour de la distance réelle")

  sql_update_length_length_real = f"""
  UPDATE phase_5_pk
  SET
    length_real = sub.length_real
  FROM (
    SELECT
      pk.pk_id
      ,pk.secteur_id
      ,s.longueur_km_redadeg AS length_theorical
      ,diff.deplace
      ,CASE
        WHEN diff.deplace = FALSE THEN pk.length_theorical
        ELSE 0
      END AS length_real
    FROM phase_5_pk pk
        JOIN secteur s ON pk.secteur_id = s.id
        JOIN phase_5_pk_diff diff ON pk.pk_id = diff.pk_id
    ORDER BY pk_id
  ) sub
  WHERE phase_5_pk.pk_id = sub.pk_id ;

  UPDATE phase_5_pk pk
  SET length_real = 0
  FROM (SELECT pk_id,(pk_id -1) AS pk_moins_1 FROM phase_5_pk WHERE length_real = 0 ORDER BY pk_id) x
  WHERE pk.pk_id = x.pk_moins_1 ;
"""
  # avec cette requête 'length_real' = 0 pour les PK déplacés et le PK le précédant

  db_redadeg_cursor.execute(sql_update_length_length_real)
  print("  fait")

  #

  print("  Mise à jour des informations sur les voies")

  sql_update_infos_ways = f"""
  UPDATE phase_5_pk
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
    FROM phase_5_pk pk, phase_2_trace_troncons t
    WHERE ST_INTERSECTS(ST_BUFFER(pk.the_geom,1), t.the_geom)
    ORDER BY pk_id 
  ) sub
  WHERE phase_5_pk.pk_id = sub.pk_id;"""

  db_redadeg_cursor.execute(sql_update_infos_ways)
  print("  fait")

  #

  print("  Mise à jour des informations sur les communes")

  sql_update_infos_communes = f"""
  UPDATE phase_5_pk
  SET
    municipality_admincode = sub.code_insee,
    municipality_postcode = sub.code_postal,
    municipality_name_fr = sub.name_fr,
    municipality_name_br = sub.name_br
  FROM (
    SELECT
     pk.pk_id,
     com.code_insee,
     com.code_postal ,
     com.name_fr,
     com.name_br
    FROM phase_5_pk pk, communes com
    WHERE ST_INTERSECTS(pk.the_geom, com.geom)
    ORDER BY pk_id 
  ) sub
  WHERE phase_5_pk.pk_id = sub.pk_id;"""

  db_redadeg_cursor.execute(sql_update_infos_communes)
  print("  fait")
  print("")

  print("  Vacuum")
  sql_vacuum = "VACUUM FULL phase_5_pk ;"
  db_redadeg_cursor.execute(sql_vacuum)
  print("  fait")
  print("")

  #

  print("  Mise à jour de la table statistiques des communes")

  sql_update_stats_communes = f"""
TRUNCATE TABLE communes_stats;
WITH source_data AS (
    SELECT
        MIN(i.pk_id) AS pk_min,
        MAX(i.pk_id) AS pk_max,
        i.code_insee,
        i.code_postal,
        i.name_br,
        i.name_fr
    FROM (
        SELECT c.*, pk.pk_id
        FROM communes c
        JOIN phase_5_pk pk ON ST_Intersects(c.geom, pk.the_geom)
    ) i
    GROUP BY i.code_insee, i.code_postal, i.name_br, i.name_fr
),
ranked_data AS (
    SELECT
        pk_min,
        pk_max,
        code_insee,
        code_postal,
        name_br,
        name_fr,
        LEAD(pk_min) OVER (ORDER BY pk_min) AS next_pk_min
    FROM source_data
)
INSERT INTO communes_stats
(pk_min, pk_max, passage_unique, name_fr, name_br, code_insee, code_postal)
SELECT
    pk_min,
    pk_max,
    CASE
        WHEN pk_max > next_pk_min THEN 'non'
        ELSE 'oui'
    END AS passage_unique,
    code_insee,
    code_postal,
    name_br,
    name_fr
FROM ranked_data;"""

  db_redadeg_cursor.execute(sql_update_stats_communes)
  print("  fait")
  print("")


  #

  # export geojson du tracé pour merour
  print("  Export geojson du tracé pour merour")
  export_cmd = ["ogr2ogr", "-f", "GeoJSON",
                f"../data/{millesime}/export/phase_5_trace.geojson",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT 'secteur '||secteur_id AS name, ST_Simplify(the_geom, 1.0) FROM phase_5_trace ORDER BY secteur_id",
                "-t_srs", "EPSG:4326"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  # export geojson encoded polyline du tracé pour merour
  print("  Export geojson encoded polyline du tracé pour merour")
  export_cmd = ["ogr2ogr", "-f", "GeoJSON",
                f"../data/{millesime}/export/phase_5_trace_encoded.geojson",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT secteur_id AS name ,ST_AsEncodedPolyline(geom) as geom FROM (SELECT secteur_id ,ST_LineMerge((dumped.geom_dump).geom) as geom FROM (SELECT secteur_id ,ST_Dump(ST_Transform(the_geom,4326)) AS geom_dump FROM phase_5_trace ) dumped ) merged",
                "-t_srs", "EPSG:4326"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  # export geojson des PK pour merour
  print("  Export geojson des PK pour merour")
  export_cmd = ["ogr2ogr", "-f", "GeoJSON",
                f"../data/{millesime}/export/phase_5_pk.geojson",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT * FROM phase_5_pk ORDER BY pk_id",
                "-t_srs", "EPSG:4326"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  # export geojson des communes pour merour
  print("  Export geojson des communes pour merour")
  export_cmd = ["ogr2ogr", "-f", "GeoJSON",
                f"../data/{millesime}/export/communes.geojson",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT code_insee, code_postal, name_fr, name_br, geom FROM communes;",
                "-t_srs", "EPSG:4326"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  #
  print("")
  #

  # export GPX du tracé
  print("  Export gpx du tracé")
  export_cmd = ["ogr2ogr", "-f", "GPX",
                f"../data/{millesime}/export/gpx/ar_redadeg_{millesime}_trace.gpx",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT 'secteur '||secteur_id AS name, ST_Simplify(the_geom, 1.0) FROM phase_5_trace ORDER BY secteur_id",
                "-t_srs", "EPSG:4326",
                "-lco", "FORCE_GPX_TRACK=YES",
                "-nlt", "linestring"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  #

  # export GPX des PK
  print("  Export gpx des PK")
  export_cmd = ["ogr2ogr", "-f", "GPX",
                f"../data/{millesime}/export/gpx/ar_redadeg_{millesime}_pk.gpx",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT pk_id AS name, way_name_fr ||', '||municipality_name_fr AS desc, the_geom FROM phase_5_pk ORDER BY pk_id",
                "-t_srs", "EPSG:4326",
                "-nlt", "point"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  #

  # export CSV liste des voies pour préfectures
  print("  Export CSV liste des voies pour préfectures")
  export_cmd = ["ogr2ogr", "-f", "CSV",
                f"../data/{millesime}/export/phase_5_prefecture_liste.csv",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT * FROM phase_5_prefecture_liste ORDER BY pk_id ;",
                "-lco", "SEPARATOR=SEMICOLON"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")


  #

  # export CSV table des statistiques par commune
  print("  Export CSV table des statistiques par commune")
  export_cmd = ["ogr2ogr", "-f", "CSV",
                f"../data/{millesime}/export/communes_stats.csv",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT * FROM communes_stats ORDER BY pk_min ;",
                "-lco", "SEPARATOR=SEMICOLON"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")


  #

  print("  Export CSV de la table des secteurs")
  export_cmd = ["ogr2ogr", "-f", "CSV",
                f"../data/{millesime}/export/secteurs.csv",
                f"PG:host={db_redadeg_host} port={db_redadeg_port} user={db_redadeg_user} password={db_redadeg_passwd} dbname={db_redadeg_db}",
                "-sql", "SELECT * FROM public.secteur ORDER BY id ;",
                "-lco", "SEPARATOR=SEMICOLON"]
  # on exporte
  subprocess.check_output(export_cmd)
  print("  fait")

  #

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


