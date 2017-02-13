<template>
<div>
	<div v-if="nodes.length > 0 && referenceNodes.length > 0">
		<div class="main">
			<div class="inset-top">
				<el-row>
					<el-col :span="11">
						<liquio-node v-for="node in nodes" v-bind:node="node" votable="false" link="true"></liquio-node>
					</el-col>
					<el-col :span="2">
						<i class="el-icon-arrow-right" style="font-size: 48px;"></i>
					</el-col>
					<el-col :span="11">
						<liquio-node v-for="node in referenceNodes" v-bind:node="node" votable="false" link="true"></liquio-node>
					</el-col>
				</el-row>
			</div>

			<div class="main-node">
				<liquio-node v-if="forChoiceNode" v-bind:node="forChoiceNode" results-key="for_choice" style="margin: 40px 0px;"></liquio-node>
				
				<liquio-node v-bind:node="relevanceNode" results-key="relevance" style="margin: 40px 0px;"></liquio-node>
			</div>
		</div>

		<calculation-options v-bind:opts="nodes[0].calculation_opts"></calculation-options>
	</div>
</div>
</template>

<script>
let Api = require('api.js')
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'

export default {
	components: {LiquioNode, CalculationOptions},
	
	data: function() {
		let self = this
		Api.getNode(this.$route.params.key, (node) => self.nodes = [node])
		Api.getNode(this.$route.params.referenceKey, (node) => self.referenceNodes = [node])
		return {
			nodes: [],
			referenceNodes: [],
			relevanceNode: null,
			forChoiceNode: null
		}
	}
}
</script>