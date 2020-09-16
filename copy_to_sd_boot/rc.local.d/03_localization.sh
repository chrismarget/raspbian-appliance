#!/bin/sh -e

if [ -e /boot/localization ]
then
  . /boot/localization

  if [ -n "$locale" ]
  then
    raspi-config nonint do_change_locale $locale
  fi

  if [ -n "$keyboard" ]
  then
    raspi-config nonint do_configure_keyboard $layout
  fi

  mkdir -p /boot/done
  mv /boot/localization /boot/done
fi
