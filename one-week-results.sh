#!/bin/bash
echo "Running"
seven_days_ago=$(date -v-7d +"%Y-%m-%d %H:%M:%S")

export last_updated_start_date="$seven_days_ago"

# Print the environment variable 
echo "last_updated_start_date is set to: $last_updated_start_date"

echo "{  
  \"policy_sandbox\": \"Policy\",
  \"report_type\": \"findings\",
  \"last_updated_start_date\": \"$last_updated_start_date\",
  \"last_updated_end_date\": \"$(date +"%Y-%m-%d %H:%M:%S")\"
}" > input.json
reporting_id=$(http --auth-type=veracode_hmac POST "https://api.veracode.com/appsec/v1/analytics/report" < input.json)
echo $reporting_id
id=$(echo $reporting_id | cut -d '"' -f6)
echo "pause for 15 seconds"
sleep 15
echo "resuming"
echo $id
# Enter in the ID from the previous method
http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v1/analytics/report/$id"  > report.json
echo "Finished processing. Filtered JSON saved to $output_file."
jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv
#less report.json

jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv
cat report.csv | awk -F, 'NR==1 {print; next} !/^"app_id","app_name",/ {print}' report.csv > tmp.csv && mv tmp.csv new_report.csv
#jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv
#
#awk -F, 'NR == 1 {print; next} !/$0 ~ /"app_id","app_name","finding_id",.../ {print}' report.csv > filtered_report.csv
echo "Removing empty columns with header"
input_file=$(new_report.csv)
output_file=$(filtered_report.csv)
# Determine the number of fields (columns)
num_fields=$(awk -F, 'NR==1 {print NF}' $input_file)
# Iterate over each field and check if it's empty for all rows
for (( i=1; i=++$num_fields; i++ )); do
    # If the column has any non-empty value, print it
    awk -F, -v field=$i 'NR==1 {header=$field} $field!="" {print header; exit}' $input_file
done > non_empty_columns.txt
# Use awk to print only the non-empty columns
awk -F, -v cols=$(paste -s -d, non_empty_columns.txt) 'BEGIN {n=split(cols, a, ",")} {for (i=1; i<=n; i++) printf "%s%s", $a[i], (i==n ? RS : FS)}' $input_file > $output_file
# Cleanup
rm non_empty_columns.txt
echo "Finished processing. Filtered CSV saved to $output_file."
