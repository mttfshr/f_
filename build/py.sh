#!/bin/bash
# Wrapper to ensure Homebrew Python is used for all f_ build scripts
export PATH="/opt/homebrew/bin:$PATH"
exec python3 "$@"
