<template>
    <div class="main">
        <div class="contents">
            <template v-if="openUsername">
                <h2>User {{ openUsername }}</h2>

                <div v-if="usernames.includes(openUsername)" class="identification">
                    <p class="login-title">Set public data</p>

                    <el-input v-model="publicName" placeholder="Full name">
                        <el-button slot="append" @click="login">Set public name</el-button>
                    </el-input>

                    <el-input v-model="websiteUrl" placeholder="Webpage URL">
                        <el-button slot="append" @click="login">Add webpage</el-button>
                    </el-input>
                </div>
                <div v-else>
                    <el-slider v-model="trustRatio" style="width: 200px; display: inline-block; vertical-align: middle;"></el-slider>
                    <span :style="{ color: '#' + trustColor }" style="width: 80px; display: inline-block; margin-left: 20px; font-size: 16px;">{{ trustText }}</span>
                    <el-button type="success" @click="setTrust({ username: openUsername, ratio: trustRatio / 100 }); openUsername = null">Set trust level</el-button>
                </div>

                <div class="message" v-for="message in userMessages" :key="message.key">
                    <p class="message-row" v-for="key in Object.keys(message.data).sort()" :key="key"><b>{{ key }}</b>: {{ formatValue(message.data[key]) }}</p>
                </div>
            </template>
            <template v-else-if="isLoginShown">
                <template v-if="randomWords === null">
                    <div class="vote-section" v-if="usernames.length > 0">
                        <p class="login-title">Current user</p>

                        <el-select class="select-user" v-model="currentUsername" placeholder="Select user">
                            <el-option v-for="username in usernames" :key="username" :label="username" :value="username" />
                        </el-select>

                        <el-button class="main-button" size="small" @click="openUsername = username">View {{ username }}</el-button>

                        <el-button class="main-button" size="small" type="danger" @click="removeUsername">Logout</el-button>
                    </div>

                    <div class="vote-section">
                        <p class="login-title">Login</p>

                        <el-input class="login-field" v-model="loginWords" @keyup.native.enter="login" placeholder="Login with 13 words">
                            <el-button slot="append" icon="el-icon-caret-right" @click="login"></el-button>
                        </el-input>
                    </div>
                </template>
                <div v-else class="vote-section">
                    <p class="login-title">Use the following 13 words to login with <b>{{ newKey.username }}</b>:</p>
                    <div class="login-words">{{ randomWords }}</div>
                    <p class="login-extra">This data never leaves your browser!</p>
                </div>
            </template>
            <template v-else-if="whitelistOpen">
                <h2>Whitelist {{ whitelistUrl }}</h2>

                <a v-for="whitelistUsername in whitelistUsernames" :key="whitelistUsername" @click="setOpenUsername(whitelistUsername)" href="#">
                    {{ whitelistUsername }}
                </a>
            </template>
            <template v-else>
                <div class="vote-section" v-for="(message, index) in displayMessages" :key="index">
                    <p class="vote-title">{{ message.name }}</p>
                    <p class="vote-key">{{ message.key.join(', ') }}</p>
                    <p v-for="item in message.items" :key="item.key"><b>{{ item.key }}</b>: {{ item.value }}</p>
                </div>
            </template>
        </div>

        <div class="footer">
            <div class="footer-contents">
                <template v-if="openUsername">
                    <el-button type="primary" @click="openUsername = null">Close</el-button>
                </template>
                <template v-else-if="isLoginShown">
                    <template v-if="randomWords === null">
                        <el-button v-if="username && messages.length > 0" type="primary" @click="loginOpen = false">Choose {{ username }}</el-button>
                        <el-button @click="createUser">Create new user</el-button>
                        <el-button @click="loadWhitelist(); whitelistOpen = true">View whitelist</el-button>
                    </template>
                    <template v-else>
                        <el-button type="primary" @click="chooseUser">Done</el-button>
                        <el-button @click="wordsDownloaded = true; downloadIdentity();" :disabled="wordsDownloaded">Download words</el-button>
                    </template>
                </template>
                <template v-else-if="whitelistOpen">
                    <el-button type="primary" @click="whitelistOpen = false">Close</el-button>

                    <el-input v-model="searchUsername" @keyup.native.enter="setOpenUsername(searchUsername)" placeholder="Username" style="width: 400px;">
                        <el-button slot="append" icon="el-icon-caret-right" @click="setOpenUsername(searchUsername)"></el-button>
                    </el-input>
                </template>
                <template v-else>
                    <el-button type="success" @click="signItems" v-if="messages.length > 0">Sign with {{ username }}</el-button>
                    <el-button @click="chooseUser(); loginOpen = true;">Change user</el-button>
                    <el-button @click="loadWhitelist(); whitelistOpen = true">View whitelist</el-button>
                </template>
            </div>
        </div>
    </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex'
