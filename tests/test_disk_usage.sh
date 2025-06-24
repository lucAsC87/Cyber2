#!/bin/bash

echo "Testing disk write/read for 20 seconds..."
stress-ng --hdd 1 --hdd-bytes 100M --timeout 20s
echo "Disk stress test finished."
