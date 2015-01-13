#!/usr/bin/env
import sys
import subprocess
import os
import argparse
import re
import json
import xml.etree.ElementTree as ET
import collections
import pdb
manifest = ''
gerritTreeList = collections.OrderedDict()
pl = ''
def debugging():
	return False
user = os.environ['USER']
user_gerritInfo = user + '.gerrit_info.txt'

project_list = \
[
'platform/vendor/qcom-proprietary/ship/bt/hci_qcomm_init',
'platform/external/bluetooth/bluedroid',
'platform/packages/apps/Bluetooth',
'platform/vendor/qcom-opensource/bluetooth',
'platform/hardware/qcom/bt',
'platform/vendor/qcom-proprietary/ship/common',
'platform/vendor/qcom-proprietary/bt/sap',
'platform/system/bluetooth',
'platform/vendor/qcom-proprietary/bt/dun',
'platform/vendor/qcom-proprietary/bt/codec',
'platform/vendor/qcom-proprietary/wlan',
'platform/vendor/qcom-opensource/wlan/qcacld-2.0',
'platform/vendor/qcom-opensource/wlan/prima',
'platform/vendor/qcom-proprietary/ship/wlan/utils',
'platform/vendor/qcom-proprietary/ship/wlan/ath6kl-utils',
'platform/hardware/qcom/wlan',
'platform/external/wpa_supplicant_8',
'platform/vendor/qcom-opensource/fm',
'platform/vendor/qcom-proprietary/fm',
'platform/external/libnfc-nci',
'platform/packages/apps/Nfc',
'platform/vendor/qcom-proprietary/nfc'
]
class gerritTree(object):
	internalDependency = None
	externalDependency = []
	gerrit = ''
	def __init__(self, gerrit):
		self.internalDependency = None
		self.externalDependency = []
		self.gerrit = gerrit
	def addInternal(self, internalDependency):
		self.internalDependency = internalDependency
	
	def addExternal(self, externalDependency):
		self.externalDependency.append(externalDependency)
	def getInternal(self):
		return self.internalDependency
	def getExternal(self):
		return self.externalDependency
	
		
def fetchGerritInfo(gerrit):
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query --format=JSON --dependencies --pls change:%s > %s"%(gerrit,user_gerritInfo)
	try:
		subprocess.check_output([cmd],shell=True);
	except subprocess.CalledProcessError, e:
		if debugging(): 
			print "Error in getting the gerrit info for gerrit %s"%(gerrit)
		return ''
	
	gerritInfo_fd = open(user_gerritInfo,"r")
	for line in gerritInfo_fd:
		if 'project' in line:
			gerritInfo = json.loads(line)
			return gerritInfo
def getManifest(branch):
	global manifest
	if os.path.exists('.repo'):
		if debugging(): 
			print 'Deleting %s'%('.repo')
		cmd = 'rm -rf %s'%('.repo')
		#os.system(cmd)
	repoInitCmd = '~/bin/repo init -u git://git.quicinc.com/platform/manifest.git -b %s'%(branch)
	subprocess.check_output(repoInitCmd, stderr=open('repoInit','w'),shell = True)
	if not os.path.exists(os.path.join('.repo','manifests','default.xml')):
		if debugging(): 
			print 'Unable to get the manifest file', os.getcwd()
		sys.exit()
	tree = ET.parse(os.path.join('.repo','manifests','default.xml'))
	manifest = tree.getroot()
def fetchCommentsGerritInfo(gerrit):
	
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query --comments change:%s > %s"%(gerrit,user_gerritInfo)

	try:
		subprocess.check_output([cmd],shell=True);
	except subprocess.CalledProcessError, e:
		if debugging(): 
			print "Error in getting the gerrit info for gerrit %s"%(gerrit)
		return ''
	
	gerritInfo_fd = open(user_gerritInfo,"r")
	return gerritInfo_fd.read()
