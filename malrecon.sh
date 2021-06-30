#!/bin/bash

#will be inspired from the lazy recon.
#modes: light recon, medium recon and deep recon.

#tools will be added stepwise.

#light recon
#knockpy, sublist3r results
#output the knockpy json results in a nice html report.
# https://github.com/raine/html-table-cli refer this later.

#medium recon
#plus subfinder and subdomy results

#deep recon
#plus amass results         [think later the placement for these tools]

#go through httprobe

#aquatone

#eventually added crawlers and parameters discovery

#may reuse lazyrecon master_report format.



###########################################
#          GENERAL CONFIGURATION
#------------------------------------------
chromiumPath=/usr/bin/chromium
knockpyWordlist=~/tools/knock/knockpy/wordlist.txt
sublist3rThreads=10
auquatoneThreads=5
###########################################

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

usage(){ 
    echo "Usage: malrecon domain.com" 1>&2; exit 1;  #redirect stdout to stderr 
}

logo(){
    echo "${red} LOGO HERE ${reset}"
}

aqua(){
    echo "Starting aquatone scan..."
    cat ./aggregated.txt | aquatone -chrome-path $chromiumPath -out ./aquatone -threads $auquatoneThreads -silent
}

json_to_html_report(){
    cd ./knockpy/
    echo "[" > ./formatted.json
    cat ./knockpy.txt | while read line; do
    val=$(cat ./$domain* | jq '.["'"$line"'"]')

    alias_value=$(echo $val | jq -c '.alias[]')
    if [[ -z "$alias_value" ]]; then
    #echo "String is empty"
    modified=$(echo $val | jq -c '.alias="'"$line"'"')
    echo $modified >> ./formatted.json
    elif [[ -n "$alias_value" ]]; then
    #echo "String is not empty"
    echo $val >> ./formatted.json
    fi

    echo "," >> ./formatted.json
    done

    echo "]" >> ./formatted.json
    cat ./formatted.json | sed 's/"domain"/"real-hostname"/g' | sed 's/"alias"/"subdomain"/g' > ./final.json
    cat ./final.json | html-table --cols subdomain,real-hostname,ipaddr,code,server > knockpy_report.html
    #Pretty format this output, refer the github examples of html-table-cli
    cd $path
}

light_scan(){
    create_needed_files $domain
    ~/tools/knock/knockpy/knockpy.py $domain -w $knockpyWordlist -o ./knockpy | tee ./knockpy/raw_output.txt  #This raw_output not working
    cat ./knockpy/$domain* |  jq 'del(._meta)' | jq -r 'keys[]' > ./knockpy/knockpy.txt
    echo "${yellow}Probing knockpy results ${reset}"
    cat ./knockpy/knockpy.txt | httprobe > ./knockpy/knockpy-probed.txt

    json_to_html_report

    # sublist3r -d $domain -t $sublist3rThreads -v -o ./sublist3r/sublist3r.txt
    # echo "${yellow}Probing sublist3r results ${reset}"
    # cat ./sublist3r/sublist3r.txt | httprobe > ./sublist3r/sublist3r-probed.txt

    #Results from both the tools will be aggregated.
    cat ./sublist3r/sublist3r-probed.txt ./knockpy/knockpy-probed.txt | sort -u > aggregated.txt
    
    #urllist.txt will contain either http or https version of the subdomain. Not both.
    # cat ./aggregated.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do
    # deduplicated=$(cat ./aggregated.txt | sort -u | grep -m 1 $line)
    # echo "$deduplicated" >> ./urllist.txt
    # done

    #aqua
}

create_needed_files(){
    mkdir -p ~/targets/$domain/$foldername
    cd ~/targets/$domain/$foldername
    path=~/targets/$domain/$foldername
    mkdir ./aquatone
    mkdir ./knockpy
    mkdir ./sublist3r
    touch ./urllist.txt
    touch ./aggregated.txt
    touch ./knockpy/formatted.json
    touch ./knockpy/knockpy.txt
    touch ./knockpy/knockpy-probed.txt
    touch ./sublist3r/sublist3r.txt
    touch ./sublist3r/sublist3r-probed.txt
}

main(){
    echo "Choose the level of recon you want to perform."
    PS3="Please select a option: "
    choices=("light" "medium" "deep")
    select choice in "${choices[@]}"; do
        case $choice in
                light)
                        light_scan $domain
                        break
                        ;;
                medium)
                        echo "Not implemented upto now :)"
                        exit 1
                        break
                        ;;
                deep)
                        echo "Not implemented upto now :)"
                        exit 1
                        ;;
        esac
    done
}

if [ -z "${1}" ]; then
    usage; exit 1;
fi

todate=$(date +"%Y-%h-%d-%H-%M")
foldername=recon-$todate
domain=$1
logo
main $domain
