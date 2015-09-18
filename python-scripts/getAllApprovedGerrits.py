#!/usr/bin/env

import sys
import subprocess
import os
import argparse
import re
import json
import xml.etree.ElementTree as ET
import collections
manifest = ''


def getProjectList():
	projectList = []
	if not os.path.exists("projects.xml"):
		print 'project xml file is missing'
		sys.exit()
	tree = ET.parse("projects.xml")
	root = tree.getroot()
	for projects in root.findall('projects'):
		for internal in projects.findall('internal'):
			for subsystem in internal:
				for project_name in subsystem:
					projectList.append(project_name.text)
	return projectList


def getManifest(branch):
	repoInitCmd = 'repo init -u git://git.quicinc.com/platform/manifest.git -b %s --repo-url git://git.quicinc.com/tools/repo --repo-branch stable-internal'%(branch)
	os.system(repoInitCmd)
	if not os.path.exists(os.path.join('.repo','manifests','default.xml')):
		print 'Unable to get the manifest file', os.getcwd()
		sys.exit()
	tree = ET.parse(os.path.join('.repo','manifests','default.xml'))
	manifest = tree.getroot()	
	return manifest


def getProjectBranch(branch, project):
	manifest = getManifest(branch)
	projectBranch = ''
	for default in manifest.findall('default'):
		defaultBranch = default.get('revision')
	projectBranch = defaultBranch
	for branchProject in manifest.findall('project'):
		if project == branchProject.get('name'):
			if branchProject.get('revision'):
				projectBranch = (branchProject.get('revision')).split('/')[-1]	
	return projectBranch


def getAllApprovedGerrits(branch, inputFile, projectList, target):
	for project in projectList:
		projectBranch = getProjectBranch(branch, project)
		cmd = 'python VerifyCompleteGerrits.py --InputGerritFile=%s --Project=%s --android_branch=%s --target=%s'%(inputFile, project, projectBranch, target)
		os.system(cmd)

def main():
	parser = argparse.ArgumentParser(description='GET ALL APPROVED GERRITS')
	parser.add_argument('-b','--branch',action='store',dest='branch',help='<Required> branch',required=True)
	parser.add_argument('-i','--inputFile',action='store',dest='inputFile', help='<Required> inputFile',required=True)
	parser.add_argument('-p','--project',action='store',dest='projectList',nargs='+', help='<Required> project list',required=False)
	parser.add_argument('-t','--target',action='store',dest='target',help='<Required> target',required=True)
	results = parser.parse_args()
	if not results.branch:
		print ("getAllApprovedGerrits.py -b BRANCH [-p PROJECTLIST]")
	branch = results.branch
	inputFile = results.inputFile
	target = results.target
	if results.projectList:
		projectList = results.projectList
	else:
		projectList = getProjectList()
	
	fp = open(inputFile,'r')
	inputList = fp.readlines()
	fp.close()
	inputList1 = []
	for line in inputList:
		if line.strip('\n').isdigit():
			inputList1.append(line)
	inputList1.append('New Gerrits')
	fp = open(inputFile,'w')
	fp.writelines(inputList1)
	fp.close()
	getAllApprovedGerrits(branch, inputFile, projectList, target)

if __name__ == '__main__':

	main()