def checkBranch_withRepo(gerrit):
	#global manifest
	projectFound = False
	gerritInfo = fetchGerritInfo(gerrit)
	for default in manifest.findall('default'):
		branch = default.get('revision')
		if branch:
			break
	for branchProject in manifest.findall('project'):
		if gerritInfo['project'] == branchProject.get('name'):
			projectFound = True
			if branchProject.get('revision'):
				branch = (branchProject.get('revision')).split('/')[-1]
			if gerritInfo['branch'] != branch:
				if debugging(): 
					print gerritInfo['branch'],branch
				return 'gerrit %s on a different branch'%(gerrit)
	if projectFound == False:
		return 'gerrit %s is not on the correct pl'%(gerrit)
	return 'Good'
def checkBranch(gerrit):
	global pl
	projectFound = False
	gerritInfo = fetchGerritInfo(gerrit)
	if pl not in gerritInfo['pls']:
		return 'gerrit %s is not on the correct pl'%(gerrit)
	return 'Good'
def checkValidity(gerrit):
	if debugging(): 
		print "checkValidity: ",gerrit
	err = 'Good'
	err = checkBranch(gerrit)
	retVal = getGerritStatus(gerrit)
	if 'Good' == retVal:
		return err
	else:
		return retVal
def findExternalDependents(gerrit):
	if debugging(): 
		print "findExternalDependents: ",gerrit
	depExtGerrit = []
	errorStr = ''
	gerritInfo = fetchCommentsGerritInfo(gerrit)	
	dependsOn = re.findall(r'Depends-on:[\s*\d{6}]*', gerritInfo)
	#dependsOn = re.findall(r'(?<=Depends-on:\s)', gerritInfo)
	if not dependsOn:
		return depExtGerrit
	depExtGerritList = re.findall(r'\d{6}',dependsOn[-1]);
	if debugging(): 
		print depExtGerritList
	for extGerrit in depExtGerritList:
		if extGerrit:
			depGerritInfo = fetchGerritInfo(extGerrit)
			if depGerritInfo['status'] == 'MERGED':
				continue
			if depGerritInfo['dependencyErrors']:
				errorStr = 'error: dependent gerrit %s has some error. %s'%(extGerrit, depGerritInfo['dependencyErrors'])
				depExtGerrit.append((extGerrit,errorStr))
				break
			errorStr = checkValidity(extGerrit)
			if 'error' in errorStr:
				errorStr = errorStr[:7] + 'dependent ' + errorStr[7:]
			depExtGerrit.append((extGerrit,errorStr))

	return depExtGerrit

def findInternalDependent(gerrit):
	if debugging(): 
		print "findInternalDependent: ",gerrit
	depGerrit = ''
	errorStr = 'Good'
	gerritInfo = fetchGerritInfo(gerrit)
	if debugging(): 
		print gerritInfo
	if not gerritInfo:
		errorStr = 'error: unable to find the gerrit info for the dependent gerrit %s'%(gerrit)
		return depGerrit,errorStr
	if 'dependsOn' not in gerritInfo.keys():
		errorStr = 'error: no dependency found. Please rebase the gerrit.'
		return depGerrit, errorStr
	for gerritDepNumber in  gerritInfo['dependsOn']:
		depGerrit = gerritDepNumber['number']
		if debugging(): 
			print depGerrit
		depGerritInfo = fetchGerritInfo(depGerrit)

		if depGerritInfo['status'] == 'MERGED':
			errorStr = 'MERGED'
			if gerritInfo['branch'] != depGerritInfo['branch']:
					continue
			return depGerrit,errorStr
		if gerritInfo['branch'] != depGerritInfo['branch']:
			errorStr = 'error: dependant gerrit %s is on different branch than the main gerrit %s\n main gerrit: %s branch: %s\n dep gerrit: %s branch: %s'%(depGerrit, gerrit, gerrit, gerritInfo['branch'],depGerrit,depGerritInfo['branch'])	
			continue
		if depGerritInfo['dependencyErrors']:
			errorStr = 'error: dependent gerrit %s has some error. %s'%(depGerrit,depGerritInfo['dependencyErrors'])
			return depGerrit,errorStr
		
		errorStr = checkValidity(depGerrit)
		if 'error' in errorStr:
			errorStr = errorStr[:7] + 'dependent ' + errorStr[7:]
		return depGerrit,errorStr
		
	return depGerrit,errorStr

