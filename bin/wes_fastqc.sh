#!/usr/bin/env bash
fastqc --threads "$1" "${@:2}"
