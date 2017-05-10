<template>
<div>
	<div class="before" v-if="node && !node.loading && node.title !== ''" style="padding-top: 0px;">
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

		<p @click="areInverseReferencesOpen = !areInverseReferencesOpen">
			<i class="el-icon-arrow-up" ref="toggle_inverse_references" style="font-size: 22px; vertical-align: middle;"></i>
			<span style="font-size: 14px; vertical-align: middle; margin-left: 10px; color: #555;">referenced by</span>
		</p>
	</div>

	<div v-if="node && !node.loading && node.path.length > 0" class="main">
		<h1 class="title">
			<a v-for="(segment, index) in node.path_segments" :href="segment.href" v-if="node.path[0].startsWith('http:') || node.path[0].startsWith('https:')" target="_blank"><span v-if="index > 0">/</span>{{segment.text}}</a>
			<span v-else>{{ node.title }}</span>
		</h1>

		<div class="score-container">
			<div style="margin-bottom: 20px;">
				<embeds :results="node.default_unit"></embeds>
			</div>

			<i class="el-icon-caret-bottom" ref="toggle_details" @click="isVoteOpen = !isVoteOpen" style="font-size: 48px;"></i>
			
			<transition v-on:enter="detailsEnter" v-on:leave="detailsLeave" v-bind:css="false">
				<div v-if="isVoteOpen">
					<p style="font-size: 24px; margin-top: 50px;">Your vote</p>

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
import Embeds from '../embeds.vue'
import LiquioInline from '../liquio-inline.vue'

export default {
	components: {App, Vote, Embeds, LiquioInline},
	data: function() {
		let self = this

		return {
			isVoteOpen: false,
			areInverseReferencesOpen: false,
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
			Velocity(this.$refs.toggle_details, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideUp", {duration: 500})
		},
		inverseReferencesEnter: function(el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideDown", {duration: 500})
		},
		inverseReferencesLeave: function (el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideUp", {duration: 500})
		},
	},
	computed: {
		node: function() {
			let node = getNode(this.$store)
			node.path_segments = _.map(node.path, (s, index) => {
				return {
					href: node.path.slice(0, index + 1).join('/').replace(':', '://'),
					text: index == 0 ? node.path[index].replace(':', '://') : node.path[index]
				}
			})
			return node
		}
	}
}

let getNode = ($store) => {
	let key = $store.getters.currentNode.key
	if($store.getters.searchQuery) {
		let node = $store.getters.searchResults($store.getters.searchQuery)
		if(!node)
			return $store.getters.currentNode
		return node
	} else {
		let node = $store.getters.getNodeByKey(key)
		if(!node)
			return $store.getters.currentNode
		return node
	}
}
</script>

<style scoped lang="less">
.title {
	display: block;
	margin: 10px 0px;
	font-size: 28px;
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
	margin: 40px 0px;

	.el-input {
		input {
			text-align: center;
		}
	}
}
</style>