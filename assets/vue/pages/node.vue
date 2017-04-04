<template>
	<div>
		<div class="before" v-if="node">
			<el-input v-model="inverse_reference_title" @keyup.native.enter="view_inverse_reference" style="max-width: 800px;">
				<el-button slot="append" icon="caret-right" @click="view_inverse_reference"></el-button>
			</el-input>
			
			<liquio-list v-if="node.path[0] !== ''" v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
		</div>

		<div v-if="node" class="main">
			<liquio-node v-bind:node="node" results-key="main"></liquio-node>
		</div>
		<div v-else class="main">
			<h1 class="fake-title" v-if="title">{{ title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>

		<div class="after" v-if="node">
			<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node.path[0] === '' || node.path[0].toLowerCase() === 'search' ? null : node" style="text-align: left;"></liquio-list>
			
			<el-input v-if="node.path[0] !== '' && node.path[0].toLowerCase() !== 'search'" v-model="reference_title" @keyup.native.enter="view_reference" style="max-width: 800px;">
				<el-button slot="append" icon="caret-right" @click="view_reference"></el-button>
			</el-input>
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
let utils = require('utils.js')

export default {
	components: {App, CalculationOptions, LiquioNode, LiquioList, NodeInput},
	data: function() {
		let self = this

		return {
			reference_title: '',
			inverse_reference_title: '',
			view_reference: (event) => {
				if(self.reference_title.length >= 3) {
					let clean_title = self.reference_title.replace(/\-/, '').trim()
					let key = self.node.key

					let input_key = encodeURIComponent(utils.getKey(clean_title, self.choice_type))
					let path = '/' + key + '/references/' + input_key
					self.$router.push(path)
				}
			},
			view_inverse_reference: (event) => {
				if(self.inverse_reference_title.length >= 3) {
					let clean_title = self.inverse_reference_title.trim()
					let key = self.node.key

					let input_key = encodeURIComponent(utils.getKey(clean_title, self.choice_type))
					let path = '/' + input_key + '/references/' + key
					self.$router.push(path)
				}
			}
		}
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
				return this.$store.getters.nodeTitle
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