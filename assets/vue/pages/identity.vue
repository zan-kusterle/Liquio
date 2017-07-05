<template>
<div>
	<el-dialog title="Import votes" v-model="importVisible">
		<el-input type="textarea" :rows="10" v-model="importData"></el-input>

		<el-button type="success" @click="importVotes(importData)" style="margin-top: 20px;">Finish</el-button>
	</el-dialog>

	<div v-if="identity">
		<div class="main">
			<el-row :gutter="50">
				<el-col :sm="24" :md="6">
					&nbsp;
					<div v-for="delegation in identity.delegations_to" :key="delegation.from_username">
						<router-link :to="'/identities/' + delegation.from_username">{{ delegation.from_username }}</router-link>
						<span v-if="delegation.is_trusting === false"><i class="el-icon-warning"></i> untrusts</span>
						<span v-if="delegation.is_trusting === true">{{ delegation.weight * 100 }}%</span>
						<span v-if="delegation.is_trusting === true && delegation.topics.length > 0">({{ delegation.topics.join(', ') }})</span>
					</div>
				</el-col>
				<el-col :sm="24" :md="12">
					<h2 class="username"><i class="el-icon-arrow-right" style="margin-right: 50px;"></i>{{ identity.username }}<i class="el-icon-arrow-right" style="margin-left: 50px;"></i></h2>
					<h3 v-if="identity.identifications['name']" class="name">{{ identity.identifications['name'] }}</h3>
					<a v-for="website in identity.websites" :key=website :href=website target="_blank" class="website">{{ website }}</a>

					<p v-if="identity.is_in_trust_metric === false">Not in trust metric</p>

					<div v-if="$store.getters.currentOpts.keypair && identity.username == $store.getters.currentOpts.keypair.username" class="add-identifications">
						<div class="add-name">
							<el-input v-model="publicName" placeholder="Your name"></el-input>
							<el-button type="success" @click="setName()">Set public name</el-button>
						</div>

						<div class="add-webpage">
							<el-input v-model="webpageURL" placeholder="Webpage URL"></el-input>
							<el-button type="success" @click="addWebpage()">Add webpage</el-button>
						</div>
					</div>
					<div v-else class="set-delegation">
						<el-button @click="setTrust(false)" :type="isTrusting === false ? 'danger' : null">I don't trust this user</el-button>
						<el-button @click="setTrust(true)" :type="isTrusting === true ? 'success' : null">I trust this user</el-button>
						
						<div v-if="isTrusting === true && ownDelegation">
							<p style="margin-top: 40px;">You are delegating <b>{{ Math.round(ownDelegation.weight * 100) }}%</b> of your voting power to this identity<span v-if="ownDelegation.topics.length > 0"> for topics <b>{{ ownDelegation.topics.join(', ') }}</b></span>.</p>
							<el-button @click="clearDelegation()" type="danger" style="margin-top: 20px;">Stop delegating</el-button>
						</div>
						<div v-else-if="isTrusting === true">
							<p style="margin-top: 40px;">Delegate your voting power</p>
							<el-slider v-model="weight"></el-slider>

							<div class="topics">
								<el-checkbox v-model="hasTopics" class="topics-checkbox">For specific topics only</el-checkbox>
								<el-select v-if="hasTopics" v-model="topics" multiple allow-create filterable placeholder="Choose topics" class="topics">
									<el-option v-for="item in allTopics" :key="item.value" :label="item.label" :value="item.value"></el-option>
								</el-select>
							</div>

							<el-button @click="setDelegation()" style="margin-top: 20px;" type="success">Start delegating</el-button>
						</div>
					</div>
				</el-col>
				<el-col :sm="24" :md="6">
					&nbsp;
					<div v-for="delegation in identity.delegations" :key="delegation.to_username">
						<router-link :to="'/identities/' + delegation.to_username">{{ delegation.to_username }}</router-link>
						<span v-if="delegation.is_trusting === false"><i class="el-icon-warning"></i> untrusts</span>
						<span v-if="delegation.is_trusting === true">{{ delegation.weight * 100 }}%</span>
						<span v-if="delegation.is_trusting === true && delegation.topics.length > 0">({{ delegation.topics.join(', ') }})</span>
					</div>
				</el-col>
			</el-row>
		</div>
		<div class="after">
			<div class="pure" v-html="identity.votes_text" v-if="identity.votes.length > 0"></div>
			<div v-else>This identity has no votes.</div>
			<el-button v-if="$store.getters.currentOpts.keypair && identity.username == $store.getters.currentOpts.keypair.username" @click="importVisible = true" style="margin-top: 30px;">Import votes</el-button>
		</div>
	</div>
	<div v-else>
		<div class="main">
			<i class="el-icon-loading loading"></i>
		</div>
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

		this.fetchData(false)

		return {
			username: username,

			identificationType: 'name',
			identificationName: '',
			isTrusting: null,
			topics: [],
			allTopics: [
				{value: 'science', label: 'Science'},
				{value: 'politics', label: 'Politics'},
				{value: 'philosophy', label: 'Philosophy'},
				{value: 'law', label: 'Law'}
			],
			weight: 100,
        	addingTopic: true,
        	topic: '',
			hasTopics: false,

			publicName: '',
			webpageURL: '',

			importVisible: false,
			importData: ''
		}
	},
	watch: {
		'$route': function(route, previous) {
			this.fetchData(route.params.username == previous.params.username)
		}
	},
	computed: {
		identity: function() {
			let identity = this.$store.getters.getIdentityByUsername(this.username)
			if(identity)
				identity.votes_text = identity.votes_text.replace(/\n/g, '<br>').replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;')
			return identity
		},
		ownDelegation: function() {
			return this.identity.delegations_to[this.$store.getters.currentOpts.keypair && this.$store.getters.currentOpts.keypair.username]
		}
	},
	methods: {
		fetchData: function(isSame) {
			let username = this.$route.params.username

			this.$store.dispatch('fetchIdentity', username).then((identity) => {
				let delegation = this.$store.getters.currentOpts.keypair && identity.delegations_to[this.$store.getters.currentOpts.keypair.username]
				if(delegation) {
					this.isTrusting = delegation.is_trusting
					this.weight = delegation.weight * 100
					this.topics = delegation.topics || []
				}
				this.publicName = identity.identifications['name']
				this.username = username
			})
		},
		setTrust: function(v) {
			this.isTrusting = v
			this.setDelegation()
		},
		setDelegation: function() {
			let weight = this.weight ? this.weight / 100 : null
			let topics = this.topics.length > 0 ? this.topics : null
			this.$store.dispatch('setDelegation', {username: this.username, is_trusted: this.isTrusting, weight: weight, topics: topics})
		},
		clearDelegation: function() {
			this.topics = []
			this.weight = 100
			this.$store.dispatch('unsetDelegation', {username: this.username})
		},
		addWebpage: function() {
			this.$store.dispatch('setIdentification', {key: this.webpageURL, name: 'true'})
		},
		setName: function() {
			this.$store.dispatch('setIdentification', {key: 'name', name: this.publicName})
		},
		importVotes: function(data) {
			let {votes, referenceVotes} = this.$store.getters.parseVotes(data)
			console.log(votes)
		}
	}
}
</script>

<style scoped lang="less">
.username {
	font-weight: normal;
	font-size: 28px;
	margin: 0px;
}
.name {
	font-weight: normal;
	font-size: 28px;
	margin: 0px;
	margin-top: 30px;
}
.website {
	display: inline-block;
	margin-top: 10px;
}

.add-identifications {
	margin-top: 50px;

	.add-name, .add-webpage {
		margin-top: 20px;

		.el-input {
			width: 250px;
		}

		.el-button {
			margin-left: 10px;
			width: 140px;
		}
	}
}

.set-delegation {
	margin-top: 50px;

	.topics {
		text-align: left;

		.el-select {
			display: inline-block;
			width: 300px;
			margin-left: 20px;
		}
	}
}

.pure {
	text-align: left;
	font-size: 15px;
	color: #444;
}
</style>