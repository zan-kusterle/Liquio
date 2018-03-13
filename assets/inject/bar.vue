<template>
<div class="liquio-bar" @mouseup="isHovered = true" @mouseover="isHovered = true" @mouseout="isHovered = false">
    <el-dialog title="Finalize vote" width="60%" v-if="currentVotes" :visible.sync="dialogVisible">
        <finalize-vote :votes="currentVotes" @close="dialogVisible = false" @vote="onVote"></finalize-vote>
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
import FinalizeVote from '../vue/finalize_vote.vue'
import { colorOnGradient, slug } from 'shared/votes'
import { allUnits } from 'shared/data'
import { usernameFromPublicKey } from 'shared/identity'
import storage from 'shared/storage'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elDialog: Dialog,
        finalizeVote: FinalizeVote
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
            username: null,
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
            isHidden: true,
            isHovered: false
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.allUnits = allUnits

        if (IS_EXTENSION) {
            storage.getUsername().then(username => {
                this.username = username
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
        username () {
            this.updateNode()
        }
    },
    computed: {
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
                    anchor: this.currentAnchor,
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
            if (this.username) {
                params.trust_usernames = this.username
            }
            return new Promise((resolve, reject) => {
                Api.getNode(this.urlKey, params, (node) => {
                    this.node = node
                    this.$root.$emit('update-node', this.node)
                    resolve()
                })
            })
        },
        onVote () {
            this.currentAnchor = null
            this.updateNode()
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
