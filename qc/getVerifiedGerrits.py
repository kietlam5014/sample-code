#!/usr/bin/env python

## Author: Kiet Lam
## Date  : Dec 22, 2014
## Description: For each project, get all gerrits that have at least following requirements:
##              - three (CR+1)s and DV+1,
##              - clean SI Status

import subprocess
import argparse
import pwd
import json
from Gerrit import *
import pdb

def getOpenGerrits(project, branch, target):
	open_gerrits = []
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query project:%s branch:%s --format=JSON status:open --commit-message --current-patch-set --files  > /tmp/open_gerritlist.txt" % (project, branch)
	os.system(cmd)

	gerrit_file = open('/tmp/open_gerritlist.txt','r')
	for line in gerrit_file:
	    if 'project' in line:
	        GerritInfoItem = {'GerritId': '', 'AssigneeId': '', 'Assignee': '', 'GerritUrl': [], 'Project': '', 'CRInformation': '', 'GerritStatus': ''}
	        GerritInfo = json.loads(line)
	        GerritInfoItem['GerritId'] = GerritInfo['number']

	        if 'files' in GerritInfo['currentPatchSet'].keys():
	            for GerritFileItem in GerritInfo['currentPatchSet']['files']:
	                if 'COMMIT_MSG' in GerritFileItem['file']:
	                    valid_files = False
	                elif 'CORE/MAC/inc/qwlan_version.h' in GerritFileItem['file']:
	                    valid_files = False
	                elif r'platform/vendor/qcom-proprietary/wlan' in GerritInfo['project']:
	                    if 'msm8974' in target:
	                        if 'prima' != GerritFileItem['file'].split('/')[0]:
	                            valid_files = False
	                            break
	                        else:
	                            valid_files = True
	                    elif 'apq8084' in target:
	                        if 'qcacld-new' != GerritFileItem['file'].split('/')[0]:
	                            valid_files = False
	                            break
	                        else:
	                            valid_files = True
	                else:
	                    valid_files = True
                if False == valid_files:
	            continue
                GerritInfoItem['GerritId'] = GerritInfoItem['GerritId'] + "\n"
	        open_gerrits.append(GerritInfoItem['GerritId'])
	return open_gerrits
	gerrit_file.close()
	os.unlink('/tmp/open_gerritlist.txt')


def processGerrits(project, branch, target, mincrs, test):
#
# return verfiedGerrits, exludedGerrits
#
	verifiedGerrits = []
	excludedGerrits = []
	print "\n"
	print "project:%s" % project
	print "branch :%s" % branch
	print "target :%s" % target
	gerritList = getOpenGerrits(project, branch, target)
	for gerritNum in gerritList:
	    gerritNum = gerritNum.strip()
	    gerrit = Gerrit(gerritNum)
	    if gerrit.isGood(mincrs) == 'Approved':
	        continue
	    if not gerrit.ciStatuses() == None:
	        cimsg = ' '.join(gerrit.ciStatuses())
	    print "Processing gerrit:%s " % gerritNum
	    if gerrit.isGood(mincrs) and (gerrit.ciStatuses() == None or 'Queued at position' in cimsg or 'Change is being verified' in cimsg):
	        # if --test supplied, check for test result
	        if test:
	            comment = gerrit.commentsSearch(r'TEST STATUS:.*\d+|TEST RESULT')
	            if comment:
	                verifiedGerrits.append(gerritNum)
	            else:
		        excludedGerrits.append(gerritNum)
		        continue
	        else:
	            verifiedGerrits.append(gerritNum)
	    else:
	        excludedGerrits.append(gerritNum)

	if excludedGerrits:
	    print "\nExcluded gerrits: "
	    for exg in excludedGerrits:
	        print exg,

	if verifiedGerrits:
	    print "\n\nCandidate gerrits: "
	    for gerritNum in verifiedGerrits:
	        print gerritNum,


	return (verifiedGerrits, excludedGerrits)


def main():
	projects = {
	  'platform/vendor/qcom-proprietary/wlan': 'master',
	  'platform/external/wpa_supplicant_8': 'kitkat',
	  'platform/hardware/qcom/wlan': 'kk',
	  'platform/vendor/qcom-proprietary/ship/wlan/utils': 'master',
	  'platform/vendor/qcom-proprietary/ship/wlan/ath6kl-utils': 'master'
	}


	curDir = os.getcwd()
	project = None
	branch  = None
	gerrit  = None
	mincrs  = 3
	target  = 'msm8974' # default target
	verifiedGerrits = []
	excludedGerrits = []
	testRequired = False

	parser = argparse.ArgumentParser(description='Get open gerrits')
	parser.add_argument('-p','--project', action='store', dest='project', help='project', required=False)
	parser.add_argument('-b','--branch', action='store', dest='branch', help='branch', required=False)
	parser.add_argument('-t','--target', action='store', dest='target', help='target (msm8974|apq804)', required=False)
	parser.add_argument('-g','--gerrit', action='store',dest='gerrit', help='gerrit',required=False)
	parser.add_argument('-m','--mincrs', action='store',dest='mincrs', help='minimum crs',required=False)
	parser.add_argument('--test', action='store_true', help='needed test result')
        results = parser.parse_args()

	if results.project:
		project = results.project
	if results.branch:
		branch = results.branch
	if results.target:
		target = results.target
	if results.mincrs:
		mincrs = results.mincrs
	if results.test:
		testRequired = True

	# process just one given gerrit. for debugging purpose of particular gerrit when needed
	if results.gerrit:
		gerritNum = results.gerrit
		gerrit = Gerrit(gerritNum)
		if not gerrit.ciStatuses() == None:
		    cimsg = ' '.join(gerrit.ciStatuses())
		if gerrit.isGood(mincrs) and (gerrit.ciStatuses() == None or 'Queued at position' in cimsg or 'Change is being verified' in cimsg):
		    verifiedGerrits.append(gerritNum)
		    print "Processed gerrit:%s " % gerritNum
		    sys.exit(0)
		else:
		    print "Excluded gerrits: %s" % gerritNum
		    sys.exit(-1)

	# process given project
	if project and branch:
	    verifiedGerrits, excludedGerrits = processGerrits(project, branch, target, mincrs, testRequired)
	    sys.exit(0)

	# process all projects
	if (not project) and (not branch):
		for project, branch in projects.iteritems():
	            verifiedGerrits, excludedGerrits = processGerrits(project, branch, target, mincrs, testRequired)

	if verifiedGerrits:
	    fo = open(os.path.join(curDir,'Input_gerritlist.txt'), "w")
	    fo.writelines(verifiedGerrits)
	    fo.close()

	print verifiedGerrits

if __name__ == '__main__':
	main()
