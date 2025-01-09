#!/bin/bash
#Author Anil
################################################################
###########Pass Uname and password##############################
#################################################################
IFPATH=$1
uname=$2
passwd=$3
infuser=$(echo $uname | awk -F'[_@]' '{print $2}' | tr '[:lower:]' '[:upper:]')
#aws_acckey=$4
#aws_seckey=$5
################################################################################################
###Properties for the entire program###########################################################
################################################################################################
################################################
##TargetCode Properties#########################
Total=0
score=0
###############################################
##########################################################
###Do not edit the below properties. Connection Properties
#########################################################
conname="mssqltest"
host="65.0.51.78"
database="master"
codepage="UTF-8"
dbschema=$infuser
mdbschema="dbo"
dbtype="SqlServer2017"
port=1433
usname="SA"
authType="SqlServer"
################################################
##Synchronization task##############################
SyncTask="Employeetask"
srcobj="EMPLOYEE"
tgtobj="EMPLOYEE_DTL"
SyncPath=$1
#####################################################
###Expression Details#################################
dtfilter="INDIA"
Cond="COUNTRY"
########################################################
###############################################################################################
########Curl to send the request to obtain the session key and session id 
#########################################################################
# Make the POST request and capture the response
#response=$(curl -s -X POST https://dm-ap.informaticacloud.com/ma/api/v2/user/login \
#   -H "Content-Type: application/json" \
#   -d "{\"@type\": \"login\",\"username\": \"$uname\",\"password\": \"$passwd\"}")

echo $response

sessionId=$(echo $response | jq -r '.icSessionId')
    serviceUrl=$(echo $response | jq -r '.serverUrl')

# Use the sessionId and serviceUrl for further API calls
echo "Using Session ID: $sessionId"
echo "Using Service URL: $serviceUrl"
serviceUrl="https://apse1.dm-ap.informaticacloud.com/saas"
sessionId="4geFJeDAqdqhq3a2pbt2So"

###################################################################################################
response1=$(curl -s -X GET "$serviceUrl/api/v2/connection/" -H "Content-Type: application/xml" \
  -H "icSessionId: $sessionId")
###################################################################################################
###################################################################################################
#######################################################################################################
tgtid=$(echo "$response1" | jq --arg tgtname "$conname" '.[] | select(.name == $tgtname)' | jq -r '.id')
echo $tgtid
resp1=$(curl -s -X GET "$serviceUrl/api/v2/connection/$tgtid" -H "Content-Type: application/json" \
	-H "icSessionId: $sessionId")
echo $resp1 | jq -r '.'
#######################################################################################################
instDispname1=$(echo "$resp1" | jq -r '.instanceDisplayName' | grep -ic "$authtype")
hosttype=$(echo "$resp1" | jq -r '.host' | grep -ic "$host")
dbport=$(echo "$resp1" | jq -r '.port' | grep -ic "$port")
dbname=$(echo "$resp1" | jq -r '.database' | grep -ic "$database")
schema=$(echo "$resp1" | jq -r '.schema' | grep -ic "$mdbschema")
codpage=$(echo "$resp1" | jq -r '.codepage' | grep -ic "$codepage")
dbtype=$(echo "$resp1" | jq -r '.type' | grep -ic "$type")
echo $instDispname1 $hosttype $dbport $dbname $schema $codpage $dbtype
##################################################################################################
if ([ $instDispname1 -ge 1 ] && [ $hosttype -ge 1 ] && [ $dbport -ge 1 ] && [ $dbname -ge 1 ] && [ $schema -ge 1 ] && [ $codpage -ge 1 ] && [ $dbtype -ge 1 ]) then
  tgtStatus="Success";
  tgtFeedback="Microsoft SQL Server connection created in the Informatica cloud";
  tgtObserv="MS SQL Server created in the Informatica cloud as given in the description";
  tgtScore=10;
  tgtPass=1;
  Total=`expr $Total + $tgtScore`;
else
  tgtStatus="Failure";
  tgtFeedback="MS SQL Server connection  not created in Informatica cloud";
  tgtObserv="MS SQL Server connection  not created in the Informatica cloud as given in the description";
  tgtScore=0;
  tgtPass=0;
  Total=`expr $Total + $tgtScore`;
fi

echo $Total
#######################################################################################################
#####################Mapping##########################################
######################################################################################################
###############################################################################
#Taskid
################################################################################
if [ $tgtPass -eq 1 ]; then 
####################################################################################
response4=$(curl -X GET "${serviceUrl}/api/v2/task?type=DSS" -H "Content-Type: application/json" \
          -H "Accept: application/json" -H "icSessionId: ${sessionId}")
