# Contributing

First off, thanks for taking the time to contribute!

When contributing to this repository, please first discuss the change you wish to make via issue.

Please note we have a code of conduct, please follow it in all your interactions with the project.

## Pull Request Process

1.  Run `make release` and follow the instructions (It will bump Xcribe version
    in all needed files. The versioning scheme we use is [SemVer](http://semver.org/)).
    After that, update `CHANGELOG.md` with a description of what is being changed in the release.

2.  Update the library documentation accordingly new changes.

3.  If your pull request is a patch you may point it to master branch. If it's a feature
    implementation you must point to the current release branch (usualy the next minor version eg `release-0.7.0`)

4.  You may merge the Pull Request in once you have the sign-off of two other developers, or if you
    do not have permission to do that, you may request the second reviewer to merge it for you.

## Publish

Every pull request to master branch will release a new version of xcribe on hex.pm.
So make sure to update the changelog and bump the version before merging the PR.
