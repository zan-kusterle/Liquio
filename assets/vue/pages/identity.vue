<template>
	<div v-if="identity">
		<div class="main">
			<el-row :gutter="50">
				<el-col :span="8">
					<div>&nbsp;
						<p v-for="incoming_identity in incoming_identities" :key="incoming_identity.username">{{ incoming_identity.username }}</p>
					</div>
				</el-col>
				<el-col :span="8">
					{{ identity.username }}

					<div style="margin-top: 50px;" v-if="$store.state.user == null || identity.username != $store.state.user.username">
						I trust this identity<br>
						<el-button @click="setTrust(false)" :type="isTrusting === false ? 'danger' : null">False</el-button>
						<el-button @click="setTrust(true)" :type="isTrusting === true ? 'success' : null">True</el-button>
						<br>
						<el-button type="text" @click="setTrust(null)" v-if="isTrusting !== null">Remove</el-button>
					</div>

					<div style="margin-top: 40px;" v-if="$store.state.user == null || identity.username != $store.state.user.username">
						Delegation
						<el-slider v-model="weight"></el-slider>

						<div>
							<el-tag class="new-topic"
								:key="tag"
								v-for="tag in topics"
								:closable="true"
								:close-transition="false"
								@close="handleClose(tag)"
								>
							{{tag}}
							</el-tag>

							<el-input class="input-new-topic" v-if="addingTopic" ref="topicInput" v-model="topic" size="mini" @keyup.enter.native="handleInputConfirm" @blur="handleInputConfirm"></el-input>
							
							<el-button v-else class="button-new-tag" size="small" @click="showInput">Add topic</el-button>
						</div>

						<div style="margin-top: 20px;">
							<el-button @click="setDelegation()">Update</el-button>
							<el-button @click="clearDelegation()" type="danger" v-if="$store.getters.currentDelegation">Remove</el-button>
						</div>
					</div>
				</el-col>
				<el-col :span="8">
					<div>&nbsp;
						<p v-for="current_identity in identities" :key="current_identity.username">{{ current_identity.username }}</p>
					</div>
				</el-col>
			</el-row>
		</div>
		<div class="after">
			<div class="list-simple">
				<liquio-inline v-for="node in identity.votes" :key="node.key" v-bind:node="node"></liquio-inline>
			</div>
		</div>
	</div>
	<div v-else>
		<div class="main">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</template>

<script>
import App from '../app.vue'
import LiquioInline from '../liquio-inline.vue'

export default {
	components: {App, LiquioInline},
	data: function() {
		let self = this
		let username = this.$route.params.username

		this.$store.dispatch('fetchIdentity', username).then((identity) => {
			self.identity = identity

			let delegation = self.$store.state.user && identity.delegations_to[self.$store.state.user.username]
			if(delegation) {
				self.isTrusting = delegation.is_trusting
				self.weight = delegation.weight * 100
				self.topics = delegation.topics || []
			}
		})

		return {
			identity: null,
			username: username,

			isTrusting: null,
			topics: [],
			weight: 100,
        	addingTopic: false,
        	topic: '',

			handleClose: function(tag) {
				self.topics.splice(self.topics.indexOf(tag), 1);
			},
			showInput: function() {
				self.addingTopic = true;
				self.$nextTick(_ => {
					self.$refs.topicInput.$refs.input.focus()
				});
			},
			handleInputConfirm: function() {
				let topic = self.topic
				if (topic)
					self.topics.push(topic)
				self.addingTopic = false
				self.topic = ''
			}
		}
	},
	methods: {
		setDelegation: function() {
			let weight = this.weight ? this.weight / 100 : null
			let topics = this.topics.length > 0 ? this.topics : null
			this.$store.dispatch('setDelegation', {username: this.username, is_trusted: this.isTrusting, weight: weight, topics: topics})
		},
		clearDelegation: function() {
			this.topics = []
			this.weight = 100
			this.setDelegation()
		},
		setTrust: function(is_trusting) {
			this.isTrusting = is_trusting
			this.setDelegation()
		}
	},
	computed: {
		incoming_identities: function() {
			let l = []
			if(self.identity) {
				_.each(self.identity.trusts_to, (x) => l.push(x))
				_.each(self.identity.delegations_to, (x) => l.push(x))
			}
			return l
		},
		identities: function() {
			let l = []
			if(self.identity) {
				_.each(self.identity.trusts, (trust) => l.push(x))
				_.each(self.identity.delegations, (delegation) => l.push(x))
			}
			return l
		}
	}
}
</script>

<style scoped>
.new-topic {
	margin: 5px 5px;
}

.input-new-topic {
	display: inline-block;
	width: 100px;
}

.list-simple {
	column-count: 3;
	column-gap: 30px;
}
</style>