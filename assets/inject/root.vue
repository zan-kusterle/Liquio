<template>
<div class="liquio-bar" @mouseup="isHovered = true" @mouseover="isHovered = true" @mouseout="isHovered = false" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div class="liquio-bar__container" v-if="currentAnchor || reliabilityVoting || currentNode || !isHidden">
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
                            <el-button @click="openNode = urlKey; dialogVisible = true;">View</el-button>
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
                        <div class="liquio-bar__embeds">
                            <embeds v-if="unitResults" :unit-results="unitResults" width="100%" height="100%"></embeds>
                        </div>
                        <div class="liquio-bar__vote-button" style="margin-left: 10px;">
                            <el-button @click="openNode = currentNode.title; dialogVisible = true;">View</el-button>
                        </div>
                        
                        <div class="liquio-bar__vote-button" v-if="currentSelection && currentSelection.length >= 10">
                            <el-button size="small" @click="startVoting">Vote on selection</el-button>
                        </div>
                        <div class="liquio-bar__vote-button" v-else-if="currentVideoTime">
                            <el-button size="small" @click="startVoting">Vote on video at {{ currentVideoTimeText }}</el-button>
                        </div>
                    </div>
                    <div class="liquio-bar__vote" v-else>
                        <div class="liquio-bar__vote-button" v-if="currentSelection && currentSelection.length >= 10">
                            <el-button size="small" @click="startVoting">Vote on selection</el-button>
                        </div>
                        <div class="liquio-bar__vote-button" v-else-if="currentVideoTime">
                            <el-button size="small" @click="startVoting">Vote on video at {{ currentVideoTimeText }}</el-button>
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

    <el-dialog v-if="openNode" :title="openNode" :visible.sync="dialogVisible" width="60%">
        <simple-node></simple-node>
    </el-dialog>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Embeds from './embeds.vue'
import axios from 'axios'
import slug from './slug'
import { allUnits } from './data'
import SimpleNode from './simple_node.vue'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elDialog: Dialog,
        embeds: Embeds,
        simpleNode: SimpleNode
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

            whitelistUrl: null,
            username: null,
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
            isHovered: false,
            dialogVisible: false,
            openNode: null
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.allUnits = allUnits

        window.addEventListener('sign-anything-response', (e) => {
            let data = e.detail
            if (data.request_name === 'whitelist') {
                this.username = data.username
                this.whitelistUrl = data.url
            } else if (data.request_name === 'sign') {
                this.updateNode()
                this.currentAnchor = null
            }
        })

        if (process.env.NODE_ENV === 'development') {
            let messages = [
                {
                    name: 'vote',
                    key: ['title', 'unit'],
                    title: 'asd',
                    unit: 'Reliable-Unreliable',
                    choice: 0.9
                }
            ]
            let data = {
                name: 'sign',
                messages: messages,
                messageKeys: ['title', 'reference_title', 'relevance', 'unit', 'choice']
            }

            setTimeout(() => {
                let event = new CustomEvent('sign-anything', { detail: data })
                window.dispatchEvent(event)
            }, 2000)
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
            //if (!this.rating)
                return '33bae7'
            
            let red = 'ff2b2b',
                yellow = 'f9e26e',
                green = '43e643'
            return this.rating < 0.5 ? colorOnGradient(yellow, red, this.rating * 2) : colorOnGradient(green, yellow, (this.rating - 0.5) * 2)
        },
        unitResults () {
            return {
                voting_power: 1,
                median: 1,
                mean: 0.79,
                unit: 'True-False'
            }

            if (!this.currentNode)
                return null
            let byUnits = this.currentNode.results
            let units = Object.keys(byUnits)
            if (units.length === 0)
                return null
            return {
                ...byUnits[units[0]],
                unit: units[0]
            }
        },
        rating () {
            if (!this.node)
                return null
            
            let units = this.node.results
            let spectrumUnitKeys = Object.keys(units).filter(k => units[k].type === 'spectrum')
            if (spectrumUnitKeys.length === 0)
                return null
            
            let bestUnitKey = spectrumUnitKeys[0]
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
        currentVideoTimeText () {
            let minutes = Math.floor(this.currentVideoTime / 60)
            let seconds = Math.floor(this.currentVideoTime - minutes * 60)
            return `${('00' + minutes).slice(-2)}:${('00' + seconds).slice(-2)}`
        }
    },
    methods: {
        updateNode () {
            if (this.whitelistUrl || this.username) {
                let params = { depth: 2 }
                if (this.whitelistUrl) {
                    params.whitelist_url = this.whitelistUrl
                }
                if (this.username) {
                    params.whitelist_usernames = this.username
                }

                return new Promise((resolve, reject) => {
                    axios.get(LIQUIO_URL + '/api/nodes/' + encodeURIComponent(this.urlKey), { params: params }).then((response) => {
                        this.node = response.data.data
                        this.$root.$emit('update-node', this.node)
                        resolve()
                    })
                })
            }
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
                let messages = []
                if (this.reliabilityVoting) {
                    messages.push([
                        {
                            name: 'vote',
                            key: ['title', 'unit'],
                            title: this.urlKey,
                            unit: 'Reliable-Unreliable',
                            choice: this.reliabilityChoice / 100
                        }
                    ])
                }

                if (this.currentTitle && this.currentUnit && this.currentAnchor) {
                    messages.push({
                        name: 'vote',
                        key: ['title', 'unit', 'choice'],
                        title: this.currentTitle.trim(' '),
                        unit: this.currentUnit.text,
                        choice: this.currentUnit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                    })
                    messages.push({
                        name: 'reference_vote',
                        key: ['title', 'reference_title'],
                        title: this.urlKey + '/' + slug(this.currentAnchor.trim(' ')),
                        reference_title: this.currentTitle.trim(' '),
                        relevance: 1.0
                    })
                }

                let data = {
                    name: 'sign',
                    messages: messages,
                    messageKeys: ['title', 'reference_title', 'relevance', 'unit', 'choice']
                }
                let event = new CustomEvent('sign-anything', { detail: data })
                window.dispatchEvent(event)
            }
        },
        resetState () {
            this.reliabilityVoting = false
            this.currentAnchor = null
            this.currentTitle = null
            this.currentUnitValue = 'true'
            this.reliabilityChoice = 50
            this.currentChoice = {
                spectrum: 50,
                quantity: 0
            }
        }
    }
}
</script>
