import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'structured_logger',
  tagline: 'Logging estruturado para Flutter com sinks plugáveis',
  favicon: 'img/logo.svg',

  url: 'https://structured-logger.altamir.dev',
  baseUrl: '/',

  organizationName: 'Altamir',
  projectName: 'structured_logger',

  onBrokenLinks: 'throw',

  markdown: {
    format: 'md',
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'pt-BR',
    locales: ['pt-BR', 'en'],
    localeConfigs: {
      'pt-BR': {
        label: 'Português',
      },
      en: {
        label: 'English',
      },
    },
  },

  presets: [
    [
      'classic',
      {
        docs: {
          path: '../docs',
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/Altamir/structured_logger/tree/master/docs/',
          exclude: ['**/blog/**', 'en/**', 'adr/**'],
        },
        blog: {
          path: 'blog',
          routeBasePath: 'blog',
          showReadingTime: true,
          blogTitle: 'Blog',
          blogDescription: 'Artigos sobre structured_logger e logging em Flutter',
          postsPerPage: 10,
          editUrl:
            'https://github.com/Altamir/structured_logger/tree/master/website/blog/',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/social-card.svg',
    navbar: {
      title: 'structured_logger',
      logo: {
        alt: 'structured_logger',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentação',
        },
        {to: 'blog', label: 'Blog', position: 'left'},
        {
          type: 'localeDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/Altamir/structured_logger',
          label: 'GitHub',
          position: 'right',
        },
        {
          href: 'https://pub.dev/packages/structured_logger',
          label: 'pub.dev',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentação',
          items: [
            {label: 'Introdução', to: '/'},
            {label: 'Início rápido', to: '/getting-started/quick-start'},
            {label: 'Integração Seq', to: '/guides/seq-integration'},
          ],
        },
        {
          title: 'Comunidade',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/Altamir/structured_logger',
            },
            {
              label: 'pub.dev',
              href: 'https://pub.dev/packages/structured_logger',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} structured_logger. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml', 'bash', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;