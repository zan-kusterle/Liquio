<template>
	
<div>
	<div v-if="nodes.length == 0">There is nothing here</div>
	<el-row class="references" v-else-if="referencingNode != null && referencingNode.choice_type == 'probability'">
		<el-col :span="12">
			<h3 class="pole-heading">Negative</h3>
		
			<div class="pole-list">
				<div class="reference-a" v-for="node in nodes">
					<liquio-inline v-if="node.reference_result.by_keys['for_choice'] && node.reference_result.by_keys['for_choice'].mean <= 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquo-inline>
				</div>
			</div>
		</el-col>
		<el-col :span="12">
			<h3 class="pole-heading">Positive</h3>
		
			<div class="pole-list">
				<div class="reference-a" v-for="node in nodes">
					<liquio-inline v-if="node.reference_result.by_keys['for_choice'] && node.reference_result.by_keys['for_choice'].mean > 0.5" v-bind:node="node" v-bind:referencing-node="referencingNode" v-bind:references-node="referencesNode"></liquo-inline>
				</div>
			</div>
		</el-col>
	</el-row>
	<div class="references-list" v-else>
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
	.references {
		text-align: inherit;
	}

	.references, .pole {
		padding: 0 15px;
	}

	.references, .pole, .pole-heading {
		text-align: left;
		font-size: 18px;
		font-weight: normal;
		margin: 0px;
		margin-bottom: 15px;
	}

	.references-list {
		padding: 0px 20px;
	}
</style>