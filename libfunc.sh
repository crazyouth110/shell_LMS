
center(){
	tput cup $1 $(( ( wwidth - ${#2} ) /2 ))	#居中显示字符串
}

bc_echo(){
	if   [ $1 -eq 1 ] && [ $2 -eq -1 ];then
		echo -ne "\e[1m${3}\e[0m"	#只加粗
	elif [ $1 -eq 0 ] && [ $2 -ge 0 ];then
		echo -ne "\e[3${2}m${3}\e[0m"	#只变色
	elif [ $1 -eq 1 ] && [ $2 -ge 0 ];then
		echo -ne "\e[1;3${2}m${3}\e[0m"	#加粗且变色
	else
		echo $3 			 #不加粗不变色
	fi
}

error(){
	errornotice=${2}
	center $1 "$errornotice";bc_echo 0 $cred "$errornotice"		#报错
}

s21-cover(){	#封面显示
	tput clear
	top=5;		center $top "$sysname";		bc_echo 1 $cbrown "$sysname"
	let top+=2;	center $top "$sysversion";	bc_echo 0 -1 "$sysversion"
	let top+=3;	center $top "$sysauthor";	bc_echo 1 $cgreen "$sysauthor"
	let top+=2;	center $top "$sysdate";		bc_echo 0 -1 "$sysdate"
	notice="Press any key to continue: "
	center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
	read -n 1 -s key
}

s21-login(){	#登陆
	sure=n
	while [ "$sure" = "n" ];do
		tput clear
		top=4;	center $top "Log In";	bc_echo 1 $cbrown "Log In"
		let left=wwidth*3/10
		let top+=4;	tput cup $top $left;	bc_echo 0 -1 "Username : "
		let top+=2;	tput cup $top $left;	bc_echo 0 -1 "Password : "
		let left+=12
		let top=8;	tput cup $top $left;	read username
		let top+=2;	tput cup $top $left;	read -s password	#读取用户名和密码
		notice="Are you sure? Or press q to quit [y/n/q] "
		center $noticeheight "$notice";	bc_echo 0 $cmagenta "$notice"
		read sure
		while [[ "$sure" != [ynq] ]] ;do	#确保输入正确
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in
			q)	tput clear;return 0;;	#直接退出
			n)	continue;;		#不确定，重来一遍
			y)	egrep "^$username%" $pd > /tmp/tmp$$	#读取所对应的用户密码记录，确保了只有一条
				if [ -z /tmp/tmp$$ ];then		#读取为空，无帐号记录
					notice="There is no user with username of $username "
					tput cup $noticeheight 1;	tput ed
					error $noticeheight "$notice"
					notice="Press any key to try again "
					error $((noticeheight+2)) "$notice"
					read -s key
					continue
				fi
				fhashpass=$(awk -F "%" '{print $2}' /tmp/tmp$$)		#读取加密后的密码
				fsalt=$(awk -F "$" '{print $3}' /tmp/tmp$$ )		#读取盐
				hashpass=$(perl -e "print crypt('$password','\$6\$$fsalt\$')")	#重新生成加密的密码
				ftype=$(awk -F "%" '{print $3}' /tmp/tmp$$)
				flastlogtime=$(awk -F "%" '{print $4}' /tmp/tmp$$)
				rm -rf /tmp/tmp$$ &> /dev/null
				if [ "$hashpass" != "$fhashpass" ];then			#比较加密后的串是否相同，即验证密码正确性
					#echo -e "$password\n";echo "$fpassword"
					notice="Password error! Press any key to try again "
					tput cup $noticeheight 1;	tput ed
					error $noticeheight "$notice"
					read -s key
					continue
				fi
				tput cup 1 1;	tput ed
				notice="Welcome back ! $username "
				top=8
				center $top "$notice";	bc_echo 0 $cgreen "$notice"
				notice="Last log in : $flastlogtime"
				let top+=2
				center $top "$notice";	bc_echo 0 $cgreen "$notice"
				notice="Press any key to continue: "
				center $noticeheight "$notice";	bc_echo 0 $cmagenta "$notice"
				read -s key
				logtime=$(date '+%Y-%m-%d : %T' )
				sed -i "/^$username.*%[^%]*$/s/%[^%]*$/%$logtime/g" $pd		#写入登陆时间
				if [ "$ftype" = "admin" ];then		#根据账户类型返回相应的值，选择对应函数
					return 2
				elif [ "$ftype" = "user" ];then
					return 1
				else
					return 0
				fi;;
		esac
	done
}

s21-main-user(){		#普通用户主界面
	error=0
	while :;do
		tput clear
		top=2;	center $top "Main Menu";	bc_echo 1 $cbrown "Main Menu"
		let left=wwidth*4/10
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "1: Show books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "2: Find books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "3: Check out books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "4: Check in books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "5: Change password"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "q: Quit"
		notice="Please enter your choice [1-4 or q]: "
		if [ $error -eq 0 ];then
			center $noticeheight "$notice"; bc_echo 0 $ccyan "$notice"
                else
                        error "$noticeheight" "Wrong input! ""$notice"
                fi
                read choice
                case $choice in
                        1) showbooks ;  error=0;;
                        2) findbooks ;  error=0;;
                        3)  checkout ;  error=0;;
                        4)   checkin ;  error=0;;
			5)  changepd ;	error=0;;		#修改密码功能暂未写，什么时候乐意什么时候写
                        [qQ])   tput clear;exit 0;;
                        *)      error=1;;
                esac
        done
}

