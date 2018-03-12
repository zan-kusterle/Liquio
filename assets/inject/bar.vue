<template>
<div class="liquio-bar" @mouseup="isHovered = true" @mouseover="isHovered = true" @mouseout="isHovered = false">
    <el-dialog v-if="currentVotes" title="Finalize vote" :visible.sync="dialogVisible" width="60%">
        <login v-show="loginOpen" :usernames="usernames" :username="username" @login="addSeed" @logout="removeUsername" @switch="switchToUsername"></login>

        <span v-if="loginOpen" slot="footer" class="dialog-footer">
            <el-button @click="dialogVisible = false">Cancel</el-button>
            <el-button type="primary" @click="loginOpen = false">Choose user</el-button>
        </span>

        <template v-if="!loginOpen">
            <p class="liquio-bar__anchor-selection"><b>Voting on</b> {{ currentAnchor }}</p>

            <p><b>{{ currentVotes.node.key }}</b> {{ currentVotes.node.unit }}: {{ currentVotes.node.choice }}</p>

            <p>Voting with user <b>{{ username }}</b></p>

            <span slot="footer" class="dialog-footer">
                <el-button @click="dialogVisible = false">Cancel</el-button>
                <el-button type="primary" @click="loginOpen = true">Switch user</el-button>
                <el-button type="success" @click="vote">Cast vote</el-button>
            </span>
        </template>
    </el-dialog>

    <div class="liquio-bar__container" v-if="currentNode || currentAnchor || isHovered || !isHidden && !isUnavailable">
        <div class="liquio-bar__wrap">
            <a class="liquio-bar__score" :style="{ 'background': `#${color}` }" :href="`${LIQUIO_URL}/v/${encodeURIComponent(urlKey)}`">
                {{ ratingText }}
            </a>
            <div class="liquio-bar__toggle-voting" v-if="currentAnchor">
                <el-button size="small" @click="currentAnchor = null">Close</el-button>
            </div>
            <div class="liquio-bar__toggle-voting" v-else-if="currentVideoTime">
                <el-button size="small" @click="startVoting">Vote on video at {{ currentVideoTimeText }}</el-button>
            </div>
            <div class="liquio-bar__main">
                <div class="liquio-bar__vote" v-if="currentAnchor">
                    <div class="liquio-bar__vote-anchor">{{ currentAnchor }}</div>
                    <div class="liquio-bar__vote-node">
                        <el-input size="small" type="text" v-model="currentTitle" placeholder="Poll title" class="liquio-bar__vote-title" />
                        <el-select size="small" v-model="currentUnitValue" class="liquio-bar__vote-unit">
                            <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
                        </el-select>
                        <div class="liquio-bar__vote-choice">
                            <el-slider size="small" v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum" class="liquio-bar__vote-spectrum"></el-slider>
                            <el-input size="small" v-else v-model="currentChoice.quantity" type="number" class="liquio-bar__vote-quantity" />
                        </div>
                        <el-button size="small" @click="dialogVisible = true" class="liquio-bar__vote-button">Vote</el-button>
                    </div>
                </div>

                <div class="liquio-bar__current-node" v-else-if="currentNode">
                    <span style="vertical-align: middle;">{{ currentNode.title }}</span>
                    <div class="liquio-bar__embeds" v-html="embedsSvg"></div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import * as Api from 'shared/api_client'
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Login from '../vue/login.vue'
import { colorOnGradient, slug } from 'shared/votes'
import { allUnits } from 'shared/data'
import { usernameFromPublicKey } from 'shared/identity'
import { decodeBase64, stringToBytes } from 'shared/utils'
import * as client from 'shared/api_client'
import { keypairFromSeed } from 'shared/identity'
import nacl from 'tweetnacl'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elDialog: Dialog,
        login: Login
    },
    props: {
        urlKey: { type: String },
        isUnavailable: { type: Boolean },
        currentNode: { type: Object },
        currentSelection: { type: String },
        currentVideoTime: { type: Number }
    },
    data () {
        return {
            trustMetricUrl: process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html',
            node: null,

            currentAnchor: null,
            currentTitle: null,
            currentUnitValue: 'true',
            currentChoice: {
                spectrum: 50,
                quantity: 0
            },

            dialogVisible: false,
            loginOpen: false,

            seeds: [],
            username: null,

            isHidden: true,
            isHovered: false
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.allUnits = allUnits

        if (IS_EXTENSION) {
            browser.storage.local.get(['seeds', 'username']).then((data) => {
                if (data.seeds && data.seeds.length > 0) {
                    data.seeds.forEach(s => {
                        if (s && s.length > 0) {
                            this.seeds.push(s)
                        }
                    })
                }

                if (data.username) {
                    this.username = data.username
                }
            })

            browser.runtime.onMessage.addListener(request => {
                if (request.name === 'toggle') {
                    this.isHidden = !this.isHidden
                }
            })
        }
    },
    watch: {
        urlKey () {
            this.updateNode()
        },
        usernames () {
            this.updateNode()
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
        },
        ratingText () {
            return this.rating ? (Math.round(this.rating * 100) / 10).toFixed(1) : '?'
        },
        color () {
            if (!this.rating)
                return '33bae7'
            
            let red = 'ff2b2b',
                yellow = 'f9e26e',
                green = '43e643'
            return this.rating < 0.5 ? colorOnGradient(yellow, red, this.rating * 2) : colorOnGradient(green, yellow, (this.rating - 0.5) * 2)
        },
        embedsSvg () {
            if (!this.currentNode)
                return null
            let byUnits = this.currentNode.results.by_units
            let unitResults = byUnits[Object.keys(byUnits)[0]]
            return unitResults.embeds.value
        },
        rating () {
            if (!this.node)
                return null
            
            let units = this.node.results.by_units
            let spectrumUnitKeys = Object.keys(units).filter(k => units[k].type === 'spectrum')
            if (spectrumUnitKeys.length === 0)
                return null
            
            let bestUnitKey = spectrumUnitKeys.sort(k => units[k].turnout_ratio)[0]
            let reliabilityResults = units[bestUnitKey]
            if (!reliabilityResults)
                return null
            
            return reliabilityResults.average
        },
        currentUnit () {
            let unit = this.allUnits.find(u => u.value === this.currentUnitValue)
            unit.defaultValue = unit.type === 'spectrum' ? 50 : 0   
            return unit
        },
        activeAnchor () {
            return this.currentSelection || this.currentVideoTime
        },
        currentVotes () {
            if (!this.currentTitle || !this.currentUnit || !this.currentAnchor)
                return null
            
            return {
                node: {
                    key: this.currentTitle.replace(/\s/, '-'),
                    unit: this.currentUnit.text,
                    choice: this.currentUnit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                },
                reference: {
                    key: this.urlKey + '/' + slug(this.currentAnchor),
                    referenceKey: this.currentTitle.replace(/\s/, '-'),
                    relevance: 1.0
                }
            }
        },
        currentVideoTimeText () {
            let minutes = Math.floor(this.currentVideoTime / 60)
            let seconds = Math.floor(this.currentVideoTime - minutes * 60)
            return `${('00' + minutes).slice(-2)}:${('00' + seconds).slice(-2)}`
        }
    },
    methods: {
        updateNode () {
            let params = { depth: 2 }
            if (this.usernames.length > 0) {
                params.trust_usernames = this.usernames.join(',')
            }
            return new Promise((resolve, reject) => {
                Api.getNode(this.urlKey, params, (node) => {
                    this.node = node
                    this.$root.$emit('update-node', this.node)
                    resolve()
                })
            })
        },
        getSignature (keypair, message) {
            let messageHash = nacl.hash(stringToBytes(message))
            return nacl.sign.detached(messageHash, this.currentKeypair.secretKey)
        },
        vote () {
            let keypair = this.currentKeypair
            if (!keypair)
                return
            
            let voteMessage = ['setVote', this.currentVotes.node.key, this.currentVotes.node.unit, this.currentVotes.node.choice.toFixed(5)].join(' ')
            let referenceMessage = ['setReferenceVote', this.currentVotes.reference.key, this.currentVotes.reference.referenceKey, this.currentVotes.reference.relevance.toFixed(5)].join(' ')

            client.setVote(keypair.publicKey, this.getSignature(this.keypair, voteMessage), this.currentVotes.node.key, this.currentVotes.node.unit, new Date(), this.currentVotes.node.choice, (r) => {
                client.setReferenceVote(keypair.publicKey, this.getSignature(this.keypair, referenceMessage), this.currentVotes.reference.key, this.currentVotes.reference.referenceKey, this.currentVotes.reference.relevance, (r) => {
                    this.dialogVisible = false
                    this.currentAnchor = null

                    this.updateNode()
                })
            })
        },
        addSeed (seed) {
            this.seeds.push(seed)
            this.username = this.usernames[this.usernames.length - 1]
            browser.storage.local.set({ seeds: this.seeds, username: this.username })
        },
        removeUsername (username) {
            let index = this.usernames.indexOf(username)
            if (index >= 0) {
                this.seeds.splice(index, 1)
                this.username = index > 0 ? this.seeds[index - 1] : null
                browser.storage.local.set({ seeds: this.seeds, username: this.username })
            }
		},
		switchToUsername (username) {
            this.username = username
            browser.storage.local.set({ username: this.username })
        },
        startVoting () {
            if (this.currentSelection) {
                this.currentAnchor = this.currentSelection
            } else {
                this.currentAnchor = this.currentVideoTimeText
            }
        }
    }
}
</script>
