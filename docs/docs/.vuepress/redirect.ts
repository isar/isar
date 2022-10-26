import { defineClientConfig } from '@vuepress/client'
import { locales } from './locales'

export default defineClientConfig({
    enhance({ app, router, siteData }) {
        router.beforeEach((to, from) => {
            // open vuepress for the first time
            let isFirstStart = to.fullPath == from.fullPath

            // Whether the home page is about to be displayed
            let isHome = to.fullPath == "/"

            if (typeof navigator != 'undefined' && isFirstStart && isHome) {
                const lang = navigator.language.split("-")[0].toLowerCase()

                if (lang != "en" && locales.some((l) => l.code === lang)) {
                    const redirectUrl = "/" + lang + "/"
                    // Avoid infinite redirection
                    if (to.fullPath != redirectUrl) {
                        return redirectUrl
                    }
                }
            }
        })
    }
})