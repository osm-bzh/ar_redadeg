#!/bin/bash

# argument 1 passé au script = millesime redadeg
millesime=$1

zip -qr /data/projets/ar_redadeg/data/$millesime/backup/geoserver_datadir_`date +"%Y.%m.%d"`.zip /var/lib/tomcat9/webapps/geoserver/data/workspaces/redadeg_$millesime/
