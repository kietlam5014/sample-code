#!/usr/bin/python
#
## Author: Kiet Lam
## Date  : Nov 11, 2014
## Description: Show reviewers' bit status in table format of each gerrits

import os
import argparse
import re
import subprocess 
import time
from email.MIMEMultipart import MIMEMultipart
from email.mime.text import MIMEText
import json
from sendEmail import sendEmail
from Gerrit import *
import pdb

## Global Variables
#
status = "OK"

def getGerritTable(gerrits_list):
	
	global status
	ci_msg = ""
	crsLink = ""

	tableProperties = r"table.tftable {font-size:12px; font-family: Arial Narrow, Arial, sans-serif; color:#333333;width:100%;border-width: 1px;border-color: #729ea5;border-collapse: collapse;} table.tftable th {font-size:12px;background-color: steelblue;color: white;font-weight: bold; border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;text-align:left;} table.tftable tr {background-color:#ffffff;} table.tftable td {font-size:12px;border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;}"
	table_items = "<tr><th>SR No</th><th>Gerrit ID</th><th>CR</th><th>Owner</th><th>Commit Message</th><th>Test Result</th><th>lnxbuild</th><th>kwuser</th><th>gator</th><th>checkpatch</th><th>devci-cnss-wlan</th><th>lostadm</th><th>Change-Id</th><th>CI Status</tr>"

	iCount = 1
	for gerrit in gerrits_list:
        	lnxbuild        = None
        	kwuser          = None
        	gator           = None
        	checkpatch      = None
        	devci_cnss_wlan = None
        	lostadm         = None
		ci_status       = None
		ci_msg          = None
		crs             = []
		test_msg        = ''

		print 'processing', gerrit
		gerritinfo = Gerrit(gerrit)
		# check and skip if gerrit does not exist
		if 'rowCount' in gerritinfo.gerritInfo:
		    print "%s does not exist!" % gerrit
		    continue
		currPatchSetNum = gerritinfo.currentPatchNum()
		lnxbuild = gerritinfo.lnxbuild()
		kwuser = gerritinfo.kwuser()
		gator = gerritinfo.gator()
		checkpatch = gerritinfo.checkpatch()
		devci_cnss_wlan = gerritinfo.devci_cnss_wlan()
		lostadm = gerritinfo.lostadm()
		changeIdMatch = gerritinfo.isIdMatch()
		crs = gerritinfo.CRs()
		ci_status = gerritinfo.ciStatuses()
		comment = gerritinfo.commentsSearch(r'TEST STATUS:.*\d+|TEST RESULT')

		# Set value < 0 to RED color
		if not lnxbuild == None:
		    if int(lnxbuild) < 0:
		        v = lnxbuild
		        lnxbuild = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		else:
		    # mandatorily set to red if bit missing
		    lnxbuild = '<span style="color:red">None</span>'
		if not kwuser == None:
		    if int(kwuser) < 0:
		        v = kwuser
		        kwuser = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		else:
		    # mandatorily set to red if bit missing
		    kwuser = '<span style="color:red">None</span>'
		if not gator == None:
		    if int(gator) < 0:
		        v = gator
		        gator = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		if not checkpatch == None:
		    if int(checkpatch) < 0:
		        v = checkpatch
		        checkpatch = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		if not devci_cnss_wlan == None:
		    if int(devci_cnss_wlan) < 0:
		        v = devci_cnss_wlan
		        devci_cnss_wlan = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		if not lostadm == None:
		    if int(lostadm) < 0:
		        v = lostadm
		        lostadm = '<span style="color:red">%s</span>' % v
			status = "FAIL"
		else:
		    lostadm = ''
		if not changeIdMatch:
		    changeIdMatch = '<span style="color:red">Not Match</span>'
		else:
		    changeIdMatch = ''
		if not ci_status == None:
		    ci_msg = "%s\n  %s" % (ci_status[0], ci_status[1])

		gerritLink    = '<a href="' + gerritinfo.url() + '">' + gerrit + '</a>'
		if not (crs == None):
		    crsLink       = '<a href="http://prism/CR/' + crs + '">' + crs + '</a>'

                if comment:
                    test_msg = comment['message']
                    i = test_msg.find('TEST RESULTS:')
		    test_msg = 'Yes'
                else:
                    test_msg = 'None'

                if comment:
                    # get latest patchset with Test Result
                    pn = re.search(r'Patch Set (\d+):', comment['message'])
                    # add warn message if latest patchset does not have Test Result
                    if int(pn.group(1)) < int(currPatchSetNum):
                        test_msg = test_msg + '<br><span style="color:red">WARNING: Latest patch set does not have Test Result</span>'

		table_items = table_items + "<tr><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"%(iCount, gerritLink, crsLink, gerritinfo.ownerName(), gerritinfo.subject()[:40], test_msg, lnxbuild, kwuser, gator, checkpatch, devci_cnss_wlan, lostadm, changeIdMatch, ci_msg)
		iCount = iCount + 1
	
	tableBody = """\
				<style type="text/css">
				%s
				</style>
				<table id="tfhover" class="tftable" border="1">
				%s
				</table>
			"""%(tableProperties, table_items)
	
	return tableBody


def main():

	parser = argparse.ArgumentParser(description='Generate Gerrit table')
	parser.add_argument('-g','--gerrits',action='store',dest='gerrit_list',nargs='+', help='<Required> List of Gerrits',required=True)
	parser.add_argument('-e','--email',action='store',dest='email_addresses',nargs='+', help='<Required> Email addresses',required=False)
	results = parser.parse_args()
	
	em_addrs = []
	gerrit_list = results.gerrit_list
	email_addresses = results.email_addresses

	localtime = time.asctime( time.localtime(time.time()) )
	if email_addresses:
	    for address in email_addresses:
                if "@" in address:
                    em_addrs.append(address + ',')
                else:
                    em_addrs.append(address + '@qca.qualcomm.com,')
	email_addresses = em_addrs

	email_body = """\
			<html>
			  <head></head>
			  <body>
				<p>
				Report Time: %s <br>
				Generated gerrit validation table<br>
				</p>
				%s
			  </body>
			</html>
			"""%(localtime, getGerritTable(gerrit_list))

	fd = open("gerritVTable.html",'w+')
	fd.write("%s" % email_body)
	fd.close()

	if email_addresses:
	    sendEmail(email_body,"Gerrit Validation",''.join(email_addresses))


	if status == "FAIL":
	    print "Gerrit Validation FAIL"
	else:
	    sys.exit(0)

if __name__ == '__main__':
	main()
