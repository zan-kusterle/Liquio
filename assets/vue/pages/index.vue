<template>
<div>
	<el-popover
		ref="extension-popover"
		placement="bottom"
		width="300"
		trigger="hover"
		content="Extension allows you to see votes on any website. To vote select text and right click.">
	</el-popover>

	<el-popover
		ref="inject-popover"
		placement="bottom"
		width="300"
		trigger="hover"
		content="Anyone can add a script to their website to enable their audience to vote on their content.">
	</el-popover>

	<el-popover
		ref="trust-metrics-popover"
		placement="bottom"
		width="300"
		trigger="hover"
		content="A webpage that contains a list of usernames whose votes will be count. You can easily change this list in settings.">
	</el-popover>

	<div class="after">
		<h1 class="title">{{ $t('message.tagline') }}</h1>

		<el-input :placeholder="$t('message.search')" v-model="searchText" @keyup.native.enter="search" style="max-width: 800px;">
			<el-button slot="append" icon="el-icon-more" @click="search"></el-button>
		</el-input>

			<div @click="$router.push('demo')" class="feature-button">
				<img src="/images/icon.svg" />
				<span>View demo article</span>
			</div>

		<el-row style="margin-top: 40px;" :gutter="40">
			<el-col :span="6">
				<div class="feature">
					<h3>No moderation</h3>
					<p><a v-popover:trust-metrics-popover>Trust metrics</a> make you your own moderator.</p>
				</div>
			</el-col>

			<el-col :span="6">
				<div class="feature">
					<h3>Signatures</h3>
					<p>Each vote has a cryptographic signature which proves who made it.</p>
				</div>
			</el-col>

			<el-col :span="6">
				<div class="feature">
					<h3>Permament</h3>
					<p>With <a href="https://ipfs.io" target="_blank">IPFS</a> data is impossible to modify and delete.</p>
				</div>
			</el-col>

			<el-col :span="6">
				<div class="feature">
					<h3>Open source</h3>
					<p>Available under permissive MIT license on <a href="https://github.com/zan-kusterle/Liquio" target="_blank">GitHub</a>.</p>
				</div>
			</el-col>
		</el-row>

		<div class="list-simple">
			<liquio-inline v-for="reference in node.references" :key="reference.key" v-bind:node="reference" v-bind:referencing-node="node.title === '' ? null : node" style="text-align: left;"></liquio-inline>
		</div>
	</div>
</div>
</template>


<script>
import LiquioInline from 'liquio-inline.vue'

export default {
	components: {LiquioInline},
	data () {
		return {
			injectDialogVisible: false,
			searchText: '',
			currentPage: 1
		}
	},
	created () {
		this.$store.dispatch('fetchNode', '')
		this.itemsPerPage = 20
	},
	computed: {
		node () {
			let node = this.$store.getters.currentNode
			node.loading = true

			let newNode = this.$store.getters.getNodeByKey('')
			if(newNode) {
				node = newNode
				node.loading = false
			}
			
			return node
		},
		pages () {
			let nodes = this.node.references
			if(!nodes)
				return []
			let page = nodes.slice(this.itemsPerPage * (this.currentPage - 1), this.itemsPerPage * this.currentPage)
			return page
		}
	},
	methods: {
		search () {
			if (this.searchText.length > 0) {
				this.$router.push('/v/' + encodeURIComponent(this.searchText.replace(/\s/g, '-')))
			}
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
}

.extension {
	text-align: center;
}

.feature-button {
	display: flex;
	margin: 30px auto;
	opacity: 0.8;
	cursor: pointer;
	height: 60px;
	align-items: center;
	justify-content: center;
	border: 1px solid #ccc;
	width: fit-content;
	padding: 10px 50px;

	img {
		display: inline-block;
		vertical-align: middle;
		width: 40px;
		margin: 0;
	}

	span {
		display: inline-block;
		vertical-align: middle;
		margin-left: 10px;
		font-size: 22px;
	}

	&:hover {
		opacity: 1;
	}
}

.feature {
	text-align: left;
	background: #f0f9ff;
	padding: 20px 30px;
	min-height: 150px;

	a {
		font-weight: bold;
	}

	h3 {
		display: block;
		margin: 0;
		margin-bottom: 30px;
		font-weight: normal;
		font-size: 26px;
		color: #111;
		padding-bottom: 10px;
		border-bottom: 1px solid rgba(0, 0, 0, 0.1);

		i {
			font-size: 28px;
			vertical-align: middle;
			margin-left: 15px;
		}
	}

	p {
		color: #444;
		font-size: 16px;
	}	
}

.get {
	margin-bottom: 50px;

	h2 {
		color: #333;
		font-weight: normal;
		font-size: 32px;
		margin: 0;
		margin-bottom: 20px;
	}
}

.list-simple {
	margin-top: 50px;
	column-count: 3;
	column-gap: 30px;

	@media only screen and (max-width: 1000px) {
		column-count: 2;
	}

	@media only screen and (max-width: 600px) {
		column-count: 1;
	}
}
</style>