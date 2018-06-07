<template>
<div class="liquio-bar" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div v-if="activeNode && !activeNode.mock" ref="barContainer" class="liquio-bar__container liquio-bar__container--node" :class="{ 'liquio-bar__container--shown': activeTitle }">
            <inline-node :node="activeNode" size="small" @click="viewActive"></inline-node>
        </div>
        <div v-else ref="barContainer" class="liquio-bar__container" :class="{ 'liquio-bar__container--shown': isAnnotationBarShown }">
            <template v-if="lastSelection && lastSelection.length >= 10 || currentVideoTime">
                <el-input ref="annotationTitle" v-model="annotationTitle" @blur="onAnnotationTitleBlur" placeholder="Annotation title" class="liquio-bar__annotation-input"></el-input>
                <el-button v-if="lastSelection && lastSelection.length >= 10" size="small" type="primary" @click="startVoting">Vote on selection</el-button>
                <el-button v-else-if="currentVideoTime" size="small" @click="startVoting">Vote on video at {{ currentVideoTimeText }}</el-button>
            </template>
        </div>
    </template>

    <el-dialog v-if="currentTitle" :visible.sync="dialogVisible" width="900px" custom-class="dialog">
        <el-autocomplete
            v-model="searchQuery"
            :fetch-suggestions="querySearchAsync"
            @keyup.enter.native="viewSearch"
            @keyup.delete.stop.native="() => {}"
            @select="viewSearch"
            placeholder="Vote on anything"
            class="search">

            <i v-if="canNavigateBack" @click="navigateBack" slot="prefix" class="el-input__icon el-icon-arrow-left"></i>
            <i @click="viewSearch" slot="suffix" class="el-input__icon el-icon-search"></i>
        </el-autocomplete>

        <reference v-if="currentReferenceTitle" :title="currentTitle" :reference-title="currentReferenceTitle"></reference>
        <node v-else :title="currentTitle"></node>

        <el-autocomplete
            ref="viewReference"
            v-if="!currentReferenceTitle"
            v-model="referenceQuery"
            :fetch-suggestions="querySearchAsync"
            @keyup.enter.native="viewReference"
            @keyup.delete.stop.native="() => {}"
            @select="viewReference"
            placement="top-start"
            placeholder="Add reference"
            class="search-reference">

            <i @click="viewReference" slot="suffix" class="el-input__icon el-icon-arrow-right"></i>
        </el-autocomplete>
    </el-dialog>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Autocomplete, Dialog } from 'element-ui'
import slug from 'slug'
import InlineNode from 'vue/inline_node.vue'
import { allUnits } from 'store/constants'
import NodeElement from 'vue/node.vue'
import Reference from 'vue/reference.vue'
import { mapState, mapGetters, mapActions } from 'vuex'

// Hack to make autocomplete work with shadow DOM
let handleFocus = Autocomplete.methods.handleFocus
Autocomplete.methods.handleFocus = function (event) {
    this.lastFocusTime = Date.now()
    handleFocus.bind(this)(event)
}

let close = Autocomplete.methods.close
Autocomplete.methods.close = function (event) {
    let canClose = true
    if (this.lastFocusTime && Date.now() - this.lastFocusTime < 500)
        canClose = false

    if (canClose)
        close.bind(this)(event)
}

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elAutocomplete: Autocomplete,
        elDialog: Dialog,
        inlineNode: InlineNode,
        node: NodeElement,
        reference: Reference
    },
    props: {
        isUnavailable: { type: Boolean },
        activeTitle: { type: String },
        currentSelection: { type: String },
        currentVideoTime: { type: Number }
    },
    data () {
        return {
            isLoading: true,
            dialogVisible: false,
            searchQuery: '',
            referenceQuery: '',
            annotationTitle: '',
            lastSelection: null,
            isLastSelectionHidden: false
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
    },
    mounted () {
        setTimeout(() => this.isLoading = false, 50)
    },
    watch: {
        currentTitle () {
            if (this.$store.state.isVotingDisabled) {
                this.$nextTick(() => {
                    if (this.$refs.viewReference)
                        this.$refs.viewReference.focus()
                })
            }
        },
        currentSelection (v) {
            if (v) {
                this.isLastSelectionHidden = false
                this.lastSelection = v
            }
        },
        isAnnotationBarShown (v, ov) {
            if (!ov && v) {
                this.annotationTitle = null
                this.$nextTick(() => this.$refs.annotationTitle.focus())
            }
        }
    },
    computed: {
        ...mapState(['currentReferenceTitle']),
        ...mapGetters(['currentTitle', 'canNavigateBack']),
        activeNode () {
            return this.$store.getters.nodeByTitle(this.activeTitle)
        },
        node () {
            return this.$store.getters.nodeByTitle(this.currentTitle)
        },
        currentVideoTimeText () {
            let minutes = Math.floor(this.currentVideoTime / 60)
            let seconds = Math.floor(this.currentVideoTime - minutes * 60)
            return `${('00' + minutes).slice(-2)}:${('00' + seconds).slice(-2)}`
        },
        isAnnotationBarShown () {
            return !this.isLastSelectionHidden && this.lastSelection && this.lastSelection.length >= 10 || this.currentVideoTime
        }
    },
    methods: {
        ...mapActions(['navigateBack', 'search']),
        onAnnotationTitleBlur () {
            setTimeout(() => {
                this.isLastSelectionHidden = true
            }, 100)
        },
        startVoting () {
            let anchor = slug(this.lastSelection || this.currentVideoTimeText).value
            this.$store.dispatch('setCurrentReferenceTitle', this.annotationTitle)
            this.$store.dispatch('setCurrentTitle', this.$store.state.currentPage + '/' + anchor)
            this.$store.dispatch('disableVoting')
            this.lastSelection = null
            this.open()
        },
        viewActive () {
            this.$store.dispatch('setCurrentTitle', this.activeTitle)
            this.open()
        },
        open () {
            this.resetState()
            this.dialogVisible = true
        },
        close () {
            this.dialogVisible = false
        },
        querySearchAsync(queryString, cb) {
            this.search(queryString).then(results => {
                let items = results ? results.map(r => ({ value: r.title })) : []
                cb(items)
            })
        },
        createFilter(queryString) {
            return (link) => {
                return (link.value.toLowerCase().indexOf(queryString.toLowerCase()) === 0)
            };
        },
        viewSearch (e) {
            if (this.searchQuery.length > 0) {
                this.$store.dispatch('setCurrentTitle', e.value || this.searchQuery)
                this.resetState()
            }
        },
        viewReference (e) {
            if (this.referenceQuery.length > 0) {
                this.$store.dispatch('setCurrentReferenceTitle', e.value || this.referenceQuery)
                this.resetState()
            }
        },
        resetState () {
            this.searchQuery = '',
            this.referenceQuery = ''
        }
    }
}
</script>
