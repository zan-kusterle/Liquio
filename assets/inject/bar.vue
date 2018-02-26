<template>
<div>
    <el-dialog v-if="currentVotes" title="Finalize vote" :visible.sync="dialogVisible" width="60%">
        <login v-show="loginOpen" :usernames="usernames" :username="username" @login="addSeed" @logout="removeUsername" @switch="switchToUsername"></login>

        <span v-if="loginOpen" slot="footer" class="dialog-footer">
            <el-button @click="dialogVisible = false">Cancel</el-button>
            <el-button type="primary" @click="loginOpen = false">Choose user</el-button>
        </span>

        <template v-if="!loginOpen">
            <p><b>{{ currentVotes.node.key }}</b> {{ currentVotes.node.unit }}: {{ currentVotes.node.choice }}</p>

            <p>Voting with user <b>{{ 'mockuser' }}</b></p>

            <span slot="footer" class="dialog-footer">
                <el-button @click="dialogVisible = false">Cancel</el-button>
                <el-button type="primary" @click="loginOpen = true">Switch user</el-button>
                <el-button type="success" @click="vote">Cast vote</el-button>
            </span>
        </template>
    </el-dialog>

    <div class="liquio-bar__container" v-if="!isHidden && !isUnavailable" :style="{ height: `${hasContent ? 60 : 20}`}">
        <div class="liquio-bar__wrap">
            <div class="liquio-bar__main">
                <div class="liquio-bar__anchor" :class="{ 'liquio-bar__anchor--big': !hasContent }">
                    <template v-if="currentAnchor">
                        <p class="liquio-bar__anchor-selection"><b>Voting on</b> {{ currentAnchor }}</p>
                    </template>
                    <template v-else-if="activeAnchor">
                        <a @click="currentAnchor = activeAnchor" class="liquio-bar__anchor-selection">{{ activeAnchor }}</a>
                    </template>
                </div>

                <template v-if="hasContent">
                    <div class="liquio-bar__data-wrap">
                        <div class="liquio-bar__vote" v-if="currentAnchor">
                            <a @click="currentAnchor = null" style="margin-right: 10px;">&lt;-</a>
                            <el-input type="text" v-model="currentTitle" placeholder="Poll title" class="liquio-bar__vote-title" />
                            <el-select v-model="currentUnitValue" class="liquio-bar__vote-unit">
                                <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
                            </el-select>
                            <div class="liquio-bar__vote-choice">
                                <el-slider v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum" class="liquio-bar__vote-spectrum"></el-slider>
                                <el-input v-else v-model="currentChoice.quantity" type="number" class="liquio-bar__vote-quantity" />
                            </div>
                            <el-button @click="dialogVisible = true" class="liquio-bar__vote-button">Vote</el-button>
                        </div>

                        <div class="liquio-bar__current-node" v-else-if="currentNode">
                            {{ currentNode.title }}
                            <div class="liquio-bar__embeds" v-html="embedsSvg"></div>
                        </div>
                    </div>
                </template>
            </div>
            <a class="liquio-bar__score" :style="{ 'background': `#${color}` }" :href="`${LIQUIO_URL}/v/${encodeURIComponent(key)}`">
                {{ ratingText }}
            </a>
        </div>
    </div>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Login from '../vue/login.vue'
import { colorOnGradient, slug } from 'shared/votes'
import { allUnits } from 'shared/data'
import { usernameFromPublicKey } from 'shared/identity'
import { decodeBase64 } from 'shared/utils'
import * as client from 'shared/api_client'
import 'element-ui/lib/theme-chalk/index.css'
import { keypairFromSeed } from 'shared/identity'

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
    data () {
        return {
            isUnavailable: true,

            key: null,
            trustMetricUrl: null,
            publicKeys: null,
            node: null,

            currentNode: null,

            currentSelection: null,
            currentVideoTime: null,
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

            isHidden: true
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.isExtension = !!(window.chrome && chrome.runtime && chrome.runtime.id)
        this.allUnits = allUnits

        if (this.isExtension) {
            chrome.storage.local.get(['seeds', 'username'], (data) => {
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

            chrome.runtime.onMessage.addListener(request => {
                if (request.name === 'toggle') {
                    this.isHidden = !this.isHidden
                }
            });
        }
    },
    computed: {
        hasContent () {
            return this.currentAnchor || this.currentNode
        },
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
        currentUsername () {
            return usernameFromPublicKey(this.publicKeys[0])
        },
        currentVideoTimeText () {
            return this.currentVideoTime
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
                    key: this.key + '/' + slug(this.currentAnchor),
                    referenceKey: this.currentTitle.replace(/\s/, '-'),
                    relevance: 1.0
                }
            }
        }
    },
    methods: {
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

            client.setVote(this.publicKeys[0], this.getSignature(this.keypair, voteMessage), this.currentVotes.node.key, this.currentVotes.node.unit, new Date(), this.currentVotes.node.choice, (r) => {
                client.setReferenceVote(this.publicKeys[0], this.getSignature(this.keypair, referenceMessage), this.currentVotes.reference.key, this.currentVotes.reference.referenceKey, this.currentVotes.reference.relevance, (r) => {
                    this.dialogVisible = false
                    this.currentAnchor = null
                })
            })
        },
        addSeed (seed) {
            this.seeds.push(seed)
            this.username = this.usernames[this.usernames.length - 1]
            chrome.storage.local.set({ seeds: this.seeds, username: this.username })
        },
        removeUsername (username) {
            let index = this.usernames.indexOf(username)
            if (index >= 0) {
                this.seeds.splice(index, 1)
                this.username = index > 0 ? this.seeds[index - 1] : null
                chrome.storage.local.set({ seeds: this.seeds, username: this.username })
            }
		},
		switchToUsername (username) {
            this.username = username
            chrome.storage.local.set({ username: this.username })
		}
    }
}
</script>

<style scoped lang="less">
.liquio-bar {
    &__container {
        cursor: default;
        font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
        position: fixed;
        bottom: 0px;
        z-index: 1000;
        width: 100%;
        user-select: none;
    }

    &__wrap {
        display: flex;
        align-items: center;
        background-color: rgba(255, 255, 255, 0.8);
    }

    &__score {
        @size: 90px;
        width: @size;
        height: @size;
        line-height: @size;
        text-align: center;
        font-size: 24px;
        color: white;
        cursor: pointer;

        &:hover {
            color: white;
        }
    }

    &__main {
        flex: 1;
        padding: 5px 20px;
        width: calc(100% - 130px);
    }

    &__embeds {
        font-size: 0;
        width: 140px;
        display: inline-block;
        vertical-align: middle;
        margin-left: 10px;
    }

    &__vote {
        display: flex;
        align-items: center;
    }

    &__vote-title {
        flex: 3;
        margin-right: 20px;
    }

    &__vote-unit {
        flex: 1;
        margin-right: 20px;
    }

    &__vote-choice {
        flex: 1;
        margin-right: 20px;
    }

    &__vote-button {
        margin-right: 40px;
    }

    &__anchor {
        font-size: 12px;
        color: #666;
        position: relative;

        &--big {
            font-size: 20px;
        }
    }

    &__data-wrap {
        height: 36px;
        margin-top: 10px;
    }

    &__anchor-selection {
        text-overflow: ellipsis;
        white-space:nowrap;
        overflow:hidden;
        display: block;
    }
}
</style>