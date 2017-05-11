import Vue from 'vue'
import Vuex from 'vuex'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'

import 'element-ui/lib/theme-default/index.css'
import velocity from 'velocity-animate'

Vue.use(Vuex)
Vue.use(VueRouter)
Vue.use(ElementUI, { locale })
import { sync } from 'vuex-router-sync'
import loginComponent from '../vue/pages/login.vue'
import extensionComponent from '../vue/pages/extension.vue'
import injectComponent from '../vue/pages/inject.vue'
import finishLoginComponent from '../vue/pages/finish-login.vue'
import identityComponent from '../vue/pages/identity.vue'
import nodeComponent from '../vue/pages/node.vue'
import referenceComponent from '../vue/pages/reference.vue'
import App from '../vue/app.vue'

let store = require('store.js').default

const routes = [
    { path: '/', component: nodeComponent },
    { path: '/link', component: extensionComponent },
    { path: '/infuse', component: injectComponent },
    { path: '/login', component: loginComponent },
    { path: '/login/:token/new', component: finishLoginComponent },
    { path: '/identities/:username', component: identityComponent },
    { path: '/search/:query', component: nodeComponent, name: 'search' },
    { path: '/:key/references', component: referenceComponent },
    { path: '/:key/references/:referenceKey', component: referenceComponent },
    { path: '/:key/:unit', component: nodeComponent },
    { path: '/:key', component: nodeComponent }
]

const router = new VueRouter({
    mode: 'history',
    routes: routes
})
sync(store, router)

const app = new Vue({
    router: router,
    store: store,
    components: { App },
    data: function() {
        this.$store.dispatch('fetchIdentity', 'me')

        return {}
    }
}).$mount('#app')

if (process.env.NODE_ENV == 'production') {
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', function() {
            navigator.serviceWorker.register('/serviceworker.js').then(function(registration) {
                // console.log('ServiceWorker registration successful with scope: ', registration.scope);
            }).catch(function(err) {
                console.log('ServiceWorker registration failed: ', err);
            });
        });
    }
}