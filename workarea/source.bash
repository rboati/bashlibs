#!/bin/bash


source <(sed 's/\<__NS__/pippo_/g' < ./lib2.bash)

pippo_hello

source ./lib2.bash

__NS__hello
