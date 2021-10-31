
################################################################################
################              FONCTION LOG_VERIF               #################
################################################################################


def log_verif(nom_fichier, txt, purger):

  # répertoire courant
  import os
  script_dir = os.path.dirname(os.path.abspath(__file__))

  if (purger == 1):
    # création d'un nouveau fichier texte contenant les logs
    log = open(script_dir + "\\logs\\" + nom_fichier + ".log", "w+")
    # remplir ce fichier avec le txt que l'on souhaite, nombre de lignes avant et après MàJ
    log.write(txt + "\n")
    print(txt)
    # puis fermeture du fichier
    log.close

  else:
    # ouverture du fichier sans supprimer les logs précédents
    log = open(script_dir + "\\logs\\"  + nom_fichier + ".log", "a")
    # remplir ce fichier avec le txt que l'on souhaite, nombre de lignes avant et après MàJ
    log.write(txt + "\n")
    print(txt)
    # puis fermeture du fichier
    log.close



