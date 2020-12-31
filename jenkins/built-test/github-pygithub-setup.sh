#!/bin/bash

env

ls -lhv

~/anaconda3/bin/virtualenv env
source env/bin/activate

which python
python --version
pip --version

pip install cryptography
pip install PyGithub
# pip install python-jwt

pip freeze
