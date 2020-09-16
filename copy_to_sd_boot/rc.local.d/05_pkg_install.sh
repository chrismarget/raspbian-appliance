#!/bin/sh
if [ -e /opt/PART3/pkgs/.skip ]
then
  exit 0
fi
touch /opt/PART3/pkgs/.skip

dpkg -i /opt/PART3/pkgs/*
