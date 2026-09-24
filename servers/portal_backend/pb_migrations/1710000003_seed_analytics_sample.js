/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  try {
    const releasesCol = app.findCollectionByNameOrId("release_snapshots");
    if (releasesCol) {
      // Seed releases data (matching real Shellit releases)
      const releasesData = [
        {
          tag_name: "v0.8.3",
          total_downloads: 1480,
          windows_downloads: 980,
          linux_downloads: 360,
          android_downloads: 140,
          assets_detail: {
            "shellit-windows-x64-setup.msi": 620,
            "shellit-windows-x64-portable.zip": 360,
            "shellit_linux_amd64.deb": 240,
            "Shellit-x86_64.AppImage": 120,
            "shellit-release.apk": 140
          }
        },
        {
          tag_name: "v0.8.2",
          total_downloads: 1120,
          windows_downloads: 740,
          linux_downloads: 280,
          android_downloads: 100,
          assets_detail: {
            "shellit-windows-x64-setup.msi": 490,
            "shellit-windows-x64-portable.zip": 250,
            "shellit_linux_amd64.deb": 190,
            "Shellit-x86_64.AppImage": 90,
            "shellit-release.apk": 100
          }
        },
        {
          tag_name: "v0.8.1",
          total_downloads: 790,
          windows_downloads: 530,
          linux_downloads: 190,
          android_downloads: 70,
          assets_detail: {
            "shellit-windows-x64-setup.msi": 350,
            "shellit-windows-x64-portable.zip": 180,
            "shellit_linux_amd64.deb": 130,
            "Shellit-x86_64.AppImage": 60,
            "shellit-release.apk": 70
          }
        }
      ];

      for (const item of releasesData) {
        const record = new Record(releasesCol, item);
        app.save(record);
      }
    }

    // Seed some initial feedback reports
    const feedbackCol = app.findCollectionByNameOrId("feedback_reports");
    if (feedbackCol) {
      const sampleFeedback = [
        {
          type: "bug",
          subject: "PTY scroll issue in 2x2 split on small resolution",
          message: "When splitting 2x2 on 1366x768 screen, the right bottom pane overflows slightly by 4px.",
          email: "alex.devops@gmail.com",
          os_info: "Linux Ubuntu 24.04 LTS",
          app_version: "v0.8.3",
          status: "in_progress"
        },
        {
          type: "feature_request",
          subject: "Support for YubiKey FIDO2 SSH resident keys",
          message: "Would be amazing to use hardware security keys via sk-ssh-ed25519@openssh.com directly in Keychain Vault.",
          email: "security-lead@fintech.io",
          os_info: "Windows 11 Pro 23H2",
          app_version: "v0.8.3",
          status: "new"
        },
        {
          type: "general",
          subject: "Incredible UX compared to Termius!",
          message: "Finally an independent SSH client with zero telemetry and real live latency dots. Subscribing to the roadmap!",
          email: "dmitry.k@yandex.ru",
          os_info: "macOS / Linux",
          app_version: "v0.8.2",
          status: "resolved"
        }
      ];

      for (const fb of sampleFeedback) {
        const record = new Record(feedbackCol, fb);
        app.save(record);
      }
    }
  } catch (e) {
    console.error("Seed analytics error:", e);
  }
});
