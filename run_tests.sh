file=$1

if [[ -z $file ]]
then
    file="test/test_suite.rb"
fi

ruby -I"lib:test:.:../arby/lib:../method_source/lib:../sdg_utils/lib" $file $2 $3 $4 $5 $6 $7 $8 $9
# bundle exec ruby -I"lib:test:.:../arby/lib:../method_source/lib:../sdg_utils/lib" $file $2 $3 $4 $5 $6 $7 $8 $9
