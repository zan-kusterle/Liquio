<template>
<div>
	<div v-if="nodes.length > 0 && referenceNodes.length > 0 && references.length > 0">
		<div class="main">
			<div class="inset-top">
				<el-row>
					<el-col :span="11">
						<liquio-inline v-for="node in nodes" v-bind:node="node" results-key="main" link="true" style="width: 95%;"></liquio-inline>
					</el-col>
					<el-col :span="2">
						<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 50px;"></i>
					</el-col>
					<el-col :span="11">
						<liquio-inline v-for="node in referenceNodes" v-bind:node="node" results-key="main" link="true" style="width: 95%;"></liquio-inline>
					</el-col>
				</el-row>
			</div>

			<div class="main-node">
				<liquio-node v-if="nodes[0].choice_type" v-bind:node="references[0]" v-bind:votable-nodes="references" v-bind:reference-key="referenceNodes[0].url_key" title="Choice Which Reference Supports" style="margin: 40px 0px;"></liquio-node>
				
				<liquio-node v-bind:node="references[0]" v-bind:votable-nodes="references" results-key="relevance" choice-type="probability" v-bind:reference-key="referenceNodes[0].url_key" title="Relevance Score" style="margin: 40px 0px;"></liquio-node>
			</div>
		</div>

		<calculation-options v-bind:opts="nodes[0].calculation_opts"></calculation-options>
	</div>
	<div v-else>
		<i class="el-icon-loading" style="font-size: 100px; margin-top: 100px;"></i>
	</div>
</div>
</template>

<script>
let Api = require('api.js')
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioInline from '../vue/liquio-inline.vue'

export default {
	components: {LiquioNode, LiquioInline, CalculationOptions},
	
	data: function() {
		let self = this
		let keys = this.$route.params.key.split('_')
		let referenceKeys = this.$route.params.referenceKey.split('_')
		Api.getNodes(keys, null, (nodes) => self.nodes = nodes)
		Api.getNodes(referenceKeys, null, (nodes) => self.referenceNodes = nodes)
		Api.getNodes(keys, referenceKeys, (nodes) => self.references = nodes)
		this.$root.bus.$on('change', () => Api.getNodes(keys, referenceKeys, (nodes) => {
			self.references = nodes
		}))
		
		return {
			nodes: [],
			referenceNodes: [],
			references: []
		}
	}
}
</script>