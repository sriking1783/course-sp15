#!/bin/bash
# bash command-line arguments are accessible as $0 (the bash script), $1, etc.
# echo "Running" $0 "on" $1
filename="$1"
SECONDS=0
touch $filename
count=$(grep -c "Title:" $filename)
rm ebook.csv ebook-sorted.csv tokens.csv token_counts.csv tokens-sorted.csv name_counts.csv
echo "title,author,release_date,ebook_id,language,body" > ebook.csv 
echo "ebook_id,token" > tokens.csv
echo "token,count" > tokens.csv
echo "token,count" > name_counts.csv
i=1
while [ $i -lt "$count" ]
do
    chunk=$(grep  "^Title:\|^Author:\|^Language:\|^Release Date:\|^\*\*\* START OF THE PROJECT GUTENBERG" $filename | awk -v "nth=$i"  "/^Title:/,/^\*\*\* START OF THE PROJECT GUTENBERG/{if(++m==1)n++;if(n==nth)print;if(/^\*\*\* START OF THE PROJECT GUTENBERG/)m=0}" )  
    if [[ "$chunk" = "" ]]; then
        break;
    fi
    title=$(echo "$chunk" | grep "Title:" | tr -d '\r\n' | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')","
    author=$(echo "$chunk" | grep "Author:" | tr -d '\r\n' | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')","
    release_date="\""$(echo "$chunk" | grep "Release Date:" | tr -d '\r\n' | cut -d '[' -f 1| cut -d ':' -f 2 | sed -e 's/^[ \t]*//'| sed -e 's/^[ \t]*//'| sed 's/ $//')"\","
    bookid=$(echo "$chunk" | grep "Release Date:" | tr -d '\r\n' | sed 's/.*\[\([^]]*\)\].*/\1/g'| cut -d " " -f 2 |cut -d '#' -f 2 | sed -e 's/^[ \t]*//')","
    language=$(echo "$chunk" | grep "Language:" | tr -d '\r\n' | cut -d ':' -f 2| sed -e 's/^[ \t]*//')","
    story=$(< $filename awk -v nth=$i  '/^\*\*\* START OF THE PROJECT GUTENBERG/,/^\*\*\* END OF THE PROJECT GUTENBERG/{if(++m==1)n++;if(n==nth)print; if(/^\*\*\* END OF THE PROJECT GUTENBERG/)m=0}' | tr -d '\r'  | sed '1d; $d' | sed "s/\"/\"\"/g" )
    printf '%s' "$story" | grep -v "^$" | awk '{print tolower($0)}' | tr -cs 'a-zA-Z' '\n' | sed "s|^|${bookid}|" >> tokens.csv
    printf '%s%s%s%s%s\"%s\n\n"\n' "$title" "$author" "$release_date" "$bookid" "$language" "$story" >> ebook.csv
    i=$((i + 1))
done
#done
cut -d ',' -f2 tokens.csv| grep -v "^\s*$" | sort | uniq -c | sort -bnr >> token_counts.csv
grep -w -i -f popular_names.txt token_counts.csv | awk '{ for (i=NF; i>1; i--) printf("%s,",$i); print $1; }' >> name_counts.csv
exit 0
