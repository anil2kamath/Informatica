#!/bin/bash
#Author Anil
################################################################
###########Pass Uname and password##############################
#################################################################
IFPATH=$1
uname=$2
passwd=$3
infuser=$(echo $2 | awk -F'[_@]' '{print $2}' | tr '[:lower:]' '[:upper:]')
aws_acckey=$4
aws_seckey=$5
################################################################################################
###Properties for the entire program###########################################################
################################################################################################
################################################
##TargetCode Properties#########################
Total=0
score=0
###############################################
aws_region="ap-south-1"
awstgtfile="UnionedEmployees.csv"
exptfile="UnionedEmployees_exp.csv"
tgtbuckname="inf-tek-buckt"
##########################################################
###Do not edit the below properties. Connection Properties
#########################################################
tgtname="awstest"
tgtbuck=$tgtbuckname
cloudconn="AMAZON"
cloudtype="TOOLKIT"
cloudreg="Mumbai"
cloudpath=$tgtbuckname
################################################
##Mapping Details##############################
MapName="EmployeeUnion_map"
srcfile="$infuser/INPUT/EmployeeNewSet.csv"
tgtfile="$infuser/OUTPUT/UnionedEmployees.csv"
tgtopr="Insert"
tgtcodpg="UTF"
tgtfmt="FLAT"
MapTask="EmployeeUnion_task"
TaskMapPath=$1
#####################################################
###Expression Details#################################
#expr1="expression"
#expr2="target"
tgtfields="EMPLOYEE_ID MAIL SALARY"
########################################################
##########################################################
####Expression Stage Names################################
valid_stages=("union")
###############################################################################################
########Curl to send the request to obtain the session key and session id 
#########################################################################
# Make the POST request and capture the response

response=$(curl -s -X POST https://dm-ap.informaticacloud.com/ma/api/v2/user/login \
   -H "Content-Type: application/json" \
   -d "{\"@type\": \"login\",\"username\": \"$uname\",\"password\": \"$passwd\"}")

clresp=$(echo "$response" | tr -d '\000-\031')
sessionId=$(echo "$clresp" | jq -r '.icSessionId')
    serviceUrl=$(echo "$clresp" | jq -r '.serverUrl')

# Use the sessionId and serviceUrl for further API calls
echo "Using Session ID: $sessionId"
echo "Using Service URL: $serviceUrl"
serviceUrl="https://apse1.dm-ap.informaticacloud.com/saas"
#sessionId="bToFn8mDXYvkUymnCDgPww"

###################################################################################################
response1=$(curl -s -X GET "$serviceUrl/api/v2/connection/" -H "Content-Type: application/xml" \
  -H "icSessionId: $sessionId")
###################################################################################################
###################################################################################################
#######################################################################################################
tgtid=$(echo "$response1" | jq --arg tgtname "$tgtname" '.[] | select(.name == $tgtname)' | jq -r '.id')
resp1=$(curl -s -X GET "$serviceUrl/api/v2/connection/$tgtid" -H "Content-Type: application/json" \
	-H "icSessionId: $sessionId")
echo $resp1 | jq -r '.'
#######################################################################################################
instname=$(echo "$resp1" | jq '.instanceName' | grep -ic "$cloudconn")
instype=$(echo "$resp1" | jq -r '.type' | grep -ic "$cloudtype")
instDispname1=$(echo "$resp1" | jq -r '.instanceDisplayName' | grep -ic "$cloudconn")
regname=$(echo "$resp1" | jq -r '.connParams.S3RegionName' | grep -ic "$cloudreg")
foldpath=$(echo "$resp1" | jq -r '.connParams.FolderPath' | grep -ic "$cloudpath")
echo $instname $instDispname1 $instype $regname $foldpath
##################################################################################################
if ([ $instname -ge 1 ] && [ $instDispname1 -ge 1 ] && [ $regname -ge 1 ] && [ $foldpath -ge 1 ]) then
  tgtStatus="Success";
  tgtFeedback="Amazon s3 Connection created in Informatica cloud";
  tgtObserv="Amazon s3  Connection created in the Informatica cloud as given in the description";
  tgtScore=10;
  tgtPass=1;
  Total=`expr $Total + $tgtScore`;
