<template>
	<div>
		<div class="before" v-if="node">
			<node-input v-bind:id="node.url_key" v-bind:enable-search="node.title == '' || node.title.startsWith('Results for ')" v-bind:enable-group="!node.title.startsWith('Results for ')" v-bind:enable-others="node.title !== '' && !node.title.startsWith('Results for ') && node.choice_type !== null" is-inverse="true" style="margin-bottom: 40px; text-align: center;"></node-input>
			<liquio-list v-if="node.title.length > 0" v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
		</div>

		<div v-if="node" class="main">
			<liquio-node v-bind:node="node" results-key="main"></liquio-node>
		</div>
		<div v-else class="main">
			<h1 class="fake-title" v-if="title">{{ title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>

		<div class="after" v-if="node">
			<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node.title == '' || node.title.startsWith('Results for') ? null : node" style="text-align: left;"></liquio-list>
			<p class="subtitle" v-if="node.references.length == 0">There is nothing here yet.</p>
			<node-input v-if="!(node.title == '' || node.title.startsWith('Results for '))" v-bind:id="node.url_key" enable-search="false" v-bind:enable-group="node.choice_type == null" style="margin-top: 30px; text-align: center;"></node-input>
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
import LiquioList from '../liquio-list.vue'
import NodeInput from '../node-input.vue'

export default {
	components: {App, CalculationOptions, LiquioNode, LiquioList, NodeInput},
	data: function() {
		return {}
	},
	created: function() {
		this.fetchData()
	},
	computed: {
		node: function() {
			if(this.$store.getters.searchQuery) {
				return this.$store.getters.searchResults(this.$store.getters.searchQuery)
			} else {
				return this.$store.getters.getNodeByKey(this.$store.getters.nodeKey)
			}
		},
		title: function() {
			if(this.$store.getters.searchQuery) {
				return 'Results for ' + this.$store.getters.searchQuery
			} else {
				return this.$store.getters.nodeKey.replace('-Probability', '').replace('-Quantity', '').replace('-Time-Series', '').replace(/-/g, ' ')
			}
		}
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			if(this.$store.getters.searchQuery) {
				this.$store.dispatch('search', this.$store.getters.searchQuery)
			} else {
				this.$store.dispatch('fetchNode', this.$store.getters.nodeKey)
			}
		}
	}
}
</script>

<style scoped>
	.fake-title {
		display: block;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
		margin: 10px 0px;
	}

	.subtitle {
		font-size: 20px;
	}
</style>