/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // 1. Collection: site_visits
  const visitsCollection = new Collection({
    name: "site_visits",
    type: "base",
    listRule: "@request.auth.id != ''", // Admin / authenticated only
    viewRule: "@request.auth.id != ''",
    createRule: "", // Public beacon can submit
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "path", type: "text", required: true },
      { name: "referrer", type: "text" },
      { name: "os", type: "text" },
      { name: "browser", type: "text" },
      { name: "device_type", type: "select", values: ["desktop", "mobile", "tablet"] },
      { name: "lang", type: "text" },
      { name: "visitor_hash", type: "text" }
    ]
  });
  app.save(visitsCollection);

  // 2. Collection: release_snapshots
  const releasesCollection = new Collection({
    name: "release_snapshots",
    type: "base",
    listRule: "", // Public can read stats
    viewRule: "",
    createRule: "@request.auth.id != ''", // Admin or server can push
    updateRule: "@request.auth.id != ''",
    deleteRule: null,
    fields: [
      { name: "tag_name", type: "text", required: true },
      { name: "total_downloads", type: "number", min: 0 },
      { name: "windows_downloads", type: "number", min: 0 },
      { name: "linux_downloads", type: "number", min: 0 },
      { name: "android_downloads", type: "number", min: 0 },
      { name: "assets_detail", type: "json" }
    ]
  });
  app.save(releasesCollection);
}, (app) => {
  try {
    const visits = app.findCollectionByNameOrId("site_visits");
    if (visits) app.delete(visits);
    const releases = app.findCollectionByNameOrId("release_snapshots");
    if (releases) app.delete(releases);
  } catch (e) {}
});
