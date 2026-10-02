# Releasing and Homebrew

`pratchett.rb` is a template for the formula in
[loudoncloud/homebrew-tap](https://github.com/loudoncloud/homebrew-tap), which
is what makes `brew install loudoncloud/tap/pratchett` work. Edit the formula
here; the release workflow fills in the version and checksum and pushes it to
the tap.

## Releasing a new version

1. Set the new version in `pratchett.plugin.zsh` (`PRATCHETT_VERSION`) and add a
   `## x.y.z` section at the top of `CHANGELOG.md`. Commit and push.
2. Tag and push the tag:
   ```sh
   git tag -a v1.3.0 -m v1.3.0 && git push origin v1.3.0
   ```

The [release workflow](../../.github/workflows/release.yml) then:

1. runs the full test suite on macOS and Linux,
2. checks the tag matches `PRATCHETT_VERSION`,
3. publishes the GitHub release with that version's notes from `CHANGELOG.md`,
4. computes the release tarball's checksum and pushes the filled-in formula to the tap,
5. installs from the tap on macOS and runs `brew test` and `brew audit --strict`.

If a step fails, fix the cause and re-run the workflow from the Actions tab.
The steps that have already finished are skipped safely.

## One-time setup: the TAP_TOKEN secret

The workflow needs permission to push to the tap repo:

1. Create a fine-grained token at <https://github.com/settings/personal-access-tokens/new>
   (signed in as loudoncloud):
   - **Repository access:** Only select repositories → `loudoncloud/homebrew-tap`
   - **Permissions:** Repository permissions → **Contents: Read and write**
   - **Expiration:** your choice; the release will say when it needs renewing.
2. Save it as a secret in this repo:
   ```sh
   gh secret set TAP_TOKEN -R loudoncloud/pratchett
   ```
   and paste the token when asked.
