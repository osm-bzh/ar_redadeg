#!usr/local/bin/python
# -*- coding: utf-8 -*-

# https://stackoverflow.com/questions/53380988/how-to-execute-shell-script-from-flask-app

import subprocess
from subprocess import Popen, PIPE
from subprocess import check_output

script = '/data/projets/ar_redadeg/scripts/traitements_phase_1.sh 2022'

def get_shell_script_output_using_communicate():
  session = Popen([script], stdout=PIPE, stderr=PIPE, shell=True)
  stdout, stderr = session.communicate()
  if stderr:
      raise Exception("Error "+str(stderr))
  return stdout.decode('utf-8')

def get_shell_script_output_using_check_output():
    stdout = check_output([script]).decode('utf-8')
    return stdout


def main():

  return '<pre>'+get_shell_script_output_using_communicate()+'</pre>'
  pass


if __name__ == "__main__":
    # execute only if run as a script
    main()


