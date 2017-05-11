<template>
<div class="extension">
	<div class="get">
		<h2>Let anyone fact check your website</h2>
		<el-button type="primary" size="large" @click="install" v-if="!isInstalled">
			<img src="/images/icon.svg" style="-webkit-filter: brightness(1000%); vertical-align: middle; width: 50px; opacity: 0.7;"></img>
			<span style="vertical-align: middle; margin-left: 10px; font-size: 22px;">Democratize your website</span>
		</el-button>
	</div>

	<div class="feature">
		<h3>Provide your audience with relevant democratic data</h3>
		<img src="/images/page-score.svg" style="width: 100%;"></img>
		<img src="/images/inline-links.png"></img>
	</div>

	<div class="feature">
		<h3>Complete transparency without censorship</h3>
		<p>It will always be possible to count votes only from the people you trust.</p>
	</div>

	<div class="feature">
		<h3>Set the default trust metric on your website, let anyone choose his/her own</h3>
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
		font-weight: normal;
		font-size: 22px;
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
