<template>
    <div class="login">
        <div v-if="randomWords === null && !loginOpen" @click="$emit('view-whitelist')">
            <i class="el-icon-tickets"></i> 42 users on whitelist
        </div>

        <div v-if="randomWords !== null" class="login__words-wrap">
            <p class="login__title">Use the following 13 words to login with <b>{{ newKey.username }}</b>:</p>
            <div class="login__words">{{ randomWords }}</div>
            <p class="login__extra">This data is never transferred over the network.</p>

            <el-button @click="loginOpen = true; chooseUser()" type="primary" size="small">I wrote the words down</el-button>
            <el-button @click="downloadWords()" :disabled="wordsDownloaded" size="small">Download words</el-button>
        </div>
        <div v-else-if="loginOpen" class="login__login-wrap">
            <el-input v-model="loginWords" @keyup.native.enter="loginWithWords" placeholder="Login with 13 words" class="login__words-input" />
            <el-button @click="loginWithWords" type="primary">Sign in</el-button>
        </div>
        <div v-else-if="username" class="login__current-wrap">
            <p @click="$emit('view-self')" class="login__username">{{ username }}</p>
            <el-button size="small" type="danger" @click="removeUsername(username)">Logout</el-button>
        </div>
        <div v-else>
            <el-button @click="loginOpen = true" type="primary" size="small">Sign in</el-button>
            <el-button @click="createUser" type="success" size="small">Sign up</el-button>
        </div>
    </div>
</template>

<script>
import { Button, Select, Option, Input } from 'element-ui'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
    },
    data () {
        return {
            loginWords: '',
            wordsDownloaded: false,
            loginOpen: false,
        }
    },
    computed: {
        ...mapState('sign', ['randomWords', 'username', 'whitelistUrl']),
        ...mapGetters('sign', ['newKey']),
    },
    methods: {
        ...mapActions('sign', ['login', 'removeUsername', 'downloadIdentity', 'createUser', 'chooseUser']),
        loginWithWords () {
            this.login(this.loginWords)
            this.loginWords = ''
            this.wordsDownloaded = false
            this.loginOpen = false
        },
        downloadWords () {
            this.wordsDownloaded = true
            this.downloadIdentity()
            this.loginOpen = true
            this.chooseUser()
        }
    }
}
</script>
