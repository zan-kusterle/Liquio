<template>
    <div :style="{ backgroundColor: color }" class="results" :size="size">
        <span v-if="results.votingPower > 0" style="vertical-align: middle;">{{ text }}</span>
        <span v-else style="vertical-align: middle; font-size: 70%; line-height: 28px;">0 votes</span>
        <span v-if="results.votingPower > 0 && unitData" class="unit" style="vertical-align: middle;">{{ unitData.short }}</span>
    </div>
</template>

<script>
import { allUnits } from '../../store/annotate/constants.ts'

export default {
    props: {
        results: { type: Object },
        unit: { type: String, required: false },
        size: { type: String },
    },
    computed: {
        unitData () {
            if (!this.unit)
                return null
            return allUnits.find(u => u.text === this.unit)
        },
        isSpectrum () {
            return this.unit.indexOf('-') >= 0
        },
        color () {
            if (!this.isSpectrum || this.results.votingPower === 0)
                return "#ddd"

            let mean = this.results.mean
            const offset = 0.25
            if (mean < offset)
                return "rgb(255, 164, 164)"
            else if (mean > 1 - offset)
                return "rgb(140, 232, 140)"
            else
                return "rgb(249, 226, 110)"
        },
        text () {
            if (this.results.votingPower === 0)
                return '?'
            if (this.isSpectrum) {
                return Math.round(this.results.mean * 100) + '%'
            } else {
                return this.formatNumber(this.results.median)
            }
        }
    },
    methods: {
        formatNumber (number) {
            let trimZeros = (s) => s.replace(/^0+|\.?0+$/g, '')

            let absolute = Math.abs(number)
            let numDigits = Math.max(0, Math.ceil(Math.log10(number)))
            let maxFractionDigits = 3

            if (numDigits < maxFractionDigits) {
                return trimZeros(number.toFixed(maxFractionDigits - numDigits))
            }

            if (numDigits >= 5) {
                let superscriptDigits = {
                    '0': '⁰',
                    '1': '¹',
                    '2': '²',
                    '3': '³',
                    '4': '⁴',
                    '5': '⁵',
                    '6': '⁶',
                    '7': '⁷',
                    '8': '⁸',
                    '9': '⁹',
                }
                let exponent = numDigits - 1
                let whole = number / Math.pow(10, exponent)
                let superscriptExponent = exponent.toString().split('').map(c => superscriptDigits[c]).join('')
                return trimZeros(whole.toFixed(maxFractionDigits)) + ' × 10' + superscriptExponent
            }

            return Math.round(number)
        }
    }
}
</script>
