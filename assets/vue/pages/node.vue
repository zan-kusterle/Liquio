<template>
	<div>
		<div class="before" v-if="!node.loading">
			<el-input v-model="inverse_reference_title" @keyup.native.enter="view_inverse_reference" style="max-width: 800px;">
				<el-button slot="append" icon="caret-right" @click="view_inverse_reference"></el-button>
			</el-input>
			
			<liquio-list v-if="node.path[0] !== ''" v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
		</div>

		<div v-if="node && !node.loading" class="main">
			<h1 class="title" style="vertical-align: middle;">{{ node.title || 'Everything' }}</h1>
			<a v-if="node.title.startsWith('https://')" :href="node.key" target="_blank" class="title" style="vertical-align: middle;">View content</a>

			<div class="score-container">
				<div>
					<div v-if="this.node.default_unit && this.node.default_unit.results.turnout_ratio > 0.01">
						<div v-html="this.node.default_unit.results.embed" style="width: 300px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
					</div>
					<div style="width: 100%; display: block;" class="choose-units">
						<el-select v-model="current_unit" v-on:change="pickUnit" size="mini">
							<el-option v-for="unit in $store.state.units" :key="unit.value" v-bind:value="unit.value" v-bind:label="unit.text"></el-option>
						</el-select>
					</div>
				</div>

				<vote v-bind:node="node"></vote>
			</div>
		</div>
		<div v-else class="main">
			<h1 class="fake-title">{{ node.title }}</h1>
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
import LiquioList from '../liquio-list.vue'
import Vote from '../vote.vue'
let utils = require('utils.js')

export default {
	components: {App, CalculationOptions, LiquioList, Vote},
	data: function() {
		let self = this

		return {
			reference_title: '',
			inverse_reference_title: '',
			view_reference: (event) => {
				let clean_key = self.reference_title.trim().replace(/\s+/g, '-')
				if(clean_key.length >= 3) {
					let path = '/' + encodeURIComponent(self.node.key) + '/references/' + encodeURIComponent(clean_key)
					self.$router.push(path)
				}
			},
			view_inverse_reference: (event) => {
				let clean_key = self.inverse_reference_title.trim().replace(/\s+/g, '-')
				if(clean_key.length >= 3) {
					let path = '/' + encodeURIComponent(clean_key) + '/references/' + encodeURIComponent(self.node.key)
					self.$router.push(path)
				}
			},
			current_unit: self.$store.state.route.params.unit,
			pickUnit: function(unit) {
				let path = '/' + self.$store.getters.currentNode.key + '/' + unit
				self.$router.push(path)
			}
		}
	},
	created: function() {
		this.fetchData()
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			let key = this.$store.getters.currentNode.key

			if(this.$store.getters.searchQuery) {
				this.$store.dispatch('search', this.$store.getters.searchQuery)
			}
			
			if(!this.$store.getters.hasNode(key)) {
				this.$store.dispatch('fetchNode', key)
			}
		}
	},
	computed: {
		node: function() {
			let key = this.$store.getters.currentNode.key
			if(this.$store.getters.searchQuery) {
				return this.$store.getters.searchResults(this.$store.getters.searchQuery)
			} else if(!this.$store.getters.hasNode(key)) {
				return this.$store.getters.currentNode
			} else {
				return this.$store.getters.getNodeByKey(key)
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