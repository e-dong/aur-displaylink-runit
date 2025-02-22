#!/bin/sh
# Copyright (c) 2016 - 2020 DisplayLink (UK) Ltd.
# File autogenerated by udev-installer.sh script

get_displaylink_dev_count()
{
   cat /sys/bus/usb/devices/*/idVendor | grep 17e9 | wc -l
}

get_displaylink_symlink_count()
{
  root=$1

  if [ ! -d "$root/displaylink/by-id" ]; then
    echo "0"
    return
  fi

  for f in $(find $root/displaylink/by-id -type l -exec realpath {} \; 2> /dev/null); do
    test -c $f && echo $f;
  done | wc -l
}

start_displaylink()
{
  if [ "$(get_displaylink_dev_count)" != "0" ]; then
    start_service
  fi
}

stop_displaylink()
{
  root=$1

  if [ "$(get_displaylink_symlink_count $root)" = "0" ]; then
    stop_service
  fi
}

remove_dldir_if_empty()
{
  root=$1
  (cd $root; rmdir -p --ignore-fail-on-non-empty displaylink/by-id)
}

create_displaylink_symlink()
{
  root=$1
  device_id=$2
  devnode=$3

  mkdir -p $root/displaylink/by-id
  ln -sf $devnode $root/displaylink/by-id/$device_id
}

unlink_displaylink_symlink()
{
   root=$1
   devname=$2

   for f in $root/displaylink/by-id/*; do
     if [ ! -e "$f" ] || ([ -L "$f" ] && [ "$f" -ef "$devname" ]); then
       unlink "$f"
     fi
   done
   (cd $root; rmdir -p --ignore-fail-on-non-empty displaylink/by-id)
}

prune_broken_links()
{
  root=$1

  dir="$root/displaylink/by-id"
  find -L "$dir" -name "$dir" -o type d -prune -o -type -l -exec rm {} +
  remove_dldir_if_empty $root
}

disable_u1_u2()
{
    echo 0 > "/sys$1/../port/usb3_lpm_permit"
}

main()
{
  action=$1
  root=$2
  devpath=$3
  devnode=$5

  if [ "$action" = "add" ]; then
    device_id=$4
    create_displaylink_symlink $root $device_id $devnode
    start_displaylink
    disable_u1_u2 "$devpath"
  elif [ "$action" = "remove" ]; then
      devname=$3
      unlink_displaylink_symlink "$root" "$devname"
      stop_displaylink "$root"
  elif [ "$action" = "START" ]; then
    start_displaylink
  fi
}

start_service()
{
  sv up displaylink
}

stop_service()
{
  sv down displaylink
}

if [ "$ACTION" = "add" ] && [ "$#" -ge 3 ]; then
  main $ACTION $1 $2 $3 $4
  return 0
fi

if  [ "$ACTION" = "remove" ]; then
  if [ "$#" -ge 2 ]; then
    main $ACTION $1 $2 $3
    return 0
  else
    prune_broken_links $root
    return 0
  fi
fi