echo $response4
Syntaskid=$(echo $response4 | jq -r '.[0].id')
echo $Syntaskid
response5=$(curl -X GET "${serviceUrl}/public/core/v3/objects?q=type=='DSS'" \
	-H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "INFA-SESSION-ID: ${sessionId}")
echo $response5
####################################################################################
DSSID=$(echo $response5 | jq -r '.objects[0].id')
DSPATH=$(echo $response5 | jq -r '.objects[0].path')
DSTYPE=$(echo $response5 | jq -r '.objects[0].type')

echo $DSSID $DSPATH $DSTYPE
###################################################################################
response6=$(curl -X POST "${serviceUrl}/public/core/v3/lookup" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "INFA-SESSION-ID: ${sessionId}" \
     -d '{
           "objects": [
               {
		   "id" : "'$DSSID'",
                   "type" : "DSS"
               }
           ]
   }')  

# Check if the "type" field in any object is "MTT"
echo "*********************"
echo $response6
echo "Export"
is_mtt=$(echo "$response6" | jq -r '.objects[] | .path' | grep -wic $SyncTask)
if [ $is_mtt -ge 1 ]; then
    echo "DSS object found."
  mttStatus="Success";
  mttFeedback="Synchronization Task created in the Informatica cloud";
  mttObserv="Synchronization Task are created in the Informatica cloud as given in the description";
  mttScore=10;
  mttPass=1;
  Total=`expr $Total + $mttScore`;
else
  mttStatus="Failure";
  mttFeedback="Synchronization Task not created in the Informatica cloud";
  mttObserv="Synchronization Task are not created in the Informatica cloud as given in the description";
  mttScore=0;
  mttPass=0;
  Total=`expr $Total + $mttScore`;
fi
echo $Total
else
  mttStatus="Failure";
  mttFeedback="Mapping Task not created in the Informatica cloud";
  mttObserv="Mapping Task are not created in the Informatica cloud as given in the description";
  mttScore=0;
  mttPass=0;
  Total=`expr $Total + $mttScore`;
fi
############################################################################################
if [ $mttPass -eq 1 ]; then 
response7=$(curl -X POST "${serviceUrl}/public/core/v3/export" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "INFA-SESSION-ID: ${sessionId}" \
     -d '{
           "name": "MappingTaskExport",
           "objects": [
               {
                   "id": "'$DSSID'",
                   "includeDependencies": true
               }
           ]
   }')
   expid=$(echo $response7 | jq -r '.id')
   expstatus=$(echo $response7 | jq -r '.status.state') 
   
echo $expid $expstatus

if [ "$expstatus" = "IN_PROGRESS" ]; then
    while true; do
        # Fetch the export status
        response8=$(curl -X GET "${serviceUrl}/public/core/v3/export/$expid?expand=objects" \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         -H "INFA-SESSION-ID: ${sessionId}")
        
        expgetstatus=$(echo "$response8" | jq -r '.status.state')
        echo "Current Status: $expgetstatus"

        # Check if the export is successful
        if [ "$expgetstatus" = "SUCCESSFUL" ]; then
            echo "Export completed successfully. Downloading the package..."

            # Download the package
            curl -X GET "${serviceUrl}/public/core/v3/export/$expid/package" \
                 -H "Content-Type: application/json" \
                 -H "Accept: application/zip" \
                 -H "INFA-SESSION-ID: ${sessionId}" \
                 --output "$SyncPath/$SyncTask.zip"

            echo "Package downloaded as $MapTask.zip."
            break
        elif [ "$expgetstatus" = "FAILED" ]; then
            echo "Export failed. Exiting."
            exit 1
        else
            echo "Export still in progress. Retrying in 5 minutes..."
            sleep 30 # Wait for 30 seconds before retrying
        fi
    done
    exppass=1;
fi
else
    exppass=0;
    "source and target not created"
fi
echo $Total
   if [ $exppass -eq 1 ]; then 
cd $SyncPath
unzip -o $SyncTask.zip
mtt_path=$(find $SyncPath -type f -iname '*DSS*.zip' | sed "s|$SyncPath||")
mtt_path1=$(find $SyncPath -type f -iname '*DSS*.zip' | sed "s|$SyncPath||" | sed 's|/[^/]*$||')
mtt_file=$(find "$SyncPath" -type f -iname '*DSS*.zip' | sed "s|$SyncPath||" | xargs -n 1 basename)
echo $mtt_path $mtt_path1 $mtt_file

