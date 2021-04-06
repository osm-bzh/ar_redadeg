#!usr/local/bin/python
# -*- coding: utf-8 -*-

from flask import Flask

import subprocess
from subprocess import Popen, PIPE
from subprocess import check_output




app = Flask(__name__)


@app.route("/")
def index():
  return "<h1 style='color:blue'>Ar Redadeg API</h1>"
  pass


@app.route("/test/")
def test():
  stdout = check_output(['./test.sh']).decode('utf-8')
  return stdout


@app.route("/phase1/")
def test():
  stdout = check_output(['../scripts/traitements_phase_1.sh']).decode('utf-8')
  return stdout



@app.route("/about/")
def about():
  return "This is a simple Flask Python application"


if __name__ == "__main__":
    app.debug = True
    app.run(host='0.0.0.0')
