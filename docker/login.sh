#!/bin/bash

echo "Start manual login"
echo "========================================================================"
echo "IMPORTANT: Use `exit` instead of CTRL-C when you successfully logged in."
echo "Otherwise protonmail bridge will not start."
echo "========================================================================"

proton-bridge -cli

echo "Consider logged in. Add flag."
echo "" > $HOME/.logged-in
