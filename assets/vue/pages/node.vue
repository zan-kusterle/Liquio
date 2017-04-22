<template>
	<div>
		<div class="before" v-if="!node.loading && node.title !== ''" style="padding-top: 0px;">
			<transition v-on:enter="inverseReferencesEnter" v-on:leave="inverseReferencesLeave" v-bind:css="false">
				<div v-if="areInverseReferencesOpen" style="margin-top: 30px; margin-bottom: 30px;">
					<div class="list-simple">
						<liquio-inline v-for="inverse_reference in node.inverse_references" :key="inverse_reference.key" v-bind:node="inverse_reference" v-bind:references-node="node"></liquio-inline>
					</div>

					<el-input v-model="inverse_reference_title" @keyup.native.enter="view_inverse_reference" style="max-width: 800px; margin-top: 20px;">
						<el-button slot="prepend" icon="caret-left" @click="view_inverse_reference"></el-button>
					</el-input>
				</div>
			</transition>

			<i class="el-icon-arrow-up" ref="toggle_inverse_references" @click="areInverseReferencesOpen = !areInverseReferencesOpen" style="font-size: 22px;"></i>
		</div>
		

		<div v-if="!node.loading && node.title !== ''" class="main">
			<h1 class="title">
				{{ node.title }}
				<a v-if="node.title.startsWith('http:') || node.title.startsWith('https:')" :href="node.key.replace(':', '://')" target="_blank" style="margin-left: 15px; vertical-align: middle;"><i class="el-icon-view"></i></a>
			</h1>

			<div class="score-container">
				<div style="margin-bottom: 20px;">
					<div v-if="this.node.default_unit && this.node.default_unit.turnout_ratio > 0">
						<div v-html="this.node.default_unit.embeds.spectrum" v-if="currentResultsView == 'latest' && this.node.default_unit.embeds.spectrum" style="width: 500px; display: block; margin: 0px auto; font-size: 36px;"></div>
						<div v-html="this.node.default_unit.embeds.value" v-if="currentResultsView == 'latest' && !this.node.default_unit.embeds.spectrum" style="width: 400px; display: block; margin: 0px auto; font-size: 36px;"></div>
						
						<div v-html="this.node.default_unit.embeds.distribution" v-if="currentResultsView == 'distribution'" style="width: 800px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
						<div v-html="this.node.default_unit.embeds.by_time" v-if="currentResultsView == 'by_time'" style="width: 800px; height: 120px; display: block; margin: 0px auto; font-size: 36px;"></div>
					
						<span @click="currentResultsView = 'latest'" v-bind:class="{ active: currentResultsView == 'latest' }" class="results-view-button">Current</span>
						<span @click="currentResultsView = 'distribution'" v-if="this.node.default_unit.embeds.distribution" v-bind:class="{ active: currentResultsView == 'distribution' }" class="results-view-button">Distribution</span>
						<span @click="currentResultsView = 'by_time'" v-if="this.node.default_unit.embeds.by_time" v-bind:class="{ active: currentResultsView == 'by_time' }" class="results-view-button">Graph</span>
					</div>
				</div>

				<i class="el-icon-caret-bottom" ref="toggle_details" @click="isVoteOpen = !isVoteOpen" style="font-size: 28px;"></i>
				<transition v-on:enter="detailsEnter" v-on:leave="detailsLeave" v-bind:css="false">
					<div v-if="isVoteOpen">
						<div class="pick-unit">
							<el-select v-model="current_unit" v-on:change="pickUnit">
								<el-option v-for="unit in $store.state.units" :key="unit.value" v-bind:value="unit.value" v-bind:label="unit.text"></el-option>
							</el-select>
						</div>
						
						<vote ref="votesContainer" has-date=true
							:unit="node.default_unit.value" :is-spectrum="node.default_unit.type == 'spectrum'"
							:own-contributions="node.own_default_unit ? node.own_default_unit.own_contributions.contributions : []"
							:results="node.default_unit" v-on:set="setVote" v-on:unset="unsetVote"></vote>
					</div>
				</transition>
			</div>
		</div>
		<div v-else-if="!node.loading" class="after">
			<h1 class="title">A liquid democracy where anyone can vote on anything</h1>

			<el-input placeholder="Search" v-model="search_title" @keyup.native.enter="search" style="max-width: 800px;">
				<el-button slot="append" icon="search" @click="search"></el-button>
			</el-input>

			<div class="get-extension">
				<router-link to="/link">
					<el-button>
						<img src="/images/google-chrome-icon.png" style="vertical-align: middle; width: 32px; opacity: 0.8;"></img>
						<span style="vertical-align: middle; margin-left: 5px; font-size: 20px;">Get extension</span>
					</el-button>
				</router-link>
			</div>
		</div>
		<div v-else class="main">
			<h1 class="fake-title">{{ node.title }}</h1>
			<i class="el-icon-loading loading"></i>
		</div>

		<div class="after" v-if="node">
			<el-input v-if="node.title !== '' && node.path[0].toLowerCase() !== 'search'" v-model="reference_title" @keyup.native.enter="view_reference" style="max-width: 800px; margin-bottom: 20px;">
				<el-button slot="append" icon="caret-right" @click="view_reference"></el-button>
			</el-input>
			
			<div class="list-simple">
				<liquio-inline v-for="reference in node.references" :key="reference.key" v-bind:node="reference" v-bind:referencing-node="node.title === '' ? null : node" style="text-align: left;"></liquio-inline>
			</div>
		</div>
	</div>
