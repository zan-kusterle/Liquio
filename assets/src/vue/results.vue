<template>
    <svg viewBox="0 0 100 30">
        <rect x="0" y="0" width="100" height="30" :fill="color"></rect>
        <text x="50" y="16.5" text-anchor="middle" alignment-baseline="middle" font-family="Helvetica" font-size="15">{{ text }}</text>
    </svg>
</template>

<script>
import { allUnits } from 'store/constants'

export default {
    props: {
        unitResults: { type: Object },
        unitKey: { type: String }
    },
    computed: {
        unit () {
            if (!this.unitKey)
                return null
            return allUnits.find(u => u.key === this.unitKey)
        },
        color () {
            let mean = this.unitResults && this.unitResults.mean
            if (!mean) return "#ddd"
            if (mean < 0.25)
                return "rgb(255, 164, 164)"
            else if (mean < 0.75)
                return "rgb(249, 226, 110)"
            else
                return "rgb(140, 232, 140)"
        },
        text () {
            if (!this.unitResults || !this.unitResults.mean)
                return '?'
            if (this.unit.type === 'spectrum') {
                return Math.round(this.unitResults.mean * 100) + '%'
            } else {
                return Math.round(this.unitResults.median * 10) / 10
            }
        }
    }
}
</script>
