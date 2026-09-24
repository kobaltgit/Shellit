/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  let existing = null;
  try {
    existing = app.findCollectionByNameOrId("feature_votes");
  } catch (e) {}

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
    console.log("Successfully created feature_votes collection.");
  }

  try {
    const roadmapCol = app.findCollectionByNameOrId("roadmap_items");
    if (roadmapCol) {
      roadmapCol.updateRule = null;
      app.save(roadmapCol);
      console.log("Successfully locked roadmap_items from direct public updates.");
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
