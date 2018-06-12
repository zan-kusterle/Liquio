<template>
<div class="liquio-bar" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div v-if="activeTitle && activeNode && !activeNode.mock" ref="barContainer" class="liquio-bar__container liquio-bar__container--node">
            <inline-node :node="activeNode" size="small" @click="viewActive"></inline-node>
        </div>
        <div v-else-if="isAnnotationBarShown" ref="barContainer" class="liquio-bar__container">
            <el-input ref="annotationTitle" v-if="isAnnotationTitleInputShown" v-model="annotationTitle" placeholder="Annotation title" class="liquio-bar__annotation-input"></el-input>

            <el-button v-if="lastSelection && lastSelection.length >= 10" size="small" type="primary" @click="startVoting" :disabled="isAnnotationTitleInputShown && !annotationTitle">Vote on selection</el-button>
            <el-button v-else-if="currentVideoTime" size="small" @click="startVoting" :disabled="isAnnotationTitleInputShown && !annotationTitle">Vote on video at {{ currentVideoTimeText }}</el-button>
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

    <el-dialog :visible.sync="isSignMessageDialogVisible" width="500px" custom-class="sign-message-dialog">
        <div class="liquio-bar__sign-extension-message">
            <p>You need another extension to save your vote.</p>

            <img :src="webstoreImageUrl" />

            <a target="_blank" href="https://chrome.google.com/webstore/detail/liquio/ppkmmjfnokhjpmkcancnceolnobphgdk">
                <button>Install <b>Liquio Sign</b> to vote</button>
            </a>
        </div>
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
            isAnnotationTitleInputShown: false
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
        this.lastSelectionSetTime = 0
    },
    mounted () {
        setTimeout(() => this.isLoading = false, 50)
        document.addEventListener('click', this.onClick)
    },
    beforeDestroy () {
        document.removeEventListener('click', this.onClick)
    },
    watch: {
        currentSelection (v, ov) {
            if (v && v != ov) {
                this.isAnnotationTitleInputShown = false
                this.lastSelection = v
                this.lastSelectionSetTime = Date.now()
            }
        }
    },
    computed: {
        ...mapState(['currentReferenceTitle', 'showSignInstallMessage']),
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
            return this.lastSelection && this.lastSelection.length >= 10 || this.currentVideoTime
        },
        webstoreImageUrl () {
            return chrome.extension.getURL('images/chrome-web-store-badge.png')
        },
        isSignMessageDialogVisible: {
            get () {
                return this.showSignInstallMessage
            },
            set () {
                this.$store.dispatch('hideSignInstallDialog')
            }
        }
    },
    methods: {
        ...mapActions(['navigateBack', 'search']),
        onClick (ev) {
            let el = document.getElementById(IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar')
            let isOutside = !(el === event.target || el.contains(event.target))
            if (isOutside && Date.now() > this.lastSelectionSetTime + 10) {
                this.lastSelection = null
                this.isAnnotationTitleInputShown = false
            }
        },
        startVoting () {
            if (this.isAnnotationTitleInputShown) {
                let anchor = slug(this.lastSelection || this.currentVideoTimeText).value
                this.$store.dispatch('setCurrentReferenceTitle', this.annotationTitle)
                this.$store.dispatch('setCurrentTitle', this.$store.state.currentPage + '/' + anchor)
                this.$store.dispatch('disableVoting')
                this.lastSelection = null
                this.isAnnotationTitleInputShown = false
                this.open()
            } else {
                this.lastSelectionSetTime = Date.now()
                this.annotationTitle = null
                this.isAnnotationTitleInputShown = true
                this.$nextTick(() => this.$refs.annotationTitle.focus())
            }
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
