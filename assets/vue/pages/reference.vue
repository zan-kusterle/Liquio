<template>
	<div>
		<div v-if="nodes.length > 0" class="main">
			<el-row :gutter="30">
				<el-col :span="11">
					<liquio-inline v-for="node in nodes" :key="node.key" v-bind:node="node" results-key="main"></liquio-inline>
				</el-col>
				<el-col :span="2">
					<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 15px;"></i>
				</el-col>
				<el-col :span="11">
					<node-input v-if="referenceNodes.length == 0" v-bind:ids="$store.getters.keys" enable-search="false" style="margin-top: 12px; text-align: center;"></node-input>
					<liquio-inline v-else v-for="node in referenceNodes" :key="node.key" v-bind:node="node" results-key="main"></liquio-inline>
				</el-col>
			</el-row>
			
		</div>
		<div v-else class="main" >
			<div class="main-node">
				<i class="el-icon-loading loading"></i>
			</div>
		</div>
		
		<div class="after" v-if="nodes.length > 0 && referenceNodes.length > 0 && references.length > 0">
			<liquio-node v-bind:node="references[0]" v-bind:votable-nodes="references" results-key="relevance" choice-type="probability" v-bind:reference-key="referenceNodes[0].url_key" title="Relevance Score" style="margin: 40px 0px;"></liquio-node>

			<liquio-node v-if="nodes[0].choice_type" v-bind:node="references[0]" v-bind:votable-nodes="references" results-key="for_choice" v-bind:reference-key="referenceNodes[0].url_key" title="Choice For Which Reference Provides Evidence" style="margin: 40px 0px;"></liquio-node>
		</div>

		<div class="footer">
			<calculation-options v-bind:opts="$store.state.calculation_opts"></calculation-options>
		</div>
	</div>
</template>

<script>
import App from '../app.vue'
import CalculationOptions from '../calculation-options.vue'
import LiquioNode from '../liquio-node.vue'
import LiquioInline from '../liquio-inline.vue'
import NodeInput from '../node-input.vue'
let utils = require('utils.js')

export default {
	components: {App, LiquioNode, LiquioInline, NodeInput, CalculationOptions},
	data: function() {
		return {}
	},
	created: function() {
		this.fetchData()
	},
	computed: {
		nodes: function() {
			return this.$store.getters.getNodesByKeys(this.$store.getters.keys)
		},
		referenceNodes: function() {			
			return this.$store.getters.getNodesByKeys(this.$store.getters.referencingKeys)
		},
		references: function() {
			let keys = _.map(this.$store.getters.referenceKeyPairs, ({key, referenceKey}) => utils.getCompositeKey(key, referenceKey))
			return this.$store.getters.getNodesByKeys(keys)
		}
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			_.each(this.$store.getters.keys, (key) => this.$store.dispatch('fetchNode', key))
			_.each(this.$store.getters.referencingKeys, (key) => this.$store.dispatch('fetchNode', key))
			_.each(this.$store.getters.referenceKeyPairs, ({key, referenceKey}) => this.$store.dispatch('fetchReference', {key: key, referenceKey: referenceKey}))
		}
	}
}
</script>