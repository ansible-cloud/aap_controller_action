#! /usr/bin/env bash

echo "AAP - Automation controller Github Action"

echo "CONTROLLER_HOST is $CONTROLLER_HOST"

if [ -z "$CONTROLLER_HOST" ]; then
  echo "Automation controller host is not set. Exiting."
  exit 1
fi

if [ -z "$CONTROLLER_USERNAME" ]; then
  echo "Automation controller username is not set. Exiting."
  exit 1
fi

if [ -z "$CONTROLLER_PASSWORD" ]; then
  echo "Automation controller password is not set. Exiting."
  exit 1
fi

echo "END OF AAP - Automation controller Github Action"
