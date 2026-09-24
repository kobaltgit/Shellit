/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // 1. Create feature_votes collection to store permanent individual votes
  try {
    const existing = app.findCollectionByNameOrId("feature_votes");
    if (!existing) {
      const votesCol = new Collection({
        name: "feature_votes",
        type: "base",
        listRule: null,
        viewRule: null,
        createRule: null,
        updateRule: null,
        deleteRule: null,
        fields: [
          { name: "feature_id", type: "text", required: true },
          { name: "voter_token", type: "text", required: true },
          { name: "ip_hash", type: "text" },
          { name: "created", type: "autodate", onCreate: true },
          { name: "updated", type: "autodate", onCreate: true, onUpdate: true }
        ],
        indexes: [
          "CREATE UNIQUE INDEX idx_feat_voter ON feature_votes (feature_id, voter_token)"
        ]
      });
      app.save(votesCol);
    }
  } catch (err) {
    console.error("Error creating feature_votes collection:", err);
  }

  // 2. Lock direct public updates on roadmap_items to prevent arbitrary vote spoofing
  try {
    const roadmapCol = app.findCollectionByNameOrId("roadmap_items");
    if (roadmapCol) {
      roadmapCol.updateRule = null; // Admin / server-only updates
      app.save(roadmapCol);
    }
  } catch (err) {
    console.error("Error locking roadmap_items:", err);
  }
}, (app) => {
  try {
    const votesCol = app.findCollectionByNameOrId("feature_votes");
    if (votesCol) app.delete(votesCol);
  } catch (e) {}
});
