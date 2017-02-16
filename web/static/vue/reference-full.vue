<template>
<div>
	<div v-if="nodes.length > 0 && referenceNodes.length > 0 && reference != null">
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
				<liquio-node v-if="nodes[0].choice_type" v-bind:node="reference" v-bind:reference-key="referenceNodes[0].url_key" results-key="for_choice" title="Choice Which Reference Supports" style="margin: 40px 0px;"></liquio-node>
				
				<liquio-node v-bind:node="reference" results-key="relevance" choice-type="probability" v-bind:reference-key="referenceNodes[0].url_key" title="Relevance Score" style="margin: 40px 0px;"></liquio-node>
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
		Api.getNode(this.$route.params.key, null, (node) => self.nodes = [node])
		Api.getNode(this.$route.params.referenceKey, null, (node) => self.referenceNodes = [node])
		Api.getNode(this.$route.params.key, this.$route.params.referenceKey, (node) => self.reference = node)
		this.$root.bus.$on('change', () => {
			Api.getNode(self.$route.params.key, self.$route.params.referenceKey, (node) => self.reference = node)
		})
		return {
			nodes: [],
			referenceNodes: [],
			reference: null,
		}
	}
}
</script>