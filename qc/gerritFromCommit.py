#!/usr/bin/env python
# Author: Kiet Lam
# Date  : Dec 22, 2014
#
# Desc  : Get list of gerrit(s) from base commit hash to tip
#
#
import os
import argparse
import json


def getCommits(commitBased):
#
# Return list of commits
#
   commitList = []
   commitInfo_txt = '/tmp/commitInfo.' + str(os.getpid())
   cmd = 'git log --pretty=%s %s..HEAD > %s' % ('%h', commitBased, commitInfo_txt)
   os.system(cmd)
   with open(commitInfo_txt,"r") as fd:
      for line in fd:
          commitList.append(line.strip())
   return commitList


def getGerrits(commitList, branch='master'):
#
# Return list of gerrits
#
   gerritList = []
   gerritInfo_txt = '/tmp/gerritInfo.' + str(os.getpid())
   for commit in reversed(commitList):
       cmd = "ssh -p 29418 review-android.quicinc.com gerrit query --format=JSON commit:%s branch:%s --current-patch-set > %s" % (commit, branch, gerritInfo_txt)
       os.system(cmd)
       fd = open(gerritInfo_txt,"r")
       line = fd.readline()
       gerritInfo = json.loads(line)   
       fd.close()
       os.unlink(gerritInfo_txt)
       gerritList.append(gerritInfo['number'])
   return gerritList


def main():
    commitList    = []
    gerritList    = []
    parser = argparse.ArgumentParser()
    parser.add_argument('-c','--commit',action='store',dest='commit',nargs='+', help='based commit hash',required=True)
    results = parser.parse_args()

    if results.commit:
       commitBased = ' '.join(results.commit)

    commitList = getCommits(commitBased)
    gerritList = getGerrits(commitList)

    for gerritId in gerritList:
        print gerritId,


if __name__ == '__main__':
        main()