def createGerritDependencyTree(gerrit):
	global gerritTreeList
	if debugging(): 
		print "createGerritDependencyTree: ",gerrit
	
	err = checkValidity(gerrit)
	if err != 'Good':
		return err
	root = gerritTree(gerrit)
	if gerrit not in gerritTreeList.keys():
		gerritTreeList[gerrit] = root
	else:
		return 'Loop detected'
	depGerrit,errorStr = findInternalDependent(gerrit)
	if debugging(): 
		print depGerrit
	if 'Good' in errorStr:
		errorStr = createGerritDependencyTree(depGerrit)
		if 'Good' not in errorStr:
			if 'MERGED' in errorStr:
				return 'Good'
			return errorStr
		root.addInternal(gerritTree(depGerrit))
	elif 'error' in errorStr:
		return errorStr

	depGerritList = findExternalDependents(gerrit)
	for depGerrit,errorStr in depGerritList:
		if 'Good' in errorStr:
			print depGerrit
			errorStr = createGerritDependencyTree(depGerrit)
			if 'Good' not in errorStr:
				if 'MERGED' in errorStr:
					return 'Good'
				if 'Loop detected' in errorStr:
					continue
				return errorStr
			root.addExternal(gerritTree(depGerrit))
		elif 'error' in errorStr:
			return errorStr
	return 'Good'

def getInternalDepOrder(gerrit, gerritIntOrder):
	if debugging(): 
		print "getInternalDepOrder: ",gerrit
	if gerritTreeList[gerrit].internalDependency:
		getInternalDepOrder(gerritTreeList[gerrit].internalDependency.gerrit, gerritIntOrder)
	if debugging(): 
		print 'getInternalDepOrder', gerrit
	gerritIntOrder.append(gerrit)

def getCherrypickOrder(gerrit):
	if debugging(): 
		print "getCherrypickOrder: ",gerrit
	gerritOrder = []
	gerritIntOrder = []
	getInternalDepOrder(gerrit, gerritIntOrder)
	gerritOrder.extend(gerritIntOrder)
	for gerrit in gerritIntOrder:
		if gerritTreeList[gerrit].externalDependency:
			for externalDependent in gerritTreeList[gerrit].externalDependency:
				gerritOrder.extend(getCherrypickOrder(externalDependent.gerrit))
	return gerritOrder
	
def printTreeNode(gerrit):
	if debugging(): 
		print 'For ',gerrit
		print 'Gerrit: ',gerritTreeList[gerrit].gerrit
	if gerritTreeList[gerrit].internalDependency:
		if debugging(): 
			print 'InternalDependent: ',gerritTreeList[gerrit].internalDependency.gerrit
		pass
	if gerritTreeList[gerrit].externalDependency:
		for externalDependency in gerritTreeList[gerrit].externalDependency:
			if debugging(): 
				print 'ExternalDependent: ',externalDependency.gerrit
			pass
def removeDuplicates(depDict):
	gerritAllList = []
	
	for rootGerrit in depDict:
		gerritList = []
		for gerrit in depDict[rootGerrit]:
			if gerrit not in gerritAllList:
				gerritAllList.append(gerrit)
				gerritList.append(gerrit)
		depDict[rootGerrit] = gerritList

def getDependencies(gerritList):
	depDict = {}
	rejList = {}
	mergedList = {}
	for gerrit in gerritList:
		if debugging(): 
			print "\nGerrit: %s"%(gerrit)
		err = checkBranch(gerrit)
		if err != 'Good':
			rejList[gerrit] = err
			continue
		err = createGerritDependencyTree(gerrit)
		if 'MERGED' in err:
			mergedList[gerrit] = err
			continue
		elif ('error' or 'different branch' or 'correct pl') in err:
			rejList[gerrit] = err
			continue
		if gerrit not in gerritTreeList:
			if debugging(): 
				print "%s gerrit is invalid"%(gerrit) 
			continue
		depDict[gerrit] = getCherrypickOrder(gerrit)
		printTreeNode(gerrit)
	removeDuplicates(depDict)
	return depDict, rejList, mergedList
