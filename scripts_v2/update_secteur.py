#!/usr/bin/python
# -*- coding: utf-8 -*-

#
# Libraries
#

import sys
import subprocess
import time

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

      # ok : on passe au type de mise à jour demandé
      if len(list_of_args[3]) > 3:
        if list_of_args[3] == "tout": typemaj = "tout"
        elif list_of_args[3] == "routage": typemaj = "routage"
        else:
          print("Mauvais type de traitement en argument")
          sys.exit()
      else:
        print("Pas de type de traitement en argument")
        sys.exit()

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
print("Début de la mise à jour des données du secteur "+str(secteur)+" pour le millésime "+str(millesime))
print("")


if typemaj == "tout":
  print("maj données phase 1 + maj du filaire de voirie routable")
  
  try:  
    subprocess.call(["./phase_1.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)
    subprocess.call(["./create_osm_roads.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)
    subprocess.call(["./update_osm_roads_pgr.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)

    print("")
    stopTime = time.perf_counter()
    hours, rem = divmod(stopTime - startTime, 3600)
    minutes, seconds = divmod(rem, 60)
    print("Exécuté en {:0>2}:{:0>2}:{:05.2f}".format(int(hours),int(minutes),seconds))

  except subprocess.CalledProcessError as e:
      raise RuntimeError("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))


if typemaj == "routage":
  print("maj du routage")

  try:
    subprocess.call(["./phase_2.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)
    subprocess.call(["./phase_2_routing_prepare.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)
    subprocess.call(["./phase_2_routing_compute.sh "+millesime+" "+secteur],shell=True,stderr=subprocess.STDOUT)

    print("")
    stopTime = time.perf_counter()
    hours, rem = divmod(stopTime - startTime, 3600)
    minutes, seconds = divmod(rem, 60)
    print("Exécuté en {:0>2}:{:0>2}:{:05.2f}".format(int(hours),int(minutes),seconds))

  except subprocess.CalledProcessError as e:
      raise RuntimeError("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))
  
  print("")



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


