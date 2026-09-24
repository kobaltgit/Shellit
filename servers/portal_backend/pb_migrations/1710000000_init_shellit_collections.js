/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // 1. Collection: roadmap_items
  const roadmapCollection = new Collection({
    name: "roadmap_items",
    type: "base",
    listRule: "", // public read
    viewRule: "", // public read
    createRule: null, // admin only
    updateRule: "", // allow public to update votes
    deleteRule: null,
    fields: [
      { name: "feature_id", type: "text", required: true },
      { name: "title_en", type: "text", required: true },
      { name: "title_ru", type: "text", required: true },
      { name: "desc_en", type: "text" },
      { name: "desc_ru", type: "text" },
      { name: "status", type: "select", required: true, values: ["shipped", "in-progress", "planned"] },
      { name: "tag", type: "text" },
      { name: "votes", type: "number", min: 0 },
      { name: "order", type: "number" }
    ]
  });
  app.save(roadmapCollection);

  // 2. Collection: plugins
  const pluginsCollection = new Collection({
    name: "plugins",
    type: "base",
    listRule: "status = 'published'", // public read for approved
    viewRule: "status = 'published'",
    createRule: "", // allow community submission
    updateRule: null, // admin only
    deleteRule: null,
    fields: [
      { name: "name", type: "text", required: true },
      { name: "slug", type: "text", required: true },
      { name: "category", type: "select", required: true, values: ["AI & Automation", "DevOps", "Localization", "Themes", "Utilities"] },
      { name: "version", type: "text", required: true },
      { name: "author", type: "text" },
      { name: "description_en", type: "text" },
      { name: "description_ru", type: "text" },
      { name: "status", type: "select", required: true, values: ["published", "pending_review", "draft"] },
      { name: "tags", type: "json" },
      { name: "plugin_file", type: "file" },
      { name: "icon", type: "file" },
      { name: "downloads", type: "number", min: 0 }
    ]
  });
  app.save(pluginsCollection);

  // 3. Collection: feedback_reports
  const feedbackCollection = new Collection({
    name: "feedback_reports",
    type: "base",
    listRule: null, // admin only
    viewRule: null,
    createRule: "", // public submit
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "email", type: "email" },
      { name: "subject", type: "text", required: true },
      { name: "message", type: "text", required: true },
      { name: "category", type: "select", values: ["feature_request", "bug_report", "general"] },
      { name: "status", type: "select", values: ["new", "in_progress", "resolved", "archived"] },
      { name: "attachment", type: "file" }
    ]
  });
  app.save(feedbackCollection);
}, (app) => {
  // Rollback
  const roadmap = app.findCollectionByNameOrId("roadmap_items");
  if (roadmap) app.delete(roadmap);

  const plugins = app.findCollectionByNameOrId("plugins");
  if (plugins) app.delete(plugins);

  const feedback = app.findCollectionByNameOrId("feedback_reports");
  if (feedback) app.delete(feedback);
});