def getProjectList():
	projectList = []
	if not os.path.exists(os.path.join("projects.xml")):
		if debugging(): 
			print 'project xml file is missing'
		sys.exit()
	tree = ET.parse(os.path.join("projects.xml"))
	root = tree.getroot()
	for projects in root.findall('projects'):
		for internal in projects.findall('internal'):
			for subsystem in internal:
				for project_name in subsystem:
					projectList.append(project_name.text)	
	return projectList
def getGerritStatus(gerrit):
	
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query %s --format=JSON --commit-message --current-patch-set --files> gerrit_output.txt" %(gerrit)
	os.system(cmd)
	mainlineNotRequired = False 
	gerrit_file = open('gerrit_output.txt','r')
	GerritStatus = ''
	service_account = 'checkpatch'
	kw_account = 'kwuser'
	global project_list
	for line in gerrit_file:
		if debugging(): 
			print line
		GerritInfo = {}

		if 'project' in line:
			GerritInfoItem = {'GerritId': '', 'AssigneeId': '', 'Assignee': '', 'GerritUrl': [], 'Project': '', 'CRInformation': '', 'GerritStatus': ''}
			dev_verified_flag = False
			dev_verified_assignee = []
			code_review_assignee = []
			code_review_bit_flag = False
			code_review_approval_flag = False
			Linux_approval_flag = 'NotSet'
			final_approval_flag = False
			integrated_bit_flag = False
			checkpatch_flag = 'NotSet'
			KW_flag = 'NotSet'
			BIT_flag = False
			Abandon_flag = False
			GerritInfo = json.loads(line)
			if 'MERGED' in GerritInfo['status']:
				return 'MERGED'
			GerritInfoItem['GerritId'] = GerritInfo['number']
			GerritInfoItem['Assignee'] = GerritInfo['currentPatchSet']['uploader']['name']
			GerritInfoItem['GerritUrl'] = GerritInfo['url']
			GerritInfoItem['Project'] = GerritInfo['project']
			project = GerritInfo['project']
			if debugging(): 
				print project
			m = re.search('(\w+)@\w+', GerritInfo['currentPatchSet']['uploader']['email'])
			GerritInfoItem['AssigneeId'] = m.group(1)

			commitMessage = GerritInfo['commitMessage']

			m = re.search('\nCRs?-Fixed: (.*)\n', commitMessage, re.IGNORECASE)
			if ((m != None) and (m.group(1))):
				GerritInfoItem['CRInformation'] = m.group(1)
			else:
				GerritInfoItem['CRInformation'] = 'Not Provided'
			if 'files' in GerritInfo['currentPatchSet'].keys() and 'wlan' in project:
				for GerritFileItem in GerritInfo['currentPatchSet']['files']:
					if 'COMMIT_MSG' in GerritFileItem['file']:
						continue
					if 'qwlan_version.h' in GerritFileItem['file'] :
						mainlineNotRequired = True
						break 
			if 'approvals' in GerritInfo['currentPatchSet'].keys():
				for GerritApprovalItem in GerritInfo['currentPatchSet']['approvals']:
					if debugging(): 
						print GerritApprovalItem
					if GerritApprovalItem['type'] == 'TEST' and GerritApprovalItem['description'] == 'Developer Verified' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] != kw_account and GerritApprovalItem['by']['username'] != service_account:
						dev_verified_flag = True
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] == service_account:
						checkpatch_flag = 'True'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '-1' and GerritApprovalItem['by']['username'] == service_account:
						checkpatch_flag = 'False'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] == kw_account:
						KW_flag = 'True'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '-1' and GerritApprovalItem['by']['username'] == kw_account:
						KW_flag = 'False'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '2' and GerritApprovalItem['by']['username'] != service_account and GerritApprovalItem['by']['username'] != kw_account:
						code_review_approval_flag = True
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and (GerritApprovalItem['value'] == '-2' or GerritApprovalItem['value'] == '-1'):
						Abandon_flag = True 
					elif GerritApprovalItem['type'] == 'TEST' and GerritApprovalItem['description'] == 'Developer Verified' and (GerritApprovalItem['value'] == '-2' or GerritApprovalItem['value'] == '-1'):
						Abandon_flag = True  
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '1':
						Linux_approval_flag = 'True'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '-1':
						Linux_approval_flag = 'False'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '1':
						code_review_bit_flag = True
              
				if Abandon_flag == True:
					GerritInfoItem['GerritStatus'] = 'error: gerrit %s needs to be abandoned or needs resubmission'%(gerrit)
				else:
					if dev_verified_flag == True and (code_review_bit_flag == True or code_review_approval_flag == True) and (KW_flag == 'True' or KW_flag == 'NotSet') and (checkpatch_flag == 'True' or checkpatch_flag == 'NotSet') and (Linux_approval_flag == 'True' or Linux_approval_flag == 'NotSet'):
						GerritInfoItem['GerritStatus'] = 'Good'
					else:
						GerritInfoItem['GerritStatus'] = 'error: gerrit %s does not have correct approvals.'%(gerrit)
						if dev_verified_flag != True:
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Dev bit is missing.\n'
						if code_review_bit_flag != True and code_review_approval_flag != True:
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Code review is missing.\n'
						if KW_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'KW has failed.\n'
						if checkpatch_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'checkpatch has failed.\n'
						if Linux_approval_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Linux lookahead has failed.\n'
			else:
				GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] = 'error: gerrit %s does not have any approvals.'%(gerrit)
			GerritStatus = GerritInfoItem['GerritStatus']
	
	# kernel projects are different for APSS.LA.0.0 and LNX.LA.3.5
	if pl == 'LNX.LA.3.5' and GerritInfoItem['Project'] == r'kernel/msm':
		return GerritStatus
	if not mainlineNotRequired:	
		#check on mainline gerrit's status - 
		mlStatus = getMainlineGerritStatus(gerrit, pl)	
		if mlStatus != 'Good' and mlStatus != 'MERGED':
			return mlStatus		
	if debugging(): 
		print GerritStatus     
	gerrit_file.close() 
	os.unlink('gerrit_output.txt')
	return GerritStatus
	
