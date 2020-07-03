#!/bin/bash

echo "Setting up gem credentials..."
# set +x
mkdir -p ~/.gem
echo '----------------------'
cat << EOF > ~/.gem/credentials
---
:github: Bearer ${GH_PERSONAL_ACCESS_TOKEN}
:rubygems_api_key: ${RUBYGEMS_API_KEY}

EOF
echo '----------------------'
chmod 0600 ~/.gem/credentials
# set -x

echo '----------------------'
cat ~/.gem/credentials
echo '----------------------'

echo "Installing dependencies..."
bundle install > /dev/null 2>&1

echo "Running gem release task..."
rake release
