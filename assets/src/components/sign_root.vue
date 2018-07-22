<template>
    <div class="main">
        <Login @view-self="whitelistOpen = false; openUsername = username" @view-whitelist="loadWhitelist(); openUsername = null; whitelistOpen = true" />

        <div class="contents">
            <template v-if="openUsername">
                <h2>User {{ openUsername }}</h2>

                <div v-if="usernames.includes(openUsername)" class="identification">
                    <p class="login-title">Set public data</p>

                    <el-input v-model="publicName" placeholder="Full name">
                        <el-button slot="append" @click="() => {}">Set public name</el-button>
                    </el-input>

                    <el-input v-model="websiteUrl" placeholder="Webpage URL">
                        <el-button slot="append" @click="() => {}">Add webpage</el-button>
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
            <template v-else-if="whitelistOpen">
                <h2>Whitelist {{ whitelistUrl }}</h2>

                <el-input v-model="searchUsername" @keyup.native.enter="setOpenUsername(searchUsername)" placeholder="Username" style="width: 400px;">
                    <el-button slot="append" icon="el-icon-caret-right" @click="setOpenUsername(searchUsername)"></el-button>
                </el-input>

                <a v-for="whitelistUsername in whitelistUsernames" :key="whitelistUsername" @click="setOpenUsername(whitelistUsername)" href="#">
                    {{ whitelistUsername }}
                </a>
            </template>
            <template v-else>
                <div class="vote-section" v-for="(message, index) in displayMessages" :key="index">
                    <template v-if="message.name === 'vote'">
                        <inline-node :node="message" size="large" />
                        <results :results="{ mean : message.choice }" :unit="message.unit" size="small"></results>
                    </template>
                    <template v-else>
                        <p class="vote-title">{{ message.name }}</p>
                        <p class="vote-key">{{ message.key.join(', ') }}</p>
                        <p v-for="item in message.items" :key="item.key"><b>{{ item.key }}</b>: {{ item.value }}</p>
                    </template>
                </div>

                <el-button type="success" @click="signItems" v-if="messages.length > 0">Sign with {{ username }}</el-button>
            </template>
        </div>
    </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex'
import { Row, Col, Slider, Button, Select, Option, Input } from 'element-ui'
import InlineNode from './generic/inline_node.vue'
import Results from './generic/results.vue'
import Login from './login.vue'

export default {
    components: {
        elRow: Row,
        elCol: Col,
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        Login,
        InlineNode,
        Results,
    },
    data () {
        return {
            whitelistOpen: false,
            openUsername: null,
            searchUsername: null,
            trustRatio: 50,
            publicName: '',
            websiteUrl: ''
        }
    },
    computed: {
        ...mapGetters(['colorOnSpectrum']),
        ...mapState('sign', ['messages', 'randomWords', 'username', 'whitelistUrl', 'whitelistUsernames', 'userMessages']),
        ...mapGetters('sign', ['keys', 'currentKey']),
        usernames () {
            return this.keys.map(k => k.username)
        },
        displayMessages () {
            let formatKey = (x) => {
                x = x.replace(/_/g, ' ')
                return x.charAt(0).toUpperCase() + x.slice(1);
            }

            return this.messages.map((message) => {
                let specifiedKeys = message.keys || []
                let missingKeys = Object.keys(message).filter(k => !specifiedKeys.includes(k))
                let keys = specifiedKeys.concat(missingKeys)

                let items = keys.filter(k => !['name', 'key', 'keys'].includes(k)).map(key => {
                    return {
                        key: formatKey(key),
                        value: this.formatValue(message[key])
                    }
                })

                return {
                    ...message,
                    name: formatKey(message.name),
                    key: message.key.map(x => formatKey(x)),
                    items: items
                }
            })
        },
        trustText () {
            return this.trustRatio <= 50 ? 'Distrust' : 'Trust'
        },
        trustColor () {
            return this.colorOnSpectrum(this.trustRatio / 100)
        }
    },
    methods: {
        ...mapActions('sign', ['signItems', 'loadWhitelist', 'setTrust', 'loadMessages']),
        setOpenUsername (username) {
            username = username.trim(' ').toLowerCase()
            this.openUsername = username
            this.whitelistOpen = false
            this.loadMessages(username)
        },
        formatValue (value) {
            if (!value && value !== 0)
                return '/'
            return value
        }
    }
}
</script>
