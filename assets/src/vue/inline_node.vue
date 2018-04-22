<template>
    <div v-if="size === 'large'" @click="$emit('click')" size="large" class="inline-node">
        <p>{{ node.title }}</p>
        <results :unit-results="unitResults" :unit-key="this.currentUnit.key" width="200px"></results>
    </div>

    <div v-else-if="size === 'medium'" @click="$emit('click')" size="medium" class="inline-node">
        <results :unit-results="unitResults" :unit-key="this.currentUnit.key" width="200px"></results>
        <p>{{ node.title }}</p>
    </div>

    <div v-else-if="size === 'small'" size="small" class="inline-node">
        <div style="display: inline;" @click="$emit('click')">
            <results :unit-results="unitResults" :unit-key="this.currentUnit.key" width="200px"></results>
            <p>{{ node.title }}</p>
        </div>
    </div>
</template>

<script>
import Results from 'vue/results.vue'
import { allUnits } from 'store/constants'

export default {
    components: {
        results: Results
    },
    props: {
        node: { type: Object, required: true },
        size: { type: String },
        forceUnit: { type: String }
    },
    computed: {
        bestUnit () {
            if (Object.keys(this.node.results) === 0)
                return allUnits[0]
            let units = Object.keys(this.node.results)
            if (units.length === 0)
                return allUnits[0]
            return allUnits.find(u => u.text === units[0])
        },
        currentUnit () {
            let currentUnit = allUnits.find(u => u.value === this.forceUnit)
            if (currentUnit)
                return currentUnit
            return this.bestUnit
        },
        unitResults () {
            if (!this.node)
                return null
            return this.node.results[this.currentUnit.text]
        }
    }
}
</script>