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

mkdir -pv src/INTT
mv src/*QA_Draw_Intt_* src/INTT/

mkdir -pv src/MVTX
mv src/*QA_Draw_Mvtx_* src/MVTX/

mkdir -pv src/TPC
mv src/*QA_Draw_Tpc_* src/TPC/

mkdir -pv src/Tracking
mv src/*QA_Draw_Tracking_* src/Tracking/

ls -lsv src/*

pwd;
ls -lhv;

sigal build -f -v -n 16 -c ../utilities/jenkins/built-test/test-tracking-qa-gallery.py src _build


pwd;
ls -lhv;

cd _build/
pwd
ls -lhv;

# tar czfv ../qa_page.tar.gz ./


