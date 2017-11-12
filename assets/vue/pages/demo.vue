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
<div>
    <h1 class="title">Is Human Activity the Cause of Global Warming?</h1>

    <div style="text-align: center;">
        <a href="/n/Human-activity-is-causing-global-warming" class="main-node">View on Liquio</a>
    </div>

    <div class="section">
        <a href="/n/Earth-temperature">Earth temperature is rising</a>
        <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi ac tempor tellus. Suspendisse non eros eget arcu eleifend ornare. Duis faucibus tempor mi a varius. Quisque sed sapien hendrerit, euismod libero vel, fermentum eros. Maecenas dignissim mi
            sed libero tincidunt dignissim. Phasellus congue erat eu dignissim porta. Nulla iaculis ipsum ac pharetra elementum. Vivamus et semper leo, quis pellentesque nisi. Sed nec bibendum risus. Proin aliquet sagittis dictum. Nunc vel interdum dui.
        </p>
    </div>


    <hr style="margin: 300px 0 80px 0; width: 100%; display: block;" />

    <div>
        <h2 class="title">Powered by this code</h2>
        <div style="padding: 20px 50px; background-color: #f5f5f5;">
<pre ref="copyArea" style="color: #888; text-align: left; width: 100%; opacity: 0.7;">&lt;script&gt;
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

        <a @click="addToClipboard">Copy this</a>
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

    },
    methods: {
        addToClipboard () {
            let copyTextarea = this.$refs.copyArea
            console.log(copyTextarea)
            copyTextarea.select()

            try {
                var successful = document.execCommand('copy');
                var msg = successful ? 'successful' : 'unsuccessful';
                console.log('Copying text command was ' + msg);
            } catch (err) {
                console.log('Oops, unable to copy');
            }
        }
    }
}
</script>