<template>
<div class="liquio-bar" @mouseup="isHovered = true" @mouseover="isHovered = true" @mouseout="isHovered = false" :style="isLoading ? { visibility: 'hidden' } : {}">
    <el-dialog title="Finalize voting" custom-class="liquio-bar__finalize-dialog" center width="800px" v-if="currentVotes" :visible.sync="dialogVisible">
        <finalize-vote :votes="currentVotes" @close="dialogVisible = false" @vote="onVote" @set-username="setUsername"></finalize-vote>
    </el-dialog>

    <el-dialog title="Choose which votes to count" center width="800px" :visible.sync="trustMetricOpen">
        <trust-metric :trust-metric-url="trustMetricUrl" @close="trustMetricOpen = false" @set-trust-metric="trustMetricUrl = $event"></trust-metric>
    </el-dialog>

    <template v-if="!isUnavailable">
        <div class="liquio-bar__container" v-if="currentAnchor || reliabilityVoting || (currentNode || isHovered || !isHidden) && !(currentSelection && currentSelection.length >= 10 || currentVideoTime)">
            <div class="liquio-bar__wrap">
                <div class="liquio-bar__score" :style="{ 'background': `#${color}` }" @click="reliabilityVoting = true">
                    {{ ratingText }}
                </div>
                <div class="liquio-bar__main">
                    <div class="liquio-bar__vote" v-if="reliabilityVoting">
                        <div class="liquio-bar__vote-button">
                            <el-button size="small" @click="resetState">Close</el-button>
                        </div>

                        <div class="liquio-bar__vote-choice">
                            <el-slider size="small" tooltip-class="liquio-bar__tooltip" v-model="reliabilityChoice" class="liquio-bar__vote-spectrum"></el-slider>
                        </div>

                        <div class="liquio-bar__vote-button">
                            <el-button size="small" type="primary" @click="finalizeVote">Vote</el-button>
                        </div>

                        <div class="liquio-bar__vote-button">
                            <a :href="`${LIQUIO_URL}/v/${encodeURIComponent(urlKey)}`" target="_blank"><el-button type="small">View on Liquio</el-button></a>
                        </div>
                    </div>
                    <div class="liquio-bar__vote" v-else-if="currentAnchor">
                        <div style="margin-right: 10px;">
                            <el-button size="small" @click="resetState">Close</el-button>
                        </div>
                        <el-input @keyup.stop.prevent @keydown.stop.prevent size="small" type="text" v-model="currentTitle" placeholder="Poll title" class="liquio-bar__vote-title" />
                        <el-select size="small" popper-class="liquio-bar__dropdown" v-model="currentUnitValue" class="liquio-bar__vote-unit">
                            <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
                        </el-select>
                        <div class="liquio-bar__vote-choice">
                            <el-slider size="small" tooltip-class="liquio-bar__tooltip" v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum" class="liquio-bar__vote-spectrum"></el-slider>
                            <el-input size="small" v-else v-model="currentChoice.quantity" type="number" class="liquio-bar__vote-quantity" />
                        </div>
                        <div>
                            <el-button size="small" type="primary" @click="finalizeVote">Vote</el-button>
                        </div>
                    </div>
                    <div class="liquio-bar__vote" v-else-if="currentNode">
                        <span style="vertical-align: middle;">{{ currentNode.title }}</span>
                        <div class="liquio-bar__embeds" v-html="embedsSvg"></div>
                        <div class="liquio-bar__vote-button" style="margin-left: 10px;">
                            <a :href="`${LIQUIO_URL}/v/${encodeURIComponent(currentNode.path.join('/'))}`" target="_blank"><el-button type="small">View on Liquio</el-button></a>
                        </div>
                    </div>
                    <div class="liquio-bar__vote" v-else>
                        <div class="liquio-bar__vote-button">
                            <el-button size="small" @click="trustMetricOpen = true">Change whitelist</el-button>
                            <a style="margin-left: 10px;" :href="trustMetricUrl" target="_blank">{{ trustMetricUrl }}</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="liquio-bar__container liquio-bar__button-container" v-else-if="currentSelection && currentSelection.length >= 10">
            <el-button size="small" @click="startVoting">Vote on selection</el-button>
        </div>
        <div class="liquio-bar__container liquio-bar__button-container" v-else-if="currentVideoTime">
            <el-button size="small" @click="startVoting">Vote on video at {{ currentVideoTimeText }}</el-button>
        </div>
    </template>
</div>
</template>

<script>
import * as Api from 'shared/api_client'
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import FinalizeVote from '../vue/finalize_vote.vue'
import TrustMetric from '../vue/trust_metric.vue'
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
        finalizeVote: FinalizeVote,
        trustMetric: TrustMetric
    },
    props: {
        urlKey: { type: String },
        isHidden: { type: Boolean },
        isUnavailable: { type: Boolean },
        currentNode: { type: Object },
        currentSelection: { type: String },
        currentVideoTime: { type: Number }
    },
    data () {
        return {
            isLoading: true,

            username: null,
            trustMetricUrl: process.env.NODE_ENV === 'production' ? 'https://trust-metric.liqu.io' : 'http://127.0.0.1:8080/dev_trust_metric.html',
            node: null,

            currentAnchor: null,
            currentTitle: null,
            currentUnitValue: 'true',
            reliabilityChoice: 50,
            currentChoice: {
                spectrum: 50,
                quantity: 0
            },

            reliabilityVoting: false,
            dialogVisible: false,
            trustMetricOpen: false,
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
        }
    },
    mounted () {
        setTimeout(() => this.isLoading = false, 50)
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
            if (this.reliabilityVoting) {
                return {
                    node: {
                        key: this.urlKey,
                        unit: 'Reliable-Unreliable',
                        type: 'spectrum',
                        choice: this.reliabilityChoice / 100
                    }
                }
            }

            if (!this.currentTitle || !this.currentUnit || !this.currentAnchor)
                return null
            
            return {
                node: {
                    key: this.currentTitle.trim(' ').replace(/\s/, '-'),
                    unit: this.currentUnit.text,
                    type: this.currentUnit.type,
                    choice: this.currentUnit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                },
                reference: {
                    anchor: this.currentAnchor.trim(' '),
                    key: this.urlKey + '/' + slug(this.currentAnchor.trim(' ')),
                    referenceKey: this.currentTitle.trim(' ').replace(/\s/, '-'),
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
            this.resetState()
            this.dialogVisible = false
            this.updateNode()
        },
        startVoting () {
            if (this.currentSelection) {
                this.currentAnchor = this.currentSelection
            } else {
                this.currentAnchor = this.currentVideoTimeText
            }
        },
        finalizeVote () {
            if (this.currentTitle || this.reliabilityVoting) {
                this.dialogVisible = true
            }
        },
        resetState () {
            this.reliabilityVoting = false
            this.currentAnchor = null
            this.currentTitle = null
            this.currentUnitValue = 'true'
            this.currentChoice = {
                spectrum: 50,
                quantity: 0
            }
        },
        setUsername (username) {
            this.username = username
        }
    }
}
</script>
