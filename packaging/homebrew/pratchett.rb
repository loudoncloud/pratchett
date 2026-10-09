# Template: the release workflow fills in @VERSION@ and @SHA256@ and pushes the
# result to loudoncloud/homebrew-tap. Edit the formula here, not in the tap.
class Pratchett < Formula
  desc "Random Terry Pratchett quotes for your terminal, with a little help from DEATH"
  homepage "https://github.com/loudoncloud/pratchett"
  url "https://github.com/loudoncloud/pratchett/archive/refs/tags/v@VERSION@.tar.gz"
  sha256 "@SHA256@"
  license all_of: ["MIT", "CC-BY-SA-4.0"]

  depends_on "cowsay" # DEATH delivers his own lines

  uses_from_macos "zsh"

  def install
    libexec.install "pratchett.plugin.zsh", "_pratchett", "death.cow", "quotes", "bin"
    bin.install_symlink libexec/"bin/pratchett"
    zsh_completion.install_symlink libexec/"_pratchett"
    bash_completion.install "completions/pratchett.bash" => "pratchett"
    fish_completion.install "completions/pratchett.fish"
  end

  def caveats
    <<~EOS
      Run `pratchett` from any shell. For the `tp` alias in zsh (and quotes
      without starting a new process), add this to your ~/.zshrc:
        source #{opt_libexec}/pratchett.plugin.zsh
    EOS
  end

  test do
    assert_path_exists zsh_completion/"_pratchett"
    assert_path_exists bash_completion/"pratchett"
    assert_path_exists fish_completion/"pratchett.fish"
    assert_match "pratchett #{version}", shell_output("#{bin}/pratchett -v")
    assert_match "— Jingo", shell_output("#{bin}/pratchett -p 'whole sword'")
    assert_match "(___/", shell_output("#{bin}/pratchett -d -s") # DEATH, via cowsay
  end
end
