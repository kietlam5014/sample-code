#!/usr/bin/env python

"""
Author: Kiet Lam
DateTime: Dec 01, 2014
Description: Read list of gerrits,
             order the gerrits based on its dependency,
             and save these back to Input_gerritlist.
"""
import sys
import os
import subprocess
import argparse
import json
from Gerrit import *
import pdb


depGerritList = []     # gerrit with its dependencies
depStatus = None
server = 'review-android.quicinc.com'

def getListOfDependencies(gerritInfo, minCRs):
        global depStatus

	if gerritInfo.isMerged():
	    print "%s is merged" % gerritInfo.gerrit
	    return "Merge"

	if not gerritInfo.isGood(minCRs):
	    depStatus = -1
	    return

        depGerritList.append(gerritInfo.gerrit)
        glist = gerritInfo.dependsOn()
	if not (glist == None):
            if 'ANCESTOR_NOT_FOR_BRANCH' in glist:
                depStatus = -1
                return
        if not (glist == None):
            if not (glist == False):
                if len(glist.split()) > 1:
                    for g in glist.split():
                        gerrit = g
                        gerritInfo = Gerrit(gerrit, server)
                        getListOfDependencies(gerritInfo, minCRs)
                else:
                    gerrit = ''.join(glist)
                gerritInfo = Gerrit(gerrit, server)
                getListOfDependencies(gerritInfo, minCRs)


def readGerritListFile(gerritlist_file):
	gerritlist = []

	inputgl_fd = open(gerritlist_file, "r+")
	for line in inputgl_fd:
#		if line in ['\n', '\r\n']:
#			continue
		if "New" in line or "Gerrits" in line:
			continue
		gerritlist.append(line.rstrip('\n'))
	inputgl_fd.close()
	return gerritlist



def main():
	orderDepGerrits = []   # gerrits in dependency order
	global depGerritList
	global depStatus
	global server
	curDir = os.getcwd()
	minCRs = 3

        parser = argparse.ArgumentParser(description='dependencyOrder script')
        parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
	parser.add_argument('-s','--server',action='store',dest='server', help='gerrit server',required=False)
	parser.add_argument('-c','--mincrs',action='store',dest='mincrs', help='Minimum CRs to consider good',required=False)
        parser.add_argument('-f','--file',action='store',dest='gerritListFile',help='gerrits',required=False)
        results = parser.parse_args()

	if results.server:
	    server = results.server

	if results.mincrs:
	    minCRs = results.mincrs

        if results.gerrits:
        	gerritlist = results.gerrits
	else:
        	gerritListFile = results.gerritListFile
		gerritlist = readGerritListFile(gerritListFile)
	for gerrit in gerritlist:
	    depStatus = 0
	    if gerrit in depGerritList:
	        continue
	    if gerrit in orderDepGerrits:
		continue
	    gerritInfo = Gerrit(gerrit.decode("utf-8"), server)
	    getListOfDependencies(gerritInfo, minCRs)
	    if depStatus == -1:
	        depGerritList = []
	    else:
	        orderDepGerrits = orderDepGerrits + depGerritList
	    depGerritList = []

	# write depGerritList to file
	fo = open(os.path.join(curDir,'Input_gerritlist.txt'), "w+")
	fo.seek(0, 2) # write at the end of the file
	for n in reversed(range(len(list(set(orderDepGerrits))))):
            gerritInfo = Gerrit(orderDepGerrits[n].decode("utf-8"), server)
	    extGerrit = gerritInfo.externalDependsOn()
	    print orderDepGerrits[n], extGerrit
	    fo.writelines(('%s\n') % (orderDepGerrits[n]))
	fo.close()

	print "dependency gerrits:",
	for n in reversed(range(len(list(set(orderDepGerrits))))):
	    print orderDepGerrits[n],

if __name__ == '__main__':
        main()
