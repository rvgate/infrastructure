#!/usr/bin/env bash
TMP_FILE=`mktemp`
echo "Fetching logs from journalctl"
journalctl -u docker CONTAINER_NAME=nginx-ingest |grep "\- \-" |cut -d "|" -f2 |sed -e 's/^[ \t]*//' > ${TMP_FILE}
LINES=`wc -l ${TMP_FILE}`
echo "Found ${LINES} lines"
HOSTS=$(grep rvgate ${TMP_FILE} | awk '{print $1}' | sort | uniq)
for HOST in ${HOSTS}; do
  echo "Generating stats for ${HOST}"
  HOST_PATH="/var/lib/docker/volumes/goaccess-static/_data/${HOST}"
  STATS_RAW_FILE=`mktemp`
  cat ${TMP_FILE} |grep "^${HOST}" > ${STATS_RAW_FILE}
  goaccess ${STATS_RAW_FILE} --log-format='%v %h - - [%d:%t %^] "%r" %s %b "%R" "%u"' --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -a -o "${HOST_PATH}.html"
  rm ${STATS_RAW_FILE}
done
rm ${TMP_FILE}
