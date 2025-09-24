# Jenkins Memory Issue Fix

## Problem Identified
Your t2.micro instance has only 914MB RAM with 73MB free. Jenkins needs more memory to start.

## Solution: Optimize Jenkins Memory Usage

Run these commands on your EC2 instance:

```bash
# 1. First, let's add some swap space to help with memory
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Edit Jenkins configuration to use less memory
sudo nano /etc/default/jenkins
```

In the nano editor, find the line:
```
JAVA_ARGS="-Djava.awt.headless=true"
```

And replace it with:
```
JAVA_ARGS="-Djava.awt.headless=true -Xms128m -Xmx400m -XX:+UseG1GC -XX:+UseStringDeduplication"
```

Save and exit (Ctrl+X, Y, Enter)

```bash
# 3. Restart Jenkins
sudo systemctl restart jenkins

# 4. Check status
sudo systemctl status jenkins
```

## Alternative: Use Smaller Jenkins Alternative

If Jenkins still doesn't work, we can use GitHub Actions instead:

```bash
# Install Act (GitHub Actions runner)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```