#!/bin/bash
##################################################################################################
# Simple Bash Script for Reporting API Generation.

# Prompt for the application profile name

echo "Please enter the application profile name: "
read app_name
echo "Running"

# Use http with veracode_hmac to make the API request
response=$(http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v1/applications/?name=${app_name}")
reply=$(echo $response | grep -i $app_name | cut -d ',' -f4)
echo $reply

# If the 'guid' field is in the top level of the response, this will extract it
app_id=$(echo $reply | cut -d '"' -f4)
echo $app_id

# Print the guid
# Request user input for each field
echo "####### ENTER GUID OF THE APPLICATION PROFILE #######"
#read -p "application GUID:" $app_id
echo "Please select a scan type:"
options=("Static Analysis" "Dynamic Analysis" "Software Composition Analysis" "Manual Test")
select opt in "${options[@]}"
do
    case $REPLY in
        1) scan_type="Static Analysis"; break;;
        2) scan_type="Dynamic Analysis"; break;;
        3) scan_type="Software Composition Analysis"; break;;
        4) scan_type="Manual Test"; break;;
        *) echo "Invalid option. Please select a number between 1-4.";;
    esac
done
#echo "Scan_Type by Default is set to policy"
#policy_sandbox='policy'
#scan_type=policy
echo "Policy Status (NOT PASSED by Default)"
policy_rule_passed='no'
#echo "##### ENTER EITHER 'Policy' or 'Sandbox' ########"
#read -p "Enter policy_sandbox: " policy_sandbox
#echo "Default = Policy Scan "
echo "Status Findings by Default 'Open'"
status='open'
echo "##### ENTER yes/no for Policy_Rules_Passed ########"
#read -p "Enter policy_rule_passed: " policy_rule_passed
echo "##### STATUS: 'open'/'closed' #########"
#read -p "Enter status: " status
echo ""
echo "##### TYPE OF REPORT 'findings' #########"
#read -p "Enter report_type: " report_type
report_type='findings'
echo "##### DATE LAST UPDATED YYYY-MM-DD HH:mm:ss"
#read -p "Enter last_updated_start_date: " last_updated_start_date
#last_updated_end_date=$(date +"%Y-%m-%d %H:%M:%S")
# Print the JSON
#seven_days_ago=$(date -v-7d +"%Y-%m-%d %H:%M:%S")

# Set it as an environment variable
#export last_updated_start_date="$seven_days_ago"

# Print the environment variable (optional)
#echo "last_updated_start_date is set to: $last_updated_start_date"

#echo "{  
#  \"policy_sandbox\": \"Policy\",
#  \"report_type\": \"findings\",
#  \"last_updated_start_date\": \"$last_updated_start_date\",
#  \"last_updated_end_date\": \"$(date +"%Y-%m-%d %H:%M:%S")\"

echo "{
  \"app_id\": \"$[app_id]\",
  \"scan_type\": [\"${scan_type[@]}\"],
  \"policy_sandbox\": \"$policy_sandbox\",
  \"policy_rule_passed\": \"$policy_rule_passed\",
  \"status\": \"$status\",
  \"report_type\": \"$report_type\",
  \"last_updated_start_date\": \"$last_updated_start_date\",
  \"last_updated_end_date\": \"$last_updated_end_date\"
    }" > input.json
reporting_id=$(http --auth-type=veracode_hmac POST "https://api.veracode.com/appsec/v1/analytics/report" < input.json)
echo $reporting_id
id=$(echo $reporting_id | cut -d '"' -f6)
echo "pause for 15 seconds"
sleep 15
echo "resuming"
echo $id
# Enter in the ID from the previous method
http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v1/analytics/report/$id" | jq . > report.json
cp report.json report-generated.json
#cat report-generated.json
#cat report.json
#less report.json
jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv
cat report.csv | awk -F, 'NR==1 {print; next} !/^"app_id","app_name",/ {print}' report.csv > tmp.csv && mv tmp.csv new_report.csv
jq -r '._embedded.findings[] | to_entries | map(.key), map(.value) | @csv' report.json > report.csv

#awk -F, 'NR == 1 {print; next} !/$0 ~ /"app_id","app_name","finding_id",.../ {print}' report.csv > filtered_report.csv
#echo "Removing empty columns with header"
#input_file="/Users/jmok/REST_API_AUTOMATION/new_report.csv"
#output_file="/Users/jmok/REST_API_AUTOMATION/filtered_new_report.csv"
# #Determine the number of fields (columns)
#num_fields=$(awk -F, 'NR==1 {print NF}' $input_file)

## Iterate over each field and check if it's empty for all rows
#for (( i=1; i<=$num_fields; i++ )); do
#    # If the column has any non-empty value, print it
#    awk -F, -v field=$i 'NR==1 {header=$field} $field!="" {print header; exit}' $input_file
#done > non_empty_columns.txt


# Use awk to print only the non-empty columns
#awk -F, -v cols=$(paste -s -d, non_empty_columns.txt) 'BEGIN {n=split(cols, a, ",")} {for (i=1; i<=n; i++) printf "%s%s", $a[i], (i==n ? RS : FS)}' $input_file > $output_file
# Cleanup
#rm non_empty_columns.txt
echo "Finished processing. Filtered CSV saved to $output_file."
