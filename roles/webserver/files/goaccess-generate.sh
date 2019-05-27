#!/usr/bin/env bash
TMP_FILE=`mktemp`
echo "Fetching logs from journalctl"
journalctl -u docker CONTAINER_NAME=nginx-ingest |grep "\- \-" |cut -d "|" -f2 |sed -e 's/^[ \t]*//' > ${TMP_FILE}
LINES=`wc -l ${TMP_FILE}`
echo "Found ${LINES} lines"
HOSTS=`cat ${TMP_FILE} |cut -d " " -f1 |sort |uniq |grep rvgate`
for HOST in ${HOSTS}; do
  echo "Generating stats for ${HOST}"
  HOST_PATH="/var/lib/docker/volumes/goaccess-static/_data/${HOST}"
  mkdir -p "${HOST_PATH}"
  touch "${HOST_PATH}"
  STATS_RAW_FILE=`mktemp`
  cat ${TMP_FILE} |grep "^${HOST}" > ${STATS_RAW_FILE}
  goaccess ${STATS_RAW_FILE} --log-format='%v %h - - [%d:%t %^] "%r" %s %b "%R" "%u"' --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -a -o "${HOST_PATH}/index.html"
  rm ${STATS_RAW_FILE}
done
rm ${TMP_FILE}