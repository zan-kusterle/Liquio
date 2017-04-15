<template>
<div class="extension">
	<el-row :gutter="50">
		<el-col :span="8" class="get-extension">
			<el-button type="primary" size="large" @click="install"  v-if="!isInstalled">
				<img src="/images/google-chrome-icon.png" style="vertical-align: middle; width: 50px; opacity: 0.7;"></img>
				<span style="vertical-align: middle; margin-left: 10px; font-size: 22px;">Get free extension</span>
			</el-button>
			<div style="font-size: 13px; margin-top: 10px; margin-right: 15px;">
				<router-link to="/" style="color: #888;">return to Liquio</router-link>
			</div>
		</el-col>
		<el-col :span="16" class="features">
			<ul>
				<li>See <b>relevant polls</b> for any <b>link</b> or <b>paragraph of text</b> on the web.</li>
				<li>Spot <b>unreliable</b>, <b>biased</b> or <b>fake news</b> instantly.</li>
				<li>Completely <b>democratic</b> with <b>no moderation</b>.</li>
				<li>You can <b>choose</b> the people to trust by changing your <b>trust metric</b>.</li>
			</ul>
		</el-col>
	</el-row>
</div>
</template>

<script>
import App from '../app.vue'

export default {
	components: {App},
	props: [],
	data: function() {
		return {
			isInstalled: chrome.app.isInstalled,
			install: function() {
				chrome.webstore.install()
			}
		}
	}
}
</script>

<style lang="less">
.extension {
	margin-top: 50px;
}

.features {
	text-align: left;

	ul {
		list-style: none;
		font-size: 16px;
		padding: 0px;

		li {
			margin: 15px 0px;
		}
	}
}

.get-extension {
	text-align: right;
	margin-top: 30px;
}
</style>
