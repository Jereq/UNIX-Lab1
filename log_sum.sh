#!/bin/sh

usage="$0 [-n N] [-h H | -d D] (-c | -2 | -r | -F | -t | -f) <filename>"

if [ $# = 0 ]; then
	echo $usage
	exit 1
fi

verifyNum() {
	case $1 in
		''|*[!0-9]*)
			echo $usage
			exit 1
			;;
	esac
}

while getopts cd:Fh:n:rt2 arg; do
	case $arg in
		c)
			func=conn ;;
		d)
			timeLimit=True
			verifyNum $OPTARG
			days=$OPTARG
			;;
		F)
			func=failResCode ;;
		h)
			timeLimit=True
			verifyNum $OPTARG
			hours=$OPTARG
			;;
		n)
			verifyNum $OPTARG
			lines=$OPTARG
			;;
		r)
			func=resCode ;;
		t)
			func=byteCount ;;
		2)
			func=succConn ;;
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
	input='-'
elif [ $# = 1 ]; then
	input="$1"
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
	lastDate=$(echo "$1" | extractDate | transformDate)
	
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

filterStatusCode() {
	while read -r dummy1 dummy2 dummy3 dummy4 dummy5 dummy6 dummy7 dummy8 returnCode rest; do
		if [ $returnCode -ge $1 -a $returnCode -lt $2 ]; then
			echo "$dummy1 $dummy2 $dummy3 $dummy4 $dummy5 $dummy6 $dummy7 $dummy8 $returnCode $rest"
		fi
	done
}

onlySuccesful() {
	filterStatusCode 200 300
}

succConn() {
	onlySuccesful | conn
}

resCode() {
	cat > inp
	cat inp | sort -k 9,9 | awk '{ print $9 }' | uniq -c > tmpCodeCount
	cat inp | awk '{ print $9 " " $1 }' | sort -k 1,1 | uniq \
		| join -1 2 tmpCodeCount - | sort -nrk 2,2 | awk '{ print $1 " " $3 }'
	rm inp
	rm tmpCodeCount
}



failResCode() {
	filterStatusCode 400 600 | resCode
}

filterNoBytes() {
	while read -r dummy1 dummy2 dummy3 dummy4 dummy5 dummy6 dummy7 dummy8 dummy9 bytes rest; do
		if [ $bytes != '-' ]; then
			echo "$dummy1 $dummy2 $dummy3 $dummy4 $dummy5 $dummy6 $dummy7 $dummy8 $dummy9 $bytes $rest"
		fi
	done
}

sumBytes() {
	local prevIp=""
	local currCount=0
	
	while read ip bytes; do
		if [ x$ip = x$prevIp ]; then
			currCount=`expr $currCount + $bytes`
		else
			if [ $prevIp ]; then
				echo "$prevIp $currCount"
			fi
			currCount=$bytes
			prevIp=$ip
		fi
	done
	
	if [ $prevIp ]; then
		echo "$prevIp $currCount"
	fi
}

byteCount() {
	filterNoBytes | awk '{ print $1 " " $10 }' | sort -k 1,1 | sumBytes | sort -nrk 2,2
}

processSome() {
	read lastLine
	local limit=$(calculateLimit "$lastLine")
	
	echo "$lastLine"

	while read ip dummy1 dummy2 date1 date2 rest; do
		date=$(echo "$date1 $date2" | transformDate)
		timestamp=$(dateToTimestamp "$date")
		if [ $timestamp -lt $limit ]; then
			break
		fi
		echo "$ip $dummy1 $dummy2 $date1 $date2 $rest"
	done
}

if [ $timeLimit ]; then
	fullResult=$(tac "$input" | processSome | eval "$func")
else
	fullResult=$(cat "$input" | eval "$func")
fi

if [ $lines ]; then
	echo "$fullResult" | head -n $lines | column -t
else
	echo "$fullResult" | column -t
fi


