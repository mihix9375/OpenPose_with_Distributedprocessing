@echo off
chcp 65001

mkdir temp
cd temp 
set zpath=C:\PROGRA~1\7-zip\7z.exe

curl "https://drive.usercontent.google.com/download?id=1QCSxJZpnWvM00hx49CJ2zky7PWGzpcEh&confirm=xxx" -o .\models.zip
%zpath% x models.zip -mmt
move models ..\models
cd ..
rmdir /s /q temp
pause