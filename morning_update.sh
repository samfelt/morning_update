#!/usr/bin/env bash

#------------[ Sources ]-------------------------------------------------------
SOURCE_DIR=$(dirname $(readlink $BASH_SOURCE))
SOURCES=( colors.sh \
          banners.sh )

for f in ${SOURCES[@]}; do
    ff=$SOURCE_DIR/$f
    [ -f $ff ] && . $ff
done

#------------[ True/False ]----------------------------------------------------

TRUE=1
FALSE=0

#------------[ File Paths ]----------------------------------------------------

STDOUT="/dev/stdout"
LOG_FOLDER="${HOME}/.morning_update"
LOG_FILE="${LOG_FOLDER}/morning_update_$(date +"%Y_%m_%d").log"

#------------[ Line Break ]----------------------------------------------------
function line_break()
{
    if [ ! -z "$1" ]; then 
        printf "%$(tput cols)s\\n" | tr ' ' "$1"
    else
        printf "%$(tput cols)s\\n" | tr ' ' -
    fi
}

#------------[ Usage ]---------------------------------------------------------
function usage()
{
    echo "Usage: morning_update.sh [OPTIONS] [UPDATES]"
    echo 
    echo "OPTIONS:"
    echo "  --all       update all available programs"
    echo "  --banner    Print ascii art banners"
    echo "  --verbose   print to stdout instead of log"
    echo "  --help      print this help"
    echo
    echo "AVAILABLE UPDATES:"
    echo "  (none)      update all available programs"
    for prog in $available_programs; do
        echo "  --$prog"
    done
    echo
    exit
}


#------------[ Run Update Command ]--------------------------------------------
function run_command()
{
# $1 - Command to be run
# $2 - Screen output

echo        >> "$OUTPUT"
line_break  >> "$OUTPUT"
echo "$2"   >> "$OUTPUT"
line_break  >> "$OUTPUT"

if (( "$VERBOSE_FLAG" == "$FALSE" )); then
    echo -n "    [ ] $2"
fi

#command_output=$(eval "$1" &>> "$OUTPUT")
#command_output=$(eval "$1" 2>&1 | tee -a "$OUTPUT")
command_output="$(eval $1 2>&1)"
echo "$command_output" >> "$OUTPUT"

retval=$?
if (( "$VERBOSE_FLAG" == $TRUE )); then
    if (( $retval != 0 )); then
        echo "ERROR: '$1' exited with a code of $retval"
    fi
else
    if (( $retval != 0 )); then
        echo -e "\r    ${Red}[X] $2${NC}"
        echo "    ERROR: '$1' exited with a code of $retval"
    else
        echo -e "\r    ${BGreen}[*]${NC} $2"
    fi
fi

}

#------------[ Test Method ]---------------------------------------------------
# Running a test, uncomment this function and run with '--test'
#function update_test()
#{
#
#}

#------------[ Update Brew ]---------------------------------------------------
function update_brew()
{
    if [ ! "$(command -v brew)" ]; then return; fi
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        brew_banner
    else
        echo -e "${BBlue}[I]${NC} ${White}Brew, starting update${NC}"
    fi

    run_command 'brew update'   'Updating Brew'
    command_output=""
    run_command 'brew outdated' 'Determining outdated packages:'
    if [ -z "$command_output" ]; then
        echo -e "    ${Blue}[i]${NC} No outdated packages"
    else
        echo -en "    ${Blue}[i]${NC} "
        for package in $command_output; do
            echo -en "${White}$package${NC} "
        done
        echo
        for package in $command_output; do
            run_command "brew upgrade $package" "Upgrading $package"
        done
    fi
    run_command 'brew outdated --cask' 'Determining outdated cask packages:'
#    command_output="$command_output" | tr "\n" " "
    if [ -z "$command_output" ]; then
        echo -e "    ${Blue}[i]${NC} No outdated cask packages"
    else
        echo -en "    ${Blue}[i]${NC} "
        for package in $command_output; do
            echo -en "${White}${package}${NC} "
        done
        echo
        for package in $command_output; do
            run_command "brew cask upgrade $package" "Upgrading $package"
        done
    fi
    run_command 'brew doctor' 'Brew Doctor'
}

#------------[ Update MacOS ]--------------------------------------------------
function update_macos()
{
    UPDATER="softwareupdate"
    if [ ! "$(command -v $UPDATER)" ]; then return; fi
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        macos_banner
    else
        echo -e "${BBlue}[I]${NC} ${White}MacOS, starting update${NC}"
    fi
#    echo -e "    ${Red}[I]${NC} MacOS update coming soon"
#    "$UPDATER" --list
    run_command "$UPDATER --list" "Finding available updates (This can take a while)"
    echo -e "    ${Blue}[i]${NC} $command_output"

}


