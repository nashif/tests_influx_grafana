
# Zephyr Hardware Results Dashboard

First you will need to install both grafana and influxdb and verify that you
can connect to databases created in influxdb from grafana.

In influxdb create a database that will host the test results and call it `zephyr_test_results`. This can be done using the command line tools for influxdb.

	nashif@master:~$ influx
	Connected to http://localhost:8086 version 1.8.4
	InfluxDB shell version: 1.8.4
	> CRATE DATABASE zephyr_test_result

In grafana, create a new data source and add the above database you have just created.

In grafana, import the dashboards available in dashboards/ directory.

Clone both repos:

 - https://github.com/zephyrproject-rtos/zephyr.git
 - https://github.com/zephyrproject-rtos/test_results.git

into your workspace.

Change the configuration in the script import.sh and make sure the following
variables reflect what you have created above:


	RESULTS_REPO_PATH=/path/to/test_results
	ZEPHYR_REPO_PATH=/path/to/zephyr/
	INFLUX_DB=influxdb://localhost:8086/zephyr_test_results


Install junit2influx using pip:

	pip3 install junit2influx

There are 2 ways the import script can be called:

- Bulk import: This will import all results (v2.5.0 results) in one call. For
  this, call the script without any arguments
- Single Run: Specify the commit you want to import as the first argument to import.sh
- Commit import: Only import new files that are part of a single commit. The
  first argument should be a commit hash in the test_results repo

