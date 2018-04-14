<template>
    <div>
        <span>{{ JSON.stringify(node.results) }}</span>

        <embeds :unit-results="unitResults"  width="200px"></embeds>
    </div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Dialog } from 'element-ui'
import Embeds from './embeds.vue'

export default {
    components: {
        elDialog: Dialog,
        embeds: Embeds
    },
    computed: {
        node () {
            return {
                title: 'Asd',
                results: []
            }
        },
        unitResults () {
            return {
                voting_power: 1,
                median: 1,
                mean: 0.79,
                unit: 'True-False'
            }
        }
    }
}
</script>