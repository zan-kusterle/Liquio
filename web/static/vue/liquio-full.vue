<template>
<app>
	<div v-if="node">
		<div class="main" v-if="node.title.length > 0">
			<div class="inset-top" style="text-align: left;">
				<liquio-list v-bind:nodes="node.inverse_references" v-bind:references-node="node"></liquio-list>
			</div>
			
			<liquio-node v-bind:node="node" results-key="main" class="main-node" id="main-node"></liquio-node>

			<div class="inset-bottom">
				<liquio-list v-bind:nodes="node.references" v-bind:referencing-node="node" style="text-align: left;"></liquio-list>
			</div>
		</div>
		<div class="main" v-else>
			<div class="main-node">
				<h1 class="fake-title">Everything</h1>
				<liquio-list v-bind:nodes="node.references" style="text-align: left;"></liquio-list>
			</div>
		</div>

		<calculation-options v-bind:opts="node.calculation_opts"></calculation-options>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<h1 class="fake-title" v-if="title">{{ title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import CalculationOptions from '../vue/calculation-options.vue'
import LiquioNode from '../vue/liquio-node.vue'
import LiquioList from '../vue/liquio-list.vue'

export default {
	components: {App, CalculationOptions, LiquioNode, LiquioList},
	data: function() {
		return {}
	},
	created: function() {
		this.fetchData()
	},
	computed: {
		node: function() {
			this.$nextTick(() => {
				let element = document.getElementById('main-node')
				if(element)
					element.scrollIntoView({block: "start", behavior: "smooth"})
			})

			if(this.$store.state.route.params.query) {
				return this.$store.getters.search(this.$store.state.route.params.query)
			} else {
				return this.$store.getters.getNodeByKey(this.$store.state.route.params.key || '')
			}
		},
		title: function() {
			if(this.$store.state.route.params.query) {
				return 'Results for ' + this.$store.route.params.query
			} else {
				return (this.$store.state.route.params.key || '').replace('-Probability', '').replace('-Quantity', '').replace('-Time-Series', '').replace(/-/g, ' ')
			}
		}
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			this.$store.dispatch('fetchNode', this.$store.state.route.params.key || '')
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
		margin: 40px 0px;
	}
</style>