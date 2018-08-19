<template>
    <div class="liquio-node">
        <inline-node :node="currentNode.definition" size="large"></inline-node>

        <template v-if="currentNode.data">
            <div style="text-align: center;">
                <results :results="currentNode.data.results" :unit="currentNode.definition.comments.length > 0 ? 'Useless-Useful' : currentNode.definition.unit" size="large"></results>
            </div>

            <div class="vote">
                <vote :is-quantity="!currentNode.definition.isSpectrum" :existing-value="currentVote && currentVote.choice" @set="setVote({ choice: $event })" @unset="setVote({ choice: null })" />
            </div>

            <div class="liquio-node__references" v-if="listItems.length > 0">
                <div v-for="(item, index) in listItems" :key="index" class="liquio-node__reference">
                    <template v-if="item.type === 'reference'">
                        <div class="liquio-node__progress-container" @click="openReference(item)">
                            <progress min="0" max="1" :value="item.weight" style="width: 100px;" />
                        </div>
                        <inline-node :node="item.definition" :results="item.results" @click="setDefinition(item.definition)" size="small"></inline-node>
                    </template>
                    <template v-else-if="item.type === 'comment'">
                        <div class="liquio-node__progress-container"  @click="openComment(item)">
                            <progress min="0" max="1" :value="item.weight" style="width: 100px;" />
                        </div>
                        <span style="font-size: 18px;" @click="setCommentDefinition(item)">{{ item.text }}</span>
                    </template>
                </div>
            </div>
        </template>
        <div v-else class="liquio-loading">
            <i class="el-icon-loading"></i>
        </div>

        <div class="search-reference">
            <div class="post-comment">
                <el-input type="textarea" autosize v-model="commentInputText" placeholder="Post a comment"></el-input>
                <el-button @click="setCommentVote({ text: commentInputText, score: 1.0 })" style="width: 120px; margin-left: 5px;">Post</el-button>
            </div>

            <div style="text-align: center;">
                <el-button @click="isAddReferenceDialogOpen = true" :disabled="recentDefinitions.length === 0" style="width: 50%;">Link recent item <i class="el-icon-tickets"></i></el-button>
            </div>


            <div style="overflow: hidden; transition: all 0.25s ease-out;" :style="{ maxHeight: isRelatedListOpen ? '400px' : '0px', height: isRelatedListOpen ? '200px' : '0px' }">
                <div v-for="(definition, index) in recentDefinitions" :key="index" @click="setDefinition(definition)">
                    <inline-node :node="definition" :show-unit="true" size="medium" class="liquio-node__main"></inline-node>
                </div>
            </div>
            <div @click="isRelatedListOpen = !isRelatedListOpen" style="display: flex; align-items: center; padding: 0 5px; font-size: 42px;">
                <i class="el-icon-caret-bottom"></i>
            </div>
        </div>

        <el-dialog v-if="currentReference" :visible.sync="isReferenceDialogOpen" custom-class="reference-dialog">
            <p style="font-size: 24px; margin-bottom: 40px; color: #333; letter-spacing: 1.3px;">LINK DETAILS</p>

            <inline-node :node="currentReference.definition" :results="currentReference.data.results" size="medium" class="liquio-node__main"></inline-node>

            <results :results="currentReference.referenceResults" unit="Irrelevant-Relevant" size="large" style="margin-top: 80px;" />

            <div class="vote">
                <vote :existing-value="currentReferenceVote && currentReferenceVote.choice" @set="setReferenceVote({ definition: currentReference.definition, relevance: $event })" @unset="setReferenceVote({ definition: currentReference.definition, relevance: null })" />
            </div>
        </el-dialog>

        <el-dialog v-if="currentComment" :visible.sync="isCommentDialogOpen" custom-class="reference-dialog">
            <p style="font-size: 24px; margin-bottom: 40px; color: #333; letter-spacing: 1.3px;">COMMENT DETAILS</p>

            <inline-node :node="currentComment.definition" :results="currentComment.data.results" size="medium" class="liquio-node__main"></inline-node>

            {{ currentComment.data.text }}
            <p>Score</p>

            <results :results="currentComment.data.results" unit="Useless-Useful" size="large" />

            <div class="vote">
                <vote :existing-value="currentCommentVote && currentCommentVote.choice" @set="setCommentVote({ text: currentCommentText, score: $event })" @unset="setCommentVote({ text: currentCommentText, score: null })" />
            </div>
        </el-dialog>

        <el-dialog :visible.sync="isAddReferenceDialogOpen" custom-class="reference-dialog">
            <p>Recent nodes</p>

            <div v-for="(definition, index) in recentDefinitions" :key="index" @click="addReferenceDefinition(definition)">
                <inline-node :node="definition" :show-unit="true" size="small" class="liquio-node__main"></inline-node>
            </div>
        </el-dialog>
    </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import { Button, Input, Dialog } from 'element-ui'
