<template>
<div>
	<el-row :gutter="50" class="liquio-list" v-if="referencingNode != null && referencingNode.choice_type == 'probability'">
		<el-col :span="12">
			<h3 class="pole-heading">Negative</h3>
		
			<div class="pole-list">
				<liquio-inline v-for="node in nodes" v-if="node.reference_result.by_keys['for_choice'] && node.reference_result.by_keys['for_choice'].mean <= 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquo-inline>
			</div>
		</el-col>
		<el-col :span="12">
			<h3 class="pole-heading">Positive</h3>
		
			<div class="pole-list">
				<liquio-inline v-for="node in nodes" v-if="node.reference_result.by_keys['for_choice'] && node.reference_result.by_keys['for_choice'].mean > 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquo-inline>
			</div>
		</el-col>
	</el-row>
	<div class="list-simple" v-else>
		<liquio-inline v-for="node in nodes" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquo-inline>
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
		column-count: 3;
		column-gap: 20px;
	}

	.list-simple {
		column-count: 5;
		column-gap: 20px;
	}
</style>