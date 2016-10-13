#! /bin/bash

set -e

for sample in samples/*
do
  echo "running $sample"
  echo ""
  mix run "$sample"
  echo ""
  echo "------------------------------------------"
  echo ""
done
