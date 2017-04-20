<template>
	<div>
		<div v-if="node" class="main">
			<el-row :gutter="30">
				<el-col :span="11">
					<liquio-inline v-bind:node="node"></liquio-inline>
				</el-col>
				<el-col :span="2">
					<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 25px;"></i>
				</el-col>
				<el-col :span="11">
					<liquio-inline v-if="referencing_node"  v-bind:node="referencing_node"></liquio-inline>
					<el-input v-else v-model="referencing_title" @keyup.native.enter="set_referencing" placeholder="Reference title" style="margin-top: 20px;">
						<el-button slot="append" icon="caret-right" @click="set_referencing"></el-button>
					</el-input>
				</el-col>
			</el-row>
		</div>
		<div v-else class="main">
			<div class="main-node">
				<i class="el-icon-loading loading"></i>
			</div>
		</div>
		
		<div class="after" v-if="reference && reference.results">
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

export default {
	components: {App, LiquioInline, Vote, CalculationOptions},
	data: function() {
		let self = this

		return {
			referencing_title: '',
			votes: [],
			setVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('setReferenceVote', {reference: self.reference, relevance: vote.choice})
			},
			unsetVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('unsetReferenceVote', self.reference)
			},
			set_referencing: function(event) {
				let path = 'references/' + encodeURIComponent(self.referencing_title.replace(/\s+/g, '-'))
				self.$router.push(path)
			}
		}
	},
	created: function() {
		this.fetchData()
	},
	computed: {
		node: function() {
			return this.$store.getters.getNodeByKey(this.$store.getters.currentNode.key)
		},
		referencing_node: function() {
			return this.$store.getters.currentReference.key ? this.$store.getters.getNodeByKey(this.$store.getters.currentReference.key) : null
		},
		reference: function() {
			return this.$store.getters.currentReference.key ? this.$store.getters.getReference(this.$store.getters.currentNode.key, this.$store.getters.currentReference.key) : null
		}
	},
	watch: {
		'$route': 'fetchData'
	},
	methods: {
		fetchData: function() {
			let self = this

			self.$store.dispatch('fetchNode', self.$store.getters.currentNode.key)
			if(self.$store.getters.currentReference.key) {
				self.$store.dispatch('fetchNode', self.$store.getters.currentReference.key)

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
}
</script>