import { Row, Col, Slider, Button, Select, Option, Input } from 'element-ui'

export default {
    components: {
        elRow: Row,
        elCol: Col,
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input
    },
    data () {
        return {
            loginOpen: true,
            whitelistOpen: false,
            loginWords: '',
            wordsDownloaded: false,
            openUsername: null,
            searchUsername: null,
            trustRatio: 50,
            publicName: '',
            websiteUrl: ''
        }
    },
    watch: {
        username (newVal, oldVal) {
            if (newVal && !oldVal)
                this.loginOpen = false
        }
    },
    computed: {
        ...mapState('sign', ['messages', 'randomWords', 'username', 'whitelistUrl', 'whitelistUsernames', 'userMessages']),
        ...mapGetters('sign', ['keys', 'currentKey', 'newKey']),
        usernames () {
            return this.keys.map(k => k.username)
        },
        displayMessages () {
            let formatKey = (x) => {
                x = x.replace(/_/g, ' ')
                return x.charAt(0).toUpperCase() + x.slice(1);
            }

            return this.messages.map((message) => {
                let missingKeys = Object.keys(message).filter(k => !message.keys.includes(k))
                let keys = message.keys.concat(missingKeys)

                let items = keys.filter(k => !['name', 'key', 'keys'].includes(k)).map(key => {
                    return {
                        key: formatKey(key),
                        value: this.formatValue(message[key])
                    }
                })

                return {
                    name: formatKey(message.name),
                    key: message.key.map(x => formatKey(x)),
                    items: items
                }
            })
        },
        currentUsername: {
            get () {
                return this.username
            },
            set (v) {
                this.switchToUsername(v)
            }
        },
        isLoginShown () {
            return this.loginOpen || !this.whitelistOpen && this.messages.length === 0
        },
        trustText () {
            return this.trustRatio <= 50 ? 'Distrust' : 'Trust'
        },
        trustColor () {
            return this.$store.getters.colorOnSpectrum(this.trustRatio / 100)
        }
    },
    methods: {
        ...mapActions('sign', ['signItems', 'loadWhitelist', 'removeUsername', 'switchToUsername', 'downloadIdentity', 'createUser', 'chooseUser', 'setTrust', 'loadMessages']),
        login () {
            this.$store.dispatch('login', this.loginWords)
            this.loginWords = null
            this.wordsDownloaded = false
        },
        setOpenUsername (username) {
            username = username.trim(' ').toLowerCase()
            this.openUsername = username
            this.whitelistOpen = false
            this.loadMessages(username)
        },
        formatValue (value) {
            if (!value)
                return '/'
            return value
        }
    }
}
</script>

<style lang="less">
body {
    margin: 20px;
}

p {
    margin: 0;
}

a {
    color: inherit;
    text-decoration: none;
}

h2 {
    font-size: 26px;
    font-weight: normal;
    margin-bottom: 40px;
}

.main {
    width: 600px;
    min-height: 100px;
}

.vote-section {
    padding: 20px 0px;

    &:first-child {
        padding-top: 0px;
    }
}

.vote-title {
    font-size: 22px;
    margin-bottom: 2px;
}

.vote-key {
    font-size: 15px;
    margin-bottom: 10px;
    color: #666;
}

.login-title {
    font-size: 18px;
    margin-bottom: 15px;
}

.node {
    display: inline;
    background-color: #c3e0ec;
    padding: 5px 10px;
    border-radius: 2px;
    line-height: 40px;
    word-break: break-all;
    vertical-align: middle;
}

.score {
    display: inline-block;
    background-color: red;
    text-align: center;
    padding: 5px 20px;
    vertical-align: middle;

    .choice {
        font-size: 18px;
    }

    .unit {
        font-size: 12px;
    }
}

.reference-arrow {
    font-size: 30px;
    vertical-align: middle;
}


.select-user {
	vertical-align: middle;
}

.main-button {
    margin-left: 15px;
}

.login-words {
	margin-top: 10px;
	font-size: 22px;
}

.login-extra {
    margin-top: 10px;
    color: #0cb704;
    font-size: 13px;
    font-weight: bold;
}

.contents {
    margin-bottom: 100px;
}

.footer {
    margin-top: 80px;
}

.footer-contents {
    position: fixed;
    bottom: 0;
    width: 100%;
    background-color: white;
    padding: 20px 0px;
}

.message {
    background-color: #eee;
    padding: 10px;
    margin: 20px 0px;
}

.message-row {
    font-size: 13px;
}

.identification {
    max-width: 400px;

    .el-input {
        margin-bottom: 20px;
    }

    .el-button {
        width: 150px;
        text-align: left;
    }
}
</style>