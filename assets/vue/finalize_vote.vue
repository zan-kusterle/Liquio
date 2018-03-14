<template>
    <div>
        <login v-show="loginOpen" :usernames="usernames" :username="username" @login="addSeed" @logout="removeUsername" @switch="switchToUsername"></login>

        <span v-if="loginOpen" slot="footer" class="dialog-footer">
            <el-button type="primary" @click="loginOpen = false">Choose user</el-button>
        </span>

        <template v-if="!loginOpen">
            <div class="vote-section">
                <p class="vote-title">Voting with user <b>{{ username }}</b></p>
            </div>

            <div class="vote-section">
                <p class="vote-title">Vote</p>

                <div class="score" :style="{ backgroundColor: getColor(votes.node.type === 'spectrum' ? votes.node.choice : null) }">
                    <p class="choice">{{ votes.node.type === 'spectrum' ? `${Math.round(votes.node.choice * 100)}%` : votes.node.choice }}</p>
                    <p class="unit">{{ votes.node.unit }}</p>
                </div>
                <p class="node">{{ votes.node.key }}</p>
            </div>

            <div class="vote-section" v-if="votes.reference">
                <p class="vote-title">Reference</p>

                <div class="score" :style="{ backgroundColor: getColor(votes.reference.relevance) }">
                    <p class="choice">{{ Math.round(votes.reference.relevance * 100) }}%</p>
                </div>
                <p class="node">{{ votes.reference.key }}</p>
                <i class="el-icon-caret-right reference-arrow"></i>
                <p class="node">{{ votes.reference.referenceKey }}</p>
            </div>

            <span slot="footer" class="dialog-footer">
                <el-button type="success" @click="vote">Confirm</el-button>
                <el-button type="primary" @click="loginOpen = true">Switch user</el-button>
                <el-button @click="$emit('close')">Cancel</el-button>
            </span>
        </template>
    </div>
</template>

<script>
import { Slider, Button, Select, Option, Input } from 'element-ui'
import Login from '../vue/login.vue'
import storage from 'shared/storage'
import { keypairFromSeed } from 'shared/identity'
import nacl from 'tweetnacl'
import * as Api from 'shared/api_client'
import { decodeBase64, stringToBytes } from 'shared/utils'
import { getColor } from 'shared/votes'

export default {
    props: {
        votes: { type: Object }
    },
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        login: Login
    },
    data () {
        return {
            loginOpen: true,
            seeds: [],
            username: null
        }
    },
    watch: {
        username (newVal, oldVal) {
            if (newVal && !oldVal)
                this.loginOpen = false
        }
    },
    created () {
        if (IS_EXTENSION) {
            storage.getSeeds().then(seeds => {
                if (seeds.length > 0) {
                    seeds.forEach(seed => {
                        if (seed.length > 0) {
                            this.seeds.push(seed)
                        }
                    })
                }
            })
            
            storage.getUsername().then(username => {
                this.username = username
            })
        }
    },
    computed: {
        keypairs () {
            return this.seeds.map(keypairFromSeed).filter(k => k)
        },
        usernames () {
            return this.keypairs.map(k => k.username)
        },
        currentKeypair () {
            return this.keypairs.find(k => k.username === this.username)
        }
    },
    methods: {
        getColor: getColor,
        vote () {
            let keypair = this.currentKeypair
            if (!keypair)
                return

            let getSignature = (keypair, message) => {
                let messageHash = nacl.hash(stringToBytes(message))
                return nacl.sign.detached(messageHash, this.currentKeypair.secretKey)
            }
            
            let voteMessage = ['setVote', this.votes.node.key, this.votes.node.unit, this.votes.node.choice.toFixed(5)].join(' ')

            Api.setVote(keypair.publicKey, getSignature(this.keypair, voteMessage), this.votes.node.key, this.votes.node.unit, new Date(), this.votes.node.choice, (r) => {
                if (this.votes.reference) {
                    let referenceMessage = ['setReferenceVote', this.votes.reference.key, this.votes.reference.referenceKey, this.votes.reference.relevance.toFixed(5)].join(' ')
                    
                    Api.setReferenceVote(keypair.publicKey, getSignature(this.keypair, referenceMessage), this.votes.reference.key, this.votes.reference.referenceKey, this.votes.reference.relevance, (r) => {
                        this.$emit('vote')
                    })
                } else {
                    this.$emit('vote')
                }
            })
        },
        addSeed (seed) {
            storage.addSeed(seed)
            this.seeds.push(seed)

            this.username = this.usernames[this.usernames.length - 1]
            storage.setUsername(this.username)
            this.$emit('set-username', this.username)
        },
        removeUsername (username) {
            let index = this.usernames.indexOf(username)
            if (index >= 0) {
                storage.removeSeed(this.seeds[index])
                this.seeds.splice(index, 1)

                this.username = index > 0 ? this.seeds[index - 1] : null
                storage.setUsername(this.username)
                this.$emit('set-username', this.username)
            }
		},
		switchToUsername (username) {
            storage.setUsername(username)
            this.username = username
            this.$emit('set-username', this.username)
        }
    }
}
</script>
