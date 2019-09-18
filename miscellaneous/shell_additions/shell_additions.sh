UAV_CORE_PATH=$GIT_PATH/uav_core/

# #{ killp()

# allows killing process with all its children
killp() {

  if [ $# -eq 0 ]; then
    echo "The command killp() needs an argument, but none was provided!"
    return
  else
    pes=$1
  fi

  for child in $(ps -o pid,ppid -ax | \
    awk "{ if ( \$2 == $pes ) { print \$1 }}")
    do
      # echo "Killing child process $child because ppid = $pes"
      killp $child
    done

# echo "killing $1"
kill -9 "$1" > /dev/null 2> /dev/null
}

# #}

# #{ sourceShellDotfile()

getRcFile() {

  case "$SHELL" in
    *bash*)
      RCFILE="$HOME/.bashrc"
      ;;
    *zsh*)
      RCFILE="$HOME/.zshrc"
      ;;
  esac

  echo "$RCFILE"
}

sourceShellDotfile() {

  RCFILE=$( getRcFile )

  source "$RCFILE"
}

# #}
alias sb="sourceShellDotfile"

# #{ cd()

SYMLINK_LIST_PATH="/tmp/symlink_list.txt"

# generate the symlink list
# if we are not in TMUX
if [ -z $TMUX ]; then

  # and the symlinklist does not exist
  if [ ! -e "$SYMLINK_LIST_PATH" ]; then

    # create the symlink list
    $UAV_CORE_PATH/miscellaneous/scripts/detacher.sh ~/.scripts/createRosSymlinkDatabase.sh
  fi
fi

if [ -e "$SYMLINK_LIST_PATH" ]; then

  # parse the csv file and extract file paths
  i="1"
  while IFS=, read -r path1 path2; do

    SYMLINK_LIST_PATHS1[$i]=`eval echo "$path1"`
    SYMLINK_LIST_PATHS2[$i]=`eval echo "$path2"`

    # echo "${SYMLINK_LIST_PATHS1[$i]} -> ${SYMLINK_LIST_PATHS2[$i]}"

    i=$(expr $i + 1)
  done < "$SYMLINK_LIST_PATH"

fi

cd() {

  # if ag is missing, run normal "cd"
  if [ -z SYMLINK_LIST_PATHS1 ]; then

    builtin cd "$@"
    return

    # if we have ag, do the magic
  else

    builtin cd "$@"
    new_path=`pwd`

    # test original paths for prefix
    # echo ""
    j="1"
    for ((i=1; i < ${#SYMLINK_LIST_PATHS1[*]}+1; i++));
    do
      if [[ "$new_path" == *${SYMLINK_LIST_PATHS2[$i]}* ]]
      then
        # echo "found prefix: ${SYMLINK_LIST_PATHS1[$i]} -> ${SYMLINK_LIST_PATHS2[$i]} for $new_path"
        # echo substracted: ${new_path#*${SYMLINK_LIST_PATHS2[$i]}}
        repath[$j]="${SYMLINK_LIST_PATHS1[$i]}${new_path#*${SYMLINK_LIST_PATHS2[$i]}}"
        # echo new_path: ${repath[$j]}
        new_path=${repath[$j]}
        j=$(expr $j + 1)
        # echo ""
      fi
    done

    if [ "$j" -ge "2" ]
    then
      builtin cd "$new_path"
    fi
  fi
}

CURRENT_PATH=`pwd`
cd "$CURRENT_PATH"

# #}

# #{ sourceShellDotfile()

getRcFile() {

  case "$SHELL" in
    *bash*)
      RCFILE="$HOME/.bashrc"
      ;;
    *zsh*)
      RCFILE="$HOME/.zshrc"
      ;;
  esac

  echo "$RCFILE"
}

sourceShellDotfile() {

  RCFILE=$( getRcFile )

  source "$RCFILE"
}

# #}
alias sb="sourceShellDotfile"

## --------------------------------------------------------------
## |                         ROS aliases                        |
## --------------------------------------------------------------

# #{ waitForRos()

waitForRos() {
  until rostopic list > /dev/null 2>&1; do
    echo "waiting for ros"
    sleep 1;
  done
}

# #}

# #{ waitForSimulation()

waitForSimulation() {
  until timeout 3s rostopic echo /gazebo/model_states -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for simulation"
    sleep 1;
  done
  sleep 1;
}

# #}

# #{ waitForOdometry()

waitForOdometry() {
  until timeout 3s rostopic echo /$UAV_NAME/mavros/local_position/odom -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for odometry"
    sleep 1;
  done
}

# #}

# #{ waitForControlManager()

waitForControlManager() {
  until timeout 3s rostopic echo /$UAV_NAME/control_manager/diagnostics -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for control manager"
    sleep 1;
  done
}

# #}

# #{ waitForControl()

waitForControl() {
  until timeout 3s rostopic echo /$UAV_NAME/control_manager/diagnostics -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for control"
    sleep 1;
  done
  until timeout 3s rostopic echo /$UAV_NAME/odometry/odom_main -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for odom_main"
    sleep 1;
  done
}

# #}

# #{ waitForMpc()

waitForMpc() {
  until timeout 3s rostopic echo /$UAV_NAME/control_manager/diagnostics -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for control"
    sleep 1;
  done
  until timeout 3s rostopic echo /$UAV_NAME/odometry/odom_main -n 1 --noarr > /dev/null 2>&1; do
    echo "waiting for odom_main"
    sleep 1;
  done
}

# #}

# #{ catkin()

# EPIGEN_ADD_BLOCK_MATOUS {
# export BEEP="/usr/share/sounds/ubuntu/notifications/Blip.ogg"
# which paplay > /dev/null
# if [ $? -eq 0 ]; then
#   alias beep='paplay $BEEP'
# else
#   alias beep='espeak BEEP'
# fi
# EPIGEN_ADD_BLOCK_MATOUS }

catkin() {

  case $* in

    init*)

      # give me the path to root of the repo we are in
      ROOT_DIR=`git rev-parse --show-toplevel` 2> /dev/null

      command catkin "$@"
      command catkin config --profile debug --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native -fno-diagnostics-color'  -DCMAKE_C_FLAGS='-march=native -fno-diagnostics-color'
      command catkin config --profile release --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native -fno-diagnostics-color'  -DCMAKE_C_FLAGS='-march=native -fno-diagnostics-color'
      command catkin config --profile reldeb --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_FLAGS='-std=c++17 -march=native -fno-diagnostics-color' -DCMAKE_C_FLAGS='-march=native -fno-diagnostics-color'

      command catkin profile set reldeb
      ;;

    build*|b|bt)

      PACKAGES=$(catkin list)
      if [ -z "$PACKAGES" ]; then
        echo "Cannot compile, not in a workspace"
      else

# EPIGEN_DEL_BLOCK_MATOUS {
        command catkin "$@"
# EPIGEN_DEL_BLOCK_MATOUS }

# EPIGEN_ADD_BLOCK_MATOUS {
        # command catkin "$@" && beep || espeak -v cs "sprav si to vole"
# EPIGEN_ADD_BLOCK_MATOUS }

      fi

      ;;

    *)
      command catkin $@
      ;;

    esac
  }

# #}
alias cb="catkin build"
