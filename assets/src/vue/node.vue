<template>
    <div v-if="node" class="liquio-node">
        <inline-node :node="node" :force-unit="currentUnitValueData" size="large" class="liquio-node__main"></inline-node>

        <div class="vote" v-if="!isVotingDisabled">
            <el-select v-model="currentUnitValue" class="unit">
                <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
            </el-select>

            <div class="choice">
                <el-slider v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum"></el-slider>
                <el-input-number v-else v-model="currentChoice.quantity" @keyup.delete.stop.native="() => {}"></el-input-number>
            </div>

            <el-button-group class="vote-buttons">
                <el-button type="success" @click="vote" class="vote-button">Vote</el-button>
                <el-button v-if="currentVote" type="danger" @click="unsetVote" class="vote-button">Delete vote</el-button>
            </el-button-group>
        </div>

        <div class="liquio-node__references" v-if="references.length > 0 || inverseReferences.length > 0">
            <div v-for="reference in references" :key="reference.title" class="liquio-node__reference">
                <i @click="viewReference(reference)" class="el-icon-caret-right liquio-node__view-reference-icon"></i>
                <inline-node :node="reference" @click="viewNode(reference)" size="small"></inline-node>
            </div>
            <div v-for="reference in inverseReferences" :key="reference.title" class="liquio-node__reference">
                <i @click="viewInverseReference(reference)" class="el-icon-caret-left liquio-node__view-reference-icon"></i>
                <inline-node :node="reference" @click="viewNode(reference)" size="small"></inline-node>
            </div>
        </div>
    </div>
    <div v-else class="liquio-loading">
        <i class="el-icon-loading"></i>
    </div>
</template>

<script>
import { Slider, Button, ButtonGroup, Select, Option, InputNumber, Dialog } from 'element-ui'
import InlineNode from 'vue/inline_node.vue'
import { allUnits } from 'store/constants'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elButtonGroup: ButtonGroup,
        elSelect: Select,
        elOption: Option,
        elInputNumber: InputNumber,
        elDialog: Dialog,
        inlineNode: InlineNode
    },
    props: {
        title: { type: String, required: true }
    },
    data () {
        return {
            currentUnitValueData: null,
            currentChoice: {
                spectrum: 50,
                quantity: 0
            }
        }
    },
    created () {
        this.allUnits = allUnits
    },
    watch: {
        title () {
            this.currentUnitValue = null
            this.currentChoice = {
                spectrum: 50,
                quantity: 0
            }
        },
        currentVote (v) {
            if (v) {
                if (this.currentUnit.type === 'spectrum') {
                    this.currentChoice.spectrum = v.choice * 100
                } else {
                    this.currentChoice.quantity = v.choice
                }
            } else {
                this.currentChoice = {
                    spectrum: 50,
                    quantity: 0
                }
            }
        },
        node (v) {
            if (!v)
                return

            let maxVotingPower = 0
            let bestUnitText = null

            for (let unit in v.results) {
                let unitResults = v.results[unit]
                if (unitResults.voting_power >= maxVotingPower) {
                    bestUnitText = unit
                }
            }

            if (bestUnitText) {
                let unit = allUnits.find(u => u.text === bestUnitText)
                if (unit) {
                    this.currentUnitValueData = unit.value
                }
            }
        }
    },
    computed: {
        ...mapState(['isVotingDisabled']),
        node () {
            return this.$store.getters.nodeByTitle(this.title)
        },
        currentUnitValue: {
            get () {
                return this.currentUnitValueData || 'reliable'
            },
            set (v) {
                this.currentUnitValueData = v
            }
        },
        currentUnit () {
            return allUnits.find(u => u.value === this.currentUnitValue)
        },
        currentVote () {
            if (!this.node || !this.currentUnit)
                return null
                
            let unitResults = this.node.results[this.currentUnit.text]
            if (!unitResults)
                return null

            return unitResults.contributions.find(c => this.$store.getters.usernames.includes(c.username))
        },
        references () {
            let byTitle = {}
            for (let reference of this.node.references) {
                byTitle[reference.title] = this.$store.getters.nodeByTitle(reference.title)
            }
            return Object.values(byTitle)
        },
        inverseReferences () {
            let byTitle = {}
            for (let reference of this.node.inverseReferences) {
                byTitle[reference.title] = this.$store.getters.nodeByTitle(reference.title)
            }
            return Object.values(byTitle)
        }
    },
    methods: {
        vote () {
            if (this.node.title) {
                this.$store.dispatch('vote', {
                    messages: [{
                        name: 'vote',
                        key: ['title', 'unit'],
                        title: this.node.title.trim(' '),
                        unit: this.currentUnit.text,
                        choice: this.currentUnit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                    }],
                    messageKeys: ['title', 'unit', 'choice']
                })
            }
        },
        unsetVote () {
            if (this.node.title) {
                this.$store.dispatch('vote', {
                    messages: [{
                        name: 'vote',
                        key: ['title', 'unit'],
                        title: this.node.title.trim(' '),
                        unit: this.currentUnit.text,
                        choice: null
                    }],
                    messageKeys: ['title', 'unit', 'choice']
                })
            }
        },
        viewNode (node) {
            this.$store.dispatch('setCurrentTitle', node.title)
        },
        viewReference (node) {
            this.$store.dispatch('setCurrentReferenceTitle', node.title)
        },
        viewInverseReference (node) {
            this.$store.dispatch('setCurrentReferenceTitle', this.node.title)
            this.$store.dispatch('setCurrentTitle', node.title)
        }
    }
}
</script>
