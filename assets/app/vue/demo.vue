<style>
    a {
        text-decoration: none;
        color: #105cae;
    }
    
    .title {
        font-size: 32px;
        text-align: center;
        font-weight: normal;
    }

    .title {
        display: block;
        margin: 10px 0px;
        font-size: 28px;
        font-weight: normal;
        color: #333;
        opacity: 1;
        word-wrap: break-word;
    }

    
    .main-node {
        display: block;
        margin: 0 auto;
    }
    
    .section {
        margin-top: 50px;
    }
    
    .section>a {
        font-size: 24px;
        margin-right: 15px;
    }
    
    .section>p {
        font-size: 16px;
        color: #333;
    }
</style>

<template>
<div style="padding-bottom: 100px;">
    <div class="demo-message">This is a demo webpage with Liquio bar at the bottom of the screen. You can see average reliability score. Hover over highlighted text to see the attached poll.</div>

    <h1 class="title">Is Human Activity the Cause of Global Warming?</h1>

    <div style="text-align: center;">
        <a href="/v/Human-activity-is-causing-global-warming" class="main-node">View on Liquio</a>
    </div>

    <div class="section">
        <a href="/v/Earth-temperature">Earth temperature is rising</a>
        <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi ac tempor tellus. Suspendisse non eros eget arcu eleifend ornare. Duis faucibus tempor mi a varius. Quisque sed sapien hendrerit, euismod libero vel, fermentum eros. Maecenas dignissim mi
            sed libero tincidunt dignissim. Phasellus congue erat eu dignissim porta. Nulla iaculis ipsum ac pharetra elementum. Vivamus et semper leo, quis pellentesque nisi. Sed nec bibendum risus. Proin aliquet sagittis dictum. Nunc vel interdum dui.
        </p>
    </div>

    <div style="margin-top: 200px;">
        <el-button type="primary" size="large" @click="install" class="feature-button">
            <img src="/images/google-chrome-icon.png"></img>
            <span>Get free extension</span>
        </el-button>

        <h2 class="title">Add this code to your website</h2>
        <div style="padding: 20px 50px; background-color: #f5f5f5;">
<pre style="color: #888; text-align: left; width: 100%; opacity: 0.7;">&lt;script&gt;
    (function(d, script) {
        script = d.createElement('script');
        script.type = 'text/javascript';
        script.async = true;
        script.onload = function() {};
        script.src = 'https://liqu.io/inject.js';
        d.getElementsByTagName('head')[0].appendChild(script);
    }(document));
&lt;/script&gt;
</pre>
        </div>
    </div>

</div>
</template>

<script>
export default {
    mounted () {
        let script = document.createElement('script')
        script.type = 'text/javascript'
        script.async = true
        script.onload = function() {}
        script.src = '/inject.js'
        document.getElementsByTagName('head')[0].appendChild(script)
    },
    beforeDestroy () {
        let bar = document.getElementById('liquio-bar')
        if (bar)
            bar.remove()
    },
    methods: {
        install () {
			chrome.webstore.install()
		}
    }
}
</script>

<style scoped lang="less">
.demo-message {
    background-color: #ffbc20;
    padding: 10px 30px;
    margin-bottom: 50px;
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
</style>