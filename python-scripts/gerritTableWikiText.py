#!/usr/bin/env python
# Author: Kiet Lam
# Date  : Nov 11, 2014
#
# Desc  : Generates wikitext output from given gerrit(s). The output can be copy and paste
#         directly into MediaWiki page.  This should bypass the extra steps of copying
#         into excel, then into excel2wiki url.
#
#
import argparse
from Gerrit import *


table = """
{| {{table}}
| align="center" style="background:#f0f0f0;"|'''#'''
| align="center" style="background:#f0f0f0;"|'''Owner'''
| align="center" style="background:#f0f0f0;"|'''Gerrit ID'''
| align="center" style="background:#f0f0f0;"|'''CR'''
| align="center" style="background:#f0f0f0;"|'''Description'''
| align="center" style="background:#f0f0f0;"|'''Test Result'''
| align="center" style="background:#f0f0f0;"|'''Platform Info'''
| align="center" style="background:#f0f0f0;"|'''Project'''
| align="center" style="background:#f0f0f0;"|'''Created'''
| align="center" style="background:#f0f0f0;"|'''Updated'''
| align="center" style="background:#f0f0f0;"|'''Proprietary Propagation'''
| align="center" style="background:#f0f0f0;"|'''OpenSrc Propagation'''
|-
| ||||||||||||(default all)||||||||
"""


def main():

    parser = argparse.ArgumentParser(description='Gerrit Table script')
    parser.add_argument('-g','--gerrits',action='store',dest='gerrits',nargs='+', help='<Required> gerrits',required=True)
    results = parser.parse_args()

    if results.gerrits:
       gerritlist = results.gerrits

    index = 0
    print ' '.join(gerritlist)
    print table,
    for gerritID in gerritlist:
        index = index + 1
        gerrit = Gerrit(gerritID.decode("utf-8"))
	comment = gerrit.commentsSearch(r'TEST STATUS:.*\d+|TEST RESULT')
	if not comment:
	    hasTestResult = "No"
	else:
	    hasTestResult = "Yes"
        ownerName = gerrit.ownerName()
        url = gerrit.url()
        subject = gerrit.subject()
        project = gerrit.project()
	if not (gerrit.CRs() == None):
            crs = "http://prism/CR/" + gerrit.CRs()
	else:
	    crs = "Not Provided"
        createdOn = gerrit.createdOn()
        lastUpdated = gerrit.lastUpdated()

        print "|-"
        print "| %d||%s||%s||%s||%s||%s||||%s||%s||%s||||" % (index, ownerName, url, crs, subject, hasTestResult, project, createdOn, lastUpdated)
    print "|-"
    print "|"
    print "|}\n"

if __name__ == '__main__':
        main()