def getMainlineGerritStatus(gerrit, mainlinePL):
	err = 'Good'
	# get the change id of the given gerrit so that we can find the mainline gerrit
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query --format=JSON change:%s > %s"%(gerrit, user_gerritInfo)
	os.system(cmd)
	gerrit_info_file = open(user_gerritInfo,'r')
	for line in gerrit_info_file:
		GerritInfo = {}
		if 'project' in line:
			GerritInfo = json.loads(line)
			break
	
	if not GerritInfo:
		err = 'error: unable to find gerrit info for the gerrit %s'%(gerrit)
		return err
	
	# get all the gerrits with the given Change ID
	cmd = "ssh -p 29418 review-android.quicinc.com gerrit query --format=JSON change:%s pl:%s --commit-message --current-patch-set > %s"%(GerritInfo['id'], mainlinePL, user_gerritInfo)
	os.system(cmd)
	gerrit_info_file = open(user_gerritInfo,'r')
	gerrit_file = gerrit_info_file.readlines()
	gerrit_info_file.close()
	os.unlink(user_gerritInfo)
	GerritStatus = ''
	service_account = 'checkpatch'
	kw_account = 'kwuser'
	global project_list
	for line in gerrit_file:
		if debugging(): 
			print line
		GerritInfo = {}

		if 'project' in line:
			GerritInfoItem = {'GerritId': '', 'AssigneeId': '', 'Assignee': '', 'GerritUrl': [], 'Project': '', 'CRInformation': '', 'GerritStatus': ''}
			dev_verified_flag = False
			dev_verified_assignee = []
			code_review_assignee = []
			code_review_bit_flag = False
			code_review_approval_flag = False
			Linux_approval_flag = 'NotSet'
			final_approval_flag = False
			integrated_bit_flag = False
			sharedGerrit = False
			checkpatch_flag = 'NotSet'
			KW_flag = 'NotSet'
			BIT_flag = False
			Abandon_flag = False
			GerritInfo = json.loads(line)
			if 'MERGED' in GerritInfo['status']:
				return 'MERGED'
			GerritInfoItem['GerritId'] = GerritInfo['number']
			GerritInfoItem['Assignee'] = GerritInfo['currentPatchSet']['uploader']['name']
			GerritInfoItem['GerritUrl'] = GerritInfo['url']
			GerritInfoItem['Project'] = GerritInfo['project']
			project = GerritInfo['project']
			if GerritInfoItem['GerritId'] == gerrit: # project is being shared with mainline PL
				sharedGerrit = True
			if debugging(): 
				print project
			m = re.search('(\w+)@\w+', GerritInfo['currentPatchSet']['uploader']['email'])
			GerritInfoItem['AssigneeId'] = m.group(1)

			commitMessage = GerritInfo['commitMessage']

			m = re.search('\nCRs?-Fixed: (.*)\n', commitMessage, re.IGNORECASE)
			if ((m != None) and (m.group(1))):
				GerritInfoItem['CRInformation'] = m.group(1)
			else:
				GerritInfoItem['CRInformation'] = 'Not Provided'
			if 'approvals' in GerritInfo['currentPatchSet'].keys():
				for GerritApprovalItem in GerritInfo['currentPatchSet']['approvals']:
					if debugging(): 
						print GerritApprovalItem
					if GerritApprovalItem['type'] == 'TEST' and GerritApprovalItem['description'] == 'Developer Verified' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] != kw_account and GerritApprovalItem['by']['username'] != service_account:
						dev_verified_flag = True
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] == service_account:
						checkpatch_flag = 'True'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '-1' and GerritApprovalItem['by']['username'] == service_account:
						checkpatch_flag = 'False'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '1' and GerritApprovalItem['by']['username'] == kw_account:
						KW_flag = 'True'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '-1' and GerritApprovalItem['by']['username'] == kw_account:
						KW_flag = 'False'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '2' and GerritApprovalItem['by']['username'] != service_account and GerritApprovalItem['by']['username'] != kw_account:
						code_review_approval_flag = True
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and (GerritApprovalItem['value'] == '-2' or GerritApprovalItem['value'] == '-1'):
						Abandon_flag = True 
					elif GerritApprovalItem['type'] == 'TEST' and GerritApprovalItem['description'] == 'Developer Verified' and (GerritApprovalItem['value'] == '-2' or GerritApprovalItem['value'] == '-1'):
						Abandon_flag = True  
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '1':
						Linux_approval_flag = 'True'
					elif GerritApprovalItem['type'] == 'VRIF' and GerritApprovalItem['description'] == 'Verified' and GerritApprovalItem['value'] == '-1':
						Linux_approval_flag = 'False'
					elif GerritApprovalItem['type'] == 'CRVW' and GerritApprovalItem['description'] == 'Code Review' and GerritApprovalItem['value'] == '1':
						code_review_bit_flag = True
				if sharedGerrit == False:
					if Abandon_flag == True:
						GerritInfoItem['GerritStatus'] = 'error: mainline gerrit %s needs to be abandoned or needs resubmission'%(GerritInfoItem['GerritId'])
					elif dev_verified_flag == True and code_review_approval_flag == True and (KW_flag == 'True' or KW_flag == 'NotSet') and (checkpatch_flag == 'True' or checkpatch_flag == 'NotSet') and (Linux_approval_flag == 'True' or Linux_approval_flag == 'NotSet'):
						GerritInfoItem['GerritStatus'] = 'Good'
					else:
						GerritInfoItem['GerritStatus'] = "error: gerrit %s's Mainline gerrit %s does not have correct approvals"%(gerrit,GerritInfoItem['GerritId'])
						if dev_verified_flag != True:
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Dev bit is missing.\n'
						if code_review_approval_flag != True:
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Code review +2 is missing.\n'
						if KW_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'KW has failed.\n'
						if checkpatch_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'checkpatch has failed.\n'
						if Linux_approval_flag == 'False':
							GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Linux lookahead has failed.\n'
				else:
					if Abandon_flag == True:
						GerritInfoItem['GerritStatus'] = 'error: gerrit %s needs to be abandoned or needs resubmission'%(GerritInfoItem['GerritId'])
					elif project in project_list: # internal project
						if dev_verified_flag == True and (code_review_bit_flag == True or code_review_approval_flag == True) and (KW_flag == 'True' or KW_flag == 'NotSet') and (checkpatch_flag == 'True' or checkpatch_flag == 'NotSet') and (Linux_approval_flag == 'True' or Linux_approval_flag == 'NotSet'):
							GerritInfoItem['GerritStatus'] = 'Good'
						else:
							GerritInfoItem['GerritStatus'] = 'error: gerrit %s does not have correct approvals.'%(GerritInfoItem['GerritId'])
							if dev_verified_flag != True:
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Dev bit is missing.\n'
							if code_review_bit_flag != True and code_review_approval_flag!=True:
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Code review is missing.\n'
							if KW_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'KW has failed.\n'
							if checkpatch_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'checkpatch has failed.\n'
							if Linux_approval_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Linux lookahead has failed.\n'
					else: # external project
						if dev_verified_flag == True and code_review_approval_flag == True and (KW_flag == 'True' or KW_flag == 'NotSet') and (checkpatch_flag == 'True' or checkpatch_flag == 'NotSet') and (Linux_approval_flag == 'True' or Linux_approval_flag == 'NotSet'):
							GerritInfoItem['GerritStatus'] = 'Good'
						else:
							GerritInfoItem['GerritStatus'] = 'error: gerrit %s does not have correct approvals. '%(GerritInfoItem['GerritId'])
							if dev_verified_flag != True:
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Dev bit is missing.\n'
							if code_review_approval_flag != True:
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Code review +2 is missing.\n'
							if KW_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'KW has failed.\n'
							if checkpatch_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Checkpatch has failed.\n'
							if Linux_approval_flag == 'False':
								GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] + 'Linux lookahead has failed.\n'					
					
			else:
				GerritInfoItem['GerritStatus'] = GerritInfoItem['GerritStatus'] = "error: gerrit %s's mainline gerrit %s does not have any approvals."%(gerrit,GerritInfoItem['GerritId'])

			GerritStatus = GerritInfoItem['GerritStatus']

	if debugging(): 
		print GerritStatus
	if GerritStatus == '':
		GerritStatus = "error: gerrit %s's mainline gerrit does not exists"%(gerrit)
	return GerritStatus

