#!/bin/bash
#
# Provides:             covid
# Short-Description:    extracts data from csv to graphical export
# Description:          extracts data from csv to graphical export

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

################################  FUNCTION

# $1
! [ "$1" ] && _exite "you have to give a file"
! [ -f "$1" ] && _exite "unable to find file '$1'"
file_in="$1"
_echoD "file_in=$file_in"

# change CR to LF
sed -i 's/\r$//' "$file_in"
sed -i 's/"Bonaire, Saint Eustatius and Saba"/Bonaire_Saint_Eustatius_and_Saba/' "$file_in"
sed -i 's/United_States_of_America/USA/' "$file_in"
sed -i 's/United_Kingdom/UK/' "$file_in"
sed -i 's/Falkland_Islands_(Malvinas)/Falkland_Islands/' "$file_in"
sed -i 's/Falkland_Islands_(Malvinas)/Falkland_Islands/' "$file_in"
sed -i 's/Marshall_Islands Micronesia_(Federated_States_of)/Marshall_Islands/' "$file_in"

declare -A pops_spe
pops_spe=( ['Anguilla']=14731 ['Bonaire_Saint_Eustatius_and_Saba']=21000 ['Czechia']=10625695  ['Eritrea']=3546421 ['Falkland_Islands']=3198 ['Saint_Barthelemy']=9877 ['Western_Sahara']=594416 ['Wallis_and_Futuna']=13460 )

world=`cut -d',' -f5 < "$file_in" | sort -u`
world="${world/countriesAndTerritories/}"
world="${world/Cases_on_an_international_conveyance_Japan/}"

# Deaths > 50/10 000 000
declare -A groups
groups["World"]="${world}"
groups["Stars"]="Belgium Bosnia_and_Herzegovina Italy Slovenia"
groups["Stars2"]="Argentina Armenia Austria Belgium Bolivia Bosnia_and_Herzegovina Brazil Bulgaria Chile Colombia Croatia Czechia Ecuador France Georgia Hungary Iran Italy Kosovo Lithuania Mexico Moldova Netherlands North_Macedonia Panama Peru Poland Portugal Romania Slovenia Spain Sweden Switzerland UK USA"
groups["Africa"]="Algeria Angola Democratic_Republic_of_the_Congo Egypt Ethiopia Kenya Morocco Nigeria South_Africa Sudan"
groups["AfricaAll"]="Algeria Angola Benin Botswana Burkina_Faso Burundi Cameroon Cape_Verde Central_African_Republic Chad Comoros Congo Cote_dIvoire Democratic_Republic_of_the_Congo Djibouti Egypt Equatorial_Guinea Eritrea Eswatini Ethiopia Gabon Gambia Ghana Guinea Guinea_Bissau Kenya Lesotho Liberia Libya Madagascar Malawi Mali Mauritania Mauritius Morocco Mozambique Namibia Niger Nigeria Rwanda Sao_Tome_and_Principe Senegal Seychelles Sierra_Leone Somalia South_Africa South_Sudan Sudan Togo Tunisia Uganda United_Republic_of_Tanzania Western_Sahara Zambia Zimbabwe
"
groups["America"]="Argentina Bolivia Brazil Canada Chile Colombia Ecuador Mexico Peru USA"
groups["AmericaAll"]="Anguilla Antigua_and_Barbuda Argentina Aruba Bahamas Barbados Belize Bermuda Bolivia Bonaire_Saint_Eustatius_and_Saba Brazil British_Virgin_Islands Canada Cayman_Islands Chile Colombia Costa_Rica Cuba Curaçao Dominica Dominican_Republic Ecuador El_Salvador Falkland_Islands Greenland Grenada Guatemala Guyana Haiti Honduras Jamaica Mexico Montserrat Nicaragua Panama Paraguay Peru Puerto_Rico Saint_Kitts_and_Nevis Saint_Lucia Saint_Vincent_and_the_Grenadines Sint_Maarten Suriname Trinidad_and_Tobago Turks_and_Caicos_islands United_States_Virgin_Islands Uruguay USA Venezuela"
groups["Europe"]="Belgium France Germany Italy Poland Romania Russia Spain Turkey UK Ukraine"
groups["EuropeAll"]="Albania Andorra Armenia Austria Azerbaijan Belarus Belgium Bosnia_and_Herzegovina Bulgaria Croatia Cyprus Czechia Denmark Estonia Faroe_Islands Finland France Georgia Germany Gibraltar Greece Guernsey Holy_See Hungary Iceland Ireland Isle_of_Man Italy Jersey Kosovo Latvia Liechtenstein Lithuania Luxembourg Malta Moldova Monaco Montenegro Netherlands North_Macedonia Norway Poland Portugal Romania Russia San_Marino Serbia Slovakia Slovenia Spain Sweden Switzerland Turkey UK Ukraine"
groups["AsiaAll"]="Afghanistan Bahrain Bangladesh Bhutan Brunei_Darussalam Cambodia China India Indonesia Iran Iraq Israel Japan Jordan Kazakhstan Kuwait Kyrgyzstan Laos Lebanon Malaysia Maldives Mongolia Myanmar Nepal Oman Pakistan Palestine Philippines Qatar Saudi_Arabia Singapore South_Korea Sri_Lanka Syria Taiwan Tajikistan Thailand Timor_Leste United_Arab_Emirates Uzbekistan Vietnam Yemen"
groups["Asia"]="Bangladesh China India Indonesia Iran Iraq Japan Pakistan Philippines Saudi_Arabia"
groups["Oceania"]="Australia Fiji French_Polynesia Guam New_Caledonia New_Zealand Northern_Mariana_Islands Papua_New_Guinea Solomon_Islands Vanuatu Wallis_and_Futuna"

