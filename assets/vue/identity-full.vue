<template>
<app>
	<div v-if="identity">
		<div class="main">
			<div class="main-node">
				<el-row :gutter="50">
					<el-col :span="8">
						dasd
					</el-col>
					<el-col :span="8">
						{{ identity.username }}<br>
						{{ identity.name }}

						<div style="margin-top: 60px;" v-if="$store.state.user == null || identity.username != $store.state.user.username">
							I trust this identity<br>
							<el-button @click="$store.dispatch('setTrust', {username: username, is_trusted: false})" :type="this.$store.state.user && this.$store.state.user.trusts[this.$route.params.username] == false ? 'danger' : null">False</el-button>
							<el-button @click="$store.dispatch('setTrust', {username: username, is_trusted: true})" :type="this.$store.state.user && this.$store.state.user.trusts[this.$route.params.username] == true ? 'success' : null">True</el-button>
							<br>
							<el-button type="text" @click="$store.dispatch('unsetTrust', username)" v-if="this.$store.state.user && this.$store.state.user.trusts[this.$route.params.username] != null">Remove</el-button>
						</div>

						<div style="margin-top: 40px;" v-if="$store.state.user == null || identity.username != $store.state.user.username">
							Delegation
							<el-slider v-model="weight"></el-slider>

							<el-tag
								:key="tag"
								v-for="tag in topics"
								:closable="true"
								:close-transition="false"
								@close="handleClose(tag)"
								>
							{{tag}}
							</el-tag>
							<el-input
								class="input-new-tag"
								v-if="inputVisible"
								v-model="inputValue"
								ref="saveTagInput"
								size="mini"
								@keyup.enter.native="handleInputConfirm"
								@blur="handleInputConfirm"
								>
							</el-input>
							<el-button v-else class="button-new-tag" size="small" @click="showInput">Add topic</el-button>

							<el-button @click="$store.dispatch('setDelegation', {username: username, weight: weight / 100, topics: topics})">Update</el-button>
							<el-button @click="$store.dispatch('unsetDelegation', username)" type="danger" v-if="$store.state.user && $store.state.user.delegations[$route.params.username]">Remove</el-button>
						</div>
					</el-col>
					<el-col :span="8">
						asdasd
					</el-col>
				</el-row>
			</div>
			<div class="inset-bottom">
				<liquio-list v-bind:nodes="identity.votes"></liquio-list>
			</div>
		</div>
	</div>
	<div class="main" v-else>
		<div class="main-node">
			<i class="el-icon-loading loading"></i>
		</div>
	</div>
</app>
</template>

<script>
import App from '../vue/app.vue'
import LiquioList from '../vue/liquio-list.vue'

export default {
	components: {App, LiquioList},
	data: function() {
		let self = this
		let username = this.$route.params.username

		this.$root.bus.$on('currentUser', function(user) {
			let delegation = self.$store.state.user.delegations[self.$route.params.username]
			if(delegation) {
				self.weight = delegation.weight * 100
				self.topics = delegation.topics
			}
		})

		this.$store.dispatch('fetchIdentity', username).then((identity) => {
			self.identity = identity
		})

		return {
			identity: null,
			username: username,

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
					self.$refs.saveTagInput.$refs.input.focus()
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
	}
}
</script>