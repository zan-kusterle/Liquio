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

    <el-dialog v-if="currentTitle" :visible.sync="dialogVisible" :before-close="beforeCloseDialog" custom-class="dialog">
        <el-autocomplete
            v-model="searchQuery"
            :fetch-suggestions="querySearchAsync"
            @keyup.enter.native="viewSearch"
            @keyup.delete.stop.native="() => {}"
            @select="viewSearch"
            placeholder="Vote on anything"
            class="search">

            <div v-if="canNavigateBack" @click="navigateBack" slot="prefix" class="back-button">
                <i class="el-input__icon el-icon-arrow-left"></i>
                <span>BACK</span>
            </div>
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

    <el-dialog v-if="messagesToSign.length > 0" :visible.sync="signDialogVisible">
        <Sign />
    </el-dialog>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Autocomplete, Dialog } from 'element-ui'
import slug from 'slug'
import InlineNode from 'vue/inline_node.vue'
import NodeElement from 'vue/node.vue'
import Reference from 'vue/reference.vue'
import Sign from 'vue/sign.vue'
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
        reference: Reference,
        Sign
    },
    props: {
        isUnavailable: { type: Boolean },
        activeTitle: { type: String },
        currentVideoTime: { type: Number }
    },
    data () {
        return {
            isLoading: true,
            dialogVisible: false,
            signDialogVisible: true,
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
        document.addEventListener('keyup', this.updateSelection)
        document.addEventListener('mouseup', this.updateSelection)
        this.$el.addEventListener('mousemove', this.onMouseMove)
    },
    beforeDestroy () {
        document.removeEventListener('click', this.onClick)
        document.removeEventListener('keyup', this.updateSelection)
        document.removeEventListener('mouseup', this.updateSelection)
        this.$el.removeEventListener('mousemove', this.onMouseMove)
    },
    watch: {
        messagesToSign (v, ov) {
            console.log(v, ov)
            if (v.length > 0 && v.length !== ov.length) {
                this.signDialogVisible = true
            }
        }
    },
    computed: {
        ...mapState('sign', ['messagesToSign']),
        ...mapState('annotate', ['currentPage', 'currentReferenceTitle']),
        ...mapGetters('annotate', ['currentTitle', 'canNavigateBack', 'nodeByTitle']),
        activeNode () {
            return thi.nodeByTitle(this.activeTitle)
        },
        node () {
            return this.nodeByTitle(this.currentTitle)
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
            if (chrome && chrome.extension)
                return chrome.extension.getURL('icons/chrome-web-store-badge.png')
            return ''
        },
    },
    methods: {
        ...mapActions('annotate', ['navigateBack', 'search']),
        onClick (ev) {
            let el = document.getElementById(IS_EXTENSION ? 'liquio-bar-extension' : 'liquio-bar')
            let isOutside = el && !(el === event.target || el.contains(event.target))
            if (isOutside && Date.now() > this.lastSelectionSetTime + 50) {
                setTimeout(() => {
                    if (!this.getSelection()) {
                        this.isAnnotationTitleInputShown = false
                        this.lastSelection = null
                    }
                }, 50)
            }
        },
        startVoting () {
            if (this.isAnnotationTitleInputShown) {
                let anchor = slug(this.lastSelection || this.currentVideoTimeText).value
                this.$store.dispatch('setCurrentReferenceTitle', this.annotationTitle)
                this.$store.dispatch('setCurrentTitle', this.currentPage + '/' + anchor)
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
        },
        reload () {
            location.reload()
        },
        updateSelection (event, canClear) {
            let selection = this.getSelection()

            if (selection) {
                if (selection !== this.lastSelection) {
                    this.isAnnotationTitleInputShown = false
                    this.lastSelection = selection
                    this.lastSelectionSetTime = Date.now()
                }
            } else 

            if (event) {
                setTimeout(this.updateSelection, 100)
            }
        },
        getSelection () {
            let selection = window.getSelection()
            if (selection.anchorNode) {
                if (selection.isCollapsed)
                    return null
                if (this.$el.contains(selection.anchorNode))
                    return null

                return selection.toString()
            } else {
                return null
            }
        },
        onMouseMove (event) {
            let dialogElements = this.$el.getElementsByClassName('el-dialog')
            let isOutside = true
            for (let dialogElement of dialogElements) {
                if (dialogElement === event.target || dialogElement.contains(event.target)) {
                    isOutside = false
                }
            }

            if (!isOutside) {
                this.lastMouseMoveTime = Date.now()
            }
        },
        beforeCloseDialog (done) {
            if (!this.lastMouseMoveTime || Date.now() > this.lastMouseMoveTime + 200) {
                done()
            }
        }
    }
}
</script>
