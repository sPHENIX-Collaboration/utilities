#!/bin/bash

env

ls -lhv

ls -lhv macros/macros/g4simulations/*

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

mkdir -pv src/Vertex
mv src/*QA_Draw_Vertex_* src/Vertex/

ls -lsv src/*

pwd;
ls -lhv;

echo "========= Env setup ========="
source ~/npm/usethis.sh
env;

echo "========= Start thumbsup ========="
thumbsup --config ../utilities/jenkins/built-test/test-tracking-qa-gallery-thumbsup.json


pwd;
ls -lhv;

cd _build/
pwd
ls -lhv;

# tar czfv ../qa_page.tar.gz ./
