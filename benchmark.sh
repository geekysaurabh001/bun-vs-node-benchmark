#!/bin/zsh

set -e

echo "🔧 Running Bun vs Node.js Benchmarks"
echo "====================================="

# CONFIG
BUN_PORT=3001
NODE_PORT=3000
LOAD_DURATION=10s
LOAD_CONNECTIONS=100

# Output files
BOOT_REPORT="boot-report.md"
WRK_BUN="wrk-bun-report.txt"
WRK_NODE="wrk-node-report.txt"
CSV_REPORT="benchmark-results.csv"

# Clean up old processes
pkill -f 'bun run' || true
pkill -f 'ts-node' || true

# Clean old reports
rm -f $BOOT_REPORT $WRK_BUN $WRK_NODE $CSV_REPORT

# Add CSV Header
echo "Server, Boot Time (ms), Requests/sec, Transfer/sec, Duration, Connections" > $CSV_REPORT

echo ""
echo "📦 Installing dependencies..."

cd bun-app
bun install > /dev/null
cd ../node-app
npm install > /dev/null
cd ..

echo ""
echo "🚀 Boot Time Benchmark"

# --- BUN ---
echo "⏱ Starting Bun..."
START_TIME=$(gdate +%s%3N)
bun run bun-app/index.ts &> /dev/null &
BUN_PID=$!
until curl -s "http://localhost:$BUN_PORT/users" > /dev/null; do sleep 0.05; done
END_TIME=$(gdate +%s%3N)
BUN_BOOT_TIME=$((END_TIME - START_TIME))
echo "✅ Bun Boot Time: $BUN_BOOT_TIME ms"
kill $BUN_PID

# --- NODE ---
echo "⏱ Starting Node..."
START_TIME=$(gdate +%s%3N)
NODE_ENV=production node --import "data:text/javascript,import { register } from 'node:module'; import { pathToFileURL } from 'node:url'; register('ts-node/esm', pathToFileURL('./node-app/node_modules')); " node-app/index.ts > node-server.log 2>&1 &
NODE_PID=$!
until curl -s "http://localhost:$NODE_PORT/users" > /dev/null; do
  echo "Waiting for Node.js to respond on /users endpoint..."
  sleep 0.05  # Small delay to prevent overwhelming the server
done
END_TIME=$(gdate +%s%3N)
NODE_BOOT_TIME=$((END_TIME - START_TIME))
echo "✅ Node Boot Time: $NODE_BOOT_TIME ms"
kill $NODE_PID

# Write boot report
echo "## Boot Time Report" >> $BOOT_REPORT
echo "" >> $BOOT_REPORT
echo "- Bun Boot Time : \`${BUN_BOOT_TIME} ms\`" >> $BOOT_REPORT
echo "- Node Boot Time: \`${NODE_BOOT_TIME} ms\`" >> $BOOT_REPORT

echo ""
echo "🔥 Load Test using wrk on /users"
echo "Duration: $LOAD_DURATION | Connections: $LOAD_CONNECTIONS"
echo "-------------------------------------------"

# Start servers again for load testing
bun run bun-app/index.ts &> /dev/null &
BUN_PID=$!
sleep 1

NODE_ENV=production node --import "data:text/javascript,import { register } from 'node:module'; import { pathToFileURL } from 'node:url'; register('ts-node/esm', pathToFileURL('./node-app/node_modules')); " node-app/index.ts &> /dev/null &
NODE_PID=$!
sleep 1

# --- WRK Test for Bun ---
echo ""
echo "▶️  Testing Bun..."
WRK_BUN_RESULT=$(wrk -t4 -c$LOAD_CONNECTIONS -d$LOAD_DURATION http://localhost:$BUN_PORT/users)
echo "$WRK_BUN_RESULT" | tee $WRK_BUN

# Extract relevant data for CSV
BUN_REQ_SEC=$(echo "$WRK_BUN_RESULT" | grep "Requests/sec" | awk '{print $2}')
BUN_TRANSFER_SEC=$(echo "$WRK_BUN_RESULT" | grep "Transfer/sec" | awk '{print $2}')
echo "bun,$BUN_BOOT_TIME,$BUN_REQ_SEC,$BUN_TRANSFER_SEC,$LOAD_DURATION,$LOAD_CONNECTIONS" >> $CSV_REPORT

# --- WRK Test for Node ---
echo ""
echo "▶️  Testing Node..."
WRK_NODE_RESULT=$(wrk -t4 -c$LOAD_CONNECTIONS -d$LOAD_DURATION http://localhost:$NODE_PORT/users)
echo "$WRK_NODE_RESULT" | tee $WRK_NODE

# Extract relevant data for CSV
NODE_REQ_SEC=$(echo "$WRK_NODE_RESULT" | grep "Requests/sec" | awk '{print $2}')
NODE_TRANSFER_SEC=$(echo "$WRK_NODE_RESULT" | grep "Transfer/sec" | awk '{print $2}')
echo "node,$NODE_BOOT_TIME,$NODE_REQ_SEC,$NODE_TRANSFER_SEC,$LOAD_DURATION,$LOAD_CONNECTIONS" >> $CSV_REPORT

echo ""
echo "🧹 Cleaning up..."
kill $BUN_PID
kill $NODE_PID

echo ""
echo "📝 Reports generated:"
echo " - $BOOT_REPORT"
echo " - $WRK_BUN"
echo " - $WRK_NODE"
echo " - $CSV_REPORT"

echo ""
echo "🏁 Benchmark complete!"
