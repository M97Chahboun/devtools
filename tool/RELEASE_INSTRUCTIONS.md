## How to release the next version of DevTools

### Configure/Refresh environment

Make sure:

1. Your Dart SDK is configured:

   a. You have a local checkout of the Dart SDK
      - (for getting started instructions, see [sdk/CONTRIBUTING.md](https://github.com/dart-lang/sdk/blob/main/CONTRIBUTING.md)).

   b. Ensure your `.bashrc` sets `$LOCAL_DART_SDK`

       ```shell
       DART_SDK_REPO_DIR=<Path to cloned dart sdk>
       export LOCAL_DART_SDK=$DART_SDK_REPO_DIR/sdk
       ```

   c. The local checkout is at `main` branch: `git rebase-update`

2. Your Flutter version is equal to latest candidate release branch:
    - Run `./tool/update_flutter_sdk.sh --local` from the main devtools directory.
3. You have goma [configured](http://go/ma-mac-setup).

### Prepare the release

#### Create a release PR

> If you need to install the [Github CLI](https://cli.github.com/manual/installation) you can run: `brew install gh`

- Run: `./tool/release_helper.sh`
- This will create a PR for you using the tip of master.
- The branch for that PR will be checked out locally for you.
- It will also update your local version of flutter to the Latest flutter candidate
    - This is to facilitate testing in the next steps

#### Verify the version changes for the Release PR

Verify the code on the release PR:
- updated the pubspecs under packages/
- updated all references to those packages
- updated the version constant in `packages/devtools_app/lib/devtools.dart`

These packages always have their version numbers updated in lock, so we don't have to worry about versioning.

### Test the release PR

- Build the DevTools binary and run it from your local Dart SDK.
   - From the main devtools/ directory.
   ```shell
   dart ./tool/build_e2e.dart
   ```

- Launch DevTools and verify that everything generally works.
   - open the page in a browser (http://localhost:53432)
   - `flutter run` an application
   - connect to the running app from DevTools
   - verify:
      - pages generally work
      - there are no exceptions in the chrome devtools log
   - If you find any release blocking issues:
      - fix them before releasing.
      - Then grab the latest commit hash that includes
         - the release prep commit
         - the bug fixes,
      - use this commit hash for the following steps.

- Once the build is in good shape,
   - revert any local changes.
      ```shell
      git checkout . && \
      git clean -f -d;
      ```

#### Submit the Release PR

Receive an LGTM for the PR, squash and commit.


### Tag the release
- Checkout the commit from which you want to release DevTools
   - This is likely the commit, on `master`, for the PR you just landed
   - You can run `git log -v` to see the commits.
- Run the `tag_version.sh` script
   - this creates a tag on the `flutter/devtools` repo for this release.
   - This script will automatically determine the version from `packages/devtools/pubspec.yaml` so there is no need to manually enter the version.

   ```shell
   tool/tag_version.sh;
   ```

### Upload the DevTools binary to CIPD
- Use the update.sh script to build and upload the DevTools binary to CIPD:
   ```shell
   TARGET_COMMIT_HASH=<Commit hash for the version bump commit in DevTools>
   ```

   ```shell
   cd $LOCAL_DART_SDK && \
   git rebase-update && \
   third_party/devtools/update.sh $TARGET_COMMIT_HASH [optional --no-update-flutter];
   ```
For cherry pick releases that need to be built from a specific version of Flutter,
checkout the Flutter version on your local flutter repo (the Flutter SDK that
`which flutter` points to). Then when you run the `update.sh` command, include the
`--no-update-flutter` flag:

   ```shell
   third_party/devtools/update.sh $TARGET_COMMIT_HASH --no-update-flutter
   ```

### Update the DevTools hash in the Dart SDK

- Create new branch for your changes:
   ```shell
   cd $LOCAL_DART_SDK && \
   git new-branch dt-release;
   ```

- Update the `devtools_rev` entry in the Dart SDK [DEPS file](https://github.com/dart-lang/sdk/blob/master/DEPS)
   - set the `devtools_rev` entry to the `TARGET_COMMIT_HASH`.
   - See this [example CL](https://dart-review.googlesource.com/c/sdk/+/215520) for reference.


- Build the dart sdk locally

   ```shell
   cd $LOCAL_DART_SDK && \
   gclient sync -D && \
   ./tools/build.py -mrelease -ax64 create_sdk;
   ```

- Verify that running `dart devtools` launches the version of DevTools you just released.
   - for OSX
      ```shell
      xcodebuild/ReleaseX64/dart-sdk/bin/dart devtools
      ```
   - For non-OSX
      ```shell
      out/ReleaseX64/dart-sdk/bin/dart devtools
      ```

- If the version of DevTools you just published to CIPD loads properly

   > You may need to hard reload and clear your browser cache in order to see the changes.

   - push up the SDK CL for review.
      ```shell
      git add . && \
      git commit -m "Bump DevTools DEP to $NEW_DEVTOOLS_VERSION" && \
      git cl upload -s;
      ```

### Publish package:devtools_shared on pub

`package:devtools_shared` is the only DevTools package that is published on pub.

- From the `devtools/packages/devtools_shared` directory, run:
   ```shell
   flutter pub publish
   ```

### Update to the next version
-  `gh workflow run daily-dev-bump.yaml -f updateType=minor+dev`
   -  This will kick off a workflow that will automatically create a PR with a `minor` + `dev` version bump
   -  That PR should then be auto submitted
-  See https://github.com/flutter/devtools/actions/workflows/daily-dev-bump.yaml
   -  To see the workflow run
-  Go to https://github.com/flutter/devtools/pulls to see the pull request that ends up being created
-  You should make sure that the release PR goes through without issue.

### Verify and Submit the release notes

1. Follow the instructions outlined in the release notes
[README.md](https://github.com/flutter/devtools/blob/master/packages/devtools_app/release_notes/README.md)
to add DevTools release notes to Flutter website and test them in DevTools.
2. Once release notes are submitted to the Flutter website, send an announcement to g/flutter-internal-announce with a link to the new release notes.
