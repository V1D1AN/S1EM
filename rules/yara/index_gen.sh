#!/bin/bash

# Trouver tous les fichiers .yar dans le répertoire courant et les inclure dans index.yar
find . -maxdepth 1 -type f -name "*.yar" -printf 'include "%p"\n' > index.yar
