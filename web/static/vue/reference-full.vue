<template>
<div>
	<div v-if="nodes.length > 0 && referenceNodes.length > 0 && reference != null">
		<div class="main">
			<div class="inset-top">
				<el-row>
					<el-col :span="11">
						<liquio-node v-for="node in nodes" v-bind:node="node" results-key="main" votable="false" link="true"></liquio-node>
					</el-col>
					<el-col :span="2">
						<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.6); font-size: 48px; margin-top: 50px;"></i>
					</el-col>
					<el-col :span="11">
						<liquio-node v-for="node in referenceNodes" v-bind:node="node" results-key="main" votable="false" link="true"></liquio-node>
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
		Api.getNode(this.$route.params.key + '/references/' + this.$route.params.referenceKey, (node) => self.reference = node)
		this.$root.bus.$on('change', () => {
			Api.getNode(self.$route.params.key + '/references/' + self.$route.params.referenceKey, (node) => self.reference = node)
		})
		return {
			nodes: [],
			referenceNodes: [],
			reference: null,
		}
	}
}
</script>