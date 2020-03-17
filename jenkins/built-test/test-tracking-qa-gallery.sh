#!/bin/bash

env

ls -lhv

ls -lhv macros/macros/g4simulations/*

~/anaconda3/bin/virtualenv env
source env/bin/activate

which python
python --version
pip --version

pip install sigal\[all\]

mkdir qa_html
cd qa_html/

mkdir src/
rsync -avl ${WORKSPACE}/macros/macros/g4simulations/*.png src/
rsync -avl ${WORKSPACE}/macros/macros/QA/tracking/*.png src/
ls -lsv src/

pwd;
ls -lhv;

sigal build -f -v -n 16 -c ../utilities/jenkins/built-test/test-tracking-qa-gallery.py src _build


pwd;
ls -lhv;

cd _build/
pwd
ls -lhv;

# tar czfv ../qa_page.tar.gz ./


