// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  devtools: { enabled: true },
  vite:{
    server:{
      hmr: {
        protocol:'ws',
        host: '0.0.0.0',
      }
    }
  }
})
