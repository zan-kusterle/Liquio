<template>
<app>
	<div v-if="nodes.length > 0">
		<div class="main">
			<div class="inset-top">
				<el-row :gutter="30">
					<el-col :span="11">
						<liquio-inline v-for="node in nodes" v-bind:node="node" results-key="main"></liquio-inline>
					</el-col>
					<el-col :span="2">
						<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 5px;"></i>
					</el-col>
					<el-col :span="11">
						<get-reference v-if="referenceNodes.length == 0" v-bind:ids="$store.getters.keys" enable-search="false" style="margin-top: 2px; text-align: center;"></get-reference>
						<liquio-inline v-else v-for="node in referenceNodes" v-bind:node="node" results-key="main"></liquio-inline>
					</el-col>
				</el-row>
			</div>

			<div class="main-node" v-if="referenceNodes.length > 0 && references.length > 0">
				<liquio-node v-if="nodes[0].choice_type" v-bind:node="references[0]" v-bind:votable-nodes="references" results-key="for_choice" v-bind:reference-key="referenceNodes[0].url_key" title="Choice Which Reference Supports" style="margin: 40px 0px;"></liquio-node>
				
				<liquio-node v-bind:node="references[0]" v-bind:votable-nodes="references" results-key="relevance" choice-type="probability" v-bind:reference-key="referenceNodes[0].url_key" title="Relevance Score" style="margin: 40px 0px;"></liquio-node>
			</div>
		</div>

		<calculation-options v-bind:opts="$store.state.calculation_opts"></calculation-options>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioInline from '../vue/liquio-inline.vue'
import GetReference from '../vue/get-reference.vue'
let utils = require('utils.js')

export default {
	components: {App, LiquioNode, LiquioInline, GetReference, CalculationOptions},
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