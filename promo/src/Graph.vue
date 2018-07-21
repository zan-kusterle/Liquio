<template>
    <svg ref="svg" viewBox="0 0 1000 420" width="100%" height="100%">
        <g class="focusable" :transform="`scale(${state === 'big' ? 0.6 : 1})`">
            <g transform="translate(0, 0)">
                <line x1="0" y1="80" x2="290" y2="80" stroke-width="10" stroke="#333" />
                <path transform="translate(282, 60) scale(0.4)" d="M3.949.714a6.994 6.994 0 0 0-3.95 6.284v86.004a6.995 6.995 0 0 0 3.95 6.284 7.094 7.094 0 0 0 7.423-.754L67.269 55.53c3.642-2.8 3.642-8.259 0-11.06L11.372 1.468A7.094 7.094 0 0 0 3.949.714z" fill="#333" />
            
                <line x1="370" y1="140" x2="370" y2="255" stroke-width="10" stroke="#333" />
                <line x1="370" y1="230" x2="390" y2="230" stroke-width="10" stroke="#333" />
                <path transform="translate(390, 215) scale(0.3)" d="M3.949.714a6.994 6.994 0 0 0-3.95 6.284v86.004a6.995 6.995 0 0 0 3.95 6.284 7.094 7.094 0 0 0 7.423-.754L67.269 55.53c3.642-2.8 3.642-8.259 0-11.06L11.372 1.468A7.094 7.094 0 0 0 3.949.714z" fill="#333" />
            
                <line x1="370" y1="140" x2="370" y2="355" stroke-width="10" stroke="#333" />
                <line x1="370" y1="350" x2="390" y2="350" stroke-width="10" stroke="#333" />
                <path transform="translate(390, 335) scale(0.3)" d="M3.949.714a6.994 6.994 0 0 0-3.95 6.284v86.004a6.995 6.995 0 0 0 3.95 6.284 7.094 7.094 0 0 0 7.423-.754L67.269 55.53c3.642-2.8 3.642-8.259 0-11.06L11.372 1.468A7.094 7.094 0 0 0 3.949.714z" fill="#333" />
            
                <g transform="translate(310, 20)">
                    <g @click="$emit('click', 'node')" class="hoverable" style="transform-origin: 60px 50%;">
                        <rect x="-5" y="-10" width="450" height="140" rx="5" ry="5" :fill="state === 'node' ? 'rgba(255, 255, 255, 0.3)' : 'transparent'" />
                        <Node color="#23dfa2" result="98%" :size="120"  title="Earth is not flat" />
                    </g>
                </g>

                <g @click="$emit('click', 'referenceQuantity')" class="hoverable" style="transform-origin: 40px 50%;">
                    <rect x="405" y="190" width="540" height="100" rx="5" ry="5" :fill="state === 'referenceQuantity' ? 'rgba(255, 255, 255, 0.3)' : 'transparent'" />
                    <Node color="#aaa" result="-300" :size="80" :is-circle="false" transform="translate(410, 205)" :lines="['Year when Aristotle provided evidence', 'for spherical shape of the Earth']" />
                </g>

                <g @click="$emit('click', 'referenceSpectrum')" class="hoverable" style="transform-origin: 40px 50%;">
                    <rect x="405" y="300" width="540" height="100" rx="5" ry="5" :fill="state === 'referenceSpectrum' ? 'rgba(255, 255, 255, 0.3)' : 'transparent'" />
                    <Node color="#23dfa2" result="91%" :size="80" transform="translate(410, 310)" :lines="['Humankind never landed on the moon']" />
                </g>
            </g>

            <g @click="$emit('click', 'webpage')" class="hoverable" style="transform-origin: center;">
                <rect x="0" y="0" width="240" height="160" fill="#ccc" />
            </g>
        </g>
    </svg>
</template>

<script>
/*
<path v-if="isFocused" fill="white" d="M42.591 57.381c-.591-.656-1.425-1.084-2.378-1.087l-26.947-.038a3.217 3.217 0 0 0-3.225 3.225c.003 1.785 2.084 3.791 2.978 4.685l6.815 6.815L0 90.625 9.375 100l19.544-19.931 6.815 6.815c1.475 1.475 2.972 3.044 4.757 3.047a3.217 3.217 0 0 0 3.225-3.225l-.038-26.947c-.003-.953-.431-1.787-1.087-2.378zm37.984-28.709L100 9.375 90.625 0 71.334 19.372l-6.931-6.975c-1.5-1.51-3.022-3.116-4.834-3.119-1.816-.003-3.282 1.475-3.282 3.3l.038 27.581c0 .975.437 1.828 1.106 2.435.603.672 1.45 1.109 2.419 1.112l27.406.038c1.813.003 3.282-1.475 3.282-3.3-.004-1.825-2.119-3.882-3.029-4.794l-6.934-6.978z" />
<path v-else fill="white" d="M.45 34.196L.02 2.878C0 1.284 1.288-.02 2.863 0l30.941.456c2.474.041 3.701 3.063 1.942 4.843l-8.609 8.715 14.315 14.49-13.293 13.454-14.314-14.489-8.61 8.714C3.497 37.942.491 36.701.45 34.196zm85.705-6.542l8.61 8.715c1.758 1.78 4.744.538 4.785-1.966L100 3.084c.02-1.594-1.268-2.898-2.843-2.877l-30.94.455c-2.475.041-3.702 3.064-1.943 4.844l8.589 8.673-14.315 14.49L71.84 42.124l14.315-14.47zM64.253 94.701c-1.758 1.779-.531 4.802 1.943 4.843l30.941.456c1.574.021 2.863-1.284 2.842-2.877l-.45-31.319c-.04-2.504-3.026-3.747-4.785-1.967l-8.609 8.715-14.315-14.49-13.293 13.455 14.315 14.49-8.589 8.694zm-61.39 5.091l30.941-.455c2.474-.042 3.701-3.064 1.942-4.844L27.137 85.8l14.315-14.49-13.293-13.456-14.314 14.49-8.61-8.714C3.476 61.85.491 63.092.45 65.597L0 96.915c0 1.594 1.288 2.898 2.863 2.877z" />        
*/
// Concepts: webpage, generic node (spectrum), reference nodes (spectrum and quantity), reference relevance (arrow width), other websites / nodes

import Node from './Node.vue'

export default {
    components: { Node },
    props: {
        state: { type: String }
    },
    created () {
        this.nodes = [
            { x: 500, y: 100, title: 'Earth is flat '}
        ]
    },
    mounted () {
    },
    computed: {
        circles () {
            let l = []
            for (let i = 0; i < 20; i++) {
                l.push({ x: Math.random() * 80 + 20, y: Math.random() * 30 + 10, r: Math.random() * 2 + 2 })
            }
            return l
        }
    },
}
</script>

<style scoped>
.focusable {
    transform-origin: center;
    transition: transform 0.5s ease-in-out;
}

.hoverable {
    cursor: pointer;
    transform-box: fill-box;
    transition: transform 0.2s ease-out;
}
.hoverable:hover {
    transform: scale(1.1);
}

rect {
    transition: all 0.3s ease;
}
</style>