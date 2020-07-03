#!/usr/bin/env bash
echo "Checking changed files"
files=$(git diff --name-only origin/master -- | xargs ls -d 2>/dev/null | egrep "\.(rb|spec|rake|rhtml|rjs|rxml|erb)$")
echo "Changed files:"
echo "***"
echo "$files"
echo "***"
if [ -z "$files" ]; then echo "No ruby files were changed"; else echo "$files" | xargs rubocop -l ; fi