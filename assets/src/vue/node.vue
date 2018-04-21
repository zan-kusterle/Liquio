<template>
    <div class="liquio-node" v-if="node">
        <inline-node ref="node" :node="node" :force-unit="currentUnitValueData" size="large" class="liquio-node__main"></inline-node>

        <div class="liquio-node__vote">
            <el-select v-model="currentUnitValue" class="unit">
                <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
            </el-select>

            <div class="choice">
                <el-slider v-if="isCurrentUnitSpectrum" v-model="currentChoice.spectrum" class="spectrum"></el-slider>
                <el-input v-else v-model="currentChoice.quantity" type="number" class="quantity" />
            </div>

            <div>
                <el-button type="success" @click="vote" class="vote-button">Vote</el-button>
            </div>
        </div>

        <div class="liquio-node__references">
            <inline-node v-for="reference in node.references" :key="reference.title" :node="reference" size="small" class="liquio-node__reference"></inline-node>
        </div>
    </div>
    <div v-else>Loading...</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import InlineNode from 'vue/inline_node.vue'
import { allUnits } from 'store/constants'

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
    computed: {
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
        isCurrentUnitSpectrum () {
            let unit = allUnits.find(u => u.value === this.currentUnitValue)
            return unit && unit.type === 'spectrum'
        }
    },
    methods: {
        vote () {
            if (this.node.title) {
                let unit = this.$refs.node.currentUnit
                this.$store.dispatch('vote', {
                    messages: [{
                        name: 'vote',
                        key: ['title', 'unit'],
                        title: this.node.title.trim(' '),
                        unit: unit.text,
                        choice: unit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                    }],
                    messageKeys: ['title', 'unit', 'choice']
                }).then(() => {
                    this.$store.dispatch('loadNode', { key: this.title })
                })
            }
        }
    }
}
</script>
