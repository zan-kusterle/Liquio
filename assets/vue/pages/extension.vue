<template>
<div class="extension">
	<div class="get">
		<h2>Vote on anything, anywhere on the web</h2>
		<el-button type="primary" size="large" @click="install" v-if="!isInstalled">
			<img src="/images/google-chrome-icon.png" style="vertical-align: middle; width: 50px; opacity: 0.7;"></img>
			<span style="vertical-align: middle; margin-left: 10px; font-size: 22px;">Get free extension</span>
		</el-button>
	</div>

	<div class="feature">
		<h3>Spot unreliable, fake or biased news</h3>
		<img src="/images/article-score.png"></img>
		<img src="/images/link-score.png"></img>
	</div>

	<div class="feature">
		<h3>Get relevant data at the right time</h3>
		<img src="/images/inline-links.png"></img>
	</div>

	<div class="feature">
		<h3>Transparent democracy without moderation</h3>
		<p>Liquio is a public database of votes. You will always have the ability to only count votes from the people you trust.</p>
	</div>
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

<style lang="less" scoped>
.extension {
	text-align: center;
}

.feature {
	margin-bottom: 100px;

	h3 {
		display: inline-block;
		border-top: 1px solid #ddd;
		padding: 20px 80px;
		padding-bottom: 0px;
		margin: 0;
		margin-bottom: 40px;
		text-transform: uppercase;
		font-weight: normal;
		font-size: 18px;
		color: #111;
	}

	img {
		opacity: 0.8;
		display: block;
		margin: 0 auto;
		margin-bottom: 20px;
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
</style>
