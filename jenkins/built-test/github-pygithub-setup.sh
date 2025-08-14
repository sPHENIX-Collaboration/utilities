#!/usr/bin/env bash

env

ls -lhv

if [ -d "env/bin" ] 
then
    echo "Directory env exists, and skip virtual env initialization. Here is its content:"
    ls -lhv env/
    ls -lhv env/bin
    exit
else
    echo "Continue to setup virtual env"
fi

~/anaconda3/bin/python -m venv env
source env/bin/activate

which python
python --version
pip --version

pip install cryptography
pip install PyGithub
# pip install python-jwt

pip freeze
