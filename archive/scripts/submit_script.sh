#!/bin/bash

scriptname=${1}
batch=${2}
max="8"

start=$(( (batch-1) * 100 + 1 ))
end=$(( batch * 100 ))

if [ "$batch" -eq "$max" ]
then
	end="724"
fi

echo "$start"
echo "$end"

cp ${scriptname} ${scriptname}.${batch}

sed -i "s@-t 1-724@-t $start-$end@g" "${scriptname}.${batch}"
qsub ${scriptname}.${batch}

