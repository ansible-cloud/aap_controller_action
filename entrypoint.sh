#! /usr/bin/env bash

echo "AAP - Automation controller Github Action"

if [ -z "$CONTROLLER_HOST" ]; then
  echo "Automation controller host is not set. Exiting."
  exit 1
fi


echo "END OF AAP - Automation controller Github Action"
