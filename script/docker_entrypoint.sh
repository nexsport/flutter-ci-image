#!/usr/bin/env bash

if [ "$ENABLE_ANALYTICS" = "true" ]; then
  dart --enable-analytics
  flutter config --analytics
  unset FASTLANE_OPT_OUT_USAGE
fi

exec "$@"
