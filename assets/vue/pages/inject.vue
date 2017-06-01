<template>
<div class="inject">
	<div class="get">
		<h2>Let everyone see relevant facts on your website</h2>
		<el-button type="primary" size="large" @click="dialogVisible = !dialogVisible">
			<img src="/images/icon.svg" style="-webkit-filter: brightness(1000%); vertical-align: middle; width: 50px; opacity: 0.7;"></img>
			<span style="vertical-align: middle; margin-left: 10px; font-size: 22px;">Democratize your website</span>
		</el-button>
	</div>

	<el-dialog title="Add this code to your site" v-model="dialogVisible">
<pre style="color: #888; border: 1px solid #ccc; background-color: #f5f5f5; text-align: left; width: 100%;">(function(d, script) {
    script = d.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.onload = function(){};
    script.src = '<b>https://liqu.io/infuse.js</b>';
    d.getElementsByTagName('head')[0].appendChild(script);
}(document));</pre>
	</el-dialog>

	<div class="feature">
		<h3>Add reliable democratic insights to your website</h3>
		<img src="/images/reference.png" style="max-width: 800px;"></img>
	</div>

	<div class="feature">
		<h3>Relevant data at the right time</h3>
		<img src="/images/inline-links.png"></img>
	</div>

	<div class="feature">
		<h3>Completely transparent without moderation or censorship</h3>
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
			dialogVisible: false
		}
	}
}
</script>

<style lang="less" scoped>
.inject {
	text-align: center;
}

.feature {
	margin-bottom: 40px;

	h3 {
		display: inline-block;
		border-top: 1px solid #eee;
		padding: 40px 80px;
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

.footnote {
	font-size: 15px;
	color: #aaa;
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
