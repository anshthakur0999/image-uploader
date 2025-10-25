#!/bin/bash
# Cleanup script for K3s to prevent disk space issues

echo "=== K3s Cleanup Script ==="
echo "Date: $(date)"

# Check current disk usage
echo -e "\n📊 Current Disk Usage:"
df -h / | grep -v Filesystem

# Clean up unused Docker images
echo -e "\n🧹 Cleaning unused container images..."
sudo crictl rmi --prune

# Clean up stopped containers
echo -e "\n🗑️  Removing stopped containers..."
sudo crictl rm $(sudo crictl ps -a -q --state=Exited) 2>/dev/null || echo "No stopped containers"

# Clean up pod logs older than 7 days
echo -e "\n📝 Cleaning old pod logs..."
sudo find /var/log/pods/ -type f -name "*.log" -mtime +7 -delete 2>/dev/null || echo "No old logs to clean"

# Clean up containerd temporary files
echo -e "\n🧼 Cleaning containerd temp files..."
sudo find /run/containerd/ -type f -name "*.sock" -mtime +1 -delete 2>/dev/null || true

echo -e "\n✅ Cleanup complete!"
df -h / | grep -v Filesystem
