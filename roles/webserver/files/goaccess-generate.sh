#!/usr/bin/env bash
TMP_FILE=`mktemp`
STATS_PATH="/var/lib/docker/volumes/goaccess-static/_data"
echo "Fetching logs from journalctl"
journalctl -u docker CONTAINER_NAME=nginx-ingest |grep "\- \-" |cut -d "|" -f2 |sed -e 's/^[ \t]*//' > ${TMP_FILE}
LINES=$(wc -l ${TMP_FILE} |awk '{print $1}')
echo "Found ${LINES} lines"
echo "Generating global stats"
goaccess ${TMP_FILE} --log-format='%v %h - - [%d:%t %^] "%r" %s %b "%R" "%u"' --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -a -o "${STATS_PATH}/global.html"
HOSTS=$(awk '{print $1}' ${TMP_FILE} | sort | uniq)
for HOST in ${HOSTS}; do
  echo "Generating stats for ${HOST}"
  STATS_RAW_FILE=`mktemp`
  grep "^${HOST}" ${TMP_FILE} > ${STATS_RAW_FILE}
  mkdir -p "${STATS_PATH}/${HOST}"
  goaccess ${STATS_RAW_FILE} --log-format='%v %h - - [%d:%t %^] "%r" %s %b "%R" "%u"' --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -a -o "${STATS_PATH}/${HOST}/index.html"
  rmdir "${STATS_PATH}/${HOST}" # Remove if no stats were generated
  rm ${STATS_RAW_FILE}
done
rm ${TMP_FILE}
