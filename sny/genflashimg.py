#!/usr/bin/env python

# =========================================================================================#
# Author: Kiet Lam (10101482)
# Date: 2012
# Description:  Create flashable images (user variant) from prod.cfg
#    e.g of prod config format:
#         Build-id     	$HOME/Model/CDF							Site
#         ----------------------------------------------------------------------------------
#         4.1.B.0.390	R800ed41i/1246-1073_R2I_Generic_1-8_GGL_Released
#         4.1.F.0.34	SO-01D/1254-1211_R11D_NTT_DoCoMo_JP_Released			cnbj
#
# Revision History:
#
# Date      Author    Description
# ------------------------------------------------------------------------------------------
# 12/04/19  10101482  Initial creation
# ==========================================================================================#

import datetime
import optparse
import os
import sys

OPT_PRODCFG = "--prodcfg"
HOME = os.environ['HOME']
BUILDSW = HOME + "/tmp/" + "builtimg/"


def main():
    parser = optparse.OptionParser()
    parser.set_usage("%prog [options]")
    parser.add_option("", OPT_PRODCFG, dest="prodcfg",
                      help="Contains the product configuration, i.e. " \
                          "SW label and CDF.")

    BUILD_ID = ""
    CDF      = ""
    SITE     = "seld"

    (options, args) = parser.parse_args()

    if None in [options.prodcfg]:
       with open("prod.cfg") as INFILE:
          for line in INFILE:
             if len(line.split()) == 0:
                continue
             elif len(line.split()) == 2:
                BUILD_ID, CDF = line.split()
             elif len(line.split()) == 3:
                BUILD_ID, CDF, SITE = line.split()
             if len(BUILD_ID) != 0:
                outdir = BUILDSW + BUILD_ID
                if not os.path.exists(outdir):
                   os.makedirs(outdir)
                myarg = HOME + "/CDF/" + CDF + ".zip" + " variant-user result-flashable -l " + BUILD_ID + " -s " + SITE + " -out " + outdir
                command = "semcpkgtoimg " + myarg
                print command
                os.system(command)


if __name__ == "__main__":
    main()