</template>

<script>
import App from '../app.vue'
import Vote from '../vote.vue'
import LiquioInline from '../liquio-inline.vue'

export default {
	components: {App, Vote, LiquioInline},
	data: function() {
		let self = this

		return {
			isVoteOpen: false,
			areInverseReferencesOpen: false,
			currentResultsView: 'latest',
			votes: [],
			search_title: '',
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
			search: (event) => {
				self.$router.push('/search/' + encodeURIComponent(self.search_title))
			},
			current_unit: null,
			pickUnit: function(unit) {
				let currentNode = self.$store.getters.currentNode
				if(unit != self.node.default_unit.value) {
					let path = '/' + encodeURIComponent(currentNode.key) + '/' + unit
					self.$router.push(path)
				}
			},
			setVote: function(vote) {
				vote.key = self.node.key
				self.$store.dispatch('setVote', vote)
			},
			unsetVote: function(vote) {
				vote.key = self.node.key
				self.$store.dispatch('unsetVote', vote)
			}
		}
	},
	created: function() {
		this.fetchData()
	},
	watch: {
		'$route': function(route, previous) {
			this.fetchData(route.params.key == previous.params.key)
		}
	},
	methods: {
		fetchData: function(isSameNode) {
			let self = this
			let handleNode = (node) => {
				self.current_unit = node.default_unit.value
			}

			if(!isSameNode) {
				let votesContainer = self.$refs.votesContainer
				if(votesContainer)
					votesContainer.$el.style.display = 'none'
				self.isVoteOpen = false
				self.areInverseReferencesOpen = false
				self.currentResultsView = 'latest'
			}

			let key = this.$store.getters.currentNode.key
			if(this.$store.getters.searchQuery) {
				this.$store.dispatch('search', this.$store.getters.searchQuery)
			} else {
				if(isSameNode) {
					handleNode(self.$store.getters.getNodeByKey(key))
				} else {
					this.$store.dispatch('fetchNode', key).then(() => {
						handleNode(self.$store.getters.getNodeByKey(key))
					})
				}
			}
		},
		detailsEnter: function (el, done) {
			Velocity(this.$refs.toggle_details, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideDown", {duration: 500})
		},
		detailsLeave: function (el, done) {
			Velocity(this.$refs.toggle_details, {rotateZ: "+=180"}, {duration: 300})
			Velocity(el, "slideUp", {duration: 300})
		},
		inverseReferencesEnter: function(el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideDown", {duration: 500})
		},
		inverseReferencesLeave: function (el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 300})
			Velocity(el, "slideUp", {duration: 300})
		},
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

<style scoped lang="less">
	.title {
		display: block;
		margin: 10px 0px;
		font-size: 26px;
		font-weight: normal;
		color: #333;
		opacity: 1;
		word-wrap: break-word;
		vertical-align: middle;
	}

	.get-extension {
		text-align: center;
		margin-top: 50px;
	}

	.results-view-button {
		display: inline-block;
		margin: 0px 10px;
		color: #111;
		font-size: 14px;
		text-transform: lowercase;
	}
	.results-view-button.active {
		font-weight: bold;
	}

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
	
	.list-simple {
		column-count: 3;
		column-gap: 30px;
	}
	.pick-unit {
		width: 100%;
		display: block;
		margin-top: 30px;

		.el-input {
			input {
				text-align: center;
			}
		}
	}
</style>