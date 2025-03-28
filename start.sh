#!/bin/bash

# Ensure Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Python3 not found. Installing..."
    apt-get update && apt-get install -y python3 python3-pip
fi

# Install dependencies globally
pip3 install --user --upgrade pip
pip3 install --user -r requirements.txt

# Start the Rails server
bundle exec rails server -b 0.0.0.0 -p $PORT
