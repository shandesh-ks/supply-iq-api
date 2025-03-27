#!/bin/bash

# Ensure Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Python3 not found. Installing..."
    apt-get update && apt-get install -y python3 python3-pip
fi

# Set up Python virtual environment
python3 -m venv myenv
source myenv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the Rails server
bundle exec rails server -b 0.0.0.0 -p $PORT

