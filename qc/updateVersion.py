#!/usr/bin/env python
#
# Author: Kiet Lam
# Date  : Nov 20, 2014
# Desc  : Update version file with next version.  Then,
#         create version gerrit with commit message. Must run
#         in wlan or wlan-noship directory.
#
#         Usage: python updateVersion.py -t apq8084

import sys
import fileinput
import argparse
import subprocess

def UpdateDriverVersion(vfile):

	with open(vfile) as f:
	  for line in f:
	     line.strip()
	     llist = line.split()
	     if 'QWLAN_VERSION_MAJOR' in line:
	        qwlanMajor = llist[2]
	     if 'QWLAN_VERSION_MINOR' in line:
	        qwlanMinor = llist[2]
	     if 'QWLAN_VERSION_PATCH' in line:
	        qwlanPatch = llist[2]
	     if 'QWLAN_VERSION_EXTRA' in line:
	        qwlanExtra = llist[2]
	     if 'QWLAN_VERSION_BUILD' in line:
	        qwlanBuild = str(int(llist[2]) + 1)
	     if 'QWLAN_VERSIONSTR' in line:
	        qwlanVersionStr = llist[2]
	f.close()

	qwlanVersionStr = '"' + qwlanMajor + '.' + qwlanMinor + '.' + qwlanPatch + '.' + qwlanBuild + qwlanExtra.lstrip('"').rstrip('"') + '"'
        for line in fileinput.input(vfile, inplace=1):
                if  'QWLAN_VERSIONSTR' in line:    
                        line = "#define QWLAN_VERSIONSTR               %s\n" % qwlanVersionStr
                elif 'QWLAN_VERSION_MAJOR' in line:
                        line = "#define QWLAN_VERSION_MAJOR            %s\n" % qwlanMajor
                elif 'QWLAN_VERSION_MINOR' in line:
                        line = "#define QWLAN_VERSION_MINOR            %s\n" % qwlanMinor
                elif 'QWLAN_VERSION_PATCH' in line:
                        line = "#define QWLAN_VERSION_PATCH            %s\n" % qwlanPatch
                elif 'QWLAN_VERSION_BUILD' in line:
                        line = "#define QWLAN_VERSION_BUILD            %s\n" % qwlanBuild
                elif 'QWLAN_VERSION_EXTRA' in line:
                        line = "#define QWLAN_VERSION_EXTRA            %s\n" % qwlanExtra
                print "%s"%(line.strip('\n'))

	return qwlanVersionStr

def UpdateCommitMsg(versionNum):
	versionNum = versionNum.lstrip('"').rstrip('"')
	fd = open("commit-msg", "w")
	fd.write("Wlan: Release %s\n" % versionNum)
	fd.write("\n")
	fd.write("Release %s\n" % versionNum)
	fd.close()
	cmd = 'git commit -a --file commit-msg --no-edit'
	try:
		subprocess.check_output([cmd], shell=True);
	except subprocess.CalledProcessError, e:
		print "%s fail\n" % cmd

	cmd = 'git log --format=%B -n 1 HEAD > commit-msg' # output just commit msg
	try:
		subprocess.check_output([cmd], shell=True);
	except subprocess.CalledProcessError, e:
		print "%s fail\n" % cmd
	cmd = "sed -i '$ d' commit-msg" # remove last extra line
        try:
                subprocess.check_output([cmd], shell=True);  
        except subprocess.CalledProcessError, e:
                print "%s fail\n" % cmd
	cmd = 'echo "CRs-Fixed: 688141" >> commit-msg'
	try:
		subprocess.check_output([cmd], shell=True);
	except subprocess.CalledProcessError, e:
		print "%s fail\n" % cmd
	cmd = 'git commit --amend --file commit-msg --no-edit'
        try:
                subprocess.check_output([cmd], shell=True);
        except subprocess.CalledProcessError, e:
                print "%s fail\n" % cmd


def main():
	primaTarget = ['msm8916', 'msm8974']

	parser = argparse.ArgumentParser(description='LA Automation Script')
	parser.add_argument('-t','--target',action='store',dest='target',help='target msm8974|apq8084',required=True)
	parser.add_argument('-v','--version',action='store',dest='versionNum',help='<Required> Version Number',required=False)
	results = parser.parse_args()
	if results.target in primaTarget:
		versionFile = 'prima/CORE/MAC/inc/qwlan_version.h'
	elif 'apq8084' in results.target or 'msm8994' in results.target:
		versionFile = 'qcacld-new/CORE/MAC/inc/qwlan_version.h'
	versionNum = results.versionNum

	qwlanVersionStr = UpdateDriverVersion(versionFile)
	UpdateCommitMsg(qwlanVersionStr)
	print "Gerrit version created: %s" % (qwlanVersionStr)

if __name__ == '__main__':
        main()
