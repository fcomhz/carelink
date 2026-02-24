import * as bootstrap from 'bootstrap'

export default defineNuxtPlugin(() => {
    console.log('Bootstrap JS Plugin Loaded')
    return {
        provide: {
            bootstrap
        }
    }
})
