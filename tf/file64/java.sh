#!/bin/bash

# Update package index
echo "Updating package list..."
sudo apt-get update -y

# Install OpenJDK 17
echo "Installing OpenJDK 17..."
sudo apt-get install -y openjdk-17-jdk

# Verify installation
echo "Verifying Java installation..."
java -version
javac -version

echo "Java installation completed successfully."
