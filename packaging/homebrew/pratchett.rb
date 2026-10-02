# Template: the release workflow fills in @VERSION@ and @SHA256@ and pushes the
# result to loudoncloud/homebrew-tap. Edit the formula here, not in the tap.
class Pratchett < Formula
  desc "Random Terry Pratchett quotes for your terminal, with a little help from DEATH"
  homepage "https://github.com/loudoncloud/pratchett"
  url "https://github.com/loudoncloud/pratchett/archive/refs/tags/v@VERSION@.tar.gz"
  sha256 "@SHA256@"
  license all_of: ["MIT", "CC-BY-SA-4.0"]

  uses_from_macos "zsh"

  def install
    libexec.install "pratchett.plugin.zsh", "_pratchett", "death.cow", "quotes", "bin"
    bin.install_symlink libexec/"bin/pratchett"
    zsh_completion.install_symlink libexec/"_pratchett"
  end

  def caveats
    <<~EOS
      Run `pratchett` from any shell. For the `tp` alias in zsh (and quotes
      without starting a new process), add this to your ~/.zshrc:
        source #{opt_libexec}/pratchett.plugin.zsh

      For DEATH's own lines to be delivered by DEATH, also install cowsay:
        brew install cowsay
    EOS
  end

  test do
    assert_path_exists zsh_completion/"_pratchett"
    assert_match "pratchett #{version}", shell_output("#{bin}/pratchett -v")
    assert_match "— Jingo", shell_output("#{bin}/pratchett -p 'whole sword'")
  end
end
