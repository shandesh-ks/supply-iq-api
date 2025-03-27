#!/bin/bash

# Ensure Python is installedhttps://github.com/shandesh-ks/supply-iq-api/blob/main/start.sh
if ! command -v python3 &> /dev/null
then
    echo "Python3 not found. Installing..."
    apt-get update && apt-get install -y python3 python3-venv python3-pip
fi

# Set up Python virtual environment
python3 -m venv myenv
if [ ! -d "myenv" ]; then
    echo "Virtual environment 'myenv' was not created successfully."
    exit 1
fi

# Activate virtual environment
source myenv/bin/activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Start the Rails server
bundle exec rails server -b 0.0.0.0 -p $PORT
