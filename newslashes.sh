#!/bin/sh
: initial setup && {
set -u
umask 0022
export LC_ALL=C
export PATH="$(command -p getconf PATH 2>/dev/null)${PATH+:}${PATH-}"
case $PATH in (:*) PATH=${PATH#?};; esac
export UNIX_STD=2003
}

usage_exit(){
	cat <<-USAGE 1>&2
	Usage: ${0##*/} [ FILE ]
	Argument:
	- FILE. Must not begin with a hyphen.
	Stdin: Used only if FILE is not given or just a hyphen '-' is given to FILE.
	USAGE
	exit 2
}
tohex(){
	od -A n -t x1 -v |
	tr ABCDEF abcdef |
	tr -Cd 0123456789abcdef\\n
}

: these are for awk script && {
s="$(printf / | tohex)"
b="$(printf '\\' | tohex)"
}

case $# in
	(0) cat ;;
	(*)
	case "$1" in
		(-) cat ;;
		(-*) usage_exit ;;
		(*)
		cat "$1"
		case $? in
			(0) : ;;
			(*) exit $? ;;
		esac
	esac
esac |
tohex |
awk '{
	for(i=1;i<=length($0);i+=2){
		p=substr($0,i,2);
		if(p=="'"$s"'")printf"//";
		else if(p=="'"$b"'")printf"xx";
		else printf p;
	}
}' |
awk '
BEGIN{
	for(i=0;i<256;i++)
		hex2oct[sprintf("%02x",i)]=sprintf("%03o",i);
	hex2oct["//"]=hex2oct["'"$s"'"];
	hex2oct["xx"]=hex2oct["'"$b"'"];
	OFS="";
	print"\"\"";
}
{
	for(;;){
		if(/^xx../){
			print"\\\\",hex2oct[substr($0,3,2)];
			sub("^....","");
			continue;
		}
		if(match("^[^x/]+")){
			for(i=1;i<=RLENGTH;i+=2)
				print"\\\\",hex2oct[substr($0,i,2)];
			$0=substr($0,RLENGTH+1);
			continue;
		}
		if(match("^//([^/x].|xx..)*//")){
			rawp=substr($0,3,RLENGTH-4);
			$0=substr($0,RLENGTH+1);
			if(!match("^([^/x].|xx..)*//"))break;
			rawr=substr($0,1,RLENGTH-2);
			$0=substr($0,RLENGTH+1);
			"echo " rawp " | "\
			"sed s/xx\\(..\\)/\\1/g" |\
			getline p;
			"echo " rawr " | "\
			"sed s/xx\\(..\\)/\\1/g" |\
			getline r;
			for(;$0~p;sub(p,r))
				;
			continue;
		}
		break;
	}
}
' |
xargs -n 1 printf

: finally && {
exit 0
}