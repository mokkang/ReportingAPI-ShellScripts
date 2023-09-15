#!/bin/bash

# Calculate the date 7 days prior to today
seven_days_ago=$(date -v-7d +"%Y-%m-%d %H:%M:%S")

# Set it as an environment variable
export LAST_UPDATED_START_DATE="$seven_days_ago"

# Print the environment variable (optional)
echo "LAST_UPDATED_START_DATE is set to: $LAST_UPDATED_START_DATE"

reporting_id=$(http --auth-type=veracode_hmac POST "https://api.veracode.com/appsec/v1/analytics/report" < input.json)
echo $reporting_id
id=$(echo $reporting_id | cut -d '"' -f6)
echo "pause for 30 seconds"
sleep 15
echo "resuming"
echo "#### THIS IS ID######"
echo $id

# Enter in the ID from the previous method
http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v1/analytics/report/$id" | jq . > report.json
jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv

