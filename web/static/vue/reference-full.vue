<template>
<div>
	<div class="main">
		<div class="inset-top pure-g">
			<div class="pure-u-2-5">
				<liquio-node v-for="node in nodes" v-bind:node="node" votable="false" link="true"></liquio-node>
			</div>
			<div class="pure-u-1-5">
				<img src="/images/arrow.svg" class="reference-arrow"></img>
			</div>
			<div class="pure-u-2-5">
				<liquio-node v-for="node in reference_nodes" v-bind:node="node" votable="false" link="true"></liquio-node>
			</div>
		</div>

		<div class="main-node">
			<liquio-node v-if="forChoiceNode" v-bind:node="forChoiceNode" results-key="for_choice" style="margin: 40px 0px;"></liquio-node>
			
			<liquio-node v-bind:node="relevanceNode" results-key="relevance" style="margin: 40px 0px;"></liquio-node>
		</div>
	</div>

	<a @click="optionsOpen = true">Options</a>
	<calculation-opts v-bind:opts="nodes['<%= Enum.at(@nodes, 0).key %>'].calculation_opts" v-if="optionsOpen" @close="optionsOpen = false"></calculation-opts>
</div>
</template>

<script>
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'

export default {
	components: {LiquioNode, CalculationOptions},
	
	data: function() {
		loadNode(this, this.$route.params.urlKey, this.$route.params.referenceUrlKey)
		return {
			nodes: [],
			reference_nodes: [],
			optionsOpen: false,
			relevanceNode: null,
			forChoiceNode: null
		}
	}
}
</script>