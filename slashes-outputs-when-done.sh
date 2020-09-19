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
	esac
	break
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
	for(i=0;i<=255;i++)
		daHex2Oct[\
			sprintf("%02x",i)\
		]=sprintf("%03o",i);
}
function myPrint(\
	argStr,\
	localA,\
	localN,\
	localI\
){
	localN=split(argStr,localA,",")-1;
	for(localI=1;localI<=localN;localI++){
		print daHex2Oct[localA[localI]];
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
			sprintf("echo %s | sed \"s/5c,\\(..,\\)/\\1/g\"",s) | getline s;
			sprintf("echo %s | sed \"s/5c,\\(..,\\)/\\1/g\"",d) | getline d;

			# print s,d,$0>"/dev/stderr";

			for(;$0~s;)
				sub(s,d);

			continue;
		}
		break;
	}
}' | 
awk '
BEGIN{
	for(i=1;i<256;i++){
		hex=sprintf("%02x",i);
		fmt[hex]=sprintf("%c",i);
		fmtl[hex]=1;
	}

	fmt["25"]="%%";
		fmtl["25"]=2;
	fmt["5c"]="\\\\\\\\";
		fmtl["5c"]=4;
	fmt["00"]="\\\\000";
		fmtl["00"]=5;
	fmt["0a"]="\\\\n";
		fmtl["0a"]=3;
	fmt["0d"]="\\\\r";
		fmtl["0d"]=3;
	fmt["09"]="\\\\t";
		fmtl["09"]=3;
	fmt["0b"]="\\\\v";
		fmtl["0b"]=3;
	fmt["0c"]="\\\\f";
		fmtl["0c"]=3;
	fmt["20"]="\\\\040";
		fmtl["20"]=5;
	fmt["22"]="\\\"";
		fmtl["22"]=2;
	fmt["27"]="\\'"'"'";
		fmtl["27"]=2;
	fmt["2d"]="\\\\055";
		fmtl["2d"]=5;
	for(i=48;i<58;i++){
		fmt[sprintf("%02x",i)]=sprintf("\\\\%03o",i);
		fmtl[sprintf("%02x",i)]=5;
	}

	ORS="";
	LF=sprintf("\n");
	printfLen=7; # as "printf "
	maxlen=int('"$(getconf ARG_MAX)"'/2)-printfLen;
	arglen=0;
}
{
	# TBH I have no ideas why 4
	if(arglen+4>maxlen){
		print LF;
		arglen=0;
	}
	print fmt[$0];
	arglen+=fmtl[$0];
}
END{
	if(NR) print LF;
	else printf"\"\"\n";
}' |
xargs -n 1 printf

# finally
exit 0
