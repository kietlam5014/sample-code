#!/usr/bin/env python

## Author: Kiet Lam
## Date  : Jan 18, 2015
## Description: For each project, get all gerrits that have at least following requirements:
##              - mincrs (CR+1)s and DV+1,
##              - clean SI Status

import subprocess
import argparse
import pwd
import json
from ConfigParser import SafeConfigParser
from Gerrit import *
import pdb


def readConfig(config, cfgFile):
#
# read config file and check required sections/keys
#
    '''
    Example config ini format:

    [default]
    project = prima
    mincrs  = 2
    target  = msm8916
    branch  = master_prima
    test    = True

    [projects]
    platform/vendor/qcom-proprietary/wlan = master_prima
    platform/external/wpa_supplicant_8 = LA.BR.1
    platform/hardware/qcom/wlan = LA.BR.1
    platform/vendor/qcom-proprietary/ship/wlan/utils = LA.BR.1
    platform/vendor/qcom-proprietary/ship/wlan/ath6kl-utils = LA.BR.1
    '''

    config.read(cfgFile)

    # test sections
    for section in ['default', 'projects']:
        if not config.has_section(section):
            print "%s does not exist" % section
            sys.exit(-1)

    # test 'default' key
    for k in ['project', 'mincrs', 'target', 'branch']:
        if not config.has_option('default', k):
            print "%s does not exist" % k
            sys.exit(-1)


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
	                elif 'CORE/MAC/inc/qwlan_version.h'.lower() in GerritFileItem['file'].lower():
	                    valid_files = False
	                elif r'platform/vendor/qcom-proprietary/wlan' in GerritInfo['project']:
	                    if target in ['msm8974', 'msm8916', 'msm8909']:
	                        if 'prima' != GerritFileItem['file'].split('/')[0]:
	                            valid_files = False
	                            break
	                        else:
	                            valid_files = True
	                    elif target in ['apq8084', 'msm8994']:
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
	print "project :%s" % project
	print "branch  :%s" % branch
	print "target  :%s" % target
	print "min crs :%s" % mincrs
	print "test req:%s" % test
	gerritList = getOpenGerrits(project, branch, target)
	for gerritNum in gerritList:
	    gerritNum = gerritNum.strip()
	    gerrit = Gerrit(gerritNum)
	    if gerrit.isGood(mincrs) == 'Approved':
	        continue
	    if not gerrit.ciStatuses() == None:
	        cimsg = ' '.join(gerrit.ciStatuses())
	    print "Processing gerrit:%s " % gerritNum
	    if gerrit.isGood(mincrs) and (gerrit.ciStatuses() == None or 'Queued at position' in cimsg or 'Change is being verified' in cimsg or 'is not enabled for BAIT automation' in cimsg):
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
	curDir = os.getcwd()
	project = None
	branch  = None
	gerrit  = None
	verifiedGerrits = []
	excludedGerrits = []
	projects = []
	target = 'msm8916'
	mincrs = 2
	testRequired = True
	config = SafeConfigParser()

	parser = argparse.ArgumentParser(description='Get open gerrits')
	parser.add_argument('-p','--project', action='store', dest='project', help='project', required=False)
	parser.add_argument('-b','--branch', action='store', dest='branch', help='branch', required=False)
	parser.add_argument('-t','--target', action='store', dest='target', help='target (msm8974|apq804)', required=False)
	parser.add_argument('-g','--gerrit', action='store',dest='gerrit', help='gerrit',required=False)
	parser.add_argument('-m','--mincrs', action='store',dest='mincrs', help='minimum crs',required=False)
	parser.add_argument('--test', action='store_true', help='needed test result')
	parser.add_argument('-c','--config', action='store',dest='config', help='config file to read',required=False)
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
	if results.config:
	    configFile = results.config
	    readConfig(config, configFile)
	    project = config.get('default', 'project')
	    mincrs  = config.get('default', 'mincrs')
            target  = config.get('default', 'target')
            branch  = config.get('default', 'branch')
	    testRequired = config.get('default', 'test')

	# process just one given gerrit. for debugging purpose of particular gerrit when needed
	if results.gerrit:
		gerritNum = results.gerrit
		gerrit = Gerrit(gerritNum)
		if not gerrit.ciStatuses() == None:
		    cimsg = ' '.join(gerrit.ciStatuses())
		if gerrit.isGood(mincrs) and (gerrit.ciStatuses() == None or 'Queued at position' in cimsg or 'Change is being verified' in cimsg or 'is not enabled for BAIT automation' in cimsg):
		    verifiedGerrits.append(gerritNum)
		    print "Processed gerrit:%s " % gerritNum
		    sys.exit(0)
		else:
		    print "Excluded gerrits: %s" % gerritNum
		    sys.exit(-1)

	# process all projects
	if results.config:
	    for project, branch in config.items('projects'):
	        verifiedGerrits, excludedGerrits = processGerrits(project, branch, target, mincrs, testRequired)
	    sys.exit(0)

	if project and branch and target:
	    verifiedGerrits, excludedGerrits = processGerrits(project, branch, target, mincrs, testRequired)

if __name__ == '__main__':
	main()
