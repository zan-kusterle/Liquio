<template>
<div>
	<div class="after">
		<h1 class="title">{{ $t('message.tagline') }}</h1>

		<el-input :placeholder="$t('message.search')" v-model="search_title" @keyup.native.enter="search" style="max-width: 800px;">
			<el-button slot="append" icon="search" @click="search"></el-button>
		</el-input>

		<el-row :gutter="60" style="margin-top: 100px;">
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-eye"></i>{{ $t('message.features.news') }}</h3>
					<img src="/images/liquio-bar-c.svg" width="100%"></img>
					<img src="/images/link-score.svg" width="100%" style="margin-top: 50px;"></img>
					<p>{{ $t('message.features.news_subtext') }}</p>
				</div>
			</el-col>
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-pie-chart"></i>Get relevant data at the right time</h3>
					<img src="/images/inline-links.svg"></img>
					<img src="/images/video-annotations.svg" style="margin-top: 50px; opacity: 1;"></img>
					<p>See polls for any paragraph or on YouTube.</p>
				</div>
			</el-col>
		</el-row>
		<el-row :gutter="60" style="margin-top: 40px;">
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-link"></i>Link polls to content on the web</h3>
					<img src="/images/reference.png" style="max-width: 800px;"></img>
				</div>
			</el-col>
		
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-lock"></i>Cryptographically secure</h3>
					<p>Votes and delegations have a cryptographic signature that proves their integrity. Data is also stored on <a href="https://ipfs.io" target="_blank"><b>IPFS</b></a> to make it impossible for anyone to delete or change.</p>
				</div>
			</el-col>
		</el-row>
		<el-row :gutter="60" style="margin-top: 40px;">
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-comments"></i>No moderation or censorship</h3>
					<p><a href="/faq#trust-metrics">Trust metrics</a> give you the power to be your own moderator.</p>
				</div>
			</el-col>
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3><i class="fa fa-cog"></i>Open and transparent</h3>
					<p>All data is publicly available to anyone on <a href="/faq#ipfs">IPFS</a>. Code is also available on <a href="https://github.com/zan-kusterle/Liquio" target="_blank">GitHub <i class="fa fa-github"></i></a>.</p>
				</div>
			</el-col>
		</el-row>

		<el-row :gutter="20" style="margin-top: 80px;">
			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3 style="margin-bottom: 10px;">See and add democratic polls anywhere</h3>
					<el-button type="primary" size="large" @click="install" v-if="!isInstalled" class="feature-button">
						<img src="/images/google-chrome-icon.png"></img>
						<span>Get free extension</span>
					</el-button>
				</div>
			</el-col>

			<el-col :sm="24" :md="12">
				<div class="feature">
					<h3 style="margin-bottom: 10px;">Let people see democratic data on your website</h3>
					<el-button type="primary" size="large" @click="injectDialogVisible = !injectDialogVisible" class="feature-button">
						<img src="/images/icon.svg"></img>
						<span>Get the code</span>
					</el-button>
				</div>
			</el-col>
		</el-row>

		<div class="feature" style="margin-top: 100px;">
			<h3>For more information check out <router-link :to="'/faq'"><b>frequently asked questions</b></router-link>.</h3>
		</div>

		<el-dialog v-model="injectDialogVisible">
			<h2 class="title">Add this code to your webpage</h2>

<pre style="color: #888; border: 1px solid #ccc; background-color: #f5f5f5; text-align: left; width: 100%;">&lt;script&gt;
	(function(d, script) {
		script = d.createElement('script');
		script.type = 'text/javascript';
		script.async = true;
		script.onload = function(){};
		script.src = '<b>https://liqu.io/infuse.js</b>';
		d.getElementsByTagName('head')[0].appendChild(script);
	}(document));
&lt;/script&gt;</pre>
		</el-dialog>

		<div class="list-simple">
			<liquio-inline v-for="reference in node.references" :key="reference.key" v-bind:node="reference" v-bind:referencing-node="node.title === '' ? null : node" style="text-align: left;"></liquio-inline>
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

		this.$store.dispatch('fetchNode', '')

		return {
			injectDialogVisible: false,
			search_title: '',
			search: (event) => {
				self.$router.push('/search/' + encodeURIComponent(self.search_title))
			},
			isInstalled: chrome.app.isInstalled,
			install: function() {
				chrome.webstore.install()
			}
		}
	},
	computed: {
		node: function() {
			let node = getNode(this.$store)
			
			return node
		}
	}
}

let getNode = ($store) => {
	let node = $store.getters.currentNode
	node.loading = true

	let newNode = $store.getters.getNodeByKey('')
	if(newNode) {
		node = newNode
		node.loading = false
	}
	
	return node
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

.feature {
	text-align: center;

	a {
		font-weight: bold;
	}

	h3 {
		display: block;
		margin: 0;
		margin-bottom: 40px;
		font-weight: normal;
		font-size: 22px;
		color: #111;

		i {
			font-size: 28px;
			vertical-align: middle;
			margin-right: 15px;
		}
	}

	p {
		color: #444;
		font-size: 14px;
	}

	img {
		width: 100%;
		opacity: 0.8;
		display: block;
		margin: 0 auto;
		margin-bottom: 20px;
	}

	.feature-button {
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
	margin-top: 100px;
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