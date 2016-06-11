#! /bin/sh

for sample in samples/*
do
  mix run "$sample"
done