else
  tgtStatus="Failure";
  tgtFeedback="Amazon s3 connection not created in Informatica cloud";
  tgtObserv="Amazon s3 Connection not created in the Informatica cloud as given in the description";
  tgtScore=0;
  tgtPass=0;
  Total=`expr $Total + $tgtScore`;
fi

echo $Total
#######################################################################################################
#####################Mapping##########################################
######################################################################################################
if [ $tgtPass -eq 1 ]; then 
response2=$(curl -s -X GET "$serviceUrl/api/v2/mapping/" -H "Content-Type: application/xml" \
	  -H "icSessionId: $sessionId")
 mapstatus=$(echo $response2 | jq --arg MapName "$MapName" '.[] | select(.name | test($MapName; "i"))' | jq '.name' | grep -ic "$MapName")
 echo $mapstatus
 if [ $mapstatus -ge 1 ]; then 
response3=$(curl -s -X GET "$serviceUrl/api/v2/mapping/name/$MapName/" -H "Content-Type: application/xml" \
	-H "icSessionId: $sessionId")
resp3=$(echo "$response3" | sed 's/%2F//g')
tgtobj=$(echo $resp3 | jq -r '[.deployTime, (.parameters[] | select(.type == "TARGET") | .targetObject, .operationType, .dataFormat.dataFormatAttributes.codePage, .dataFormat.formatId)] | @tsv')
echo $tgtobj "target object"
srcobj=$(echo $resp3 | jq -r '.parameters[] | select(.type == "EXTENDED_SOURCE") | .extendedObject.objects[0] | .name | select (.!= null)')
echo $srcobj "source object"
srcfname=$(echo $srcobj | grep -ic "$srcfile")
tgtfname=$(echo $tgtobj | grep -ic "$tgtfile")
tgtoper=$(echo $tgtobj | grep -ic "$tgtopr")
tgtcod=$(echo $tgtobj | grep -ic "$tgtcodpg")
tgtfmt=$(echo $tgtobj | grep -ic "$tgtfmt")
echo $srcfname $tgtfname $tgtoper $tgtcod $tgtfmt
if ([ $srcfname -ge 1 ] && [ $tgtfname -ge 1 ] && [ $tgtoper -ge 1 ] && [ $tgtcod -ge 1 ] && [ $tgtfmt -ge 1 ]); then 
  srcfStatus="Success";
  srcfFeedback="Source and Target files created in Informatica cloud";
  srcfObserv="Source and Target files are created in the Informatica cloud as given in the description";
  srcfScore=15;
  srcfPass=1;
  Total=`expr $Total + $srcfScore`;
else
  srcfStatus="Failure";
  srcfFeedback="Source and Target files not created in Informatica cloud";
  srcfObserv="Source and Target files not created in the Informatica cloud as given in the description";
  srcfScore=0;
  srcfPass=0;
  Total=`expr $Total + $srcfScore`;
fi
echo $Total
 fi
else
	echo "Mapping not found"
fi

