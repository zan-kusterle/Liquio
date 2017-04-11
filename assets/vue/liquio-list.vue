<template>
<div>
	<div class="list-simple">
		<liquio-inline v-for="node in nodes" :key="node.key" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquio-inline>
	</div>
</div>
</template>

<script>
import LiquioInline from '../vue/liquio-inline.vue'

export default {
	props: ['nodes', 'referencingNode', 'referencesNode'],
	components: { LiquioInline },
	data: function() {
		return {}
	}
}
</script>

<style scoped>
	.liquio-list {
		text-align: left;
	}

	.pole-heading {
		font-weight: normal;
	}

	.pole-list {
		column-count: 2;
		column-gap: 30px;
	}

	.list-simple {
		column-count: 3;
		column-gap: 30px;
	}
</style>