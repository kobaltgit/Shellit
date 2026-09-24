import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://shellit.top',
  integrations: [
    starlight({
      title: 'Shellit Docs',
      components: {
        SiteTitle: './src/components/starlight/SiteTitle.astro',
        ThemeSelect: './src/components/starlight/ThemeSelect.astro',
        LanguageSelect: './src/components/starlight/LanguageSelect.astro',
      },
      social: {
        github: 'https://github.com/kobaltgit/Shellit',
      },
      customCss: [
        './src/styles/starlight-custom.css',
      ],
      defaultLocale: 'root',
      locales: {
        root: {
          label: 'English',
          lang: 'en',
        },
        ru: {
          label: 'Русский',
          lang: 'ru',
        },
      },
      sidebar: [
        {
          label: 'Getting Started',
          translations: {
            ru: 'Начало работы',
          },
          autogenerate: { directory: 'getting-started' },
        },
        {
          label: 'Security & Vault',
          translations: {
            ru: 'Безопасность',
          },
          autogenerate: { directory: 'security' },
        },
        {
          label: 'Self-Hosted Sync',
          translations: {
            ru: 'Синхронизация',
          },
          autogenerate: { directory: 'sync' },
        },
        {
          label: 'AI & MCP Gateway',
          translations: {
            ru: 'ИИ и MCP',
          },
          autogenerate: { directory: 'ai' },
        },
        {
          label: 'Plugin Ecosystem',
          translations: {
            ru: 'Экосистема плагинов',
          },
          autogenerate: { directory: 'plugins' },
        },
      ],
    }),
    tailwind({
      applyBaseStyles: false,
    }),
  ],
  vite: {
    build: {
      cssCodeSplit: false,
      rollupOptions: {
        maxParallelFileOps: 2,
      },
    },
    server: {
      watch: {
        usePolling: false,
      },
    },
  },
});
