<template>
<div>
	<div class="before" v-if="node && !node.loading" style="padding-top: 0px;">
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

	<div v-if="node && !node.loading" class="main">
		<h1 class="title" v-if="node.path[0].startsWith('http:') || node.path[0].startsWith('https:')">
			<a :href="node.path.join('/').replace" target="_blank">{{node.path.join('/')}}</a>
			<br>
			<a :href="'/page/' + encodeURIComponent(node.url)" target="_blank" style="font-size: 18px; font-weight: bold;">Visit with Liquio</a>
		</h1>
		<h1 class="title" v-else>
			<p>{{ node.title }}</p>
		</h1>

		<div class="score-container">
			<div style="margin-bottom: 20px;">
				<embeds :results="node.default_unit"></embeds>
			</div>

			<i class="el-icon-caret-bottom" ref="toggle_details" v-if="$store.getters.currentOpts.keypair" @click="isVoteOpen = !isVoteOpen" style="font-size: 48px;"></i>
			
			<transition v-on:enter="detailsEnter" v-on:leave="detailsLeave" v-bind:css="false">
				<div v-if="isVoteOpen">
					<p style="font-size: 24px; margin-top: 50px;">Your vote</p>

					<div class="pick-unit">
						<el-select v-model="current_unit" v-on:change="pickUnit">
							<el-option v-for="unit in $store.state.units" :key="unit.value" v-bind:value="unit.value" v-bind:label="unit.text"></el-option>
						</el-select>
					</div>
					
					<vote ref="votesContainer" :has-date="true"
						:unit="node.default_unit.value" :is-spectrum="node.default_unit.type == 'spectrum'"
						:own-contributions="node.default_unit.contributions_by_identities && node.default_unit.contributions_by_identities[$store.getters.currentOpts.keypair.username] ? node.default_unit.contributions_by_identities[$store.getters.currentOpts.keypair.username].contributions : []"
						:results="node.default_unit" v-on:set="setVote" v-on:unset="unsetVote"></vote>
				</div>
			</transition>
		</div>
	</div>
	<div v-else class="main">
		<h1 class="fake-title">{{ node.title }}</h1>
		<i class="el-icon-loading loading"></i>
	</div>

	<div class="after" v-if="node && !node.loading">
		<el-input v-if="node.title !== ''" v-model="reference_title" @keyup.native.enter="view_reference" style="max-width: 800px; margin-bottom: 20px;">
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
			current_unit: null,

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
		fetchData(isSameNode) {
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
		view_reference(event) {
			let clean_key = this.reference_title.trim().replace(/\s+/g, '-')
			if(clean_key.length >= 3) {
				let path = '/n/' + encodeURIComponent(this.node.key) + '/references/' + encodeURIComponent(clean_key)
				this.$router.push(path)
			}
		},
		view_inverse_reference(event) {
			let clean_key = this.inverse_reference_title.trim().replace(/\s+/g, '-')
			if(clean_key.length >= 3) {
				let path = '/n/' + encodeURIComponent(clean_key) + '/references/' + encodeURIComponent(this.node.key)
				this.$router.push(path)
			}
		},
		pickUnit(unit) {
			let currentNode = this.$store.getters.currentNode
			if(unit != this.node.default_unit.value) {
				let path = '/n/' + encodeURIComponent(currentNode.key) + '/' + unit
				this.$router.push(path)
			}
		},
		setVote(vote) {
			vote.key = this.node.key
			this.$store.dispatch('setVote', vote)
		},
		unsetVote(vote) {
			vote.key = this.node.key
			this.$store.dispatch('unsetVote', vote)
		},
		detailsEnter (el, done) {
			Velocity(this.$refs.toggle_details, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideDown", {duration: 500})
		},
		detailsLeave (el, done) {
			Velocity(this.$refs.toggle_details, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideUp", {duration: 500})
		},
		inverseReferencesEnter(el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideDown", {duration: 500})
		},
		inverseReferencesLeave(el, done) {
			Velocity(this.$refs.toggle_inverse_references, {rotateZ: "+=180"}, {duration: 500})
			Velocity(el, "slideUp", {duration: 500})
		},
	},
	computed: {
		node() {
			let node = this.$store.getters.currentNode

			node.loading = true
			if(this.$store.getters.searchQuery) {
				let searchNode = this.$store.getters.searchResults(this.$store.getters.searchQuery)
				if(searchNode) {
					node = searchNode
					node.loading = false
				}
			} else {
				let newNode = this.$store.getters.getNodeByKey(node.key)
				if(newNode) {
					node = newNode
					node.loading = false
				}
			}

			node.url = node.path.join('/').replace(':', '://')
			
			return node
		}
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

  @media only screen and (max-width: 1000px) {
    column-count: 2;
  }

  @media only screen and (max-width: 600px) {
    column-count: 1;
  }
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