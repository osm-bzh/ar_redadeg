import subprocess
from subprocess import Popen, PIPE
from subprocess import check_output
from flask import Flask


def hello():
  stdout = check_output(['./hello.sh']).decode('utf-8')
  return stdout


app = Flask(__name__)



@app.route('/',methods=['GET',])
def home():
  return '<pre>'+hello()+'</pre>'


@app.route('/phase_1/',methods=['GET',])
def phase1():
  stdout = '<pre>'+check_output(['../scripts/traitements_phase_1.sh']).decode('utf-8')+'</pre>'
  return stdout


app.run(debug=True)

