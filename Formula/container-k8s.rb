class ContainerK8s < Formula
  desc "Kubernetes development cluster plugin for Apple's container CLI"
  homepage "https://github.com/stephenlclarke/container-k8s"
  url "https://github.com/stephenlclarke/container-k8s/releases/download/homebrew-main/container-k8s-plugin-main-release-arm64.tar.gz"
  sha256 :no_check
  version "release-bootstrap"
  license "Apache-2.0"

  depends_on "container"
  depends_on arch: :arm64
  depends_on macos: :sequoia

  conflicts_with "container-k8s-snapshot", because: "both install the container-k8s command and k8s plugin"

  def install
    plugin = libexec/"container-plugins/k8s"
    plugin.install Dir["k8s/*"]

    bin.install_symlink plugin/"bin/k8s" => "container-k8s"
  end

  def caveats
    <<~EOS
      The plugin is installed under:
        #{opt_libexec}/container-plugins/k8s

      To make the Homebrew-installed container CLI discover it, link it into
      container's plugin directory and restart the container service:
        mkdir -p "$(brew --prefix container)/libexec/container-plugins"
        ln -sfn "#{opt_libexec}/container-plugins/k8s" "$(brew --prefix container)/libexec/container-plugins/k8s"
        brew services restart container

      This formula installs the release bootstrap prebuilt release asset:
        container-k8s-plugin-main-release-arm64.tar.gz
    EOS
  end

  test do
    assert_match "0.1.0", shell_output("#{bin}/container-k8s version --short")
    assert_predicate libexec/"container-plugins/k8s/config.toml", :exist?
    assert_predicate libexec/"container-plugins/k8s/resources/build-info.json", :exist?
  end
end
