FROM anapsix/alpine-java:8_jdk
LABEL maintainer="Dariusz Siedlecki <datrio@gmail.com>"

ENV LC_ALL "en_US.UTF-8"
ENV LANGUAGE "en_US.UTF-8"
ENV LANG "en_US.UTF-8"

ENV VERSION_SDK_TOOLS "3859397"
ENV VERSION_BUILD_TOOLS "28.0.3"
ENV VERSION_TARGET_SDK "28"

ENV ANDROID_HOME "/sdk"

ENV PATH "$PATH:${ANDROID_HOME}/tools:$PATH:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools"
ENV DEBIAN_FRONTEND noninteractive

ENV HOME "/root"

RUN apk update && apk add --no-cache \
    wget \
    tar \
    unzip \
    libstdc++6 \
    zlib \
    expect \
    bash \
    perl \
    curl \
    unzip \
    zip \
    git \
    ruby \
    ruby-dev \
    ruby-rdoc \
    ruby-irb \
    openssh \
    openssh-server \
    g++ \
    make \
    cmake \
    ninja \
    nodejs \
    nodejs-npm \
    python \
    && rm -rf /tmp/* /var/tmp/*

ADD https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip /tools.zip
RUN unzip /tools.zip -d /sdk && \
    rm -v /tools.zip

# Workaround for host bitness error with android emulator
# https://stackoverflow.com/a/37604675/455578
RUN mv /bin/sh /bin/sh.backup \
  && cp /bin/bash /bin/sh

COPY android-wait-for-emulator /usr/local/bin/android-wait-for-emulator
COPY assure_emulator_awake.sh /usr/local/bin/assure_emulator_awake.sh

RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --licenses
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager "platforms;android-${VERSION_TARGET_SDK}"

RUN mkdir -p $HOME/.android && touch $HOME/.android/repositories.cfg
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "tools" "platform-tools" "build-tools;${VERSION_BUILD_TOOLS}"
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "extras;android;m2repository" "extras;google;google_play_services" "extras;google;m2repository"
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2"
RUN ${ANDROID_HOME}/tools/bin/sdkmanager "ndk-bundle"

RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager "system-images;android-${VERSION_TARGET_SDK};google_apis;x86_64" "system-images;android-${VERSION_TARGET_SDK};google_apis;arm64-v8a"

RUN mkdir -p $HOME/lokalise && cd $HOME/lokalise
RUN wget -O ./inst.tgz https://s3-eu-west-1.amazonaws.com/lokalise-assets/cli/lokalise-0.44-linux-amd64.tgz
RUN tar -xvzf ./inst.tgz
RUN mv ./lokalise /usr/local/bin/lokalise

RUN gem install fastlane
RUN gem install dotenv
RUN gem install json

# Downloading gcloud package
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz

# Installing the package
RUN mkdir -p /usr/local/gcloud
RUN tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz
RUN /usr/local/gcloud/google-cloud-sdk/install.sh --quiet

# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

RUN npm install -g webpack webpack-cli wrapper-webpack-plugin

ADD id_rsa $HOME/.ssh/id_rsa
ADD id_rsa.pub $HOME/.ssh/id_rsa.pub
ADD adbkey $HOME/.android/adbkey
ADD adbkey.pub $HOME/.android/adbkey.pub