import { compareDefinition, compareComments } from '../store/annotate/utils'
import InlineNode from './generic/inline_node.vue'
import Results from './generic/results.vue'
import Vote from './generic/vote.vue'

export default {
    components: {
        elButton: Button,
        elInput: Input,
        elDialog: Dialog,
        InlineNode,
        Results,
        Vote,
    },
    data () {
        return {
            commentInputText: '',
            currentReferenceDefinition: null,
            isReferenceDialogOpen: false,
            currentCommentText: null,
            isCommentDialogOpen: false,
            isAddReferenceDialogOpen: false,
            isRelatedListOpen: false,
        }
    },
    computed: {
        ...mapGetters('annotate', ['currentNode', 'recentDefinitions']),
        ...mapGetters('sign', ['usernames']),
        currentVote () {
            return this.currentNode.data && this.currentNode.data.results.contributions.find(c => this.usernames.includes(c.username))
        },
        currentReference () {
            return this.currentReferenceDefinition && this.currentNode.data &&
                this.currentNode.data.references.find(r => compareDefinition(r.definition, this.currentReferenceDefinition))
        },
        currentReferenceVote () {
            return this.currentReference && this.currentReference.referenceResults.contributions.find(c => this.usernames.includes(c.username))
        },
        currentComment () {
            return this.currentCommentText && this.currentNode.data && this.currentNode.data.comments.find(c => {
                return compareComments(c.definition.comments, this.currentNode.definition.comments.concat([this.currentCommentText]))
            })
        },
        currentCommentVote () {
            return this.currentComment && this.currentComment.data.results.contributions.find(c => this.usernames.includes(c.username))
        },
        listItems () {
            let comments = this.currentNode.data.comments.map(comment => {
                return {
                    type: 'comment',
                    weight: comment.data.results.mean,
                    text: comment.definition.comments[0],
                    definition: comment.definition,
                }
            })

            let references = this.currentNode.data.references.map(reference => {
                return {
                    type: 'reference',
                    weight: reference.referenceResults.mean,
                    definition: reference.definition,
                    results: reference.data.results,
                }
            })

            return comments.concat(references).sort((a, b) => b.weight - a.weight)
        }
    },
    methods: {
        ...mapActions('annotate', ['loadNode', 'setDefinition', 'setVote', 'setReferenceVote', 'setCommentVote']),
        openReference (reference) {
            this.currentReferenceDefinition = reference.definition
            this.isReferenceDialogOpen = true
        },
        openComment (comment) {
            this.currentCommentText = comment.text
            this.isCommentDialogOpen = true
        },
        addReferenceDefinition (definition) {
            this.isAddReferenceDialogOpen = false
            this.setReferenceVote({ definition: definition, relevance: 1 })
        },
        setCommentDefinition (comment) {
            this.setDefinition({
                ...this.currentNode.definition,
                comments: this.currentNode.definition.comments.concat([comment.text])
            })
        }
    }
}
</script>
