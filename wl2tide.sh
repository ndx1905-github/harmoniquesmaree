#!/bin/bash

set -e

if [ $# -eq 0 ];
then
  echo "$0: fournir le lien de téléchargement";
  exit 1;
fi;

wget $1 -P /data/

unzip -d /data/maregraphie -o /data/maregraphie.zip 
echo "Station,StationID" > /data/list.txt

for FILENAME in /data/maregraphie/*.sml; do
	awk '(NR < 4) || (FNR > 14) ' ${FILENAME%%.sml*}*.txt > ${FILENAME%%.sml*}.csv
	awk '(NR < 4)' ${FILENAME%%.sml*}.csv | sed '{s/#//g;s/:/=/g;s/ //g}' > ${FILENAME%%.sml*}a.csv 	 
	cut -f 1,2 -d ";" ${FILENAME%%.sml*}.csv > ${FILENAME%%.sml*}b.csv  
	awk '(FNR > 14)' ${FILENAME%%.sml*}b.csv > ${FILENAME%%.sml*}.csv
	awk -F';' '$2{print $0}' ${FILENAME%%.sml*}.csv > ${FILENAME%%.sml*}b.csv
	sed 's/\([0-9]\{2\}\)\/\([0-9]\{2\}\)\/\([0-9]\{4\}\)/\3\/\2\/\1/g' ${FILENAME%%.sml*}b.csv > ${FILENAME%%.sml*}.csv 
	sed '{s/\// /g;s/:/ /g}' ${FILENAME%%.sml*}.csv > ${FILENAME%%.sml*}b.csv 
	awk -F';' '{$1 = mktime($1)} 1' ${FILENAME%%.sml*}b.csv > ${FILENAME%%.sml*}.csv

	source ${FILENAME%%.sml*}a.csv
	StationID=${FILENAME##*/}
	StationID=${StationID%.sml}
        echo $Station","$StationID >> /data/list.txt
	echo $StationID
	echo $Latitude
	echo $Longitude

	/harmgen-3.1.3/harmgen --name $Station --station_id $StationID --coordinates $Latitude $Longitude --units meters /harmgen-3.1.3/congen_9yrs.txt ${FILENAME%%.sml*}.csv ${FILENAME%%.sml*}.sql

	/usr/local/pgsql/bin/psql harmbase2 < ${FILENAME%%.sml*}.sql

done;

/harmbase2-20220109/hbexport --optimize /data/output.tcd
/tcd-utils-20120115/restore_tide_db /data/output.tcd /data/output 

Rscript /tide_harmonics_parse.R;

Rscript /tide_harmonics_library_generator_multi.R;