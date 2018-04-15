<template>
    <div>
        <template v-if="node">
            <embeds :unit-results="unitResults"  width="200px"></embeds>

            <div class="liquio-node__vote">
                <el-select v-model="currentUnitValue" class="unit">
                    <el-option v-for="unit in allUnits" :key="unit.key" :label="unit.text" :value="unit.value" />
                </el-select>

                <div class="choice">
                    <el-slider v-if="currentUnit.type === 'spectrum'" v-model="currentChoice.spectrum" class="spectrum"></el-slider>
                    <el-input v-else v-model="currentChoice.quantity" type="number" class="quantity" />
                </div>

                <div>
                    <el-button type="success" @click="finalizeVote" class="vote-button">Vote</el-button>
                </div>
            </div>
        </template>
        <div v-else>Loading...</div>
    </div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Embeds from './embeds.vue'
import { allUnits } from './data'


export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elDialog: Dialog,
        embeds: Embeds
    },
    props: {
        title: { type: String, required: true }
    },
    data () {
        return {
            currentUnitValue: 'reliable',
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
        unitResults () {
            if (!this.node)
                return null
            
            let byUnits = this.node.results
            let units = Object.keys(byUnits)
            if (units.length === 0)
                return null

            return {
                ...byUnits[units[0]],
                unit: units[0]
            }
        },
        currentUnit () {
            let unit = this.allUnits.find(u => u.value === this.currentUnitValue)
            unit.defaultValue = unit.type === 'spectrum' ? 50 : 0
            return unit
        }
    },
    methods: {
        finalizeVote () {
            if (this.node.title) {
                let data = {
                    name: 'sign',
                    messages: [{
                        name: 'vote',
                        key: ['title', 'unit'],
                        title: this.node.title.trim(' '),
                        unit: this.currentUnit.text,
                        choice: this.currentUnit.type === 'spectrum' ? this.currentChoice.spectrum / 100 : parseFloat(this.currentChoice.quantity)
                    }],
                    messageKeys: ['title', 'relevance', 'unit', 'choice']
                }
                let event = new CustomEvent('sign-anything', { detail: data })
                window.dispatchEvent(event)
            }
        }
    }
}
</script>
