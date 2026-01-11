#!/usr/bin/env bash

ENDPOINTS=(
  "NameNode|http://localhost:9870"
  "ResourceManager|http://localhost:8088"
  "DataNode|http://localhost:9864"
)

echo "🔍 Testing Hadoop services..."
echo

for entry in "${ENDPOINTS[@]}"; do
  NAME="${entry%%|*}"
  URL="${entry##*|}"

  if curl -s --max-time 5 "$URL" > /dev/null; then
    echo "✅ $NAME is UP ($URL)"
  else
    echo "❌ $NAME is DOWN ($URL)"
  fi
done

echo
echo "📁 Testing HDFS via WebHDFS..."
echo

HDFS_URL="http://localhost:9870/webhdfs/v1/?op=LISTSTATUS"

if curl -s --max-time 5 "$HDFS_URL" > /tmp/hdfs_test.json; then
  echo "HDFS root content:"
  cat /tmp/hdfs_test.json | sed -n 's/.*"pathSuffix":"\([^"]*\)".*"type":"\([^"]*\)".*/- \1 (\2)/p'
else
  echo "❌ HDFS test failed"
fi
