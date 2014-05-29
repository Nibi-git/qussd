#!/bin/sh

# design by garynych 08.31.2012
# used decoder by Jerry_Offsping
# edited and tuned by Nibiru 05.28.2014

n=1;    #set port

encode_gsm7bit() {
local text="$1"
local i=0
local shift=0

while [ $i -lt ${#text} ]
do
  if [ $(( $i+1 )) -eq ${#text} ]; then
    next_byte=0
  else
  : $(( next_byte=(($(echo $(printf "%d" "'${text:$(( $i+1 )):1} ")) << (7 - $shift)) & 0xFF) ))
  fi

: $(( current_byte=($(echo $(printf "%d" "'${text:$i:1} ")) >> $shift) | $next_byte ))

ret=$ret$(echo $current_byte | awk '{printf("%02X",$0)}')

: $(( i++ ))
: $(( shift++ ))

if [ $shift -eq 7 ]; then
  shift=0
  : $(( i++ ))
fi

done
}

decode_gsm7bit() {
local text="$1"
local i=0
while [ $i -lt ${#text} ]
do
  local data=$data${text:$i:2}" "
  i=$(($i+2))
done

local shift=0
local carry=0

for byte in $data
do
 if [ $shift -eq 7 ]; then
  ret=$ret$(echo $carry | awk '{printf("%c",$0)}')

  carry=0
  shift=0
 fi

byte=$((0x$byte))

: $(( a = (0xFF >> ($shift + 1)) & 0xFF ))
: $(( b = $a ^ 0xFF ))

: $(( digit = $carry | (($byte & $a) << $shift) & 0xFF ))
: $(( carry = ($byte & $b) >> (7 - $shift) ))

ret=$ret$(echo $digit | awk '{printf("%c",$0)}')

: $(( shift++ ))
done
}

if [ -z "$1" ]; then
echo "Please add USSD query as parameter, like "$0" *111#"
exit 1
fi

#for 7-bit query
ret=''; encode_gsm7bit "$1"

#for plain text query
#ret="$1"

F="/dev/ttyUSB$n"
#F="/dev/ttyUSB$2"

if ! [ -e "$F" ]; then
echo "Open port ERROR"
exit 1
fi

echo "AT+CUSD=1,"$ret",15">$F 

cat $F  | grep "+CUSD:"  > /tmp/bal &
sleep 5
killall cat

answer=`cat /tmp/bal`

answer=${answer%\"*} 
answer=${answer##*\"}

ret=''; decode_gsm7bit "$answer"; echo $ret

rm /tmp/bal*
exit 0