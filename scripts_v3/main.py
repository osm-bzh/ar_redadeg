import argparse

from phase1 import run_phase1
from phase2 import run_phase2


# ==================================================================================================

def main():
    parser = argparse.ArgumentParser(description="Gestion des phases d'un projet.")
    parser.add_argument("--millesime", type=int, required=True, help="Millésime du projet (année).")
    parser.add_argument("--phase", type=int, required=True, choices=[1, 2], help="Phase du projet (1 ou 2).")

    args = parser.parse_args()

    if args.phase == 1:
        print(f"Exécution de la phase 1 pour le millésime {args.millesime}.")
        run_phase1(args.millesime)
    elif args.phase == 2:
        print(f"Exécution de la phase 2 pour le millésime {args.millesime}.")
        run_phase2(args.millesime)


if __name__ == "__main__":
    main()