s21-main-admin(){		#管理员主页面
	error=0
	while :;do
		tput clear
		top=2;	center $top "Main Menu";	bc_echo 1 $cbrown "Main Menu"
		let left=wwidth*4/10
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "1: Show books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "2: Find books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "3: Add books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "4: Edit books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "5: Check out books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "6: Check in books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "7: Delect books"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "8: Add user"
		let top+=2;	tput cup $top $left;  bc_echo 1 -1 "q: Quit"
		notice="Please enter your choice [1-8 or q]: "
		if [ $error -eq 0 ];then
			center $noticeheight "$notice"; bc_echo 0 $ccyan "$notice"
                else
                        error "$noticeheight" "Wrong input! ""$notice"
                fi
                read choice
                case $choice in
                        1) showbooks ;  error=0;;
                        2) findbooks ;  error=0;;
                        3)  addbooks ;  error=0;;
                        4) editbooks ;  error=0;;
                        5)  checkout ;  error=0;;
                        6)   checkin ;  error=0;;
                        7)  delbooks ;  error=0;;
			8)   adduser ;  error=0;;
                        [qQ])   tput clear;exit 0;;
                        *)      error=1;;
                esac
        done
}

showbooks(){			#展示书籍信息
        error=0
        while :;do
                tput clear
		top=4;	center $top "Show books";  bc_echo 1 $cbrown "Show books"
                let left=wwidth*4/10
		let top+=2;	tput cup $top $left;       bc_echo 1 -1 "1: Sort by ID"
                let top+=2;	tput cup $top $left;       bc_echo 1 -1 "2: Sort by Title"
                let top+=2;	tput cup $top $left;       bc_echo 1 -1 "3: Sort by Author"
		let top+=2;	tput cup $top $left;       bc_echo 1 -1 "q: Return to main menu"
                notice="Please enter your choice [1-3 or q]: "
                if [ $error -eq 0 ];then
                        center $noticeheight "$notice"; bc_echo 0 $ccyan "$notice"
                else
                        error $noticeheight "Wrong input! ""$notice"
			error=0
                fi
                read choice
		case $choice in
                        1)      sortbooks 1;;
                        2)      sortbooks 2;;
                        3)      sortbooks 3;;
                        [qQ])   tput clear; return 0;;
                        *)      error=1;;
                esac
        done
}

sortbooks(){			#根据选择进行排序并写入临时文件
	case $1 in
		1) sort -t% -k 1 $db > /tmp/tmp$$;;
		2) sort -t% -k 2 $db > /tmp/tmp$$;;
		3) sort -t% -k 3 $db > /tmp/tmp$$;;
	esac
	bookinfo
	rm -rf /tmp/tmp$$ &>/dev/null
}

bookinfo(){			#打印书籍信息
	#if [] fi
	oldIFS="$IFS"		#暂存分隔符
	IFS="%"
	cat /tmp/tmp$$ | while read id title author tags state outname outtime ;do
		echo  "		     ID	: $id"
		echo  "		  Title	: $title"
		echo  "		 Author	: $author"
		echo  "		   Tags	: $tags"
		echo  "		  State	: $state"
		if [ "$state" = "out" ];then	
			echo  "	    Borrowed by : $outname"
			echo  "		   Date	: $outtime"
		fi
		echo
	done | less
	IFS="$oldIFS"
}

