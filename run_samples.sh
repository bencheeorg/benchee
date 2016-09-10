#! /bin/bash

set -e

for sample in samples/*
do
  mix run "$sample"
  echo ""
  echo "------------------------------------------"
  echo ""
done
