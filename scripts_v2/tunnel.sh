#! /bin/bash

# crée un tunnel SSH vers le serveur PostgreSQL de ar redadeg

ssh -L 55432:bed110.bedniverel.bzh:5432 bed110.bedniverel.bzh