findbooks(){			#找书
        tput clear
	if [ ! -s "$db" ];then		#数据库为空
		notice="There is no book in the libiary!"
		center 5 "$notice"
		bc_echo 1 $cred "$notice"
		notice="Press any key to return: "
		center $noticeheight "$notice"
		bc_echo 0 $ccyan "$notice"
		read -s key
	fi
	sure=
	anymore=y
        while [ "$anymore" = "y" ] ;do
		tput clear
		top=4;	center $top "Find books";	bc_echo 1 $cbrown "Find books"
		left=$(( wwidth*2/10 ))
		let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "           ID: "
		let top+=2; 	tput cup $top $left;    bc_echo 0 $cmagenta "        Title: "
                let top+=2;     tput cup $top $left;    bc_echo 0 $cmagenta "       Author: "
		let top+=2;	tput cup $top $left;    bc_echo 0 $cmagenta "         Tags: "
                let top+=2;	tput cup $top $left;    bc_echo 0 $cmagenta "State(in/out): "
		let top+=2; 	tput cup $top $left;	bc_echo 0 $cmagenta "     Borrower: "
		let left+=15
		top=4
		let top+=2;	 tput cup $top $left;   read id
		let top+=2;	 tput cup $top $left;   read title
		let top+=2;	 tput cup $top $left;   read author
		let top+=2;	 tput cup $top $left;   read tags
		let top+=2;	 tput cup $top $left;   read state
		let top+=2;	 tput cup $top $left;	read outname
		notice="Are you sure ? [y/n/c]: "
		center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]];do
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in
			c)	tput clear;return 0;;
			n)	continue ;;
			y)	if [ ! $id ] && [ ! $title ] && [ ! $author ] && [ ! $tags ] && [ ! $state ] && [ ! $outname ];then
					notice="Your input is empty! Press any key to try again: "
					error $noticeheight "$notice"
					read -s key
					continue;
				fi 		#全部字段为空，再来一遍
				id=$(idtos21 $id)	#将id标准化
				if [ ! $id ];then	#判断id是否为空
					egrep "^s21-0*[0-9]*%[^%]*$title[^%]*%[^%]*$author[^%]*%[^%]*$tags[^%]*%[^%]*$state[^%]*%[^%]*$outname[^%]*%[^%]*" $db > /tmp/tmp$$
				else 
					egrep "^$id%[^%]*$title[^%]*%[^%]*$author[^%]*%[^%]*$tags[^%]*%[^%]*$state[^%]*%[^%]*$outname[^%]*%[^%]*" $db > /tmp/tmp$$
				fi
				bookinfo
				rm -rf /tmp/tmp$$ &> /dev/null;;
		esac
		notice="Anymore book to find ? [y/n]: "
		center $((noticeheight + 2))  "$notice";bc_echo 0 $ccyan "$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight+2)) 1
			tput ed
			error $((noticeheight+2)) "Wrong input! ""$notice"
			read  anymore
		done
	done
}

