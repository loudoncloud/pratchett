# Homebrew

`pratchett.rb` is the formula for the tap at
[loudoncloud/homebrew-tap](https://github.com/loudoncloud/homebrew-tap), which
is what makes `brew install loudoncloud/tap/pratchett` work.

## Releasing a new version

1. Bump `PRATCHETT_VERSION` in `pratchett.plugin.zsh`, commit, then tag and push:
   ```sh
   git tag v1.0.1 && git push origin main v1.0.1
   ```
2. Point the formula at the new tag and fill in its checksum:
   ```sh
   v=1.0.1
   url=https://github.com/loudoncloud/pratchett/archive/refs/tags/v$v.tar.gz
   sha=$(curl -sL "$url" | shasum -a 256 | cut -d' ' -f1)
   sed -i '' -e "s|/v[0-9.]*\.tar\.gz|/v$v.tar.gz|" -e "s|sha256 \".*\"|sha256 \"$sha\"|" pratchett.rb
   ```
3. Copy `pratchett.rb` to `Formula/pratchett.rb` in the tap repo, then check it:
   ```sh
   brew install --build-from-source loudoncloud/tap/pratchett
   brew test pratchett && brew audit --strict pratchett
   ```
