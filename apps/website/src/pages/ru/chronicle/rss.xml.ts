import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

function escapeXml(unsafe: string): string {
  return unsafe.replace(/[<>&'"]/g, (c) => {
    switch (c) {
      case '<':
        return '&lt;';
      case '>':
        return '&gt;';
      case '&':
        return '&amp;';
      case "'":
        return '&apos;';
      case '"':
        return '&quot;';
      default:
        return c;
    }
  });
}

export const GET: APIRoute = async () => {
  const acts = await getCollection('chronicle', ({ data }) => data.lang === 'ru');
  const sorted = acts.sort((a, b) => a.data.actNumber - b.data.actNumber);

  const rssItems = sorted
    .map((act) => {
      const slug = act.id.replace(/^ru\//, '').replace(/\.md$/, '');
      const url = `https://shellit.top/ru/chronicle/${slug}/`;
      const pubDate = new Date(act.data.pubDate).toUTCString();
      const categories = act.data.tags
        .map((tag) => `      <category>${escapeXml(tag)}</category>`)
        .join('\n');

      return `    <item>
      <title>${escapeXml(act.data.title)}</title>
      <link>${url}</link>
      <guid isPermaLink="true">${url}</guid>
      <pubDate>${pubDate}</pubDate>
      <description><![CDATA[${act.data.description}]]></description>
${categories}
    </item>`;
    })
    .join('\n');

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Летопись Shellit | Архитектура и разработка</title>
    <description>Тематические главы с разбором архитектурных решений, отладки багов, перекрестного аудита нейросетей и веб-летописи.</description>
    <link>https://shellit.top/ru/chronicle/</link>
    <atom:link href="https://shellit.top/ru/chronicle/rss.xml" rel="self" type="application/rss+xml" />
    <language>ru</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
${rssItems}
  </channel>
</rss>`;

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
    },
  });
};
