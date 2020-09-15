#!/bin/sh
set -ue
umask 0022
export LC_ALL=C
export PATH="$(command -p getconf PATH 2>/dev/null)${PATH+:}${PATH-}"
case $PATH in :*) PATH=${PATH#?};; esac
export UNIX_STD=2003

sedlyLF="$(printf '\\\012_')"; sedlyLF="${sedlyLF%_}"
{
	od -A n -t x1 -v "${1:--}" |
		tr ABCDEF abcdef |
		tr -Cd '0123456789abcdef\n' |
		sed 's/../&'"$sedlyLF"'/g' |
		grep . |
		tr '\n' ,
	echo
} |
awk '
BEGIN{
	for(i=0;i<256;i++)
		daHex2Oct[sprintf("%02x",i)]=\
			sprintf("%03o",i);
}
function myPrint(hexes){
	for(gsub(",","",hexes);hexes~/^../;hexes=substr(hexes,3)){
		system("printf \\\\"\
		       daHex2Oct[substr(hexes,1,2)]);
	}
}
{
	for(;;){
		if(match($0,/^(2[^f],|5[^c],|[^25].,)+/)){
			myPrint(substr($0,1,RLENGTH));
			$0=substr($0,RLENGTH+1);
			continue;
		}
		if(match($0,/^5c,..,/)){
			myPrint(substr($0,1+3,3));
			$0=substr($0,RLENGTH+1);
			continue;
		}
		if(match($0,\
			"^2f,"\
			"(2[^f],|5[^c],|[^25].,|5c,..,)*2f,"\
			"(2[^f],|5[^c],|[^25].,|5c,..,)*2f,")\
		){
			rEndAt=RLENGTH;
			match($0,"^2f,(2[^f],|5[^c],|[^25].,|5c,..,)*2f");
			pEndAt=RLENGTH;
			oneCharLen=3;
			rBeginAt=pEndAt+oneCharLen-1;
			pBeginAt=1+oneCharLen;
			s=substr($0,pBeginAt,pEndAt-pBeginAt-oneCharLen+2);
			d=substr($0,rBeginAt,rEndAt-rBeginAt-oneCharLen+1);

			programContinueFrom=rEndAt+1;
			$0=substr($0,programContinueFrom);

			# You know what, many impls of utils with ERE
			# might not support what looks like /(..)\1/ 
			for(;escPos=match(s,/5c,...,/);)
				s=substr(s,1,escPos-3) substr(s,escPos+3);
			for(;escPos=match(d,/5c,...,/);)
				d=substr(d,1,escPos-3) substr(d,escPos+3);

			# print s,d>"/dev/stderr";

			for(;$0~s;)
				sub(s,d);

			continue;
		}
		break;
	}
}'

# finally
exit 0
