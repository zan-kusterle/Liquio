<template>
    <div :style="{ backgroundColor: color }">
        <span v-if="hasData" style="vertical-align: middle;">{{ text }}</span>
        <span v-else style="vertical-align: middle; font-size: 70%;">0 votes</span>
        <span v-if="hasData && unit" class="unit" style="vertical-align: middle;">{{ unit.short }}</span>
    </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
    props: {
        unitResults: { type: Object },
        unitKey: { type: String }
    },
    computed: {
        ...mapGetters('annotate', ['allUnits']),
        unit () {
            if (!this.unitKey)
                return null
            return this.allUnits.find(u => u.key === this.unitKey)
        },
        hasData () {
            return this.unitResults && this.unitResults.mean
        },
        color () {
            if (!this.hasData || this.unit.type === 'quantity')
                return "#ddd"

            let mean = this.unitResults.mean
            if (mean < 0.25)
                return "rgb(255, 164, 164)"
            else if (mean < 0.75)
                return "rgb(249, 226, 110)"
            else
                return "rgb(140, 232, 140)"
        },
        text () {
            if (this.unit.type === 'spectrum') {
                return Math.round(this.unitResults.mean * 100) + '%'
            } else {
                return this.formatNumber(this.unitResults.median)
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