#------------[ Update Pip2 ]---------------------------------------------------
function update_pip2()
{
    PIP="pip2"
    if [ ! "$(command -v $PIP)" ]; then return; fi
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        pip2_banner
    else
        echo -e "${BBlue}[I]${NC} ${White}pip2, ${Red}python2 has been deprecated${NC}"
    fi

    command_output=""
    run_command "$PIP list --outdated 2> /dev/null | tail -n+3 | awk '{print \$1}'" "Determining pip2 outdated packages"

    if [ -z "$command_output" ]; then
        echo -e "    ${Blue}[i]${NC} No outdated packages found"
    else
        echo -en "    ${Blue}[i]${NC} "
        for package in $command_output; do
            echo -en "${White}$package${NC} "
        done
        echo
        for package in $command_output; do
            run_command "$PIP install --upgrade $package 2> /dev/null" "Upgrading $package"
        done
    fi
}

#------------[ Update Pip3 ]----------------------------------------------------
function update_pip3()
{
    PIP="pip3"
    if [ ! "$(command -v $PIP)" ]; then return; fi
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        pip3_banner
    else
        echo -e "${BBlue}[I]${NC} ${White}pip3, starting update${NC}"
    fi

    command_output=""
    run_command "$PIP list --outdated 2> /dev/null | tail -n+3 | awk '{print \$1}'" "Determining pip3 outdated packages"

    if [ -z "$command_output" ]; then
        echo -e "    ${Blue}[i]${NC} No outdated packages found"
    else
        echo -en "    ${Blue}[i]${NC} "
        for package in $command_output; do
            echo -en "${White}$package${NC} "
        done
        echo
        for package in $command_output; do
            run_command "$PIP install --upgrade $package" "Upgrading $package"
        done
    fi

}

#------------[ Vim Plugins ]---------------------------------------------------
function update_vim-plugins()
{

    #Assuming using pathogen and all plugins are contained in ~/.vim/bundle
    plugins_dir=~/.vim/bundle
    
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        vim_plugins_banner
    else
        echo -e "${BBlue}[I]${NC} ${White}Vim Plugins, staring updates${NC}"
    fi

    #Find plugins that are git repos
    for dir in $(find $plugins_dir -depth 1 -type d); do
        if [ -d "$dir/.git" ]; then
            run_command "git -C $dir pull" "$(basename $dir)"
        fi
    done
}

#------------[ Upgrade Apt ]---------------------------------------------------
function update_apt()
{
    if [ ! "$(command -v apt-get)" ]; then return; fi
    if (( "$VERBOSE_FLAG" == $TRUE || "$BANNER_FLAG" == $TRUE )); then
        apt_banner
    fi
    commands=( update
               upgrade
               dist-upgrade
               autoremove
               autoclean
               clean )

    for c in "${commands[@]}"; do
        run_command "sudo apt-get -y $c" "apt $c"
    done

}

function print_up_table()
{
    for prog in ${available_programs[@]}; do
        echo "$prog": ${update_table[$prog]}
    done
}

#------------[ Main ]---------------------------------------------------------
#if (($(date | cut -d" " -f4 | cut -d":" -f1) > 11)); then
#    echo This update is only meant for the morning!!
#    exit
#fi

# Get list of functions starting with 'update_' to build list of updates
available_programs=$(declare -F | grep 'update_' | sed -n -e 's/^.*update_//p')

# Create Update table to keep track of which updates we are going to run
declare -A update_table
for prog in $available_programs; do
    update_table["$prog"]=$FALSE
done

if [ $# -eq 0 ]; then
    for prog in ${available_programs[@]}; do
        update_table["$prog"]=$TRUE
    done
fi

# Set Flags to default value
BANNER_FLAG=$FALSE
VERBOSE_FLAG=$FALSE
OUTPUT=$STDOUT

# Touch LOG_FILE to ensure that the folder and log exists
mkdir -p $LOG_FOLDER
touch $LOG_FILE

while (( "$#" )); do
    case $1 in
        "--all")
            for prog in ${available_programs[@]}; do
                update_table["$prog"]=$TRUE
            done
            ;;
        "-b"|"--banner")
            echo "Setting Banner Flag"
            BANNER_FLAG=$TRUE
            ;;
        "-v"|"--verbose")
            VERBOSE_FLAG=$TRUE
            ;;
        "--help")
            usage
            ;;
        "--"*)
            program=$(echo $1 | sed -n -e 's/--//p')
            if [[ "$available_programs" =~ "$program" ]]; then
                update_table["$program"]=$TRUE
            else
                echo "ERROR: $program is not an avaialable program"
            fi
            ;;
    esac
    shift
done

# Set output for commands
if (( "$VERBOSE_FLAG" == $TRUE )); then
    OUTPUT=$STDOUT
else
    OUTPUT="$LOG_FILE"
fi


# Go through available programs and see if we need to update them
# do this becase there is no way to go through the keys for the update table
programs_to_update=""
for prog in $available_programs; do
    if [[ ${update_table["$prog"]} == $TRUE ]]; then
        programs_to_update+=" $prog"
    fi
done

echo -e "${BBlue}[I]${NC} ${BWhite}The following programs have been detected and will be updated${NC}"
for prog in $programs_to_update; do
    echo "    $prog"
done

for prog in $programs_to_update; do
    update_$prog
done
