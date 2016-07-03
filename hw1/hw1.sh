#!/bin/bash
# bash command-line arguments are accessible as $0 (the bash script), $1, etc.
# echo "Running" $0 "on" $1
filename="$1"
SECONDS=0
line_count=0
body_count=0
csvline=""
whole_body=""
count=-1
rm ebook.csv ebook-sorted.csv tokens.csv token_counts.csv tokens-sorted.csv
echo "title,author,release_date,ebook_id,language,body" > ebook.csv 
declare -a expected_values=("Title" "Author" "Release Date" "Language")
#[[ $line == "Title"* ]] && echo "$line starts with Title"
grep  "^Title:\|^Author:\|^Language:\|^Release Date:" $filename | sed '/^[\r\n]*$/d'|  tr -d '\r' |  while read -r line; do     
    #echo $line;     
    if [[ $line == "Title"* ]]; then         
         story=$(cat $filename | awk -v "nth=$body_count"  '/^\*\*\* START OF THE PROJECT GUTENBERG/,/^\*\*\* END OF THE PROJECT GUTENBERG/{if(++m==1)n++;if(n==nth)print;if(/^\*\*\* END OF THE PROJECT GUTENBERG/)m=0}'| sed '1d; $d' | sed "s/\"/\"\"/g" )
        echo "$story" | awk '{print tolower($0)}' | tr -cs 'a-zA-Z' '\n' | sed "s|^|${bodyid}|" >> tokens.csv
        echo "$story"  | sort >> ebook-sorted.csv
        csvline="$csvline, $story"
        echo "$csvline" >> ebook.csv
        body_count=$((body_count + 1))
        csvline=$(echo $line | cut -d ':' -f 2 | sed -e 's/^[ \t]*//' | sed -e 's/^[ \t]*//')","
        count=0;     
    elif [[ $line == "Release Date"* ]]; then
        csvline+="\""$(echo $line | cut -d '[' -f 1| cut -d ':' -f 2 | sed -e 's/^[ \t]*//')"\""","
        bodyid=$(echo $line | sed 's/.*\[\([^]]*\)\].*/\1/g'| cut -d " " -f 2 |cut -d '#' -f 2)","
        csvline+="\""$(echo $line | sed 's/.*\[\([^]]*\)\].*/\1/g'| cut -d " " -f 2 |cut -d '#' -f 2 | sed -e 's/^[ \t]*//')"\","
     else
         csvline+=$(echo $line | cut -d ':' -f 2 | cut -d '#' -f 2 | sed -e 's/^[ \t]*//')","
     fi;     
     previous_line=$line;     
     let "count=count+1"; 
     let "line_count=line_count+1"; 
done
cat tokens.csv | cut -d ',' -f2| grep -v "^\s*$" | sort | uniq -c | sort -bnr >> token_counts.csv
grep -w -i -f popular_names.txt token_counts.csv | awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }' | sed 's/\>/,/g;s/,$//' >> names.csv
sort ebook-sorted.csv -o ebook-sorted.csv
exit 0