addbooks(){			#增加书籍
        tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ] ; do
		tput clear
		id=$( getnewnum $db )		#自动获得最大书籍号
		if [ "$id" == "big" ];then	#图书数量超过书籍号最大存储
			notice="There are too many books to add more! "
			error $noticeheight "$notice"
			notice="Press any key to return "
			error $((noticeheight+2)) "$notice"
			#let left=wwidth/2+${#notice}/2
			#tput cup $((noticeheight+2)) $left
			read -s key
			return 0;
		fi
		top=4
		center $top "Add books";	bc_echo 1 "$cbrown" "Add books"
		left=$(( wwidth*2/10 ))
		let top+=3;	tput cup $top $left;	bc_echo 0 $cmagenta "         ID: ";echo -n $id
		let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "     Title : "
		let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "    Author : "
		let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "      Tags : "
		let left+=13
		top=7;
		let top+=2;	tput cup $top $left;	read title
		let top+=2;	tput cup $top $left;	read author
		let top+=2;	tput cup $top $left;	read tags
		notice="Are you sure ? [y/n/c] : "
		center $noticeheight "$notice"; bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]];do
			tput cup $noticeheight 1
		        tput ed
		        error $noticeheight "Wrong input! ""$notice"
		        read sure
		done
		case $sure in
			c)	tput clear;return 0;;
			n)	continue;;
			y)	emptyflag=0		#判断某个字段是否为空
				empty="field with no input! "
				if [ ! "$tags" ];then 	empty="tags ""$empty"; 	emptyflag=1; fi
				if [ ! "$author" ];then empty="author ""$empty";emptyflag=1; fi
				if [ ! "$title" ];then 	empty="title ""$empty";	emptyflag=1; fi
				if [ "$emptyflag" = "1" ];then
					tput clear
					error $noticeheight "$empty"
					empty="Please try again. "
					error $((noticeheight+2)) "$empty"
					read -s key
					continue
				fi
				info="$id""%""$title""%""$author""%""$tags""%""in""%%"
				echo $info >> $db
		esac
		notice="Anymore book to add ? [y/n]: "
		center $((noticeheight + 2))  "$notice";bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight+2)) 1
			tput ed
			error $((noticeheight+2)) "Wrong input! ""$notice"
			read  anymore
		done
	done
}
idtos21(){
	id=$1
	if [ -z "$id" ];then		#id为空
		echo "$id"
		return 0
	fi
	echo $id>/tmp/tmp$$
	id=` sed 's/s21-//g' /tmp/tmp$$ `	#标准化为数字格式
	rm -rf /tmp/tmp$$ &> /dev/null
	len=${#id}
	let len=5-len
	for i in $(seq $len);do		#根据id长度增加对应个0
		id="0""$id"
	done
	id="s21-""$id"
	echo $id

}
getnewnum(){
	m=0
	if [ ! -s $db ];then		#判断数据库是否为空
		m=1
	else
		m=$( awk -F "%" 'END{print $1}' $db | awk -F "-" '{print $2}')
	fi
	m=$( echo "m=$m;m+1" | bc )	#仅bc可计算 0000x + y
	if [ $m -gt 99999 ];then	#数据库满了
		echo "big"
		return 0
	fi
	m=$(idtos21 $m)
	echo $m
}
editbooks(){				#编辑图书信息
        tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ];do
		tput clear
		top=4;	lines "Edit book" $top;	top=7
		left=$((wwidth*2/10))
		let left+=14
		tput cup $top $left
		read id
		id=$(idtos21 $id)
		tput clear
		top=4;	lines "Edit book" $top;	top=7
		tput cup $top $left
		echo -n $id				#将id标准化后重新输出
		checkbookex $id
		egrep "^$id" $db > /tmp/tmp$$
		title=$(awk -F "%" '{print $2}' /tmp/tmp$$ )
		author=$(awk -F "%" '{print $3}' /tmp/tmp$$ )
		tags=$(awk -F "%" '{print $4}' /tmp/tmp$$ )
		state=$(awk -F "%" '{print $5}' /tmp/tmp$$ )
		outname=$(awk -F "%" '{print $6}' /tmp/tmp$$ )
		outtime=$(awk -F "%" '{print $7}' /tmp/tmp$$ )		#从数据库中读取记录信息
		rm -rf /tmp/tmp$$ &> /dev/null
		let top+=2;	tput cup $top $left;	echo -n $title;		bc_echo 0 $cblue " ==> "
		let top+=2;	tput cup $top $left;	echo -n $author;	bc_echo 0 $cblue " ==> "
		let top+=2;	tput cup $top $left;	echo -n $tags;		bc_echo 0 $cblue " ==> "
		let top+=2;	tput cup $top $left;	echo -n $state;		bc_echo 0 $cblue " ==> "
		let top+=2;	tput cup $top $left;	echo -n $outname;	bc_echo 0 $cblue " ==> "
		let top+=2;	tput cup $top $left;	echo -n $outtime;	bc_echo 0 $cblue " ==> "
		top=9;		tput cup $top $((left+${#title}+5));	read newtitle
		let top+=2;	tput cup $top $((left+${#author}+4));	read newauthor
		let top+=2;	tput cup $top $((left+${#tags}+4));	read newtags
		let top+=2;	tput cup $top $((left+${#state}+4));	read newstate
		let top+=2;	tput cup $top $((left+${#outname}+4));	read newoutname
		let top+=2;	tput cup $top $((left+${#outtime}+4));	read newouttime
		notice="Are you sure? [y/n/c] : "
		center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]] ;do
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in 
			c)	tput clear;return 0;;
			n)	continue;;
			y)	if [ "$newtitle" ];	then title="$newtitle";fi
				if [ "$newauthor" ];	then author="$newauthor";fi
				if [ "$newtags" ];	then tags="$newtags";fi
				if [ "$newstate" ];	then state="$newstate";fi
				if [ "$newoutname" ];	then outname="$newoutname";fi
				if [ "$newouttime" ];	then outtime="$newouttime";fi		#如果字段值有变化，则赋新值
				top=7
				let top+=2;	tput cup $top $left;tput el;	echo "$title"
				let top+=2;	tput cup $top $left;tput el;	echo "$author"
				let top+=2;	tput cup $top $left;tput el;	echo "$tags"
				let top+=2;	tput cup $top $left;tput el;	echo "$state"
				let top+=2;	tput cup $top $left;tput el;	echo "$outname"
				let top+=2;	tput cup $top $left;tput el;	echo "$outtime"
				info="$id%$title%$author%$tags%$state%$outname%$outtime"
				sed -i "/^$id/s/.*/$info/g" $db				#写入数据库
		esac
		tput cup $((noticeheight+2)) 1
		tput ed
		notice="Anymore book to edit? [y/n]: "
		center $((noticeheight + 2)) "Success! ""$notice";	bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight + 2)) 1
			tput ed
			error $((noticeheight + 2)) "Wrong input! ""$notice"
			read anymore
		done

	done

}
checkin(){		#还书
        tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ];do
		tput clear
		top=4;	lines "Check in book" $top;	top=7
		left=$((wwidth*2/10))
		let left+=14
		tput cup $top $left
		read id
		id=$(idtos21 $id)
		tput clear
		top=4;	lines "Check in book" $top;	top=7
		tput cup $top $left
		echo -n $id
		checkbookex $id
		egrep "^$id" $db > /tmp/tmp$$
		title=$(awk -F "%" '{print $2}' /tmp/tmp$$ )
		author=$(awk -F "%" '{print $3}' /tmp/tmp$$ )
		tags=$(awk -F "%" '{print $4}' /tmp/tmp$$ )
		state=$(awk -F "%" '{print $5}' /tmp/tmp$$ )
		outname=$(awk -F "%" '{print $6}' /tmp/tmp$$ )
		outtime=$(awk -F "%" '{print $7}' /tmp/tmp$$ )
		rm -rf /tmp/tmp$$ &> /dev/null
		let top+=2;	tput cup $top $left;	echo -n $title
		let top+=2;	tput cup $top $left;	echo -n $author
		let top+=2;	tput cup $top $left;	echo -n $tags
		let top+=2;	tput cup $top $left;	echo -n $state
		let top+=2;	tput cup $top $left;	echo -n $outname
		let top+=2;	tput cup $top $left;	echo -n $outtime
		notice="Are you sure? [y/n/c] : "
		center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]] ;do
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in 
			c)	tput clear;return 0;;
			n)	continue;;
			y)	if [ "$state" == "in" ];then			#如果书状态值为in，则报错
					notice="Failed ! The book has been checked in"
					tput cup $((noticeheight + 2)) 1
					tput ed
					error $((noticeheight + 2)) "$notice"
					read -s key
					continue
				fi
				state="in"
				outtime=""
				top=13
				let top+=2;	tput cup $top $left;tput el;	bc_echo 0 $cblue "$state"
				let top+=2;	tput cup $top $left;tput el;
				let top+=2;	tput cup $top $left;tput el;
				info="$id%$title%$author%$tags%$state%$outname%$outtime"
				sed -i "/^$id/s/.*/$info/g" $db		#写入
		esac
		tput cup $((noticeheight+2)) 1
		tput ed
		notice="Anymore book to check in? [y/n]: "
		center $((noticeheight + 2)) "Success! ""$notice";	bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight + 2)) 1
			tput ed
			error $((noticeheight + 2)) "Wrong input! ""$notice"
			read anymore
		done

	done
}
checkout(){		#借书
        tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ];do
		tput clear
		top=4;	lines "Check out book" $top;	top=7
		left=$((wwidth*2/10))
		let left+=14
		tput cup $top $left
		read id
		id=$(idtos21 $id)
		tput clear
		top=4;	lines "Check out book" $top;	top=7
		tput cup $top $left
		echo -n $id
		checkbookex $id
		egrep "^$id" $db > /tmp/tmp$$
		title=$(awk -F "%" '{print $2}' /tmp/tmp$$ )
		author=$(awk -F "%" '{print $3}' /tmp/tmp$$ )
		tags=$(awk -F "%" '{print $4}' /tmp/tmp$$ )
		state=$(awk -F "%" '{print $5}' /tmp/tmp$$ )
		outname=$(awk -F "%" '{print $6}' /tmp/tmp$$ )
		outtime=$(awk -F "%" '{print $7}' /tmp/tmp$$ )
		rm -rf /tmp/tmp$$ &> /dev/null
		let top+=2;	tput cup $top $left;	echo -n $title
		let top+=2;	tput cup $top $left;	echo -n $author
		let top+=2;	tput cup $top $left;	echo -n $tags
		let top+=2;	tput cup $top $left;	echo -n $state
		let top+=2;	tput cup $top $left;	echo -n $outname
		let top+=2;	tput cup $top $left;	echo -n $outtime
		notice="Are you sure? [y/n/c] : "
		center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]] ;do
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in 
			c)	tput clear;return 0;;
			n)	continue;;
			y)	if [ "$state" == "out" ];then
					notice="Failed ! The book has been checked out"
					tput cup $((noticeheight + 2)) 1
					tput ed
					error $((noticeheight + 2)) "$notice"
					read -s key
					continue
				fi
				notice="Please input your name "
				tput cup $((noticeheight+2)) 1
				tput ed
				center $((noticeheight+2)) "$notice";	bc_echo 0 $ccyan "$notice"
				let top-=2
				tput cup $top $left
				read outname
				state="out"
				outtime=$(date '+%Y-%m-%d : %T' )
				top=13
				let top+=2;	tput cup $top $left;tput el;	bc_echo 0 $cblue "$state"
				let top+=2;	tput cup $top $left;tput el;	bc_echo 0 $cblue "$outname"
				let top+=2;	tput cup $top $left;tput el;	bc_echo 0 $cblue "$outtime"
				info="$id%$title%$author%$tags%$state%$outname%$outtime"
				sed -i "/^$id/s/.*/$info/g" $db
		esac
		tput cup $((noticeheight+2)) 1
		tput ed
		notice="Anymore book to check out? [y/n]: "
		center $((noticeheight + 2)) "Success! ""$notice";	bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight + 2)) 1
			tput ed
			error $((noticeheight + 2)) "Wrong input! ""$notice"
			read anymore
		done
	done
}	

