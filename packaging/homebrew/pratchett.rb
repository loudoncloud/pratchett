class Pratchett < Formula
  desc "Random Terry Pratchett quotes for your terminal, with a little help from DEATH"
  homepage "https://github.com/loudoncloud/pratchett"
  url "https://github.com/loudoncloud/pratchett/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "4b0c5f014883a41544a812a2b7aa3bd0aa26667418b556822beeaec0eb4ade9d"
  license all_of: ["MIT", "CC-BY-SA-4.0"]

  uses_from_macos "zsh"

  def install
    libexec.install "pratchett.plugin.zsh", "death.cow", "quotes", "bin"
    bin.install_symlink libexec/"bin/pratchett"
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
    assert_match "pratchett #{version}", shell_output("#{bin}/pratchett -v")
    assert_match "— Jingo", shell_output("#{bin}/pratchett -p 'whole sword'")
  end
end
