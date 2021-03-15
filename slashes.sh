#!/bin/sh
set -ue
umask 0022
export LC_ALL=C
export PATH="$(command -p getconf PATH 2>/dev/null)${PATH+:}${PATH-}"
case $PATH in :*) PATH=${PATH#?};; esac
export UNIX_STD=2003

while :; do
	case $# in 0) break; esac
	case $1 in
		'-d')
			debug=1
			shift
			;;
		'-d'[12])
			debug=${1#-d}
			shift
			;;
		*)
			break
			;;
	esac
done

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
	debug="'"${debug:-NOPE}"'";
	for(i=1;i<=255;i++)
		daHex2Char[\
			sprintf("%02x",i)\
		]=sprintf("%c",i);
}
function myPrint(\
	argStr,\
	localA,\
	localN,\
	localI\
){
	localN=split(argStr,localA,",")-1;
	ORS="";
	for(localI=1;localI<=localN;localI++){
		if(localA[localI]in daHex2Char)
			print daHex2Char[localA[localI]];
		else
			system("printf \\\\000");
	}
}
{
	for(;;){
		if(debug~1)
			printf"\n[%s]\n",$0 >"/dev/stderr";
		if(match($0,"^(2[^f],|5[^c],|[^25].,)+")){
			# printf substr($0,1,RLENGTH);
			myPrint(substr($0,1,RLENGTH));
			$0=substr($0,RLENGTH+1);
			if(debug~2)
				printf"\n[%s]\n",$0 >"/dev/stderr";
			continue;
		}
		if(/^5c,..,/){
			# printf substr($0,1+3,3);
			myPrint(substr($0,1+3,3));
			$0=substr($0,6+1);
			if(debug~2)
				printf"\n[%s]\n",$0 >"/dev/stderr";
			continue;
		}
		if(match($0,\
			"^2f,"\
			"(2[^f],|5[^c],|[^25].,|5c,..,)*2f,"\
			"(2[^f],|5[^c],|[^25].,|5c,..,)*2f,")\
		){
			oneCharLen=3;
			patternFirst=1+oneCharLen;
			replaceLast=RLENGTH-oneCharLen;
			match($0,"^2f,(2[^f],|5[^c],|[^25].,|5c,..,)*2f,");
			patternLast=RLENGTH-oneCharLen;
			replaceFirst=RLENGTH+1;
			s=substr($0,patternFirst,patternLast-patternFirst+1);
			d=substr($0,replaceFirst,replaceLast-replaceFirst+1);
			$0=substr($0,replaceLast+oneCharLen+1);

			# You know what, many impls of utils with ERE
			# might not support what looks like /(..)\1/ 
			# SO LET THE SED DO SOMETHING WITH IT!
			template="echo %s | sed \"s/5c,\\(..,\\)/\\1/g\"";
			sprintf(template,s) | getline s;
			sprintf(template,d) | getline d;

			# print s,d,$0>"/dev/stderr";

			for(;$0~s;)
				sub(s,d);

			continue;
		}
		break;
	}
}' 

# finally
exit 0
