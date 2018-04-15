<template>
<div class="liquio-bar" @mouseup="isHovered = true" @mouseover="isHovered = true" @mouseout="isHovered = false" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div class="liquio-bar__container" v-if="currentAnchor || reliabilityVoting || currentNode || !isHidden">
            <div class="liquio-bar__wrap">
                <div class="liquio-bar__main" v-if="signInstruction">
                    <div class="liquio-bar__items">
                        <div class="liquio-bar__vote">
                            Check you sign extension
                        </div>
                        <div class="liquio-bar__buttons">
                            <el-button size="small" type="success" @click="signInstruction = false">Close</el-button>
                        </div>
                    </div>
                </div>
                <div class="liquio-bar__main" v-else-if="currentAnchor">
                    <div class="liquio-bar__items">
                        <div class="liquio-bar__vote">
                            <el-input @keyup.stop.prevent @keydown.stop.prevent size="small" type="text" v-model="currentTitle" placeholder="Poll title" class="liquio-bar__vote-title" />
                        </div>
                        <div class="liquio-bar__buttons">
                            <el-button size="small" type="primary" @click="finalizeVote">Vote</el-button>
                            <el-button size="small" @click="resetState">Close</el-button>
                        </div>
                    </div>
                </div>
                <div class="liquio-bar__main" v-else-if="currentNode">
                    <div class="liquio-bar__items">
                        <div class="liquio-bar__vote">
                            <span style="vertical-align: middle;">{{ currentNode.title }}</span>
                            <div class="liquio-bar__results">
                                <results :unit-results="unitResults" width="100%" height="100%"></results>
                            </div>
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

    <el-dialog v-if="openNode" :visible.sync="dialogVisible" width="60%">
        <simple-node :title="openNode"></simple-node>
    </el-dialog>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Results from './results.vue'
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
        results: Results,
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
            openNode: null,
            signInstruction: false
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.allUnits = allUnits
    },
    mounted () {
        setTimeout(() => this.isLoading = false, 50)
    },
    computed: {
        node () {
            return this.$store.state.nodesByKey[this.urlKey]
        },
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
        startVoting () {
            if (this.currentSelection) {
                this.currentAnchor = this.currentSelection
            } else {
                this.currentAnchor = this.currentVideoTimeText
            }
        },
        viewNode (key) {
            this.openNode = key
            this.dialogVisible = true
            this.$store.dispatch('loadNode', { key: this.openNode })
        },
        finalizeVote () {
            if (this.currentAnchor && this.currentTitle) {
                this.signInstruction = true
                let referenceTitle = this.currentTitle.trim(' ')
                this.$store.dispatch('vote', {
                    messages: [{
                        name: 'reference_vote',
                        key: ['title', 'reference_title'],
                        title: this.urlKey + '/' + slug(this.currentAnchor.trim(' ')),
                        reference_title: referenceTitle,
                        relevance: 1.0
                    }],
                    messageKeys: ['title', 'reference_title', 'relevance']
                }).then(() => {
                    this.$store.dispatch('loadNode', { key: this.urlKey })
                    this.$store.dispatch('loadNode', { key: referenceTitle })
                    this.currentAnchor = null
                    this.currentTitle = null
                })
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
