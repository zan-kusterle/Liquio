<template>
    <g class="node" @click="$emit('click')">
        <circle class="results" v-if="isCircle" :cx="size / 2" :cy="size / 2" :r="size / 2" :fill="color" />
        <rect class="results" v-else x="0" y="0" :width="size" :height="0.6 * size" :fill="color" />

        <text :x="size / 2" :y="textOffset" :font-size="size * 0.3" text-anchor="middle" dominant-baseline="central" font-family="Helvetica" fill="#333">{{ result }}</text>

        <text x="0" :y="textOffset" :font-size="size * 0.3" dominant-baseline="central" font-family="Helvetica" fill="#333">
            <tspan v-for="(line, index) in textLines" :key="index" :x="size * 1.3" :dy="`${index * 1.2}em`">{{ line }}</tspan>
        </text>
    </g>
</template>

<script>
export default {
    props: {
        size: { type: Number },
        color: { type: String },
        result: { type: String },
        title: { type: String },
        lines: { type: Array },
        isCircle: { type: Boolean, default: true },
        isActive: { type: Boolean, default: false }
    },
    computed: {
        textLines () {
            return this.lines || [this.title]
        },
        textOffset () {
            if (!this.isCircle)
                return 0.6 * this.size / 2
            return this.size / 2
        }
    }
}
</script>

<style scoped>
text {
    user-select: none;
}
</style>
