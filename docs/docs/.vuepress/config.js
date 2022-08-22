const { viteBundler } = require("@vuepress/bundler-vite");
const { defaultTheme } = require("@vuepress/theme-default");
const { shikiPlugin } = require("@vuepress/plugin-shiki");

module.exports = {
  head: [
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "256x256",
        href: `/icon-256x256.png`,
      },
    ],
    [
      "link",
      {
        rel: "icon",
        type: "image/png",
        sizes: "512x512",
        href: `/icon-512x512.png`,
      },
    ],
    [
      "link",
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Montserrat:wght@800&display=swap",
      },
    ],
    ["meta", { name: "application-name", content: "Isar Database" }],
    ["meta", { name: "apple-mobile-web-app-title", content: "Isar Database" }],
    [
      "meta",
      { name: "apple-mobile-web-app-status-bar-style", content: "black" },
    ],
    [
      "script",
      {
        async: "",
        src: "https://www.googletagmanager.com/gtag/js?id=G-NX9QJRWFGX",
      },
    ],
    [
      "script",
      {},
      `window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-NX9QJRWFGX');`,
    ],
    [
      "script",
      {},
      `(function(c,l,a,r,i,t,y){
        c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
      })(window, document, "clarity", "script", "ciawnmxjdh");`,
    ],
  ],
  locales: {
    "/": {
      lang: "en-US",
      title: "Isar Database",
      description: "Super Fast Cross Platform Database for Flutter",
    },
  },
  bundler: viteBundler({}),
  theme: defaultTheme({
    logo: "/isar.svg",
    repo: "isar/isar",
    docsRepo: "isar/docs",
    docsDir: "docs",
    contributors: true,
    navbar: [
      {
        text: "pub.dev",
        link: "https://pub.dev/packages/isar",
      },
      {
        text: "API",
        link: "https://pub.dev/documentation/isar/latest/isar/isar-library.html",
      },
    ],
    sidebarDepth: 1,
    sidebar: [
      {
        text: "TUTORIALS",
        children: [
          {
            text: "Quickstart",
            link: "/tutorials/quickstart.md",
          },
          {
            text: "Contacts App",
            link: "/tutorials/contacts_app.md",
          },
        ],
      },
      {
        text: "CONCEPTS",
        children: [
          "/schema.md",
          "/crud.md",
          "/queries.md",
          "/transactions.md",
          "/indexes.md",
          "/links.md",
          "/watchers.md",
          "/type_converters.md",
          "/limitations.md",
          "/faq.md",
        ],
      },
      {
        text: "RECIPES",
        children: ["/recipes/full_text_search.md", "/recipes/multi_isolate.md"],
      },
      {
        text: "Sample Apps",
        link: "https://github.com/isar/samples",
      },
    ],
  }),
  markdown: {
    code: {
      lineNumbers: false,
    },
  },
  plugins: [
    [
      shikiPlugin({
        theme: "one-dark-pro",
      }),
    ],
  ],
};