###############################################################################
#Taskid
################################################################################
if [ $srcfPass -eq 1 ]; then 
response4=$(curl -s -X GET "$serviceUrl/api/v2/mttask" -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionId: $sessionId")
echo $response4
taskid=$(echo "$response4" | jq -r --arg MapTask "$MapTask" '.[] | select(.name | ascii_downcase == ($MapTask | ascii_downcase)) | .id')
echo $taskid
if [ ! -z $taskid ]; then 
####################################################################################
response5=$(curl -X GET "${serviceUrl}/public/core/v3/objects?q=type=='MTT'" \
	-H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "INFA-SESSION-ID: ${sessionId}")
echo $response5
####################################################################################
maptaskid=$(echo "$response5" | jq -r --arg MapTask "$MapTask" '.objects[] | select(.path | ascii_downcase | contains($MapTask | ascii_downcase)) | .id')
maptaskpath=$(echo "$response5" | jq -r --arg MapTask "$MapTask" '.objects[] | select(.path | ascii_downcase | contains($MapTask | ascii_downcase)) | .path')
echo $maptaskid
echo $maptaskpath
###################################################################################
response6=$(curl -X POST "${serviceUrl}/public/core/v3/lookup" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "INFA-SESSION-ID: ${sessionId}" \
     -d '{
           "objects": [
               {
		   "id" : "'$maptaskid'",
                   "type" : "MTT"
               }
           ]
   }')  

# Check if the "type" field in any object is "MTT"
echo "*********************"
echo $response6
is_mtt=$(echo "$response6" | jq -r '.objects[] | .path' | grep -wic $MapTask)
if [ $is_mtt -ge 1 ]; then
    echo "MTT object found."
  mttStatus="Success";
  mttFeedback="Mapping Task created in the Informatica cloud";
  mttObserv="Mapping Task are created in the Informatica cloud as given in the description";
  mttScore=15;
  mttPass=1;
  Total=`expr $Total + $mttScore`;
else
  mttStatus="Failure";
  mttFeedback="Mapping Task not created in the Informatica cloud";
  mttObserv="Mapping Task are not created in the Informatica cloud as given in the description";
  mttScore=0;
  mttPass=0;
  Total=`expr $Total + $mttScore`;
fi
echo $Total
fi
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
                   "id": "'$maptaskid'",
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
                 --output "$TaskMapPath$MapTask.zip"

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
cd $TaskMapPath
unzip -o $MapTask.zip
dtemp_path=$(find $TaskMapPath -type f -iname '*DTemplate*.zip' | sed "s|$TaskMapPath||")
dtemp_path1=$(find $TaskMapPath -type f -iname '*DTemplate*.zip' | sed "s|$TaskMapPath||" | sed 's|/[^/]*$||')
mtt_path=$(find $TaskMapPath -type f -iname '*MTT*.zip' | sed "s|$TaskMapPath||")
mtt_path1=$(find $TaskMapPath -type f -iname '*MTT*.zip' | sed "s|$TaskMapPath||" | sed 's|/[^/]*$||')
dtemp_file=$(find "$TaskMapPath" -type f -iname '*DTemplate*.zip' | sed "s|$TaskMapPath||" | xargs -n 1 basename)
mtt_file=$(find "$TaskMapPath" -type f -iname '*MTT*.zip' | sed "s|$TaskMapPath||" | xargs -n 1 basename)
echo $dtemp_path $mtt_path $dtemp_path1 $mtt_path1 $dtemp_file $mtt_file

if [ -n "$dtemp_path" ]; then 
	cd $TaskMapPath$dtemp_path1
	echo "unzip file"
	unzip -o $dtemp_file
else
    echo "not found"
fi
if [ -n "$mtt_path" ]; then
       cd $TaskMapPath$mtt_path1	
	unzip -o $mtt_file
else
	echo "not found"
fi
ls
############################################################################################################################
############################################################################################################################
#######Please write expression logic accordingly for each exercise#######################################
# Extract expressions from the JSON file################################################################
#############################################################################################################################
stages=$(cat bin/@3.bin | jq -r '.content.annotations[] | select(.jsonBlob != null) | (.jsonBlob | fromjson | keys | .[])')
#Process stages
stgpass=0
for stage in $stages; do 
	echo "Processing stages" $stage
# Convert stage name to lowercase for case-insensitive comparison
  stage_lower=$(echo "$stage" | tr '[:upper:]' '[:lower:]')
  echo $stage_lower ":lower stages"
 for valid_stage in "${valid_stages[@]}"; do 
   if [[ "$stage_lower" == "$valid_stage" ]]; then
    score=$((score + 15))
    echo $valid_stage $score
    stgpass=1
    break
  fi
done 
    if [ $stgpass -eq 0 ]; then 
	    echo "stage not valid"
    fi
done
echo $score  "stage pass" $stgpass
if [ $stgpass -eq 1 ]; then
  stgStatus="Success";
  stgFeedback="Stage name is created in the Informatica cloud";
  stgObserv="Stage names  are created in the Informatica cloud as given in the description";
  stgScore=$score;
  stgPass=1;
  Total=`expr $Total + $stgScore`;
else
  stgStatus="Failure";
  stgFeedback="Stage name is not created in the Informatica cloud";
  stgObserv="Stage name is  not created in the Informatica cloud as given in the description";
  stgScore=$score;
  stgPass=0;
  Total=`expr $Total + $stgScore`;
fi
else
stgStatus="Failure";
  stgFeedback="Stage name is not created in the Informatica cloud";
  stgObserv="Stage name is  not created in the Informatica cloud as given in the description";
  stgScore=$score;
  stgPass=0;
  Total=`expr $Total + $stgScore`;
fi
echo $Total

#########################################################################################################################
##############Fields check#######
###############################
if [ $stgPass -eq 1 ]; then 
response5=$(curl -s -X POST "$serviceUrl/api/v2/job" -H "Content-Type: application/json" -H "Accept: application/json" -H "icSessionId: $sessionId" -d '{ "@type": "job",  "taskId": "'"$taskid"'", "taskType": "MTT",  "runtime": {
        "@type": "mtTaskRuntime"
    }
}')
echo $response5
rid=$(echo $response5 | jq -r '.runId')
tid=$(echo $response5 | jq -r '.taskId')
echo $rid $tid
sleep 25s
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
if [ $succsrcrows -ge 10 ] && [ $succtgtrows -ge 10 ]; then 
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

