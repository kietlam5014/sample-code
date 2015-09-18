#!/usr/bin/env python

# Author: Kiet Lam
# Oct 12, 2014

import sys
import os
import argparse
from Gerrit import *


def main():
    server = 'enter-server-here'

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
        print "subject    : %s" % gerrit.subject()
        print "ref        : %s" % gerrit.ref()
        print "dependsOn  : %s" % gerrit.dependsOn()
        print "extDepend  : %s" % gerrit.externalDependsOn()
	print "Id match?  : %s" % gerrit.isIdMatch()
if __name__ == '__main__':
        main()

