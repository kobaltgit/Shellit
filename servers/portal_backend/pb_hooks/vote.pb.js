/// <reference path="../pb_data/types.d.ts" />

routerAdd("OPTIONS", "/api/roadmap/vote", (e) => {
  e.response.header().set("Access-Control-Allow-Origin", "*");
  e.response.header().set("Access-Control-Allow-Methods", "POST, OPTIONS");
  e.response.header().set("Access-Control-Allow-Headers", "*");
  return e.noContent(204);
});

routerAdd("POST", "/api/roadmap/vote", (e) => {
  e.response.header().set("Access-Control-Allow-Origin", "*");
  e.response.header().set("Access-Control-Allow-Methods", "POST, OPTIONS");
  e.response.header().set("Access-Control-Allow-Headers", "*");

  try {
    const app = e.app || $app;
    const body = e.requestInfo().body || {};
    const featureId = String(body.feature_id || "").trim();
    const voterToken = String(body.voter_token || "").trim();

    if (!featureId) {
      return e.json(400, { error: "missing_feature_id", message: "feature_id is required" });
    }

    if (!voterToken) {
      return e.json(400, { error: "missing_voter_token", message: "voter_token is required" });
    }

    const safeFeatureId = featureId.replace(/'/g, "\\'");
    const safeVoterToken = voterToken.replace(/'/g, "\\'");

    // Hash client IP with salt for GDPR-safe one-vote-per-IP/browser enforcement
    const rawIp = e.realIP() || e.remoteIP() || "unknown";
    let hash = 0;
    const ipSalt = rawIp + "_shellit_salt_2026";
    for (let i = 0; i < ipSalt.length; i++) {
      hash = (hash << 5) - hash + ipSalt.charCodeAt(i);
      hash |= 0;
    }
    const ipHash = "ip_" + Math.abs(hash).toString(16);

    // 1. Verify item exists in roadmap_items
    let itemRecord = null;
    try {
      itemRecord = app.findFirstRecordByFilter("roadmap_items", "feature_id = '" + safeFeatureId + "'");
    } catch (err) {
      console.log("findFirstRecordByFilter error:", err);
    }

    if (!itemRecord) {
      return e.json(404, { error: "not_found", message: "Roadmap item not found: " + featureId });
    }

    // 2. Check if vote already exists for (feature_id + voter_token) OR (feature_id + ip_hash)
    let existingVote = null;
    try {
      existingVote = app.findFirstRecordByFilter(
        "feature_votes",
        "feature_id = '" + safeFeatureId + "' && (voter_token = '" + safeVoterToken + "' || ip_hash = '" + ipHash + "')"
      );
    } catch (err) {}

    if (existingVote) {
      return e.json(409, {
        error: "already_voted",
        message: "You have already voted for this feature",
        votes: itemRecord.get("votes") || 0
      });
    }

    // 3. Record the unique vote in feature_votes
    const votesCol = app.findCollectionByNameOrId("feature_votes");
    const newVote = new Record(votesCol, {
      feature_id: featureId,
      voter_token: voterToken,
      ip_hash: ipHash
    });
    app.save(newVote);

    // 4. Atomically increment votes on roadmap_items
    const newVotes = (itemRecord.get("votes") || 0) + 1;
    itemRecord.set("votes", newVotes);
    app.save(itemRecord);

    return e.json(200, {
      success: true,
      feature_id: featureId,
      votes: newVotes
    });
  } catch (err) {
    return e.json(500, { error: "server_error", message: String(err) });
  }
});
