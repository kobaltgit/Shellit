/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  try {
    const rows = arrayOf(new Record);
    app.recordQuery("site_visits").all(rows);

    const now = new Date();
    const dayBuckets = [
      { daysAgo: 0, count: 15 },
      { daysAgo: 1, count: 12 },
      { daysAgo: 2, count: 10 },
      { daysAgo: 3, count: 8 },
      { daysAgo: 4, count: 7 },
      { daysAgo: 5, count: 6 },
      { daysAgo: 6, count: 4 }
    ];

    let idx = 0;
    for (const bucket of dayBuckets) {
      for (let i = 0; i < bucket.count && idx < rows.length; i++) {
        const id = rows[idx].id;
        idx++;
        const d = new Date(now.getTime() - (bucket.daysAgo * 86400000) - (i * 3600000));
        const dtStr = d.toISOString().replace('T', ' ');
        app.db().newQuery("UPDATE site_visits SET created = {:dt}, updated = {:dt} WHERE id = {:id}")
          .bind({ dt: dtStr, id: id })
          .execute();
      }
    }
  } catch (e) {
    console.error("Distribute error:", e);
  }
});