if [ $logpass -eq 1 ]; then
       cd $1	
echo $aws_acckey $aws_seckey $infuser $tgtbuckname
	AWS_ACCESS_KEY_ID=$aws_acckey AWS_SECRET_ACCESS_KEY=$aws_seckey aws s3 ls s3://$tgtbuckname/$infuser/
buckcnt=$(AWS_ACCESS_KEY_ID=$aws_acckey AWS_SECRET_ACCESS_KEY=$aws_seckey aws s3 ls s3://$tgtbuckname/$infuser/OUTPUT/ | grep -wic $awstgtfile)
if [ $buckcnt -ge 1 ]; then 
AWS_ACCESS_KEY_ID=$aws_acckey AWS_SECRET_ACCESS_KEY=$aws_seckey aws s3 cp s3://$tgtbuckname/$infuser/OUTPUT/$awstgtfile $1
extractfile=$(ls $awstgtfile)
echo $extractfile
sort $extractfile -o $extractfile
sort $exptfile -o $exptfile
ls -lart $awstgtfile
diff_result1=$(diff "$exptfile" "$extractfile")
if [ -z "$diff_result1" ]; then
  awsStatus="Success";
  awsFeedback="Target file is matched";
  awsObserv="Target fields and the file is matched based on the requirement";
  awsScore=30;
  Total=`expr $Total + $awsScore`;
else
 awsStatus="Failure";
 awsFeedback="Target file is not matched";
 awsObserv="Target fields and the file is not matched based on the requirement";
 awsScore=0;
 Total=`expr $Total + $awsScore`; 
fi
else
  awsStatus="Failure";
 awsFeedback="Target file is not matched";
 awsObserv="Target fields and the file is not matched based on the requirement";
 awsScore=0;
 Total=`expr $Total + $awsScore`; 
fi
else
  awsStatus="Failure";
 awsFeedback="Target file is not matched";
 awsObserv="Target fields and the file is not matched based on the requirement";
 awsScore=0;
 Total=`expr $Total + $awsScore`;
fi
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
            "Name": "Creating Mapping with the given name",
            "Status": "'$srcfStatus'",
            "Skill": "Beginner",
            "Score": "'$srcfScore'%",
            "Feedback": "'$srcfFeedback'",
            "Observation": "'$srcfObserv'",
            "ConsoleOutput": ""
        },
		{
            "Name": "Creating Mapping Task to run the Mapping job",
            "Status": "'$mttStatus'",
            "Skill": "Beginner",
            "Score": "'$mttScore'%",
            "Feedback": "'$mttFeedback'",
            "Observation": "'$mttObserv'",
            "ConsoleOutput": ""
        },
         {
            "Name": "Stage Name checked in the Mapping",
            "Status": "'$stgStatus'",
            "Skill": "Beginner",
            "Score": "'$stgScore'%",
            "Feedback": "'$stgFeedback'",
            "Observation": "'$stgObserv'",
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

