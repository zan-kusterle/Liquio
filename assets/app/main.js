import Vue from 'vue'
import Vuex from 'vuex'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'
import VueI18n from 'vue-i18n'
import messages from 'app/texts'
import css from 'app/main.less'

require("font-awesome-webpack")

Vue.use(VueI18n)
Vue.use(Vuex)
Vue.use(VueRouter)
Vue.use(ElementUI, { locale })

import { sync } from 'vuex-router-sync'
import { CrossStorageHub } from 'cross-storage'
import demoComponent from 'pages/demo.vue'
import identityComponent from 'pages/identity.vue'
import indexComponent from 'pages/index.vue'
import searchComponent from 'pages/search.vue'
import nodeComponent from 'pages/node.vue'
import referenceComponent from 'pages/reference.vue'
import App from 'app.vue'
import store from 'store/store'

const routes = [
    { path: '/', component: indexComponent },
    { path: '/demo', component: demoComponent },
    { path: '/identities/:username', component: identityComponent },
    { path: '/search/:query', component: searchComponent, name: 'search' },
    { path: '/v/:key/references', component: referenceComponent },
    { path: '/v/:key/references/:referenceKey', component: referenceComponent },
    { path: '/v/:key/:unit', component: nodeComponent },
    { path: '/v/:key', component: nodeComponent }
]

const router = new VueRouter({
    mode: 'history',
    routes: routes
})
sync(store, router)

const i18n = new VueI18n({
    locale: 'en',
    messages: messages
})

const app = new Vue({
    router: router,
    store: store,
    i18n: i18n,
    components: { App },
    data: function() {
        return {}
    }
}).$mount('#app')

CrossStorageHub._set = function(params) {
    return localStorage.setItem('trustMetricURL', params.value)
}
CrossStorageHub._get = function(params) {
    if(params.keys[0] == 'usernames') {
        let seeds = store.getters.currentOpts.keypairs
        return seeds.map((k) => k.username).join(',')
    }
    return localStorage.getItem('trustMetricURL')
}
CrossStorageHub.init([
    { origin: /.*/, allow: ['get', 'set'] }
])

if (process.env.NODE_ENV === 'production') {
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', function() {
            navigator.serviceWorker.register('/serviceworker.js').then(function(registration) {
                // console.log('ServiceWorker registration successful with scope: ', registration.scope);
            }).catch(function(err) {
                console.log('ServiceWorker registration failed: ', err)
            })
        })
    }
}