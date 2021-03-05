#!/bin/bash

RESULTS_PATH=/Users/anashif/zephyr/zephyrproject/test_results/results/
ZEPHYR_PATH=/Users/anashif/zephyr/zephyrproject/zephyr
INFLUX_DB=influxdb://10.0.1.4/twister1
RUN=$1

if [ -z "$RUN" ]; then
	for f in `ls -1 $RESULTS_PATH`; do
		if [[ $f == *"v2.4.0"* ]]; then
			for ff in `ls -1 $RESULTS_PATH/$f`; do
				platform=$(basename $ff .xml)
				echo "$f ($platform)"
				d=$(git -C $ZEPHYR_PATH log --format=%ct --date=local $f^..$f)
				echo $d
				junit2influx $RESULTS_PATH/$f/$ff --timestamp "$d" --tag platform=$platform --tag version=$f --influxdb-url $INFLUX_DB
				sleep 2
			done
		 fi;
	done
else
	for p in `ls -1 $RESULTS_PATH/$RUN`; do
		platform=$(basename $p .xml)
		echo "$RUN ($platform)"
		d=$(git -C $ZEPHYR_PATH log --format=%ct --date=local $RUN^..$RUN)
		echo $d
		junit2influx $RESULTS_PATH/$RUN/$p --timestamp "$d" --tag platform=$platform --tag version=$RUN --influxdb-url $INFLUX_DB
		sleep 2
	done

fi
