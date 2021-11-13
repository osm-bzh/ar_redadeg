#! /bin/bash


python3 phase_3_prepare.py 2022 100
python3 phase_3_prepare.py 2022 200
python3 phase_3_prepare.py 2022 300
python3 phase_3_prepare.py 2022 400
python3 phase_3_prepare.py 2022 500
python3 phase_3_prepare.py 2022 600
python3 phase_3_prepare.py 2022 700
python3 phase_3_prepare.py 2022 800
python3 phase_3_prepare.py 2022 900

python3 phase_3_compute.py 2022 100
python3 phase_3_compute.py 2022 200
python3 phase_3_compute.py 2022 300
python3 phase_3_compute.py 2022 400
python3 phase_3_compute.py 2022 500
python3 phase_3_compute.py 2022 600
python3 phase_3_compute.py 2022 700
python3 phase_3_compute.py 2022 800
python3 phase_3_compute.py 2022 900

./phase_3_export.sh 2022
