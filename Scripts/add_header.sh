for fn in $(find Classes -type f -name "*.[hm]")
do
mv $fn ${fn}.save
cp code_header.txt $fn
cat ${fn}.save >> $fn
rm $fn.save
done