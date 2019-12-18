#!/bin/bash

read -p "Full path to project: " project_path
git clone https://github.com/Iipal/makemebetter project_path

rm -rf project_path
