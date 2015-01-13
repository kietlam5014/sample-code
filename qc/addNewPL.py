#!/usr/bin/env python
#
# Author: Kiet Lam
# Date  : Nov 5, 2014
# Desc  : For each gerrit(s), add new PL to its CR
#

import sys
import os
import argparse
import pdb
from Prism import *
from Gerrit import *

def main():
    refPL = 'LNX.LA.0.0'          # default to reference PL to use if user not supply
    target = 'ALL'                # default target if not supply
    version_GerritCRId = '688141' # version gerrit CR Id need not tagged
    gerritlist = []
    cr = None

    parser = argparse.ArgumentParser(description='Add new PL script')
    parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
    parser.add_argument('-p','--refpl',action='store',dest='refpl', help='reference PL to use',required=False)
    parser.add_argument('-n','--newpl',action='store',dest='newpl', help='new product line',required=True)
    parser.add_argument('-t','--target',action='store',dest='target', help='new pl target',required=False)
    parser.add_argument('-m','--notes',action='store',dest='notes', help='target lead notes',required=False)
    results = parser.parse_args()

    if results.gerrits:
        gerritlist = results.gerrits
    if results.refpl:
        refPL = results.refpl
    if results.newpl:
        newPL = results.newpl
    if results.target:
        target = results.target
    if results.notes:
        notes = results.notes

    for gerritId in gerritlist:
        crIdList = []
        gerritInfo = Gerrit(gerritId.decode("utf-8"))
        crIdList.append(gerritInfo.CRs())
	if None in crIdList:
	    print "%s is missing a CR!" % gerritId
	    sys.exit(1)
        for crId in crIdList:
	    if crId == version_GerritCRId:
	        print "Skipping version gerrit CR Id"
	        continue
            prism = Prism(crId, refPL)
            cr = prism.getChangeRequestById(crId)
            cr = prism.addNewPL(cr, newPL, target, notes)
            info = prism.saveChangeRequest(cr)
	    if type(info) == str:
	        print info
	        print "Error on %s" % crId
	        sys.exit(1)
	    else:
	        print "%s updated successfully with new PL" % crId

if __name__ == '__main__':
        main()
