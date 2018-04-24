<template>
    <svg viewBox="0 0 100 30">
        <rect x="0" y="0" width="100" height="30" :fill="color"></rect>
        <text x="50" y="16.5" text-anchor="middle" dominant-baseline="middle" font-family="Helvetica" font-size="15">{{ text }}</text>
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
            if (this.unit.type === 'quantity' || !mean)
                return "#ddd"
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
