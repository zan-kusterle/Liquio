<template>
<div class="features">
    <div class="feature">
        <div class="graph">
            <div class="svg-wrap">
                <graph :state="state" @click="onSelect" />
            </div>

            <p>{{ explainationText }}</p>

            <svg @click="nextStep" style="margin-left: 50px;" width="100px" viewBox="0 0 60 100" xmlns="http://www.w3.org/2000/svg">
                <path fill="rgba(0, 0, 0, 0.3)" d="M58.371 46.098l-45.449-44.5A5.604 5.604 0 0 0 8.971 0a5.601 5.601 0 0 0-3.95 1.598L1.674 4.874a5.398 5.398 0 0 0 0 7.736l38.165 37.369L1.632 87.39A5.374 5.374 0 0 0 0 91.257c0 1.466.58 2.839 1.632 3.87l3.347 3.275A5.603 5.603 0 0 0 8.929 100c1.496 0 2.9-.567 3.951-1.598l45.491-44.541A5.38 5.38 0 0 0 60 49.982a5.38 5.38 0 0 0-1.629-3.884z"/>
            </svg>
        </div>
    </div>

    <div class="feature">
        Anonymous, signed, permament.
        figure: anon user -> signs data in browser -> signed data sent to server -> ipfs -> browser gets data through proxy
    </div>
    
    <div class="feature">
        How do I know results are reliable: Whitelists
        Delegations
        figure: data -> whitelist filtering box (proxy) -> browser


        Stack exchange / subreddits, what's the difference?
    </div>

</div>
</template>

<script>
import Graph from './Graph.vue'

export default {
    components: { Graph },
    data () {
        return {
            activeIndex: null
        }
    },
    created () {
        this.steps = ['node', 'referenceQuantity', 'referenceSpectrum', 'webpage', 'big']
    },
    computed: {
        explainationText () {
            if (this.state === null) {
                return 'Lorem ipsum'
            } else if (this.state === 'node') {
                return 'A claim that is complex to verify'
            } else if (this.state === 'referenceQuantity') {
                return 'Very specific quantitative data that is hard to deny'
            } else if (this.state === 'referenceSpectrum') {
                return 'A more specific claim that is easier to verify'
            } else if (this.state === 'webpage') {
                return 'Any page on the web'
            } else if (this.state === 'big') {
                return 'There are other websites that can link to same claim'
            }
        },
        state () {
            
            if (this.activeIndex === null)
                return null
            return this.steps[this.activeIndex % this.steps.length]
        }
    },
    methods: {
        nextStep () {
            if (this.activeIndex === null)
                this.activeIndex = 0
            else
                this.activeIndex ++
        },
        onSelect (name) {
            let index = this.steps.findIndex(x => x === name)
            this.activeIndex = index
        }
    }
}
</script>

<style scoped>


.feature {
	margin: 0px 20px;
	margin-bottom: 60px;
	padding: 30px 20px;
}

.graph {
    display: flex;
    align-items: center;
}

.graph > .svg-wrap {
    font-size: 0;
    flex: 3;
    min-width: 600px;
    max-width: 700px;
    background-color: white;
    padding: 10px;
    border-radius: 3px;
    /* border: 1px solid #ccc; */
}

.graph > p {
    flex: 5;
    margin: 0;
    padding-left: 50px;
    font-size: 28px;
    font-family: "Helvetica";
    text-align: left;
}
</style>
