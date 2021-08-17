#!/bin/bash

build_no="$1"
build_args="--compress"
tag_prefix="registry.library.oregonstate.edu/osulp-api"

if [ -z "$BCR_PASS" ]; then
   echo 'Please set the BCR password in $BCR_PASS'
   exit 1
fi

if [ -z "$build_no" ]; then
   if [ -f ".version" ]; then
      version=`cat .version`
      let build_no=($version + 1)
      echo "Using cached build number: (old: $version, new: $build_no)"
   else
      echo "Usage: $0 <build number>"
      exit 1
   fi
fi
tag1="$tag_prefix:osulp-${build_no}"
tag2="$tag_prefix:latest"

echo "Building for tag $tag1"
docker build ${build_args} . -t "$tag1"

if [ "$?" -eq 0 ]; then
   echo "Logging into BCR as admin"
   echo $BCR_PASS | docker login --password-stdin registry.library.oregonstate.edu

   echo "pushing: $tag1"
   docker push "$tag1"
   if [ "$?" -eq 0 ]; then
      echo $build_no > .version
   fi
   echo "tagging $tag1 as :latest"
   docker tag $tag1 $tag2
   docker push "$tag2"
fi
