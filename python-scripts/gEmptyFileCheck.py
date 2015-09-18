#!/usr/bin/env python

# Author: Kiet Lam
# Desc  : Check if a given gerrit has empty files
# Dec 08, 2014

import argparse
from Gerrit import *

def main():
    server = 'review-android.quicinc.com'
    hasError = False
    latest = False

    parser = argparse.ArgumentParser(description='gEmptyFileCheck script')
    parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
    parser.add_argument('-l','--latest', action='store_true', help='check just latest patchset',required=False)
    parser.add_argument('-s','--server',action='store',dest='server', help='gerrit server',required=False)

    results = parser.parse_args()

    if results.gerrits:
        gerritlist = results.gerrits

    if results.latest:
        latest = True

    if results.server:
        server = results.server

    for gerritID in gerritlist:
	gerritError = False
        print "\nFilelist Check Gerrit %s: " % gerritID
        gerrit = Gerrit(gerritID.decode("utf-8"), server)
	createdOn = gerrit.createdOn()
	if latest:
	    lastupdate = gerrit.lastUpdated()
	    if len(gerrit.filePath()) == 0:
	        print "[%s] ERROR: no files associated" % lastupdate
	        hasError = True
	else:
	    for m in xrange(len(gerrit.gerritInfo['patchSets'])):
	        if len(gerrit.gerritInfo['patchSets'][m]['files']) == 1:
		    createdOn = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(gerrit.gerritInfo['patchSets'][m]['createdOn']))
	            print "   patchSets %s [%s] ERROR: no files associated" % (m, createdOn)
	            hasError = True
		    gerritError = True
		    # break

	if not gerritError:
	    print "   [%s] OK" % createdOn

    if hasError:
        sys.exit(-1)

if __name__ == '__main__':
        main()

