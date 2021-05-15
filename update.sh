#!/bin/bash

set -euo pipefail

declare -A versions=(
  [4.2.16]='1bbe619072b05efb55725c9df851363892b77ad6788dfd28eadce6a8f84a8209'
  [4.4.4]='34c316a4a78d7ee9b95d4391530f9bb3ff3edd99ebbebfac6354ed173e940884'
  [5.0.1]='6c181cc592c48a2cba8b8df1d45fda0938d70f84ceeba1afc436f16a6090f556'
)

for rt_version in "${!versions[@]}"; do
  dir=${rt_version:0:3}
  rt_sha=${versions[$rt_version]}

  if [[ "$rt_version" == *"alpha"* ]] || [[ "$rt_version" == *"beta"* ]]; then
    rt_release='devel'
  else
    rt_release='release'
  fi

  mkdir -p "$dir"

  if [ "$dir" = "4.2" ]; then
    # RT::Authen::Token requires v4.2.5 or later
    cat RT_SiteConfig.pm | sed -e '/Plugin("RT::Authen::Token");/d' \
                         | tee 4.2/RT_SiteConfig.pm > /dev/null
    
    # RT 4.2 does not support --enable-externalauth
    cat Dockerfile.template | sed -e '/RUN cpanm RT::Authen::Token/{N;d;}' \
                                  -e '/--enable-externalauth/d' \
                            | tee "$dir"/Dockerfile > /dev/null

  elif [ "$dir" = 4.4 ]; then
    cp -a RT_SiteConfig.pm $dir
    cp -a Dockerfile.template "$dir"/Dockerfile

  else
    cp -a RT_SiteConfig.pm "$dir"

    # RT::Authen::Token is included with v5.0
    cat Dockerfile.template | sed '/RUN cpanm RT::Authen::Token/{N;d;}' \
                            | tee "$dir"/Dockerfile > /dev/null
  fi

  cp -a \
    apache.rt.conf \
    docker-entrypoint.sh \
    "$dir"

  sed -i \
    -e "s/%%RT_RELEASE%%/$rt_release/" \
    -e "s/%%RT_SHA%%/$rt_sha/" \
    -e "s/%%RT_VERSION_MAJOR%%/${rt_version:0:1}/" \
    -e "s/%%RT_VERSION%%/$rt_version/" \
    "$dir"/apache.rt.conf "$dir"/docker-entrypoint.sh "$dir"/Dockerfile
done
