# Contributing

This document contains useful information about contributing to this project. Please read it before opening issues or submitting pull requests.

## Releasing

1. Bump the version in `mix.exs` and `README.md`.
2. Run `mix hex.publish`.
3. Commit the changes, tag them with the version number and push the changes upstream.
4. Publish the release on GitHub and automatically generate the changelog.