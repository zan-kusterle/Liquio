<template>
    <div v-if="node && referenceNode" class="liquio-reference">
        <inline-node :node="node" @click="viewNode(node)" size="medium"></inline-node>
        <i class="el-icon-arrow-down"></i>
        <inline-node :node="referenceNode" @click="viewNode(referenceNode)" size="medium"></inline-node>

        <inline-node :node="resultsNode" size="large" style="margin-top: 40px;"></inline-node>

        <div class="vote" style="margin-top: 20px;">
            <div class="choice">
                <el-slider v-model="currentRelevance" class="spectrum"></el-slider>
            </div>
            <el-button-group class="vote-buttons">
                <el-button type="success" @click="vote" class="vote-button">Vote</el-button>
                <el-button v-if="currentVote" type="danger" @click="unsetVote" class="vote-button">Delete vote</el-button>
            </el-button-group>
        </div>
    </div>
    <div v-else class="liquio-loading">
        <i class="el-icon-loading"></i>
    </div>
</template>

<script>
import { Slider, Button, ButtonGroup } from 'element-ui'
import InlineNode from 'vue/inline_node.vue'
import { mapGetters } from 'vuex'

export default {
    components: {
        elSlider: Slider,
        elButtonGroup: ButtonGroup,
        elButton: Button,
        inlineNode: InlineNode
    },
    props: {
        title: { type: String, required: true },
        referenceTitle: { type: String, required: true }
    },
    data () {
        return {
            currentRelevance: 50
        }
    },
    watch: {
        currentVote (v) {
             if (v) {
                this.currentRelevance = Math.round(v.choice * 100)
            } else {
                this.currentRelevance = 50
            }
        }
    },
    computed: {
        ...mapGetters('annotate', 'nodeByTitle', 'usernames'),
        node () {
            return this.nodeByTitle(this.title)
        },
        referenceNode () {
            return this.nodeByTitle(this.referenceTitle)
        },
        referenceResults () {
            if (!this.node)
                return null
            let reference = this.node.references.find(r => r.title === this.referenceTitle)
            if (!reference)
                return null
            return {
                ...reference.referenceResults,
                unit: {
                    type: 'spectrum'
                }
            }
        },
        currentVote () {
            return this.referenceResults && this.referenceResults.contributions.find(c => this.usernames.includes(c.username))
        },
        resultsNode () {
            return {
                title: 'Reference relevance',
                results: {
                    "Relevant-Irrelevant": this.referenceResults
                }
            }
        }
    },
    methods: {
        vote () {
            this.$store.dispatch('annotate/vote', {
                messages: [{
                    name: 'reference_vote',
                    key: ['title', 'reference_title'],
                    title: this.title.trim(' '),
                    reference_title: this.referenceTitle.trim(' '),
                    relevance: this.currentRelevance / 100
                }],
                messageKeys: ['title', 'reference_title', 'relevance']
            }).then(() => {
                this.$store.dispatch('loadNode', { key: this.title })
                this.$store.dispatch('loadNode', { key: this.referenceTitle })
            })
        },
        unsetVote () {
            this.$store.dispatch('annotate/vote', {
                messages: [{
                    name: 'reference_vote',
                    key: ['title', 'reference_title'],
                    title: this.title.trim(' '),
                    reference_title: this.referenceTitle.trim(' '),
                    relevance: null
                }],
                messageKeys: ['title', 'reference_title', 'relevance']
            }).then(() => {
                this.$store.dispatch('loadNode', { key: this.title })
                this.$store.dispatch('loadNode', { key: this.referenceTitle })
            })
        },
        viewNode (node) {
            this.$store.dispatch('setCurrentReferenceTitle', null)
            this.$store.dispatch('setCurrentTitle', node.title)
        }
    }
}
</script>