def dependencyCheck(gerrit, productLine):
	global pl
	pl = productLine
	gerritList = []
	gerritList.append(gerrit)
	dependencyDict, rejList, mergedList = getDependencies(gerritList)
	for gerrit in dependencyDict:
		return "gerrit %s is good"%(gerrit)
	for gerrit, err in rejList.items():
		return "gerrit %s is not good because %s"%(gerrit, err)
	for gerrit, err in mergedList.items():
		return "gerrit %s is merged"%(gerrit)

def main():
	global pl
	parser = argparse.ArgumentParser(description='LA AUTOMATION SCRIPT')
	parser.add_argument('-b','--branch',action='store',dest='branch',help='<Required> branch',required=False)
	parser.add_argument('-p','--pl',action='store',dest='pl',help='<Required> product line',required=True)
	parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
	results = parser.parse_args()
	if not results.pl:
		print ("getDependencies.py -b BRANCH [-g GERRITS|-f file]")
		pass
	pl = results.pl
	if results.branch:
		branch = results.branch
	
	gerritList = results.gerrits
	#initialize repo
	#getManifest(branch)		
	dependencyDict, rejList, mergedList = getDependencies(gerritList)
	fd = open('results.txt','w')
	if debugging(): 
		print 'Gerrits with dependencies'
	for gerrit in dependencyDict:
		print gerrit,': ',dependencyDict[gerrit]
		print "gerrit %s is good"%(gerrit)
		gerritStr = ''
		for gerritList in dependencyDict[gerrit]:
			gerritStr = gerritList + ' '
		fd.write(gerritStr + '\n')
		
	if debugging(): 
		print 'Rejected gerrits due to some depedency issues'
	for gerrit, err in rejList.items():
		print "gerrit %s is not good because"%(gerrit), err
		if debugging(): 
			print gerrit,':',err
		
	for gerrit, err in mergedList.items():
		print "gerrit %s is merged"%(gerrit)
		if debugging(): 
			print gerrit,':',err
	fd.close()
	
if __name__ == '__main__':
	main()
