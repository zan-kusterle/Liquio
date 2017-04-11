<template>
	<div>
		<div v-if="reference" class="main">
			<el-row :gutter="30">
				<el-col :span="11">
					<liquio-inline :key="reference.key" v-bind:node="reference.node"></liquio-inline>
				</el-col>
				<el-col :span="2">
					<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 25px;"></i>
				</el-col>
				<el-col :span="11">
					<el-input v-if="!reference.referencing_node" v-model="current_title" @keyup.native.enter="view" placeholder="Title" style="max-width: 800px;">
						<el-button slot="append" icon="caret-right" @click="view"></el-button>
					</el-input>
					<liquio-inline v-else :key="reference.referencing_node.key" v-bind:node="reference.referencing_node"></liquio-inline>
				</el-col>
			</el-row>
			
		</div>
		<div v-else class="main" >
			<div class="main-node">
				<i class="el-icon-loading loading"></i>
			</div>
		</div>
		
		<div class="after" v-if="reference && reference.results">
			<h1 class="title" style="vertical-align: middle;">Relevance Score</h1>

			<div v-html="reference.results.embeds.spectrum" style="width: 600px; display: block; margin: 0px auto;"></div>

			<vote single=true :votes="votes" :results="reference.results" v-on:set="setVote" v-on:unset="unsetVote"></vote>
		</div>

		<div class="footer">
			<calculation-options v-bind:opts="$store.state.calculation_opts"></calculation-options>
		</div>
	</div>
</template>

<script>
import App from '../app.vue'
import CalculationOptions from '../calculation-options.vue'
import LiquioInline from '../liquio-inline.vue'
import Vote from '../vote.vue'
let utils = require('utils.js')

export default {
	components: {App, LiquioInline, Vote, CalculationOptions},
	data: function() {
		let self = this

		return {
			votes: [],
			setVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('setReferenceVote', {reference: self.reference, relevance: vote.choice})
			},
			unsetVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('unsetReferenceVote', self.reference)
			}
		}
	},
	created: function() {
		this.fetchData()
	},
	computed: {
		reference: function() {
			return this.$store.getters.getReference(this.$store.getters.currentNode.key, this.$store.getters.currentReference.key)
		}
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			let self = this

			self.$store.dispatch('fetchReference', {key: self.$store.getters.currentNode.key, referenceKey: self.$store.getters.currentReference.key}).then(() => {
				let reference = self.$store.getters.getReference(self.$store.getters.currentNode.key, self.$store.getters.currentReference.key)
				self.votes = _.map(reference.own_results.contributions, (contribution) => {
					return {
						unit: 'Relevant-Irrelevant',
						unit_type: 'spectrum',
						choice: contribution.relevance * 100,
						at_date: new Date(contribution.at_date),
						needs_save: false
					}
				})
			})
		}
	}
}
</script>