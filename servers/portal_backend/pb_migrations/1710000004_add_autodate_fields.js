/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collections = ["site_visits", "release_snapshots", "feedback_reports", "roadmap_items", "plugins"];
  for (const name of collections) {
    try {
      const col = app.findCollectionByNameOrId(name);
      if (!col) continue;

      let changed = false;
      const createdField = col.fields.getByName("created");
      if (!createdField) {
        col.fields.add(new AutodateField({
          name: "created",
          onCreate: true,
        }));
        changed = true;
      }

      const updatedField = col.fields.getByName("updated");
      if (!updatedField) {
        col.fields.add(new AutodateField({
          name: "updated",
          onCreate: true,
          onUpdate: true,
        }));
        changed = true;
      }

      if (changed) {
        app.save(col);
      }
    } catch (err) {
      console.error("Migration error on collection " + name + ":", err);
    }
  }

  // Backfill timestamps
  try {
    const now = new Date();
    const nowIso = now.toISOString().replace('T', ' ');

    app.db().newQuery("UPDATE site_visits SET created = {:now} WHERE created IS NULL OR created = ''").bind({ now: nowIso }).execute();
    app.db().newQuery("UPDATE site_visits SET updated = {:now} WHERE updated IS NULL OR updated = ''").bind({ now: nowIso }).execute();

    app.db().newQuery("UPDATE release_snapshots SET created = {:now} WHERE created IS NULL OR created = ''").bind({ now: nowIso }).execute();
    app.db().newQuery("UPDATE release_snapshots SET updated = {:now} WHERE updated IS NULL OR updated = ''").bind({ now: nowIso }).execute();

    app.db().newQuery("UPDATE feedback_reports SET created = {:now} WHERE created IS NULL OR created = ''").bind({ now: nowIso }).execute();
    app.db().newQuery("UPDATE feedback_reports SET updated = {:now} WHERE updated IS NULL OR updated = ''").bind({ now: nowIso }).execute();

    app.db().newQuery("UPDATE roadmap_items SET created = {:now} WHERE created IS NULL OR created = ''").bind({ now: nowIso }).execute();
    app.db().newQuery("UPDATE roadmap_items SET updated = {:now} WHERE updated IS NULL OR updated = ''").bind({ now: nowIso }).execute();

    app.db().newQuery("UPDATE plugins SET created = {:now} WHERE created IS NULL OR created = ''").bind({ now: nowIso }).execute();
    app.db().newQuery("UPDATE plugins SET updated = {:now} WHERE updated IS NULL OR updated = ''").bind({ now: nowIso }).execute();
  } catch (err) {
    console.error("Backfill error:", err);
  }
}, (app) => {
  // no-op rollback
});
