<template>
    <div v-if="node" class="liquio-node">
        <inline-node :node="node" :force-unit="currentUnitValueData" size="large" class="liquio-node__main"></inline-node>

        <div class="vote" v-if="!isVotingDisabled">
            <el-select v-model="currentUnitValue" class="unit">
                <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
            </el-select>

            <div class="choice">
                <el-slider v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum" class="spectrum"></el-slider>
                <el-input v-else v-model="currentChoice.quantity" type="number" class="quantity" />
            </div>

            <div>
                <el-button type="success" @click="vote" class="vote-button">Vote</el-button>
            </div>
        </div>

        <div class="liquio-node__references">
            <div v-for="reference in node.references" :key="reference.title" class="liquio-node__reference">
                <inline-node :node="reference" @click="viewNode(reference)" size="small"></inline-node>
                <i @click="viewReference(reference)" class="el-icon-caret-right" style="cursor: pointer; vertical-align: middle;"></i>
            </div>
            <div v-for="reference in node.inverse_references" :key="reference.title" class="liquio-node__reference">
                <inline-node :node="reference" @click="viewNode(reference)" size="small"></inline-node>
                <i @click="viewInverseReference(reference)" class="el-icon-caret-left" style="cursor: pointer; vertical-align: middle;"></i>
            </div>
        </div>
    </div>
    <div v-else class="liquio-loading">
        <i class="el-icon-loading"></i>
    </div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import InlineNode from 'vue/inline_node.vue'
import { allUnits } from 'store/constants'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
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
        }
    },
    computed: {
        ...mapState(['isVotingDisabled']),
        node () {
            return this.$store.state.nodesByKey[this.title]
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
                }).then(() => {
                    this.$store.dispatch('loadNode', { key: this.title })
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