checkbookex(){		#检查书号是否存在
	id=$1
	if ! grep -q "$id" $db ;then 		#grep -q，静默模式
		notice="There is no book with such id of $id"
		error $noticeheight "$notice"
		notice="Please try again."
		error $((noticeheight+2)) "$notice"
		read -s key
		continue
	fi

}

lines(){		#页面显示部分
	h=$1
	local top=$2
	center $top "$h";	bc_echo 1 $cbrown "$h"
 	local left=$((wwidth*2/10))
	let top+=3;	tput cup $top $left;	bc_echo 0 $cmagenta "        ID : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "     Title : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "    Author : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "      Tags : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "    in/out : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "  Borrower : "
	let top+=2;	tput cup $top $left;	bc_echo 0 $cmagenta "   outTime : "
}

delbooks(){			#删除书籍
        tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ];do
		tput clear
		top=4;	lines "Delete book" $top;	top=7
		left=$((wwidth*2/10))
		let left+=14
		tput cup $top $left
		read id
		id=$(idtos21 $id)
		tput clear
		top=4;	lines "Delete book" $top;	top=7
		tput cup $top $left
		echo -n $id
		checkbookex $id
		egrep "^$id" $db > /tmp/tmp$$
		title=$(awk -F "%" '{print $2}' /tmp/tmp$$ )
		author=$(awk -F "%" '{print $3}' /tmp/tmp$$ )
		tags=$(awk -F "%" '{print $4}' /tmp/tmp$$ )
		state=$(awk -F "%" '{print $5}' /tmp/tmp$$ )
		outname=$(awk -F "%" '{print $6}' /tmp/tmp$$ )
		outtime=$(awk -F "%" '{print $7}' /tmp/tmp$$ )
		rm -rf /tmp/tmp$$ &> /dev/null
		let top+=2;	tput cup $top $left;	echo -n $title
		let top+=2;	tput cup $top $left;	echo -n $author
		let top+=2;	tput cup $top $left;	echo -n $tags
		let top+=2;	tput cup $top $left;	echo -n $state
		let top+=2;	tput cup $top $left;	echo -n $outname
		let top+=2;	tput cup $top $left;	echo -n $outtime
		notice="Are you sure ? [y/n/c]: "
		center $noticeheight "$notice";	bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]];do
			tput cup $noticeheight 1
			tput ed
			error $noticeheight "Wrong input! ""$notice"
			read sure
		done
		case $sure in 
			c)	tput clear;return 0;;
			n)	continue;;
			y)	top=7;		tput cup $top $left;tput el;		#清除书籍信息的显示
				let top+=2;	tput cup $top $left;tput el;
				let top+=2;	tput cup $top $left;tput el;
				let top+=2;	tput cup $top $left;tput el;
				let top+=2;	tput cup $top $left;tput el;
				let top+=2;	tput cup $top $left;tput el;
				sed -i "/^$id/d" $db
		esac
		tput cup $((noticeheight+2)) 1
		tput ed
		notice="Anymore book to delete? [y/n]: "
		center $((noticeheight + 2)) "Success! ""$notice";	bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight + 2)) 1
			tput ed
			error $((noticeheight + 2)) "Wrong input! ""$notice"
			read anymore
		done
	done

}

