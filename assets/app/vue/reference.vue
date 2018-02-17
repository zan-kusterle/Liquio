<template>
<div style="padding-top: 50px; padding-bottom: 100px;">
	<div v-if="node" class="before" style="padding: 20px 80px;">
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
	
	<div class="main" v-if="reference && reference.results && !reference.loading">
		<embeds :results="reference.results"></embeds>

		<p style="font-size: 24px; margin-top: 50px;">Your vote</p>

		<vote has-date=false unit="Reliable-Unreliable" is-spectrum=true
			:own-contributions="reference.results.contributions_by_identities[$store.getters.currentOpts.keypair.username] ? reference.results.contributions_by_identities[$store.getters.currentOpts.keypair.username].contributions : []"
			:results="reference.results"
			v-on:set="setVote" v-on:unset="unsetVote"></vote>
	</div>
	<div v-else class="main">
		<div class="main-node">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</div>
</template>

<script>
import LiquioInline from 'reusable/liquio-inline.vue'
import Vote from 'reusable/vote.vue'
import Embeds from 'reusable/embeds.vue'

export default {
	components: {LiquioInline, Vote, Embeds},
	data: function() {
		let self = this

		return {
			referencing_title: '',
			setVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('setReferenceVote', {key: self.reference.node.key, referencingKey: self.reference.referencing_node.key, relevance: vote.choice})
			},
			unsetVote: function(vote) {
				if(self.reference)
					self.$store.dispatch('unsetReferenceVote', {key: self.reference.node.key, referencingKey: self.reference.referencing_node.key})
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
			let r = this.$store.getters.currentReference.key ? this.$store.getters.getReference(this.$store.getters.currentNode.key, this.$store.getters.currentReference.key) : null
			if(r)
				r.loading = false
			return r
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
				})
			}
		}
	}
}
</script>