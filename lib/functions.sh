#!/bin/bash
function initialize_colors() {
	normal_color="\e[1;0m"
	green_color="\033[1;32m"
	blue_color="\033[1;34m"
	cyan_color="\033[1;36m"
	brown_color="\033[0;33m"
	yellow_color="\033[1;33m"
	pink_color="\033[1;35m"
	white_color="\e[1;97m"
	clear_screen="\033c"
  ### Regular Colors

  G='\033[0;32m' #Green Color Title
  R='\033[1;31m' #Red Color
  W='\033[0;37m' # White Color
  B='\033[0;34m' # Blue Color
  C='\033[0;36m' # Cyan Color
  M='\033[0;35m' # Purple
  LG='\033[0;37m'
  O='\033[0;33m'
  Y='\033[1;33m'  # Yellow
  RESET='\033[0m'

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# colors to use with read cmd
read_normal_color=$'\e[1;0m'
read_green_color=$'\033[1;32m'
read_blue_color=$'\033[1;34m'
read_cyan_color=$'\033[1;36m'
read_brown_color=$'\033[0;33m'

}

#Pass colors to our terminal banner
function hearts_pirates(){
	case $1 in
		1)banner_color=${R}

		 ;;
		2) banner_color=${G}

		;;
		3) banner_color=${BBlue}

		;;
		4) banner_color=${brown_color}

		;;
		5) banner_color=${W}

		;;

	esac
	banner

sleep 0.4
}


banner(){
	echo -e ${banner_color}"                                 ;okO0KKKKKK0Oko;   "${RESET}
	echo -e ${banner_color}"                                .oolc;,dMMd,;cloo.  "${RESET}
	echo -e ${banner_color}"                         .lx.      .:lxXMMXxl:.      .oc.   "${RESET}
	echo -e ${banner_color}"                        oWWo   .l0WMWK0OkkO0KWMW0l.   dWWo   "${RESET}
	echo -e ${banner_color}"                      ,XMk. .oXMXd:.          .,oKMXo. .xMK.  "${RESET}
	echo -e ${banner_color}"                     lWMX''dWWk,...            ...'kWWk:;XMW:  "${RESET}
	echo -e ${banner_color}"                    dMWONMMMK,lKMMMW0:      ,0WMMMKo;KMMMNOWMc  "${RESET}
	echo -e ${banner_color}"                   :MW, :MM0.KMMMMMMMMO    oMMMMMMMMN,0MM: :MW'  "${RESET}
	echo -e ${banner_color}"                   XMl  OMX.;MMMMMMMMMW.   WMMMMMMMMM: KMK  xMx   "${RESET}
	echo -e ${banner_color}"                   ll  .MMl  OMMMMMMMWc    lWMMMMMMMO  ;MM'  l;  "${RESET}
	echo -e ${banner_color}"                      :MM,   ,kXNNKd.  ,,  .dKNNXk,    XM:    "${RESET}
	echo -e ${banner_color}"                       :MMc            .00.             KM:   "${RESET}
	echo -e ${banner_color}"                   dk. .MMMWXK000OOOOOOOO00000KKKKXXXNWMMM' .Oo   "${RESET}
	echo -e ${banner_color}"                  OMO  OMN'.xMk,,lM0,,;NN;,,0M0,,kMx..XM0  KMd    "${RESET}
	echo -e ${banner_color}"                   .WMo oMM0.lMl  .Mx   XX   kMx  lMl OMMl xMX. "${RESET}
	echo -e ${banner_color}"                    ,WMWMMMMKOMl  .Mx   XX   OMk  lMOKMMMMWMN.  "${RESET}
	echo -e ${banner_color}"                     .XMN'.lNMMO  'Mk   XX   0MO  kMMNl.'WMK.  "${RESET}
	echo -e ${banner_color}"                       dMX:  lKMNxOM0   XX   KMXdXMKc  cNWd   "${RESET}
	echo -e ${banner_color}"                        '0M0.  .ckNMMK00WW0KKWMNOc.  .0M0'    "${RESET}
	echo -e ${banner_color}"                          .,       .,coKMMKoc,.       ,.    "${RESET}
	echo -e ${banner_color}"                                .OOkdocxMMxcodxkx.    "${RESET}
	echo -e ${banner_color}"                                 .;ldkO000OOkdl;.  "${RESET}
}


#Provide Animation for the banner
animate_banner(){

	#echo -e "\033[6B"

	for i in $(seq 1 3); do
		echo -e ${clear_screen}

		if [ "$i" -le 3 ]; then
			color_index=${i}
		else
			color_index=$(( i-4 ))
		fi
		hearts_pirates "$color_index"
	done

}
check_yes_no(){
  # Input validation.
if [[ $# -ne 1 ]]; then
echo "Need exactly one argument, exiting."
exit 1 # No validation done, exit script.
fi
  local question=$1
  while true; do
  read -p "$question " answer #Pass the Question To ask the user
  case ${answer,,} in
    n | no )
    return 1
    break
    ;;
    y | yes )
    return 0
    break
    ;;
    *) echo "Please Answer Yes or No"
      echo
    ;;
  esac
done
}

confirmPass(){
	PASS=$1
	CONFIRM_PASS=$2
	while true; do

		if [[  ${PASS} != ${CONFIRM_PASS} ]];then
			return 1
		else
			return 0
		fi
	done
}

usage(){
	echo -e "
	Usage: ${O}./$1 [-i  ] | [ -h ] | [-O ] ${RESET}


	OPTIONS:
	========
	    -i    Start Installation Process
	    -h    Help Function
	    -O    Optimize Installation [optional], should be done after ${BGreen}INSTALLATION is Complete${normal_color}

	EXAMPLE:
	=========
		${O}./$1 -h
${RESET}
	"
}
mysql_import_function(){
  path=$1
  dbname=$4
  db_username=$2
  user_pass=$3
  pv zcat $1 | pv --progress --size `gzip -l %s | sed -n 2p | awk '{print $2}'` --name '  Importing Database.. ' | mysql -u$db_username -p$user_pass $dbname
}