adduser(){		#增加用户
	tput clear
        sure=
	anymore=y
	while [ "$anymore" = "y" ] ; do
		tput clear
		top=4
		center $top "Add user";	bc_echo 1 "$cbrown" "Add user"
		left=$(( wwidth*3/10 ))
		let top+=4;	tput cup $top $left;	bc_echo 0 -1 "Username : "
		let top+=2;	tput cup $top $left;	bc_echo 0 -1 "Password : "
		top=4
		let left+=12
		let top+=4;	tput cup $top $left;	read username
		let top+=2;	tput cup $top $left;	read password
		notice="Would you like to set him/her as an administrator ? [y/n] :"
		let top+=4
		center $top "$notice";	bc_echo 0 -1 "$notice"
		left=$((wwidth/2+${#notice}/2+2))
		tput cup $top $left
		read utype
		while [[ "$utype" != [yn] ]];do
			tput cup $top 1;	tput ed
			error $top "Wrong input! ""$notice"
			read utype
		done
		if [ "$utype" = "y" ];then utype="admin" ;	#是否设置为管理员
		else utype="user" ;fi
		notice="Are you sure ? [y/n/c] : "
		center $noticeheight "$notice"; bc_echo 0 $ccyan "$notice"
		read sure
		while [[ "$sure" != [ync] ]];do
			tput cup $noticeheight 1
		        tput ed
		        error $noticeheight "Wrong input! ""$notice"
		        read sure
		done
		case $sure in
			c)	tput clear;return 0;;
			n)	continue;;
			y)	if egrep -q "^$username%" $pd ;then 		#用户名已被使用
					notice="Failed! The username is already been used "
					tput cup $noticeheight 1;	tput ed
					error $noticeheight "$notice"
					notice="Press any key to try again : "
					error $((noticeheight+2)) "$notice"
					read -s key
					continue
				fi
				salt=$(openssl rand -base64 8)		#产生8为随机串，作为盐
				salt=${salt:1:8}
				hashpass=$(perl -e "print crypt('$password','\$6\$$salt\$')"  )		#加密
				info="$username""%""$hashpass""%""$utype""%"
				echo "$info" >> $pd		#写入
		esac
		notice="Anymore user to add ? [y/n]: "
		center $((noticeheight + 2))  "$notice";bc_echo 0 $ccyan "Success! ""$notice"
		read anymore
		while [[ "$anymore" != [yn] ]];do
			tput cup $((noticeheight+2)) 1
			tput ed
			error $((noticeheight+2)) "Wrong input! ""$notice"
			read  anymore
		done
	done

}


