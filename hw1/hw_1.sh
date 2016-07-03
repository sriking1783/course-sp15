#!/bin/bash
# bash command-line arguments are accessible as $0 (the bash script), $1, etc.
# echo "Running" $0 "on" $1
filename="$1"
SECONDS=0
line_count=0
body_count=0
csvline=""
whole_body=""
touch $filename
count=$(grep "Title:" $filename  | wc -l)
rm ebook.csv ebook-sorted.csv tokens.csv token_counts.csv tokens-sorted.csv
echo "title,author,release_date,ebook_id,language,body" > ebook.csv 
echo "ebook_id,token" > tokens.csv
i=1
while [ $i -lt $count ]
do
    chunk=$(grep  "^Title:\|^Author:\|^Language:\|^Release Date:\|^\*\*\* START OF THE PROJECT GUTENBERG" $filename | awk -v "nth=$i"  '/^Title:/,/^\*\*\* START OF THE PROJECT GUTENBERG/{if(++m==1)n++;if(n==nth)print;if(/^\*\*\* START OF THE PROJECT GUTENBERG/)m=0}' )  
    #echo "$chunk" 
    title=$(echo "$chunk" | grep "Title:" | tr -d '\r\n' | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')","
    author=$(echo "$chunk" | grep "Author:" | tr -d '\r\n' | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')","
    release_date="\""$(echo "$chunk" | grep "Release Date:" | tr -d '\r\n' | cut -d '[' -f 1| cut -d ':' -f 2 | sed -e 's/^[ \t]*//'| sed -e 's/^[ \t]*//'| sed 's/ $//')"\","
    bookid=$(echo "$chunk" | grep "Release Date:" | tr -d '\r\n' | sed 's/.*\[\([^]]*\)\].*/\1/g'| cut -d " " -f 2 |cut -d '#' -f 2 | sed -e 's/^[ \t]*//')","
    language=$(echo "$chunk" | grep "Language:" | tr -d '\r\n' | cut -d ':' -f 2| sed -e 's/^[ \t]*//')","
    story=$(cat $filename | awk -v nth=$i  '/^\*\*\* START OF THE PROJECT GUTENBERG/,/^\*\*\* END OF THE PROJECT GUTENBERG/{if(++m==1)n++;if(n==nth)print; if(/^\*\*\* END OF THE PROJECT GUTENBERG/)m=0}' | tr -d '\r'  | sed '1d; $d' | sed "s/\"/\"\"/g" )
    printf "$story" | awk '{print tolower($0)}' | tr -cs 'a-zA-Z' '\n' | sed "s|^|${bookid}|" >> tokens.csv
    printf "$title$author$release_date$bookid$language\"$story\n\"\n" >> ebook.csv
    i=$((i + 1))
    #echo "Processing $i - $bookid"
done
#done
awk '!/,$/' tokens-sorted.csv > temp && mv temp tokens-sorted.csv
tail -n+1 tokens.csv | cut -d ',' -f2| grep -v "^\s*$" | sort | uniq -c | sort -bnr >> token_counts.csv
grep -w -i -f popular_names.txt token_counts.csv | awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }' | sed 's/\>/,/g;s/,$//' >> names.csv
#sed '/^$/d' unsorted_ebook-sorted.csv > unsorted_ebook-sorted.csv.tmp
#rm ebook-sorted.csv
#sort -n unsorted_ebook-sorted.csv.tmp  > ebook-sorted.csv
echo "DONE"
exit 0
