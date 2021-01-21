#!/usr/bin/env bash

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";
echo '---------' && env && echo '--------------'
echo "Pushing $APP_ID:$TRAVIS_BRANCH or $APP_ID:$TRAVIS_TAG"
case "$TRAVIS_BRANCH" in
  dev )
      docker tag $APP_ID:local $DOCKER_USERNAME/$APP_ID:dev;
      docker push $DOCKER_USERNAME/$APP_ID:dev
    ;;
  master )
      docker tag $APP_ID:local $DOCKER_USERNAME/$APP_ID:latest;
      docker push $DOCKER_USERNAME/$APP_ID:latest
    ;;
esac
case "$TRAVIS_TAG" in
  [0-9]* )
      docker tag $APP_ID:local $DOCKER_USERNAME/$APP_ID:$TRAVIS_TAG;
      docker push $DOCKER_USERNAME/$APP_ID:$TRAVIS_TAG
    ;;
esac

# Id: U-S:
