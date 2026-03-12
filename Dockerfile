# =============================================================================
# NexSport Flutter CI Docker Image
# 100% Debian 13 Trixie slim — zero repo externe
#
# Inspired by: https://github.com/gmeligio/flutter-docker-image
# Adds: Node.js (required by Forgejo Actions)
# Uses: Java 21 (native Trixie) instead of Java 17 (Bookworm)
# =============================================================================

FROM debian:trixie-slim AS flutter

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    unzip \
    nodejs \
 && rm -rf /var/lib/apt/lists/*

ENV HOME=/root
WORKDIR "$HOME"

ENV SDK_ROOT="$HOME/sdks"
ENV FLUTTER_ROOT="$SDK_ROOT/flutter"
ENV PATH="$PATH:$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin"

ARG flutter_version

RUN git clone \
    --depth 1 \
    --branch "$flutter_version" \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_ROOT" \
 && flutter --version \
 && flutter config --no-cli-animations \
 && dart --disable-analytics \
 && flutter config \
    --no-cli-animations \
    --no-analytics \
    --no-enable-android \
    --no-enable-web \
    --no-enable-linux-desktop \
    --no-enable-windows-desktop \
    --no-enable-fuchsia \
    --no-enable-custom-devices \
    --no-enable-ios \
    --no-enable-macos-desktop \
 && flutter doctor

COPY ./script/docker_entrypoint.sh "$HOME/docker_entrypoint.sh"
RUN chmod +x "$HOME/docker_entrypoint.sh"

ENTRYPOINT [ "/root/docker_entrypoint.sh" ]

# =============================================================================
# Fastlane (Ruby + bundler + cached gem)
# =============================================================================

FROM flutter AS fastlane

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ruby-full \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

ENV RUBY_ROOT="$SDK_ROOT/ruby"
ENV GEM_HOME="$RUBY_ROOT"
ENV GEM_PATH="$GEM_HOME"
ENV PATH="$PATH:$GEM_HOME/bin"

ENV FASTLANE_OPT_OUT_USAGE="YES"
ENV FASTLANE_SKIP_UPDATE_CHECK="YES"
ENV FASTLANE_HIDE_CHANGELOG="YES"

RUN gem install --no-document bundler

ENV FASTLANE_ROOT="$SDK_ROOT/fastlane"
RUN mkdir -p "$FASTLANE_ROOT"
WORKDIR "$FASTLANE_ROOT"

ARG fastlane_version
RUN bundle init \
 && bundle add --version "$fastlane_version" fastlane

# =============================================================================
# Android (Java 21 + SDK + NDK + CMake + Gradle warm-up)
# =============================================================================

FROM fastlane AS android

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV ANDROID_HOME="$SDK_ROOT/android-sdk" \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    openjdk-21-jdk-headless \
 && rm -rf /var/lib/apt/lists/*

WORKDIR "$HOME"

ARG android_build_tools_version
ARG android_platform_versions
ARG android_ndk_version
ARG cmake_version

RUN mkdir -p "$ANDROID_HOME" \
 && command_line_tools_url="$(curl -s https://developer.android.com/studio/ | grep -o 'https://dl.google.com/android/repository/commandlinetools-linux-[0-9]\+_latest.zip')" \
 && curl -o android-cmdline-tools.zip "$command_line_tools_url" \
 && mkdir -p "$ANDROID_HOME/cmdline-tools/" \
 && unzip -q android-cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/" \
 && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
 && rm android-cmdline-tools.zip \
 && (yes || true) | sdkmanager --licenses \
 && mkdir -p "$HOME/.android" \
 && touch "$HOME/.android/repositories.cfg" \
 && sdkmanager --update \
 && (yes || true) | sdkmanager \
    "platform-tools" \
    "build-tools;$android_build_tools_version" \
    "ndk;$android_ndk_version" \
    "cmake;$cmake_version" \
 && for version in $android_platform_versions; do (yes || true) | sdkmanager "platforms;android-$version"; done \
 && flutter config --enable-android \
 && (yes || true) | flutter doctor --android-licenses \
 && flutter precache --android \
 && flutter create /tmp/_warmup \
 && cd /tmp/_warmup/android && ./gradlew --version \
 && cd / && rm -rf /tmp/_warmup

WORKDIR "$HOME"
