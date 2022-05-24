@echo off
TITLE New Machine

ECHO Starting Script

powershell -ep bypass "%~dp0new-machine.ps1"

PAUSE

