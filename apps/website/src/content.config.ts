import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: glob({
      pattern: '**/*.{md,mdx}',
      base: './src/content/docs',
    }),
    schema: docsSchema(),
  }),
  chronicle: defineCollection({
    loader: glob({
      pattern: '**/*.{md,mdx}',
      base: './src/content/chronicle',
    }),
    schema: z.object({
      title: z.string(),
      description: z.string(),
      actNumber: z.number(),
      period: z.string(),
      pubDate: z.coerce.date(),
      readingTime: z.string(),
      stage: z.string(),
      relatedBugs: z.array(z.string()).default([]),
      tags: z.array(z.string()).default([]),
      lang: z.enum(['en', 'ru']).default('en'),
    }),
  }),
};
