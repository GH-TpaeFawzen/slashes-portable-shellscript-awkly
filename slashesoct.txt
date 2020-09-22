#!/bin/sh
set -ue
umask 0022
export LC_ALL=C
export PATH="$(command -p getconf PATH 2>/dev/null)${PATH+:}${PATH-}"
case $PATH in :*) PATH=${PATH#?};; esac
export UNIX_STD=2003


case $# in
	0) : ;;
	*)
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
	case $# in
		0) : ;;
		*)
		case $1 in
			-) : ;;
			*) set -- "./$1" ;;
		esac
	esac
esac

sedlyLF="$(printf '\\\012_')"; sedlyLF="${sedlyLF%_}"
{
	od -A n -t o1 -v "${1:--}" |
		tr -Cd '01234567'
	echo
} |
awk '
BEGIN{
	debug="'"${debug:-NOPE}"'";
	what2print=pattern=replacement="";
}
function myPrint(str){
	print str;
}
function addstr(str){
	if(mode=0){
		what2print=what2print str;
		return;
	}
	if(mode=1){
		pattern=pattern str;
		return;
	}
	replace=replace str;
}
function action(){
	if(mode==2){
		while(pattern~$0)
			sub(pattern,replace);
		pattern=replace="";
		return;
	}
	if(!mode){
		myPrint(what2print);
		what2print="";
		return;
	}
}
{
	for(;;){
		# 057 for slash; 134 for backslash
		if(/^134$/)break;
		if(/^134.../){
			addstr(substr($0,4,3));
			$0=substr($0,7);
			continue;
		}
		if(/^057/){
			$0=substr($0,4);
			action();
			mode=(mode+1)%3;
			continue;
		}
		if(pos=match($0,"057|134")){
			addstr(substr($0,1,pos-3));
			$0=substr($0,pos+1);
			continue;
		}
		if(!mode)addstr($0);
		break;
	}
	if(!mode&&what2print!~/^$/)myPrint(what2print);
}
0{
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
}' |
sed s/.../\\\\&/g |
xargs -n 1 printf 2>/dev/null

# finally
exit 0
