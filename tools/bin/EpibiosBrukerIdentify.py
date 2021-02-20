# /usr/bin/env python3

""" compute the scan identifier from a JSON bruker parameter file """ 

from subprocess import call
from subprocess import Popen
from subprocess import PIPE
from os.path import join
from os.path import basename
from os.path import dirname
from os.path import exists
from os.path import abspath
from os.path import pardir
from os.path import expanduser
from os import environ
from os import walk
from os import getcwd
from sys import argv
from sys import exit
from sys import stdout
from sys import stderr
from sys import platform
from optparse import OptionParser

import json
from pprint import pprint

def identify(fn):
  data = json.load(open(fn))
  method = data["Method"] 

  # the Melbourne data has 'Bruker:' prepended, so let's remove it this way
  method = method.split(":")[-1] 

  if method == "RARE":
    return method
  elif method == "MGE":
    return method
  elif method == "FieldMap":
    return method
  elif method == "PRESS":
    return method
  elif method == "FLASH" or method == "<Bruker:FLASH>":
    if "PVM_DeriveGains" in data and "PVM_MagTransOnOff" in data:
      return "FLASH_%s_%s" % (data["PVM_DeriveGains"], data["PVM_MagTransOnOff"])
  elif method == "dtiEpiT" or method == "DtiEpi":
    postfix = "" 
    if "PVM_DwGradRead" in data:
      postfix = "_%s" % data["PVM_DwGradRead"]
    if data["PVM_DwDir"].split(" ")[0] == "1":
      return "DWIR%s" % postfix
    else:
      return "DWI%s" % postfix
  elif method == "EPI":
    if "PVM_MtP0" in data and "PVM_DeriveGains" in data:
      return "%s_%s_%s" % (method, data["PVM_DeriveGains"], data["PVM_MtP0"])

  return "Unknown_%s" % method

def main():
    usage = "identify_scan.py [opts]"
    parser = OptionParser(usage=usage, description=__doc__)

    (opts, pos) = parser.parse_args()

    if len(pos) == 0:
        parser.print_help()
        return

    print(identify(pos[0]))

if __name__ == "__main__":
    main()
