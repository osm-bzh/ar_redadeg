#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import configparser
import argparse
from argparse import RawTextHelpFormatter
import psycopg2


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



def initVariables():

  # lecture du fichier de configuration qui contient les infos de connection aux bases de données
  config = configparser.ConfigParser()
  config.read('config.ini')

  # enregistrement en variables
  pg_host = config['pg_redadeg']['host']
  pg_port = config['pg_redadeg']['port']
  pg_db = config['pg_redadeg']['db'] + "_" + millesime
  pg_user = config['pg_redadeg']['user']
  pg_passwd = config['pg_redadeg']['passwd']

  # chaîne de connexion Postgres
  global PG_ConnString
  PG_ConnString = "host="+ pg_host + " port="+ pg_port +" dbname="+ pg_db +" user="+ pg_user +" password="+ pg_passwd
  #print(PG_ConnString)



# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


def main():

  # variables globales
  global millesime
  global PG_ConnString

  # millesime forcé
  millesime = "2022"

  initVariables()
  

  # connection à la base
  try:
    # connexion à la base, si plante, on sort
    conn = psycopg2.connect(PG_ConnString)
    cursor = conn.cursor()

  except:
    print( "connexion à la base impossible")


  # déconnection de la base
  try:
    cursor.close()
    conn.close()
  except:
    print("")

  
  print( "")
  print( "  F I N")

  return


if __name__ == "__main__":
    # execute only if run as a script
    main()


