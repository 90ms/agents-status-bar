cask "agents-status-bar" do
  version "0.4.1"
  sha256 "ddba5d961aa6cdf000a334a90380c6ad854604f29c630b6e62a3634fa4a58212"

  url "https://github.com/90ms/agents-status-bar/releases/download/v#{version}/AgentsStatusBar-#{version}.zip"
  name "Agents Status Bar"
  desc "Menu bar usage monitor for AI coding agents"
  homepage "https://github.com/90ms/agents-status-bar"

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Agents Status Bar.app"

  zap trash: "~/Library/Preferences/dev.agentsstatusbar.app.plist"

  caveats <<~EOS
    This preview is ad-hoc signed. On first launch, macOS may require approval in
    System Settings > Privacy & Security.
  EOS
end
