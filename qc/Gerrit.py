#!/usr/bin/env python
#
# Author: Kiet Lam
# Dec 22, 2014
#
import os
import sys
import xml.etree.ElementTree as ET
import subprocess
import json
import re
import time


class Gerrit(object):

	def __init__(self, gerrit, server='review-android.quicinc.com'):
	#
	# Constructor
	#
	    global fd
	    self.gerritInfo_txt = '/tmp/gerritInfo.' + str(os.getpid())
	    self.server = server
	    self.gerrit = gerrit
	    if not 'qca-git01' in self.server:
	        self.cmd = "ssh -p 29418 %s gerrit query --format=JSON --dependencies --commit-message --comments --patch-sets --current-patch-set --crs --pls --files change:%s > %s"%(self.server, self.gerrit, self.gerritInfo_txt)
	    else:
	        self.cmd = "ssh -p 29418 %s gerrit query --format=JSON --dependencies --commit-message --comments --patch-sets --current-patch-set --crs --files change:%s > %s"%(self.server, self.gerrit, self.gerritInfo_txt)
            try:
                subprocess.check_output([self.cmd],shell=True);
            except subprocess.CalledProcessError, e:
                print "Error in getting the gerrit info for gerrit %s"%(self.gerrit)
                return None

            fd = open(self.gerritInfo_txt,"r")
            line = fd.readline()
            self.gerritInfo = json.loads(line)
	    fd.close()
	    os.unlink(self.gerritInfo_txt)


	def id(self):
	#
	# return Change-Id
	#
	    return self.gerritInfo['id']

	def owner(self):
	#
	# return gerrit's owner
	#
	    return self.gerritInfo['owner']['name']

	def ownerName(self):
	#
	# return owner name
	#
	    return self.gerritInfo['owner']['name']

	def ownerEmail(self):
	#
	# return owner email
	#
	    return self.gerritInfo['owner']['email']

	def ownerUsername(self):
	#
	# return username
	#
	    return self.gerritInfo['owner']['username']

	def url(self):
	#
	# return url - eg https://review-android.quicinc.com/308853
	#
	    return self.gerritInfo['url']

	def createdOn(self):
	#
	# return created date - eg 2014-09-10 07:33:22
	#
	    return time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(self.gerritInfo['createdOn']))

	def lastUpdated(self):
	#
	# return last updated date - eg 2014-09-15 20:27:10
	#
	    return time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(self.gerritInfo['lastUpdated']))

	def status(self):
	#
	# return its status - eg status: NEW
	#
	    return self.gerritInfo['status']

	def ref(self):
	#
	# return ref - eg refs/changes/66/801366/2
	#
	    return self.gerritInfo['currentPatchSet']['ref']

	def project(self):
	#
	# return gerrit project - eg platform/vendor/qcom-proprietary/wlan
	#
	    return self.gerritInfo['project']

	def subject(self):
	#
	# return Commit Message
	#
	    return self.gerritInfo['subject']

	def branch(self):
	#
	# return gerrit's branch it's raised on
	#
	    return self.gerritInfo['branch']

	def branchPLs(self):
	#
	# return list of PLs
	#
	    if self.gerritInfo.has_key('pls'):
	        return self.gerritInfo['pls']
	    else:
	        return 'None'

	def currentPatchNum(self):
	#
	# return current patch set number
	#
	    return self.gerritInfo['currentPatchSet']['number']

	def currentPatchRev(self):
	#
	# return current patch set revision
	#
	    return self.gerritInfo['currentPatchSet']['revision']

	def filePath(self):
	#
	# return list of path/filename
	# Need to verify if it is not a merge-gerrit - which has 0 filePath
	#
	    if 'files' in self.gerritInfo['currentPatchSet'].keys():
		fileList = []
	        for fileItem in self.gerritInfo['currentPatchSet']['files']:
	            if not ('COMMIT_MSG' in fileItem['file']):
	                fileList.append(fileItem['file'])
		return fileList


	def dependsOn(self):
	#
	# return Depends On gerrit
	#
	    depGerrit = None
	    if 'dependsOn' not in self.gerritInfo.keys() and (not self.gerritInfo['dependencyErrors']):
	        return None

	    if 'dependencyErrors' in self.gerritInfo.keys():
	        if self.gerritInfo['dependencyErrors']:
	            return self.gerritInfo['dependencyErrors']

	    for i in xrange(len(self.gerritInfo['dependsOn'])):
	        if (self.gerritInfo['dependsOn'][i]['isCurrentPatchSet']):
	            depGerrit = self.gerritInfo['dependsOn'][i]['number']
	    return depGerrit


	def CRs(self):
	#
	# return a list of Cr(s)
	#
            commitMessage = self.gerritInfo['commitMessage']
            m = re.search('\nCRs?-Fixed: (.*)\n', commitMessage, re.IGNORECASE)
            if ((m != None) and (m.group(1))):
                CR_Fixed = m.group(1)
            else:
                CR_Fixed = None
            return CR_Fixed


	def externalDependsOn(self):
	#
	# return a list of external dependencies that is listed after 'Depends-On:'
	#
	    found = False
	    if 'rowCount' in self.gerritInfo:
	        return
	    for m in xrange(len(self.gerritInfo['comments'])):
	        if 'Depends-on' in self.gerritInfo['comments'][m]['message']:
	            dependsOn = re.findall('Depends-on:\s([\s*\d{6}]*)', self.gerritInfo['comments'][m]['message'])
	            found = True
	    if found:
	        if len(dependsOn) > 0:
                    return dependsOn[0].split()


	def commentsSearch(self, str, option=None):
	#
	# str - string to search for
	# option - ic (ignore case)
	#
	# return first comment having str found in its message
	#
            if not 'comments' in self.gerritInfo:
                return None
            for m in reversed(xrange(len(self.gerritInfo['comments']))):
	        if option == "ic":
	            match = re.search(str, self.gerritInfo['comments'][m]['message'], re.IGNORECASE)
		else:
		    match = re.search(str, self.gerritInfo['comments'][m]['message'])
                if match:
                    return self.gerritInfo['comments'][m]
            return None


	def ciStatuses(self):
	#
	# return statuses of CI
	#
	    statusURL = 'http://baites.qualcomm.com:9200/ci_status!review-android/_search?q=_id:' + self.gerrit
	    outFile = '/tmp/cistatus'
	    self.cmd = 'curl -s %s > %s' % (statusURL, outFile)
            try:
                subprocess.check_output([self.cmd],shell=True);
            except subprocess.CalledProcessError, e:
                print "curl error"
                return ''
            fd = open(outFile,"r")
            line = fd.readline()
            ciStatusInfo = json.loads(line)
            fd.close()
            os.unlink(outFile)

            if ciStatusInfo['hits']['total'] == 0:
                return None
            for m in xrange(len(ciStatusInfo['hits']['hits'])):
                return (ciStatusInfo['hits']['hits'][m]['_type'], ciStatusInfo['hits']['hits'][m]['_source']['reasons'][0])


	def isMerged(self):
	    if 'MERGED' in self.gerritInfo['status']:
	        return True
	    else:
	        return False


	def kwuser(self):
	#
	# return the value, if any, set by Klocwork Automation User
	#
	    if 'rowCount' in self.gerritInfo:
	        return
            if not 'approvals' in self.gerritInfo['currentPatchSet']:
                return False
	    for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
	        type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
	        if not (type == 'SUBM'):
	            desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
	            value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
	            name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
	            if 'Verified' in desc and 'Klocwork Automation User' in name:
	                return value


	def lnxbuild(self):
	#
	# return the value, if any, set by Linux Build Service Account (linux lookahead)
	#
	    if 'rowCount' in self.gerritInfo:
	        return
	    if not 'approvals' in self.gerritInfo['currentPatchSet']:
	        return False
	    for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
	        type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
		if not (type == 'SUBM'):
	            desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
	            value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
	            name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
	            if 'Verified' in desc and 'Linux Build Service Account' in name:
	                return value


        def devci_cnss_wlan(self):
        #
        # return the value, if any, set by devci-cnss-wlan
        #
            if 'rowCount' in self.gerritInfo:
                return
            if not 'approvals' in self.gerritInfo['currentPatchSet']:
                return False
            for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
                type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
	        if not (type == 'SUBM'):
                    desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
                    value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
                    name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
                    if 'Verified' in desc and 'devci-cnss-wlan' in name:
                        return value


	def gator(self):
	#
	# return the value, if any, set by Gator Service Account
	#
	    if 'rowCount' in self.gerritInfo:
	        return
	    if not 'approvals' in self.gerritInfo['currentPatchSet']:
	        return False
	    for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
	        type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
	        if not (type == 'SUBM'):
	            desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
	            value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
	            name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
	            if 'Code Review' in desc and 'Gator Service Account' in name:
	                return value


        def checkpatch(self):
        #
        # return the value, if any, set by Checkpatch Service Account
        #
            if 'rowCount' in self.gerritInfo:
                return
            if not 'approvals' in self.gerritInfo['currentPatchSet']:
                return False
            for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
                type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
	        if not (type == 'SUBM'):
                    desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
                    value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
                    name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
                    if 'Code Review' in desc and 'Checkpatch Service Account' in name:
                        return value


        def lostadm(self):
        #
        # return the value, if any, set by lost adm
        #
            if 'rowCount' in self.gerritInfo:
                return
            if not 'approvals' in self.gerritInfo['currentPatchSet']:
                return False
            for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
                type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']       
	        if not (type == 'SUBM'):
                    desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
                    value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']     
                    name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
                    if 'Code Review' in desc and 'lost adm' in name:
                        return value


	def isApprovedByFAO(self, pname, pdesc):
	#
	# pname - functional owner username
	# pdesc - type description - ie 'Code Review', 'Developer Verified'
	#
	# return true if approved by pname (Functional Area Owner) for pdesc type of approval
	#
	    if 'rowCount' in self.gerritInfo:
	        return
	    if not 'approvals' in self.gerritInfo['currentPatchSet']:
	        return False
	    for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
	        type  = self.gerritInfo['currentPatchSet']['approvals'][m]['type']
	        if not (type == 'SUBM'):
	            desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
	            value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
	            username  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['username']
	            if pname == username and pdesc == desc:
	                return True


	def isIdMatch(self):
	#
	# check and return true if Change-Id matches the Change-Id in Commit Message
	#
	    commitMessage = self.gerritInfo['commitMessage']
	    m = re.search('\nChange?-Id: (.*)\n', commitMessage, re.IGNORECASE)
	    if ((m != None) and (m.group(1))):
	        cmid = m.group(1)
	    else:
	        cmid = None
	    if cmid == self.id():
	        return True
	    else:
	        return False


	def isGood(self, minCRs=3):
	#
	# minCRs = minimum CRs required to be good candidate
	#
	# check and return true if it is good to be picked, otherwise return false
	# assumption is (at least minCRs of CR+1 & one DV+1) = good
	#
            cr = 0
            allVerified = int('000',2)

            if 'rowCount' in self.gerritInfo:
                return
            if 'MERGED' in self.gerritInfo['status']:
                return False
	    if 'ANCESTOR_OUTDATED' in self.gerritInfo['dependencyErrors']:
	        return False
	    if not 'approvals' in self.gerritInfo['currentPatchSet']:
	        return False
            for m in xrange(len(self.gerritInfo['currentPatchSet']['approvals'])):
                desc  = self.gerritInfo['currentPatchSet']['approvals'][m]['description']
                value = self.gerritInfo['currentPatchSet']['approvals'][m]['value']
	        name  = self.gerritInfo['currentPatchSet']['approvals'][m]['by']['name']
                if '-1' in value:
                    allVerified = -1
                    break
                if ('Code Review' in desc and '1' in value) and (self.ownerName != name):
                    cr += 1
                    allVerified = int(allVerified | int('010',2))
                elif 'Code Review' in desc and value == '2':
                    return 'Approved'
                elif 'Developer Verified' in desc and '1' in value:
                    allVerified = int(allVerified | int('001',2))

            if (allVerified >= 3 and cr >= int(minCRs)):
                return True
            else:
                return False



'''
Example usage:
  import sys
  from Gerrit import *
  gerrit = Gerrit(727192)
  print "is good?   : %s" % gerrit.isGood()
  print "owner email: %s" % gerrit.ownerEmail()
  print "branch     : %s" % gerrit.branch()
  print "file path  : %s" % gerrit.filePath()

output:
  is good?   : False
  owner email: pranavd@qti.qualcomm.com
  branch     : master
  file path  : qcacld-new/CORE/HDD/inc/qc_sap_ioctl.h
'''
