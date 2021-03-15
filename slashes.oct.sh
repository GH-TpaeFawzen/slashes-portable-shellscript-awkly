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

{
	od -A n -t o1 -v "${1:--}" |
		tr -Cd '01234567'
	echo
} |
awk '
BEGIN{
	debug="'"${debug:-NOPE}"'";
	what2print=pattern=replace="";
}
function myPrint(str){
	print str;
	printed=1;
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
	if(!printed)printf"\"\"\n";
}' |
sed /\"/!s/.../\\\\&/g |
xargs -n 1 printf

# finally
exit 0
