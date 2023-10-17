#!/bin/bash

VERSION=""

# get parameters
while getopts v flag
do
  case "$flag" in
    v) VERSION=${OPTARG};;
    *) echo "usage: $0 [-v]" >&2
        exit 1;;
  esac
done

# get highest tag number, and add v0.1.0 if doesn't exist
git fetch --prune --unshallow 2>/dev/null
CURRENT_VERSION=$("git describe --abbrev=0 --tags 2>/dev/null")

if [[ $CURRENT_VERSION == '' ]]
then
  CURRENT_VERSION='v0.0.1'
fi
echo "Current Version: $CURRENT_VERSION"

# replace . with space so can split into an array
CURRENT_VERSION_PARTS=("${CURRENT_VERSION//./ }")

# get number parts
MAJOR=${CURRENT_VERSION_PARTS[0]}
MINOR=${CURRENT_VERSION_PARTS[1]}
PATCH=${CURRENT_VERSION_PARTS[2]}

if [[ $VERSION == 'major' ]]
then
  MAJOR=v$((MAJOR+1))
elif [[ $VERSION == 'minor' ]]
then
  MINOR=$((MINOR+1))
elif [[ $VERSION == 'patch' ]]
then
  PATCH=$((PATCH+1))
else
  echo "No version type (https://semver.org/) or incorrect type specified, try: -v [major, minor, patch]"
  exit 1
fi

# create new tag
NEW_TAG="$MAJOR.$MINOR.$PATCH"
echo "($VERSION) updating $CURRENT_VERSION to $NEW_TAG"

# get current hash and see if it already has a tag
GIT_COMMIT=$("git rev-parse HEAD")
NEEDS_TAG=$("git describe --contains $GIT_COMMIT 2>/dev/null")

# only tag if no tag already
if [ -z "$NEEDS_TAG" ]; then
  echo "Tagged with $NEW_TAG"
  git tag $NEW_TAG
  git push --tags
  git push
else
  echo "Already a tag on this commit"
fi

#echo ::set-output name=git-tag::$NEW_TAG
echo "name=$(git-tag::$NEW_TAG)" >>"$GITHUB_OUTPUT"

exit 0
