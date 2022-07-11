#! /usr/bin/env bash

echo "hello"

echo "Hello $1"
time=$(date)
echo "::set-output name=time::$time"
