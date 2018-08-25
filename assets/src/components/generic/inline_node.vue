<template>
    <div v-if="size === 'large'" @click="$emit('click')" size="large" class="inline-node">
        <p>{{ node.title }}</p>
        <p v-if="node.anchor">{{ node.anchor }}</p>
        <p v-if="showUnit">{{ node.unit }}</p>
        <div v-for="(comment, index) in node.comments" :key="index">
            {{ comment }}
        </div>

        <results v-if="results" :results="results" :unit="node.comments.length > 0 ? 'Useless-Useful' : node.unit" :size="size" />
    </div>

    <div v-else-if="size === 'medium'" @click="$emit('click')" size="medium" class="inline-node">
        <results v-if="results" :results="results" :unit="node.comments.length > 0 ? 'Useless-Useful' : node.unit" :size="size" />
        <p>{{ node.title }} <template v-if="showUnit">({{ node.unit }})</template></p>

        <div v-for="(comment, index) in node.comments" :key="index">
            {{ comment }}
        </div>

    </div>

    <div v-else-if="size === 'small'" @click="$emit('click')" size="small" class="inline-node">
        <results v-if="results" :results="results" :unit="node.comments.length > 0 ? 'Useless-Useful' : node.unit" :size="size" />
        <p>{{ node.title }} <template v-if="showUnit">({{ node.unit }})</template></p>
    </div>
</template>

<script>
import Results from './results.vue'

export default {
    components: {
        Results,
    },
    props: {
        node: { type: Object },
        size: { type: String, default: 'small' },
        showUnit: { type: Boolean, default: false },
        results: { type: Object, required: false },
    },
}
</script>