import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://shellit.top',
  redirects: {
    '/docs': '/getting-started/quick-start/',
    '/ru/docs': '/ru/getting-started/quick-start/',
    '/getting-started': '/getting-started/quick-start/',
    '/ru/getting-started': '/ru/getting-started/quick-start/',
    '/security': '/security/prod-guard/',
    '/ru/security': '/ru/security/prod-guard/',
    '/sync': '/sync/self-hosted-server/',
    '/ru/sync': '/ru/sync/self-hosted-server/',
    '/ai': '/ai/gemini-snippets/',
    '/ru/ai': '/ru/ai/gemini-snippets/',
    '/plugins': '/plugins/creating-plugins/',
    '/ru/plugins': '/ru/plugins/creating-plugins/',
    '/devlog': '/chronicle/',
    '/ru/devlog': '/ru/chronicle/',
  },
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
    sitemap({
      filter: (page) =>
        !page.includes('/admin') &&
        !page.includes('/404') &&
        !page.includes('/api'),
      i18n: {
        defaultLocale: 'root',
        locales: {
          root: 'en',
          ru: 'ru',
        },
      },
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
