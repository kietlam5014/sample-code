#!/usr/bin/env python

# Author: Kiet Lam
# Oct 12, 2014

import sys
import os
import argparse
from Gerrit import *


def main():
    server = 'review-android.quicinc.com'

    parser = argparse.ArgumentParser(description='dependencyOrder script')
    parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
    parser.add_argument('-s','--server',action='store',dest='server', help='gerrit server',required=False)
    results = parser.parse_args()

    if results.gerrits:
        gerritlist = results.gerrits

    if results.server:
        server = results.server

    for gerritID in gerritlist:
        gerrit = Gerrit(gerritID.decode("utf-8"), server)
        ci_status = gerrit.ciStatuses()
        print ""
        print "gerrit     : %s" % gerrit.gerrit
	print "id         : %s" % gerrit.id()
        print "is good?   : %s" % gerrit.isGood()
        print "merged?    : %s" % gerrit.isMerged()
        print "owner email: %s" % gerrit.ownerEmail()
        print "branch     : %s" % gerrit.branch()
        print "PLs        : %s" % gerrit.branchPLs()
        print "file path  : %s" % gerrit.filePath()
        print "project    : %s" % gerrit.project()
        print "subject    : %s" % gerrit.subject()
        print "ref        : %s" % gerrit.ref()
        print "dependsOn  : %s" % gerrit.dependsOn()
        print "extDepend  : %s" % gerrit.externalDependsOn()
        print "LA set?    : %s" % gerrit.lnxbuild()
        print "KW set?    : %s" % gerrit.kwuser()
	print "Id match?  : %s" % gerrit.isIdMatch()
        print "CRs        : %s" % gerrit.CRs()
	if not (ci_status == None):
	    print "CI Status  :\n%s\n    %s" % (ci_status[0], ci_status[1])

if __name__ == '__main__':
        main()

