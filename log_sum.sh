#!/bin/sh

usage="$0 [-n N] [-h H | -d D] (-c | -2 | -r | -F | -t | -f) <filename>"

if [ $# = 0 ]; then
	echo $usage
	exit 1
fi

while getopts cd:fFh:n:rt2 arg; do
	case $arg in
		c)
			func=conn ;;
		d)
			timeLimit=True
			days=$OPTARG ;;
		h)
			timeLimit=True
			hours=$OPTARG ;;
		n)
			lines=$OPTARG ;;
		*)
			echo "Option '-$arg' not handled" ;;
	esac
done

if [ ! $func ]; then
	echo "Missing criteria"
	echo $usage
	exit 1
fi

shift $((OPTIND - 1))

if [ $# = 0 ]; then
	input=/dev/stdin
elif [ $# = 1 ]; then
	if [ $1 = - ]; then
		input=/dev/stdin
	else
		input="$1"
	fi
else
	echo "Invalid arguments"
	echo $usage
	exit
fi

extractDate() {
	awk '{ print $4 " " $5 }'
}

transformDate() {
	sed "s:/: :g;s/:/ /;s/[][]//g"
}

dateToTimestamp() {
	date --date="$1" +%s
}

calculateLimit() {
	lastDate=$(tail -n1 "$input" | extractDate | transformDate)
	
	if [ $days ]; then
		midnight=$(date --date="$lastDate -$((days - 1)) days" +%D)
		dateToTimestamp "$midnight"
	else
		lastTimestamp=$(dateToTimestamp "$lastDate")
		echo $((lastTimestamp - 3600 * hours))
	fi
}

conn() {
	sort -k 1,1 | awk '{ print $1 }' | uniq -c | sort -k 1,1 -rn | awk '{ print $2 " " $1 }'
}

processSome() {
	local limit=$(calculateLimit)
	#local count=0
	while read ip dummy1 dummy2 date1 date2 rest; do
		date=$(echo "$date1 $date2" | transformDate)
		timestamp=$(dateToTimestamp "$date")
		if [ $timestamp -lt $limit ]; then
			break
		fi
		echo "$ip $dummy1 $dummy2 $date1 $date2 $rest"
		#count=`expr $count + 1`
	done

	#echo $count
}

processAll () {
	echo "Hej"
}

if [ $timeLimit ]; then
	fullResult=$(tac "$input" | processSome | eval "$func")
else
	fullResult=$(eval "$func" < "$input")
fi

if [ $lines ]; then
	echo "$fullResult" | head -n $lines | column -t
else
	echo "$fullResult" | column -t
fi

#echo "Sum: $countedLines"


