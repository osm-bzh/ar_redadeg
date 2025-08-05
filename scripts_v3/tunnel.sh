#! /bin/bash

# crée un tunnel SSH vers le serveur PostgreSQL de ar redadeg
# ssh -L 55432:bed110.bedniverel.bzh:5432 bed110.bedniverel.bzh

# autossh
autossh -M 20000 -o "ServerAliveInterval 30" -t -L 55432:bed110.bedniverel.bzh:5432 bed110.bedniverel.bzh
