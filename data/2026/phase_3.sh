#! /bin/bash


python3 phase_3_prepare.py 2026 100 ; python3 phase_3_compute.py 2026 100
python3 phase_3_prepare.py 2026 200 ; python3 phase_3_compute.py 2026 200
python3 phase_3_prepare.py 2026 300 ; python3 phase_3_compute.py 2026 300
python3 phase_3_prepare.py 2026 400 ; python3 phase_3_compute.py 2026 400
python3 phase_3_prepare.py 2026 500 ; python3 phase_3_compute.py 2026 500
python3 phase_3_prepare.py 2026 600 ; python3 phase_3_compute.py 2026 600
python3 phase_3_prepare.py 2026 700 ; python3 phase_3_compute.py 2026 700
python3 phase_3_prepare.py 2026 800 ; python3 phase_3_compute.py 2026 800

python3 update_pk_infos.py 2026

./phase_3_export.sh 2026