ddate="${file_in%.csv}"
ddate="${ddate##*worldwide-}"

path="${PWD}/${ddate}"
! [ -d "${path}" ] && mkdir "${path}"

for group in ${!groups[*]}; do

	_echoI "${group}"

	file_data_case_tmp="${path}/${ddate}_${group}_case_data.tmp"
	file_data_death_tmp="${path}/${ddate}_${group}_death_data.tmp"
	file_data_case="${path}/${ddate}_${group}_case_data.csv"
	file_data_death="${path}/${ddate}_${group}_death_data.csv"
	file_graph_case="${path}/${ddate}_${group}_case_graph.csv"
	file_graph_death="${path}/${ddate}_${group}_death_graph.csv"

	#~file_tmp="${PWD}/tmp"
	#echo > "$file_tmp"

	# count dates
	titles="date"
	pops="population"
	continents="continent"
	dates=
	dates_count=0
	for country in ${groups["$group"]}; do
		dates_count_tmp=`grep -c ",${country}," "$file_in"`
		if [ "$dates_count_tmp" -gt "$dates_count" ]; then
			dates_count="$dates_count_tmp"
			dates=`grep ",${country}," "$file_in"|cut -d',' -f1`
		fi
		titles="${titles},${country}"
		continents="${continents},$(grep ",${country}," "$file_in"|tail -n1|cut -d',' -f9|xargs)"
		if [[ " ${!pops_spe[*]} " = *" ${country} "* ]]; then
			pops="${pops},${pops_spe[$country]}"
		else
			pops="${pops},$(grep ",${country}," "$file_in"|tail -n1|cut -d',' -f8|xargs)"
		fi
	#	_echoD "dates_count|data_case|data_death=$dates_count|$data_case|$data_death"
	done

	_echoI "$dates_count"

	for file in "$file_data_case" "$file_data_death" "$file_graph_case" "$file_graph_death"; do
		echo "$continents" > "$file"
		echo "$pops" >> "$file"
		echo "$titles" >> "$file"
	done

	_echoD dates=$dates
	_echoD "dates_count=$dates_count"

	data_case="$dates"
	data_death="$dates"
	#data_count=
	for country in ${groups["$group"]}; do
		#data_case_tmp=`grep ",${country}," "$file_in"|cut -d',' -f5`
		#data_count="$data_count-$(wc -l <<<"$data_case_tmp")"
		data_case=`paste -d',' <(echo "$data_case") <(grep ",${country}," "$file_in"|cut -d',' -f3)`
		data_death=`paste -d',' <(echo "$data_death") <(grep ",${country}," "$file_in"|cut -d',' -f4)`
		#echo "--$country" >> "$file_tmp"
		#echo "$data_case" >> "$file_tmp"
	done
	#_echoD $data_count

	echo "$data_case" >> "$file_data_case"
	echo "$data_death" >> "$file_data_death"

	echo "$data_case" > "$file_data_case_tmp"
	echo "$data_death" > "$file_data_death_tmp"

	tac "$file_data_case_tmp" >> "$file_graph_case"
	tac "$file_data_death_tmp" >> "$file_graph_death"

	rm "$file_data_case_tmp" "$file_data_death_tmp"

	for file in "$file_data_case" "$file_data_death" "$file_graph_case" "$file_graph_death"; do
		sed -i 's|^\([0-9]/.*\)$|0\1|' "$file"
	done
	#sed -i "s|/2020,|,|" "$file_data_case"
	#sed -i "s|/2019,|,|" "$file_data_death"
done

_exit 0
