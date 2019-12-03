cmd[0]="aws athena list-named-queries"
pref[0]="NamedQueryIds"
tft[0]="aws_glue_crawler"
cmd[1]="aws athena get-named-query --named-query-id"
pref[1]="NamedQuery"
tft[1]="aws_athena_named_query"

# get number of query ids
for c in `seq 0 0`; do
    cm=${cmd[$c]}
    ttft=${tft[(${c})]}
    echo $cm
    awsout=`eval $cm`
    #echo $awsout
    count=`echo $awsout | jq ".${pref[(${c})]} | length"`
    echo $count
done


c2=1
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    #loop through query id's
    for i in `seq 0 $count`; do
        qid=`echo $awsout | jq ".${pref[(${c})]}[(${i})]" | tr -d '"'`
        #echo "quid=$qid"
        cm="${cmd[$c2]} $qid"
        myuuid=`date +%s`
        #cm=`printf "%s %s" "$cm" "$quid"`
        
        ttft=${tft[(${c2})]}
        #echo "command= $cm"
        awsout2=`eval $cm`
        #echo $awsout
        cname=`echo $awsout2 | jq ".${pref[(${c2})]}" | jq .Name | tr -d '"'`
        cname=`printf "%s__%s" $cname $myuuid`
        echo "name=$cname"
        ttft=${tft[(${c2})]}
        printf "resource \"%s\" \"%s\" {" $ttft $cname > $cname.tf
        printf "}" $cname >> $cname.tf
        terraform import $ttft.$cname $qid
        if [ $? -ne 0 ]; then
            exit
        fi
        terraform state show $ttft.$cname > t2.txt
        rm $cname.tf

        cat t2.txt | perl -pe 's/\x1b.*?[mGKH]//g' > t0.txt
        cat t0.txt | sed 's/\\n/ /g' > t1.txt
        echo "T1"
        cat t1.txt
        file="t1.txt"
        fn=`printf "%s__%s.tf" $ttft $cname`
        while IFS= read line
        do
			skip=0
            # display $line or do something with $line
            t1=`echo "$line"` 
            if [[ ${t1} == *"="* ]];then
                tt1=`echo "$line" | cut -f1 -d'=' | tr -d ' '` 
                tt2=`echo "$line" | cut -f2- -d'='`  
                if [[ ${tt1} == "arn" ]];then	
                	#printf "acl = \"private\" \n" >> $fn
                    #printf "force_destroy = false \n" >> $fn

                    skip=1
                fi
                if [[ ${tt1} == "query" ]];then
                    #echo "tt2="
                    #echo $tt2
                    echo query=$tt2 | sed 's/",/\\",/g' | sed 's/,"/,\\"/g' > t5.txt
                    tt5=`echo $tt2 | sed 's/",/\\",/g' | sed 's/,"/,\\"/g'`
                    #echo "part1="$tt1
                    #echo "part2="$tt5
                    
                    t1=`printf "%s=%s" "$tt1" "$tt5"`
                    t1=`cat t5.txt`
                    #echo "query="
                    #echo $t1
                             
                fi


                    
                if [[ ${tt1} == "id" ]];then
                    #printf "acl = \"private\"\n" >> $fn
                    #printf "force_destroy = false \n" >> $fn

                    skip=1
                fi
                    
                if [[ ${tt1} == "role_arn" ]];then skip=0;fi
                if [[ ${tt1} == "force_destroy" ]];then skip=1;fi
                if [[ ${tt1} == "bucket_domain_name" ]];then skip=1;fi
                if [[ ${tt1} == "bucket_regional_domain_name" ]];then skip=1;fi
                if [[ ${tt1} == "allocated_capacity" ]];then skip=1;fi
            fi
			if [ "$skip" == "0" ]; then

				#echo $skip $t1 $ttft

				echo $t1 >> $fn
			fi
        done <"$file"      
        
    done
fi





exit


awsout=`aws athena list-named-queries`
count=`echo $awsout | jq ".${pref[(${c})]} | length"`
echo $qrys | jq '.NamedQueryIds'




exit


for c in `seq 0 1`; do
    cm=${cmd[$c]}
    ttft=${tft[(${c})]}
    echo $cm
    awsout=`eval $cm`
    count=`echo $awsout | jq ".${pref[(${c})]} | length"`
    if [ "$count" -gt "0" ]; then
        count=`expr $count - 1`
        for i in `seq 0 0`; do
            echo $i
            cname=`echo $awsout | jq ".${pref[(${c})]}[(${i})].Name" | tr -d '"'`
            echo $cname
            printf "resource \"%s\" \"%s\" {" $ttft $cname > $cname.tf
            printf "}" $cname >> $cname.tf
            terraform import $ttft.$cname $cname
            terraform state show $ttft.$cname > t2.txt
            rm $cname.tf
            cat t2.txt | perl -pe 's/\x1b.*?[mGKH]//g' > t1.txt
            #	for k in `cat t1.txt`; do
            #		echo $k
            #	done
            file="t1.txt"
            while IFS= read line
            do
                skip=0
                # display $line or do something with $line
                t1=`echo "$line"`
                
                if [[ ${t1} == *"arn"*"="* ]];then
                    echo "in arn"
                    skip=1
                fi
                
                if [[ ${t1} == *"id"*"="* ]];then
                    skip=1
                fi
                
                if [[ ${t1} == *"role_arn"*"="* ]];then skip=0;fi
                if [[ ${t1} == *"allocated_capacity"*"="* ]];then skip=1;fi
                
                if [ "$skip" == "0" ]; then
                    #echo $skip $t1
                    echo $t1 >> $cname.tf
                fi
            done <"$file"
            
            
            
        done
    fi
done
rm t*.txt
