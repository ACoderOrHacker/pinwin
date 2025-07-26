import { defineConfig } from 'vitepress'

export default defineConfig({
  base: '/pinwin/',
  head: [
    ["link", { rel: "icon", href: `/pinwin/logo.ico` }],
  ],
  title: "Pinwin",
  description: "A tool for pining windows to the top of your screen",
  themeConfig: {
    logo: '/logo.png',
    siteTitle: 'Pinwin',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Downloads', link: '/downloads/' }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/ACoderOrHacker/pinwin' }
    ]
  }
})