if [ -n "$mtt_path" ]; then
       cd $SyncPath$mtt_path1	
	unzip -o $mtt_file
else
	echo "not found"
fi
ls
############################################################################################################################
 
############################################################################################################################
response6=$(curl -s -X POST "$serviceUrl/api/v2/job" -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionId: $sessionId" -d '{ "@type": "job",  "taskId": "'"$Syntaskid"'", "taskType": "DSS" }
')
echo $response6
rid=$(echo $response6 | jq -r '.runId')
tid=$(echo $response6 | jq -r '.taskId')
echo $rid $tid
sleep 20s
###################
response6=$(curl -s -X GET "$serviceUrl/api/v2/activity/activityLog" -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionId: $sessionId" | jq --arg rid "$rid" --arg tid "$tid" '.[] | select(.runId == ($rid | tonumber) and .objectId == $tid)')
echo $response6 | jq -r '.'

echo $response6
# Assuming response6 contains your JSON data
extracted_values=$(echo "$response6" | jq -r '{failedSourceRows, successSourceRows, failedTargetRows, successTargetRows, errorMsg}')

# Print the extracted values
echo "$extracted_values"
failsrcrows=$(echo $response6 | jq -r '.failedSourceRows')
succsrcrows=$(echo $response6 | jq -r '.successSourceRows')
succtgtrows=$(echo $response6 | jq -r '.successTargetRows')
failtgtrows=$(echo $response6 | jq -r '.failedTargetRows')
errmsg=$(echo $response6 | jq -r '.errorMsg')
echo $failsrrows
echo $succtgtrows
echo $succsrcrows
echo $failtgtrows
echo $errmsg
if [ $succsrcrows -ge 3 ] && [ $succtgtrows -ge 3 ]; then 
  logStatus="Success";
  logFeedback="task is successful ran in the Informatica cloud";
  logObserv="Task is successfully ran in the Informatica cloud as given in the description";
  logScore=15;
  logpass=1;
  Total=`expr $Total + $logScore`;
else
  logStatus="Failure";
  logFeedback="task is not successful ran in the Informatica cloud";
  logObserv="Task is not successfully ran in the Informatica cloud as given in the description";
  logScore=0;
  logpass=0;
  Total=`expr $Total + $logScore`;
fi
else 
	logStatus="Failure";
  logFeedback="task is not successful ran in the Informatica cloud";
  logObserv="Task is not successfully ran in the Informatica cloud as given in the description";
  logScore=0;
  logpass=0;
  Total=`expr $Total + $logScore`;
fi



Result='@responsestart@ \n
        {
    "Exercise": "Creating Customer data in Informatica cloud",
    "TestCases": [
        {
            "Name": "Creating connection object",
            "Status": "'$tgtStatus'",
            "Skill": "Beginner",
            "Score": "'$tgtScore'%",
            "Feedback": "'$tgtFeedback'",
            "Observation": "'$tgtObserv'",
            "ConsoleOutput": ""
        },
	{
            "Name": "Creating Synchronization Task",
            "Status": "'$mttStatus'",
            "Skill": "Beginner",
            "Score": "'$mttScore'%",
            "Feedback": "'$mttFeedback'",
            "Observation": "'$mttObserv'",
            "ConsoleOutput": ""
        },
	{
            "Name": "Expression checked in the stages",
            "Status": "'$exprStatus'",
            "Skill": "Beginner",
            "Score": "'$exprScore'%",
            "Feedback": "'$exprFeedback'",
            "Observation": "'$exprObserv'",
            "ConsoleOutput": ""
        },
	    {
            "Name": "Check the Activity log for the mapping task",
            "Status": "'$logStatus'",
            "Skill": "Beginner",
            "Score": "'$logScore'%",
            "Feedback": "'$logFeedback'",
            "Observation": "'$logObserv'",
            "ConsoleOutput": ""
        },
		{
            "Name": "Target files in aws s3 bucket",
            "Status": "'$awsStatus'",
            "Skill": "Beginner",
            "Score": "'$awsScore'%",
            "Feedback": "'$awsFeedback'",
            "Observation": "'$awsObserv'",
            "ConsoleOutput": ""
        }
    ],
    "TotalScore": "'$Total'%"
}
\n
                        @responseend@'
              echo -e $Result

