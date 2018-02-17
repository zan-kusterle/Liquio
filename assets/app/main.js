import Vue from 'vue'
import Vuex from 'vuex'
import ElementUI from 'element-ui';
import locale from 'element-ui/lib/locale/lang/en'
import VueRouter from 'vue-router'
import VueI18n from 'vue-i18n'
import nacl from 'tweetnacl'
import { stringToBytes, encodeBase64 } from 'shared/utils'
import messages from 'app/texts'
import css from 'app/main.less'

require("font-awesome-webpack")

Vue.use(VueI18n)
Vue.use(Vuex)
Vue.use(VueRouter)
Vue.use(ElementUI, { locale })

import { sync } from 'vuex-router-sync'
import { CrossStorageHub } from 'cross-storage'
import demoComponent from 'demo.vue'
import identityComponent from 'identity.vue'
import indexComponent from 'index.vue'
import searchComponent from 'search.vue'
import nodeComponent from 'node.vue'
import referenceComponent from 'reference.vue'
import App from 'app.vue'
import store from 'app/store/store'

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
CrossStorageHub._get = function({ keys }) {
    if(keys[0] == 'publicKeys') {
        let keypairs = store.getters.currentOpts.keypairs
        return keypairs.map((k) => encodeBase64(k.publicKey)).join(',')
    } else if (keys[0] === 'signature') {
        let username = keys[1]
        let message = keys[2]

        let keypairs = store.getters.currentOpts.keypairs
        let keypair = keypairs.find(k => k.username === username)
        if (!keypair)
            return null
        
        let messageHash = nacl.hash(stringToBytes(message))
        let signature = nacl.sign.detached(messageHash, keypair.secretKey)
        return encodeBase64(signature)
    } else if (keys[0] === 'trustMetricURL') {
        return localStorage.getItem('trustMetricURL')
    }
    return null
}
CrossStorageHub.init([
    { origin: /.*/, allow: ['get', 'set'] }
])