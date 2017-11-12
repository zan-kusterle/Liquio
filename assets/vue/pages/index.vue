<template>
<div>
	<el-popover
		ref="extension-popover"
		placement="bottom"
		width="300"
		trigger="hover"
		content="Extension allows you to see votes on any website. To vote select text and right click.">
	</el-popover>

	<div class="after">
		<h1 class="title">{{ $t('message.tagline') }}</h1>

		<el-input :placeholder="$t('message.search')" v-model="searchText" @keyup.native.enter="search" style="max-width: 800px;">
			<el-button slot="append" icon="el-icon-search" @click="search"></el-button>
		</el-input>

		<div>
			<el-button v-popover:extension-popover type="primary" size="large" @click="install" v-if="!isInstalled" class="feature-button">
				<img src="/images/google-chrome-icon.png"></img>
				<span>Get free extension</span>
			</el-button>
		
			<el-button type="primary" size="large" @click="$router.push('demo')" class="feature-button">
				<img src="/images/icon.svg"></img>
				<span>View demo article</span>
			</el-button>
		</div>

		<el-row style="margin-top: 40px;" :gutter="40">
			<el-col :span="8">
				<div class="feature">
					<h3>Cryptographically secure</h3>
					<p>Every vote has a signature which proves its integrity. Data is also stored on <a href="https://ipfs.io" target="_blank"><b>IPFS</b></a> to make it impossible to modify or delete.</p>
				</div>
			</el-col>

			<el-col :span="8">
				<div class="feature">
					<h3>Moderation free</h3>
					<p><a href="/faq#trust-metrics">Trust metrics</a> give you the power to be your own moderator.</p>
				</div>
			</el-col>

			<el-col :span="8">
				<div class="feature">
					<h3>Open source</h3>
					<p>Code is available under permissive MIT license on <a href="https://github.com/zan-kusterle/Liquio" target="_blank">GitHub</a>.</p>
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
			isInstalled: chrome.app.isInstalled,
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
				this.$router.push('/search/' + encodeURIComponent(this.searchText))
			}
		},
		install () {
			chrome.webstore.install()
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
	text-align: center;
	display: block;
	display: inline-block;
	margin: 80px 50px 20px 50px;

	img {
		display: inline-block;
		-webkit-filter: brightness(0%);
		vertical-align: middle;
		width: 40px;
		opacity: 0.7;
		margin: 0;
	}

	span {
		display: inline-block;
		vertical-align: middle;
		margin-left: 10px;
		font-size: 22px;
	}
}

.feature {
	text-align: left;
	background: #f0f9ff;
	padding: 20px 30px;

	a {
		font-weight: bold;
	}

	h3 {
		display: block;
		margin: 0;
		margin-bottom: 30px;
		font-weight: normal;
		font-size: 22px;
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