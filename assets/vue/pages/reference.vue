<template>
	<div>
		<div v-if="reference" class="main">
			<el-row :gutter="30">
				<el-col :span="11">
					<liquio-inline :key="reference.key" v-bind:node="reference.node"></liquio-inline>
				</el-col>
				<el-col :span="2">
					<i class="el-icon-arrow-right" style="color: rgba(0, 0, 0, 0.5); font-size: 32px; margin-top: 15px;"></i>
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

			<div class="score-container">
				<div v-html="reference.results.embeds.main" style="width: 300px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>

				<div class="vote-choices">
					<div class="vote-choice">
						<div class="number">
							<span>{{ Math.round(relevance_choice) }}</span><span class="percent">%</span>
						</div>

						<div class="range">
							<el-slider v-model="relevance_choice" />
						</div>

						<a class="action" v-on:click="set" style="width: 90px;">Save <i class="el-icon-circle-check"></i></a>
					</div>
				</div>

				<div class="vote-container open">
					<div class="votes" v-if="reference.results.contributions.length > 0">
						<p class="ui-title">{{ Math.round(reference.results.turnout_ratio * 100) }}% turnout</p>
						<div class="contribution" v-for="contribution in reference.results.contributions" :key="contribution.username">
							<div class="weight">
								<el-progress :text-inside="true" :stroke-width="24" :percentage="Math.round(contribution.weight * 100)"></el-progress>
							</div>
							<div class="choice" v-html="contribution.embeds.main" style="height: 40px;"></div>
							<div class="username"><router-link :to="'/identities/' + contribution.identity_username">{{ contribution.identity_username }}</router-link></div>
							<div class="date">{{ moment(new Date(contribution.datetime)).fromNow() }}</div>
						</div>
					</div>
				</div>
			</div>
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
let utils = require('utils.js')

export default {
	components: {App, LiquioInline, CalculationOptions},
	data: function() {
		let self = this

		return {
			relevance_choice: 50,
			set: function(event) {
				let relevance = parseFloat(self.relevance_choice) / 100
				let reference = self.reference
				if(reference)
					self.$store.dispatch('setReferenceVote', {reference: reference, relevance: relevance})
			},
			unset: function(event) {
				let reference = self.reference
				if(reference)
					self.$store.dispatch('unsetReferenceVote', reference)
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
			this.$store.dispatch('fetchReference', {key: this.$store.getters.currentNode.key, referenceKey: this.$store.getters.currentReference.key})
		}
	}
}
</script>