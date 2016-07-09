#! /bin/bash

set -e

for sample in samples/*
do
  mix run "$sample"
done
