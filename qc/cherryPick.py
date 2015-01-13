#!/usr/bin/env python
#
# Author: Kiet Lam
# Desc  : Cherry pick given gerrits.  Assume you're in the git project for this set of gerrits
# Date  : Nov 04, 2014

import sys
import os
import pwd
import argparse
import git
from subprocess import Popen, PIPE, STDOUT
from Gerrit import *

# default
server = 'review-android.quicinc.com'

def resetToTipOfCommit():
    cmd = ("git reset --hard").split(' ')
    resetPipe = Popen(cmd, stdout=PIPE, stderr=PIPE)
    (output, error) = resetPipe.communicate()
    if resetPipe.returncode != 0:
        print output
        raise IOError, "git reset %s failed" % (cmd)

def isCherryPicked(gerritinfo):
#
# check and return TRUE if already cherry-picked
#
    repo = git.Repo()
    changeID = gerritinfo.id().encode("utf-8")
    if changeID in repo.git.log():
        return True
    else:
        return False

def cherryPickChange(gerritinfo):
    user = pwd.getpwuid(os.getuid())[0]
    project = gerritinfo.project()
    ref = gerritinfo.ref()
    cherryFetchCmd = "git fetch ssh://"+user+"@"+server+":29418"+"/"+project+" "+ref
    cherryPickCmd = "git cherry-pick FETCH_HEAD"
    print "Cherrypicking %s" % gerritinfo.gerrit,

    try:
        fetchPipe = Popen(cherryFetchCmd.split(' '), stdout=PIPE, stderr=PIPE)
        (output, error) = fetchPipe.communicate()
    except IOError:
        if fetchPipe.returncode != 0:
            print output
            raise Exception('git command %s failed' % (cherryFetchCmd))
    pickPipe = Popen(cherryPickCmd.split(' '), stdout=PIPE, stderr=PIPE)
    (output, error) = pickPipe.communicate()

    if pickPipe.returncode != 0:
        print "failed"
        resetToTipOfCommit()
        return -1
    print "success"
    return 0


def main():
	global server
	gerritlist = []
	status = 0

	parser = argparse.ArgumentParser(description='Cherry Picker')
	parser.add_argument('-g','--gerrit',action='store',dest='gerrits',nargs='+', help='<Required> gerrit',required=False)
	parser.add_argument('-s','--server',action='store',dest='server', help='gerrit server',required=False)
	parser.add_argument('-f','--file',action='store',dest='gerritListFile',help='file with list of gerrits',required=False)
	results = parser.parse_args()

        if results.server:
            server = results.server

	if results.gerrits:
	    gerritlist = results.gerrits

	if results.gerritListFile:
	    fd = open(results.gerritListFile, "r+")
	    for line in fd:
	        gerritlist.append(line.rstrip('\n'))

        for gerrit in gerritlist:
            gerritInfo = Gerrit(gerrit.decode("utf-8"), server)
	    if isCherryPicked(gerritInfo):
	        print "%s already cherry-picked. Skip" % gerrit
	        continue
	    status = cherryPickChange(gerritInfo)
	    if status:
	        status = -1

	return status

if __name__ == '__main__':
        main()
