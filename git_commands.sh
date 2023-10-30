#!/bin/bash
RED='\e[31m'
YELLOW='\e[33m'
STD='\033[0;0;39m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\e[1m'
IP='' 
TIME=''
LogFile="${PWD}/logs/"
ACTIVE_BRANCH=''
PARENT_BRANCH=''
DEV_NAME='';
SEP='^'
PARENT_BRANCH=''

# ==== 1 ====
gitStatus(){
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 1. git  status (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    logIt "git status"
    git status
    echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"	
}
# ==== 1 ====

# ==== 2 ====
gitPull(){
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo " 2. git pull origin (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"

    if [ "$ACTIVE_BRANCH" != "master" ] && [ "$ACTIVE_BRANCH" != "developer" ]; then
        echo -e "${YELLOW}${BOLD}.------------------------------."
        echo -e "|          BRANCH NAME         |"
        echo -e "|------------------------------|"
        echo -e "|  1.  git pull origin master  |"
        echo -e "|  2.  git pull origin ${ACTIVE_BRANCH}"
        echo -e "'------------------------------'${STD}"
        read -p "Enter choice [1 OR 2] : " choice
        if [ "$choice" == 1 ] ; then 
            echo -e "\n${YELLOW}Executing >> ${BOLD}git pull origin master${NC}\n"
            logIt "Executing >> git pull origin master"
            PULL="$(git pull origin master)"
            SAVEIFS=$IFS   # Save current IFS
            IFS=$'\n'      # Change IFS to new line
            names=($PULL) # split to array $names
            IFS=$SAVEIFS   # Restore IFS
            for (( i=0; i<${#names[@]}; i++ ))
            do
                echo "${names[$i]}"
            done

            if echo "$PULL" | grep -q "CONFLICT (content): Merge conflict"; then
                solveConflict 'NA' 'NA' 'master'
            fi
        elif [ "$choice" == 2 ] ; then 
            echo -e "\n${YELLOW}Executing >> ${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}\n"
            logIt "Executing >> git pull origin ${ACTIVE_BRANCH}"
            PULL="$(git pull origin ${ACTIVE_BRANCH})"

            SAVEIFS=$IFS   # Save current IFS
            IFS=$'\n'      # Change IFS to new line
            names=($PULL) # split to array $names
            IFS=$SAVEIFS   # Restore IFS
            for (( i=0; i<${#names[@]}; i++ ))
            do
                echo "${names[$i]}"
            done

            if echo "$PULL" | grep -q "CONFLICT (content): Merge conflict"; then
                solveConflict 'NA' 'NA' ${ACTIVE_BRANCH}
            fi
        else
            echo -e "\n${YELLOW}Oops!! Not a valid option.${NC}"
        fi
    else
        echo -e "\n${YELLOW}Executing >> ${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}\n"
        logIt "git pull origin ${ACTIVE_BRANCH}"
        git pull origin ${ACTIVE_BRANCH}
    fi

    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 2 ====

# ==== 3 ====
gitAddCommit(){
    local para
    addfile=${PWD}/logs/add.log
    phpvcheckfile=${PWD}/logs/phpversion.log
    checkcnt=0;
    logcnt=0;
    phpvcnt=0;
    fncnt=0;
    
    if [ -f $addfile ]; then
        rm ${addfile}
    fi
    logIt "git add"
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 3. git add/commit (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter all files sperated by space and press ENTER to execute : " para
    array=(zip gz tar cgz) #add here if you restrict more extension
    
    if [ ${#para} -ge 1 ]; then
        function join { local IFS="$1"; shift; echo "$*"; }
        readarray -t scan_error < $(dirname "${PWD}")/eo_config/thirdparty_lib/op_tool/scan_error.txt
        scan_error=$(join "|" ${scan_error[@]})
        
        for word in ${para}
        do
            if [ "${word##*.}" == "php" ]; then
                echo -e "\n${YELLOW}Executing >> ${BOLD}Code Review Tool >>${NC}${BOLD} ${word}${NC}\n"
                logIt "Executing >> Code Review Tool - ${PWD}/$word"
                bash $(dirname "${PWD}")/eo_config/thirdparty_lib/op_tool/run_phpcrt.sh ${PWD}/$word >> ${addfile}
                if [ -f "${addfile}" ]
                then
                fcnt=`grep -E "${scan_error}" ${addfile} | wc -l`
                find=`grep -E "${scan_error}" ${addfile}`
                if [ "$fcnt" -ne 0  ]; then
                    checkcnt=`expr $checkcnt + 1`
                    if [ "$checkcnt" -eq 1 ]; then
                        echo -e "\n${BOLD}Found errors affecting following files${NC}"
                        echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                    fi
                    echo -e "${BOLD}FILE : " ${PWD}/$word "${NC}"
                    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                    echo -e "${find}"
                    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                    #echo -e "\n"
                    logIt "error file -- $find"
                    rm ${addfile}
                fi
                fi
            elif [[ "${array[*]}" =~ "${word##*.}" ]]; then
                    echo -e "${BOLD}You can't add/commit this type of file ${CYAN}${BOLD}${word}${NC}"
                    exit;
            fi
        done
        
        if [ "$checkcnt" -gt 0 ]; then
            echo -e "\n${BOLD}${RED}Please fix error and than after that you can add/commit files.${NC}"
            logIt "Please fix error and than after that you can add/commit files."
            show_menus
            read_options
            return;
        else
            echo -e "\n${BOLD}No Syntax Error Found${NC}"
            logIt "No Syntax Error Found"
        fi
        
        for word in ${para}
        do
            if [ "${word##*.}" == "php" ]; then          
                phpcs --standard=PHPCompatibility --error-severity=1 --warning-severity=8 --runtime-set testVersion 8.1 ${word} > ${addfile}
                fcnt=`cat ${addfile} | wc -l`
                if [ "$fcnt" -ne 0 ] #if [ -f "${addfile}" ]
                then
                phpvcnt=`expr $phpvcnt + 1`
                if [ "$phpvcnt" -eq 1 ]; then
                    echo -e "\n${CYAN}${BOLD}Your code is not compatible with PHP v8.1. Check the details below to get more information.${NC}"
                    logIt "Your code is not compatible with PHP v8.1. Check the details below to get more information."
                    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                fi
                echo -e "${BOLD}FILE :  ${word} ${NC}"
                logIt "${BOLD}FILE :  ${word} ${NC}"
                cat ${addfile}
                rm ${addfile}
                fi  
            fi
        done
        
        if [ "$phpvcnt" -gt 0 ]; then
            show_menus
            read_options
            return;
        fi
             
        for word in ${para}
        do
            if [ "${word##*.}" == "php" ]; then
        
                sca_log=`bash $(dirname "${PWD}")/eo_config/thirdparty_lib/op_tool/scan_logs.sh ${PWD} ${word}`
                
                if [ -n "${sca_log}" ]; then
                logcnt=`expr $logcnt + 1`
                if [ "$logcnt" -eq 1 ]; then
                    echo -e "\n${YELLOW}${BOLD}Found logs with array or object or json, for security reason remove, comment or encrypt this logs.${NC}"
                    logIt "Found logs with array or object or json, for security reason remove, comment or encrypt this logs."
                    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                fi
                echo -e "${BOLD}FILE :  ${word} ${NC}"
                logIt "${BOLD}FILE :  ${word} ${NC}"
                echo -e "${sca_log}"
                fi
            fi
        done
        
        if [ "$logcnt" -gt 0 ]; then
            show_menus
            read_options
            return;
        fi
        
       for word in ${para}
       do
           if [ "${word##*.}" == "php" ]; then
                echo "Data:--- grep -n "${word%%/*}
                match=`grep -n "${word##*/}" ${PWD}/autoscripts/autoscripts_connect.php`
                
                if [ "${word%%/*}" != "autoscripts" ] || [ "${word%%/*}" == "autoscripts" -a -n "${match}" ]; then
                    
                    scan_functions=`bash $(dirname "${PWD}")/eo_config/thirdparty_lib/op_tool/scan_functions.sh ${PWD}/${word}`
                    
                    if [ -n "${scan_functions}" ]; then
                    fncnt=`expr $fncnt + 1`
                    if [ "$fncnt" -eq 1 ]; then
                        echo -e "\n${YELLOW}${BOLD}Found some vulnerable functions, for security concern please check with Jignesh Rana${NC}"
                        logIt "Found some vulnerable functions, for security concern please check with Jignesh Rana"
                        echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
                    fi
                    echo -e "${BOLD}FILE :  ${word} ${NC}"
                    logIt "${BOLD}FILE :  ${word} ${NC}"
                    echo -e "${scan_functions}"
                    fi
                fi
            fi
        done
        
        if [ "$fncnt" -gt 0 ]; then
            read -e -p "If you have already checked with Jignesh Rana then type 'Yes' to continue: " para_scan
            logIt "If you have already checked with Jignesh Rana then type 'Yes' to continue: ${para_scan}"
            if [ "$para_scan" != "Yes" ] && [ "$para_scan" != "yes" ] ; then
            show_menus
            read_options
            return;
            fi
        fi
        
        logIt "git add ${para}"
        git add ${para}
        echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
        read -e -p "Are sure you want to commit above listed files? Please insert comment and press ENTER : " paracom
        git commit -m "${paracom}" ${para}
    else
        echo -e "\nOperation cancelled as nothing entered.${NC}"
    fi
    echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 3 ====

# ==== 4 ====
gitBranch(){
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 4. git branch (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    logIt "git branch"
    git branch
    echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"	
}
# ==== 4 ====

# ==== 5 ====
gitBranchCheckout() {
    branchName=''
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e " 5. git checkout ${YELLOW}<branch name>${CYAN}${BOLD} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter branch name and press ENTER to switch : " branchName
    # branchName="$(echo -e "${branchName}" | tr -d '[:space:]')"
    if [ ${#branchName} -ge 1 ]; then
        echo -e "\n${YELLOW}Executing >> ${BOLD}git checkout ${branchName}${NC}\n"
        logIt "git checkout ${branchName}"
        git checkout ${branchName}
    fi
    echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"	
}
# ==== 5 ====

# ==== 6 ====
gitCreateBranch(){
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e " 6. git checkout -b ${YELLOW}<branch name>${CYAN}${BOLD} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    #   read -p "Are You Sure You Want Take PULL of ${para} Branch [Yes/No] : " parareply
    if [ "$ACTIVE_BRANCH" == "developer" ] || [ "$ACTIVE_BRANCH" == "qa" ] ; then
        echo -e "\n${RED}${BOLD}Oops!! We can not create branch from ${ACTIVE_BRANCH} branch.${NC}"
    else
     if [ "$ACTIVE_BRANCH" == "master" ] ; then
    
        read -p "Enter new branch name : " branchname
        branchName="$(echo -e "${branchName}" | tr -d '[:space:]')"
        if [ ${#branchname} -ge 1 ]; then
            echo -e "${YELLOW}${BOLD}.------------------------------."
            echo -e "|        TYPE OF BRANCH        |"
            echo -e "|------------------------------|"
            echo -e "|  ${RED}1.  Urgent Fix (No QA)${YELLOW}${BOLD}      |"
            echo -e "|  2.  Hotfix                  |"
            echo -e "|  3.  Feature (Long Running)  |"
            echo -e "'------------------------------'${STD}"
            read -p "Enter choice [1, 2 OR 3] : " choice
            urgentfix_reason=''
            urgentfix_approvedby=''
            if [ "$choice" == 1 ] ; then 
                branchname="UrgentFix_${branchname}_${DEV_NAME}"
                read -p "Mention reason of urgent release : " urgentfix_reason
                # urgentfix_reason="$(echo -e "${urgentfix_reason}" | tr -d '[:space:]')"
                if [ ${#urgentfix_reason} -ge 5 ]; then
                    read -p "Person name who has approved urgent fix : " urgentfix_approvedby
                    # urgentfix_approvedby="$(echo -e "${urgentfix_approvedby}" | tr -d '[:space:]')"
                    if [ ${#urgentfix_approvedby} -le 4 ]; then
                        branchname=''
                        echo -e "\n${RED}${BOLD}Enter atleast 5 characters to proceed.${NC}"
                    fi
                else
                    branchname=''
                    echo -e "\n${RED}${BOLD}Enter atleast 5 characters to proceed.${NC}"
                fi
            elif [ "$choice" == 2 ] ; then 
                branchname="Hotfix_${branchname}_${DEV_NAME}"
            elif [ "$choice" == 3 ] ; then 
                branchname="Feature_${branchname}_${DEV_NAME}"
            else
                branchname=''
                echo -e "\n${YELLOW}Oops!! Not a valid option.${NC}"
            fi

            BRANCH_EXIST="$(git branch | grep ${branchname})"
            if [ ${#BRANCH_EXIST} -ge 1 ]; then
                echo -e "\n${RED}${BOLD}Oops!! branch ${branchname} is already exist.${NC}"
            else
                if [ ${#branchname} -ge 1 ]; then
                    echo -e "\n${YELLOW}Executing >> ${BOLD}git checkout -b ${branchname}${NC}"
                    logIt "Executing >> git checkout -b ${branchname}"
                    git checkout -b ${branchname}
                 fi
            fi
        else
            echo -e "\n${YELLOW}Oops!! You didn't mention branch name.${NC}"
        fi
     else
           echo -e "\n${RED}Oops!! Invalid Choice.${NC}" 
     fi     
    fi
    echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"	
}
# ==== 6 ====

# ==== 7 ====
gitRemoveBranch(){
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e " 7. git branch -d ${YELLOW}<branch name>${CYAN}${BOLD} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"

    read -p "Enter branch name : " branchname
    branchName="$(echo -e "${branchname}" | tr -d '[:space:]')"
    if [ ${#branchname} -ge 1 ]; then
        # removeRemoteBranch ${branchname}
        BRANCH_EXIST="$(git branch | grep ${branchname})"
        if [ ${#BRANCH_EXIST} -ge 1 ]; then
            echo -e "\n${YELLOW}Executing >> ${BOLD}git branch -d ${branchname}${NC}"
            logIt "Executing >> git branch -d ${branchname}"
            deloutput="$(git branch -d ${branchname})"

            if [ ${#deloutput} -ge 1 ]; then
                #api_resp=$(curl -sb -H --data "op=branchDelete&branchname=${branchname}&parentbranch=${ACTIVE_BRANCH}&ip=${IP}&name=${DEV_NAME}" /dev/null http://192.168.20.62/cloud_release_3/cloud_tech_release3_0.php)
                #
                #ERR="$(cut -d'^' -f1 <<<${api_resp})"
                #if [ "$ERR" != "200" ] ; then
                #    echo -e "\n${RED}${BOLD}Something is going wrong in background. Report it to OP team.${NC}"
                #fi
                removeRemoteBranch ${branchname}
            else
                echo -e "\n${RED}${BOLD}Oops!! Branch in not fully merged.${NC}\n"
                read -p "Oops!! Branch is not fully merged. If you still want to delete it forcefully, type yes [Yes/No] : " parareply
                parareply="$(echo -e "${parareply}" | tr -d '[:space:]')"

                if [ "$parareply" == "Yes" ] || [ "$parareply" == "yes" ] || [ "$parareply" == "YES" ] ; then
                    echo -e "\n${YELLOW}Executing >> ${BOLD}git branch -D ${branchname}${NC}"
                    logIt "Executing >> git branch -D ${branchname}"
                    git branch -D ${branchname}

                    #api_resp=$(curl -sb -H --data "op=branchDelete&branchname=${branchname}&parentbranch=${ACTIVE_BRANCH}&ip=${IP}&name=${DEV_NAME}" /dev/null http://192.168.20.62/cloud_release_3/cloud_tech_release3_0.php)
                    #
                    #ERR="$(cut -d'^' -f1 <<<${api_resp})"
                    #if [ "$ERR" != "200" ] ; then
                    #    echo -e "\n${RED}${BOLD}Something is going wrong in background. Report it to OP team.${NC}"
                    #fi
                    removeRemoteBranch ${branchname}
                else
                    echo -e "\n${YELLOW}Operation cancelled.${NC}"
                fi
            fi
        else
            echo -e "\n${RED}${BOLD}Oops!! branch ${branchname} is not available.${NC}"
        fi
    else
        echo -e "\n${YELLOW}Oops!! You didn't mention branch name.${NC}"
    fi
  echo -e "${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"	
}

removeRemoteBranch() {
    BRANCH_EXIST="$(git branch -a | grep remotes/origin/$1)"
    if [ ${#BRANCH_EXIST} -ge 1 ]; then
        read -p "Remove this branch from remote? Enter 'Yes' to continue, 'No' to abort. : " parareply
            parareply="$(echo -e "${parareply}" | tr -d '[:space:]')"
            if [ "$parareply" == "Yes" ] || [ "$parareply" == "yes" ] || [ "$parareply" == "YES" ] ; then
                echo -e "\n${YELLOW}Executing >> ${BOLD}git push origin --delete $1${NC}"
                logIt "Executing >> git push origin --delete $1"
                git push origin --delete $1
            else
                echo -e "\n${YELLOW}Operation cancelled.${NC}"
            fi
    fi
}
# ==== 7 ====

# ==== 8 ====
gitPushOnRemote() {
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 8. git push origin ${ACTIVE_BRANCH} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    
    if [ "${ACTIVE_BRANCH}" != "master" ] && [ "${ACTIVE_BRANCH}" != "developer" ] && [ "${ACTIVE_BRANCH}" != "qa" ] ; then
        #api_resp=$(curl -sb -H --data "op=branchMerged&branchname=${ACTIVE_BRANCH}&ip=${IP}&name=${DEV_NAME}" /dev/null http://192.168.20.62/cloud_release_3/cloud_tech_release3_0.php)
        #ERR="$(cut -d'^' -f1 <<<${api_resp})"
        #if [ "$ERR" != "200" ] ; then
        #    echo -e "\n${RED}${BOLD}Something is going wrong in background. Report it to OP team.${NC}"
        #fi

        echo -e "\n${YELLOW}Executing >> ${BOLD}git push origin ${ACTIVE_BRANCH}${NC}"
        logIt "Executing >> git push origin ${ACTIVE_BRANCH}"
        git push origin ${ACTIVE_BRANCH}
    else
        echo -e "\n${YELLOW}Executing >> ${BOLD}git push origin ${ACTIVE_BRANCH}${NC}"
        logIt "Executing >> git push origin ${ACTIVE_BRANCH}"
        git push origin ${ACTIVE_BRANCH}
    fi
    
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 8 ====

# ==== 9 ====
gitMergeAndPush() {
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 9. Merge and push branch on ${ACTIVE_BRANCH} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"

    if [ "${ACTIVE_BRANCH}" == "master" ] || [ "${ACTIVE_BRANCH}" == "developer" ] || [ "${ACTIVE_BRANCH}" == "live_release" ] ; then
        echo -e "\n${RED}${BOLD}Oops!! Invalid branch. This option is available only for sub branch of master and developer live Realese branch.${NC}"
        # read -e -p "Enter branch name : " para
        # para="$(echo -e "${para}" | tr -d '[:space:]')"
    else
        if [ "${ACTIVE_BRANCH}" != "master" ] || [ "${ACTIVE_BRANCH}" != "developer" ] || [ "${ACTIVE_BRANCH}" != "live_release" ] ; then
            branchname = "${ACTIVE_BRANCH}_qa"
            logIt "Executing >> git pull origin master"
            PULL="$(git pull origin master)"
            SAVEIFS=$IFS   # Save current IFS
            IFS=$'\n'      # Change IFS to new line
            names=($PULL) # split to array $names
            IFS=$SAVEIFS   # Restore IFS
            for (( i=0; i<${#names[@]}; i++ ))
            do
                echo "${names[$i]}"
            done

            if echo "$PULL" | grep -q "CONFLICT (content): Merge conflict"; then
                solveConflict 'NA' 'NA' 'master'
            fi
            # BRANCH_EXIST="$(git branch | grep ${para})"
            # if [ ${#BRANCH_EXIST} -ge 1 ]; then
            #     read -e -p "Are you sure, You want to merge branch ${para} With$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/') branch? [Yes/No] : " parareply
            #     parareply="$(echo -e "${parareply}" | tr -d '[:space:]')"
            #     if [ "$parareply" == "Yes" ] || [ "$parareply" == "yes" ] ; then
            #         if [ "$ACTIVE_BRANCH" == "master" ] ; then
            #             #api_resp=$(curl -sb -H --data "op=checkBeforeMergeInMaster&branchname=${para}&ip=${IP}&name=${DEV_NAME}" /dev/null http://192.168.20.62/cloud_release_3/cloud_tech_release3_0.php)
            #             #ERR="$(cut -d'^' -f1 <<<${api_resp})"
            #             #STATUS="$(cut -d'^' -f2 <<<${api_resp})"
            #             #if [ "$ERR" != "200" ] ; then
            #             #    echo -e "\n${RED}${BOLD}Something is going wrong in background. Report it to OP team.${NC}"
            #             #else
            #             #    if [ "$STATUS" == "MERGED_FOR_QA" ] ; then
            #             #        echo -e "\n${RED}${BOLD}Aborting... Can't merge this branch as it is still in QA testing.${NC}"
            #             #    elif [ "$STATUS" == "QA_PASS" ] || [ "$STATUS" == "NO_QA" ] ; then
            #             #        echo -e "\n${CYAN}${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}"
            #             #        git pull origin ${ACTIVE_BRANCH}
            #             #        mergeParaBranch 'merge' ${para} 'master'
            #             #    elif [ "$STATUS" == "QA_FAILED" ] ; then
            #             #        echo -e "\n${RED}${BOLD}Aborting... Failed branches can not be merged. Please approve it from QA team and then merge.${NC}"
            #             #    elif [ "$STATUS" == "MERGED_WITH_PROD" ] ; then
            #             #        echo -e "\n${RED}${BOLD}Aborting... This branch is already merged with master branch.${NC}"
            #             #    elif [ "$STATUS" == "DEVELOPMENT" ] ; then
            #             #        echo -e "\n${RED}${BOLD}Aborting... This branch can not be merged without QA.${NC}"
            #             #    fi
            #             #fi
            #             echo -e "\n${RED}${BOLD}Please generate PR in AWS Code Commit to merge branch with master.${NC}"
            #         elif [ "$ACTIVE_BRANCH" == "developer" ] || [ "$ACTIVE_BRANCH" == "qa" ] ; then
            #             # echo -e "\n${CYAN}${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}"
            #             # git pull origin ${ACTIVE_BRANCH}

            #             BRANCH_EXIST="$(git branch | grep ${para}_dev_merg)"
            #             if [ ${#BRANCH_EXIST} -ge 1 ]; then
            #                 echo -e "\n${CYAN}${BOLD}git checkout ${para}_dev_merg${NC}"
            #                 logIt "git checkout ${para}_dev_merg"
            #                 git checkout ${para}_dev_merg
            #             else
            #                 echo -e "\n${CYAN}${BOLD}git checkout -b ${para}_dev_merg${NC}"
            #                 logIt "git checkout -b ${para}_dev_merg"
            #                 git checkout -b ${para}_dev_merg
            #             fi

            #             echo -e "\n${CYAN}${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}"
            #             PULL="$(git pull origin ${ACTIVE_BRANCH})"

            #             SAVEIFS=$IFS   # Save current IFS
            #             IFS=$'\n'      # Change IFS to new line
            #             names=($PULL) # split to array $names
            #             IFS=$SAVEIFS   # Restore IFS
            #             for (( i=0; i<${#names[@]}; i++ ))
            #             do
            #                 echo "${names[$i]}"
            #             done

            #                 if echo "$PULL" | grep -q "CONFLICT (content): Merge conflict"; then
            #                 solveConflict 'pull' ${para} ${ACTIVE_BRANCH}
            #                 else
            #                     mergeParaBranch 'merge' ${para} ${ACTIVE_BRANCH}
            #                 fi
            #             else 
            #                 echo -e "\n${RED}${BOLD}Oops!! This option is available only for master and developer branch.${NC}"
            #             fi
            #         elif [ "$parareply" == "No" ] || [ $"$parareply" == "no" ] ; then
            #             echo -e "\n${YELLOW}Operation cancelled.${NC}"
            #         else
            #             echo -e "\n${YELLOW}Oops!! Not a valid option.${NC}"
            #         fi
            #     else
            #         echo -e "\n${RED}${BOLD}Oops!! branch ${para} is not available.${NC}"
            #     fi
            # else 
            #     echo -e "\n${RED}${BOLD}Oops!! branch name should not be blank.${NC}"
            # fi
        fi
        #echo -e "\n${RED}${BOLD}Oops!! Invalid branch. This option is available only for master and developer branch.${NC}"
    fi
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}

mergeParaBranch() {
    echo -e "\n${CYAN}${BOLD}git merge --no-ff $2${NC}"
    MERGE="$(git merge --no-ff $2)"
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'      # Change IFS to new line
    names=($MERGE) # split to array $names
    IFS=$SAVEIFS   # Restore IFS

    for (( i=0; i<${#names[@]}; i++ ))
    do
        echo "${names[$i]}"
    done
    
    if echo "$MERGE" | grep -q "CONFLICT (content): Merge conflict"; then
        solveConflict 'merge' $2 $3
    else
        mergeBranchWithParent $2 $3
    fi
}

mergeBranchWithParent() {
    echo -e "\n${CYAN}${BOLD}git checkout ${ACTIVE_BRANCH}${NC}"
    logIt "git checkout ${ACTIVE_BRANCH}"
    git checkout ${ACTIVE_BRANCH}

    if [ "${ACTIVE_BRANCH}" == "developer" ] || [ "${ACTIVE_BRANCH}" == "qa" ] ; then
        echo -e "\n${CYAN}${BOLD}git merge --no-ff ${1}_dev_merg${NC}"
        logIt "git merge --no-ff" ${1}_dev_merg
        git merge --no-ff ${1}_dev_merg
    else 
        echo -e "\n${CYAN}${BOLD}git merge --no-ff ${1}${NC}"
        logIt "git merge --no-ff" ${1}
        git merge --no-ff ${1}
    fi
    
    echo -e "\n${CYAN}${BOLD}git pull origin ${ACTIVE_BRANCH}${NC}"
    logIt "git pull origin ${ACTIVE_BRANCH}"
    git pull origin ${ACTIVE_BRANCH}
    
    echo -e "\n${CYAN}${BOLD}git push origin ${ACTIVE_BRANCH}${NC}"
    logIt "git push origin ${ACTIVE_BRANCH}"
    git push origin ${ACTIVE_BRANCH}

    #api_resp=$(curl -sb -H --data "op=branchMerged&branchname=${1}&ip=${IP}&name=${DEV_NAME}&type=${2}" /dev/null http://192.168.20.62/cloud_release_3/cloud_tech_release3_0.php)
    #ERR="$(cut -d'^' -f1 <<<${api_resp})"
    #if [ "$ERR" != "200" ] ; then
    #    echo -e "\n${RED}${BOLD}Something is going wrong in background. Report it to OP team.${NC}"
    #fi

    if [ "$2" == "developer" ] || [ "$2" == "qa" ] ; then
        echo -e "\n${CYAN}${BOLD}git branch -D ${1}_dev_merg${NC}"
        logIt "git branch -D ${1}_dev_merg"
        git branch -D ${1}_dev_merg
    fi
}

solveConflict() {
    echo -e "\n${RED}${BOLD}Oops!! We have conflicts in code. Resolve all conflics in below files${NC}"
    git diff --name-only --diff-filter=U

    read -e -p "Resolve all conflicts and reply with 'Yes' to continue or else 'No' to abort : " parareply
    parareply="$(echo -e "${parareply}" | tr -d '[:space:]')"
    if [ "$parareply" == "Yes" ] || [ "$parareply" == "yes" ] ; then
        echo -e "\n${CYAN}${BOLD}git add .${NC}"
        logIt "git add ."
        git add .

        echo -e "\n${CYAN}${BOLD}git commit -m 'Resolved conflicts'${NC}"
        logIt "git commit -m Resolved conflicts"
        git commit -m "Resolved conflicts"

        if [ $1 == "pull" ] ; then
            mergeParaBranch $1 $2 $3
        elif [ $1 == "merge" ] ; then
            mergeBranchWithParent $2 $3
        fi
    else
        echo -e "\n${RED}${BOLD}Operation aborted. Reverting changes.${NC}"
        echo -e "\n${CYAN}${BOLD}git reset --hard HEAD@{0}'${NC}"
        logIt "git reset --hard HEAD@{0}"
        git reset --hard HEAD@{0}
        
        if [ "$3" == "developer" ] || [ "$3" == "qa" ] ; then
            echo -e "\n${CYAN}${BOLD}git checkout ${ACTIVE_BRANCH}${NC}"
            logIt "git checkout ${ACTIVE_BRANCH}"
            git checkout ${ACTIVE_BRANCH}

            echo -e "\n${CYAN}${BOLD}git branch -D ${1}_dev_merg${NC}"
            logIt "git branch -D ${1}_dev_merg"
            git branch -D ${1}_dev_merg
        fi
    fi
}
# ==== 9 ====

# ==== 10 ====
gitLog(){
    local para
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 10. git log (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter additional information (optional) and press ENTER to execute : " para
    # para="$(echo -e "${para}" | tr -d '[:space:]')"
    if [ ${#para} -ge 1 ]; then
        echo -e "\n${YELLOW}Executing >> ${BOLD}git log ${para}${NC}\n"
    fi
    logIt "git log ${para}"
    git log ${para}
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 10 ====

# ==== 11 ====
gitWhatchanged(){
    local para
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 11. git whatchanged (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter additional information (optional) and press ENTER to execute : " para
    # para="$(echo -e "${para}" | tr -d '[:space:]')"
    logIt "git whatchanged ${para}"
    git whatchanged ${para}
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 11 ====

# ==== 12 ====
gitShow () {
    local para 
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo " 12. git show (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter git commit id and press ENTER to execute : " para
    # para="$(echo -e "${para}" | tr -d '[:space:]')"
    logIt "git show ${para}"
    git show ${para}
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 12 ====

# ==== 13 ====
gitAll(){
    local para
    echo -e "\n\n${CYAN}${BOLD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
    echo -e " 13. git ${YELLOW}<command>${CYAN}${BOLD} (${IP})"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    read -e -p "Enter additional information (optional) and press ENTER to execute : " para
    # para="$(echo -e "${para}" | tr -d '[:space:]')"
    if [ ${#para} -ge 1 ]; then
        if echo "$para" | grep -q "add "; then
            logIt "git ${para} >> using in point 13"
            echo -e "\n${YELLOW}If you add file then please use point #3"
            show_menus
            read_options
            return;
        elif echo "$para" | grep -q "merge "; then
            logIt "git ${para} >> using in point 13"
            echo -e "\n${YELLOW}Merging a branch is prohibited via this point. Please use point #4"
            show_menus
            read_options
            return;
        fi
        echo -e "\n${YELLOW}Executing >> ${BOLD}git ${para}${NC}\n"
    fi
    logIt "git ${para}"
    git ${para}
    echo -e "${CYAN}${BOLD}\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}
# ==== 13 ====


show_menus() {
	#clear
    ACTIVE_BRANCH=`git rev-parse --abbrev-ref HEAD`
    echo -e "\n"
	echo -e "${BOLD}${YELLOW} BRANCH - ${ACTIVE_BRANCH}"
	echo -e ".-------------------------------------------------------."
    echo -e "|  G I T  - C O M M A N D S\t\t\t\t|"
	echo -e "|-------------------------------------------------------|"
    echo -e "|  1.  git status\t\t\t\t\t|"
    echo -e "|  2.  git pull origin <BranchName>\t\t\t|"
  	echo -e "|  3.  git add/commit\t\t\t\t\t|"
    #echo -e "|  4.  git merge \t\t\t\t\t|"
    echo -e "|-------------------------------------------------------|"
    echo -e "|  4.  git branch ${CYAN}${BOLD}(BRANCH LIST)${YELLOW}${BOLD}\t\t\t\t|"
    echo -e "|  5.  git checkout ${CYAN}${BOLD}(SWITCH BRANCH)${YELLOW}${BOLD}\t\t\t|"
    if [ "$ACTIVE_BRANCH" == "master" ] ; then
    echo -e "|  6.  git checkout -b ${CYAN}${BOLD}(CREATE NEW BRANCH)${YELLOW}${BOLD}\t\t|"
    fi
    echo -e "|  7.  git branch -d ${CYAN}${BOLD}(DELETE BRANCH)${YELLOW}${BOLD}\t\t\t|"
    echo -e "|  8.  git push origin ${ACTIVE_BRANCH} ${CYAN}${BOLD}(PUSH BRANCH ON REMOTE)${YELLOW}${BOLD}\t|"
    echo -e "|  ${RED}${BOLD}9. PUSH ON MASTER/DEVELOPER/LIVE_RELEASE (BE CAREFUL)${YELLOW}${BOLD}\t|"
    echo -e "|-------------------------------------------------------|"
    echo -e "|  10. git log\t\t\t\t\t\t|"
  	echo -e "|  11. git whatchanged\t\t\t\t\t|"
  	echo -e "|  12. git show\t\t\t\t\t\t|"
    echo -e "|  13. git (others)\t\t\t\t\t|"
    echo -e "|-------------------------------------------------------|"
    # echo -e "|  ${RED}${BOLD}13. MERGE CONFLICTED CODE\t\t\t${YELLOW}|"
    #echo -e "|  ${CYAN}${BOLD}14. BRANCH REPORT [deprecated]\t\t\t${YELLOW}|"
    #echo -e "|  ${CYAN}${BOLD}15. Security Assessment [deprecated]\t\t\t${YELLOW}|"
	echo -e "|  0.  exit${NC}\t\t\t\t\t\t${BOLD}${YELLOW}|"
    echo -e "'-------------------------------------------------------'${STD}"
}

read_options(){
	local choice
	read -p "Enter choice [0 - 13] : " choice
    choice="$(echo -e "${choice}" | tr -d '[:space:]')"

# 4) gitMerge ;;
	case $choice in
    1) gitStatus ;;
	2) gitPull ;;
    3) gitAddCommit ;;
    4) gitBranch ;;
    5) gitBranchCheckout ;;
    6) gitCreateBranch ;;
    7) gitRemoveBranch ;;
    7) gitPushOnRemote ;;
    8) gitPushOnRemote ;;
    9) gitMergeAndPush ;;
    10) gitLog ;;
    11) gitWhatchanged ;;
    12) gitShow ;;
    13) gitAll ;;
	0) 
      echo -e "\n"
      exit 0
      ;;
    *) 
      echo -e "\n" 
      exit 0
      ;;
	esac
}

logIt() {
  TIME="$(date +'%r')"
  echo "BRANCH -$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/') > ${TIME} > ${IP} > $1 " >> ${LogFile}
#   echo "${IP} > $1 " >> ${LogFile}
}
 
#IP="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
#IP=`who -m`
IP=`who -m | awk -F" " '{print $5}'`
IP="${IP/(}"
IP="${IP/)}"
DEV_NAME=`whoami`
LogFile="$LogFile$(whoami)_gitshelladdcommitlogs_$(date +'%Y%m%d').log"
if [[ ! -e ${LogFile} ]]; then
    touch ${LogFile}
fi

while true
do
	show_menus
	read_options
done

