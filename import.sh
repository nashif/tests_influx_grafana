#!/bin/bash

RESULTS_REPO_PATH=/home/nashif/Work/zephyrproject/test_results
RESULTS_DIR=$RESULTS_REPO_PATH/results
ZEPHYR_REPO_PATH=/home/nashif/Work/zephyrproject/zephyr
INFLUX_DB=influxdb://localhost:8086/zephyr_test_results
RUN=$1

export PYTHONPATH=$PWD/junit2influx-0.2.1:$PYTHONPATH

git -C $ZEPHYR_REPO_PATH pull --rebase
git -C $RESULTS_REPO_PATH pull --rebase

if [ -z "$RUN" ]; then
	for f in `ls -1 $RESULTS_DIR`; do
		if [[ $f == *"v2.5.0"* ]]; then
			for ff in `ls -1 $RESULTS_DIR/$f`; do
				platform=$(basename $ff .xml)
				echo "$f ($platform)"
				d=$(git -C $ZEPHYR_REPO_PATH log --format=%ct --date=local $f^..$f)
				echo $d
				junit2influx $RESULTS_DIR/$f/$ff --timestamp "$d" --tag platform=$platform --tag version=$f --influxdb-url $INFLUX_DB
				sleep 2
			done
		 fi;
	done
elif [ -d $RESULTS_DIR/$RUN ]; then
	for p in `ls -1 $RESULTS_DIR/$RUN`; do
		echo $p
		platform=$(basename $p .xml)
		echo "$RUN ($platform)"
		d=$(git -C $ZEPHYR_REPO_PATH log --format=%ct --date=local $RUN^..$RUN)
		./check.py -d $INFLUX_DB -p $platform -c $RUN
		if [ "$?" == 0 ]; then
			junit2influx $RESULTS_DIR/$RUN/$p --timestamp "$d" --tag platform=$platform --tag version=$RUN --influxdb-url $INFLUX_DB
		fi
		sleep 2
	done

else
	files=$(git -C $RESULTS_REPO_PATH show --pretty="" --name-only $RUN)
	for f in `printf '%s\n' $files`; do
		platform=$(basename $f .xml)
		version_=$(dirname $f)
		version=$(basename $version_)
		d=$(git -C $ZEPHYR_REPO_PATH log --format=%ct --date=local $version^..$version)
		junit2influx $RESULTS_REPO_PATH/$f --timestamp "$d" --tag platform=$platform --tag version=$version --influxdb-url $INFLUX_DB
		sleep 2
	done
fi
