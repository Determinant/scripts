#!/bin/bash
REMOTE=Plutonium
repos=(~/rec ~/conf ~/web/blog ~/english/flashcards)
for i in "${repos[@]}"; do
    cd "$i"
    git push "$REMOTE"
done
