#!/bin/bash
echo "************* Update Version.java *************"
export rversion=1.0.${BUILD_NUMBER}.${SVN_REVISION}
cd Dev/HP.Cheshire.Android/src/com/hp/cheshire/android
sed -i "s/1.0.0.0/$rversion/" Version.java
