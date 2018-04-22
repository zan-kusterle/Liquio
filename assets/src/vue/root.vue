<template>
<div class="liquio-bar" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div class="liquio-bar__container" style="bottom: 10px;" v-if="currentNode || !isHidden">
            <div class="liquio-bar__main">
                <div class="liquio-bar__items">
                    <div class="liquio-bar__vote">
                        <inline-node :node="currentNode" size="small"></inline-node>
                    </div>
                </div>
            </div>
        </div>
        <div class="liquio-bar__container liquio-bar__button-container" v-else-if="currentSelection && currentSelection.length >= 10">
            <el-button size="small" type="primary" @click="startVoting">Vote on selection with Liquio</el-button>
        </div>
        <div class="liquio-bar__container liquio-bar__button-container" v-else-if="currentVideoTime">
            <el-button size="small" @click="startVoting">Vote on video with Liquio at {{ currentVideoTimeText }}</el-button>
        </div>
    </template>

    <el-dialog v-if="currentTitle" :visible.sync="dialogVisible" width="60%" custom-class="dialog">
        <el-autocomplete
            v-model="searchQuery"
            :fetch-suggestions="querySearchAsync"
            @keyup="viewSearch"
            placeholder="Search anything"
            class="search">

            <i v-if="canNavigateBack" @click="navigateBack" slot="prefix" class="el-input__icon el-icon-arrow-left"></i>
            <i @click="viewSearch" slot="suffix" class="el-input__icon el-icon-search"></i>
        </el-autocomplete>

        <reference v-if="currentReferenceTitle" :title="currentTitle" :reference-title="currentReferenceTitle"></reference>
        <node v-else :title="currentTitle"></node>

        <el-autocomplete
            v-if="!currentReferenceTitle"
            v-model="referenceQuery"
            :fetch-suggestions="querySearchAsync"
            @keyup="viewReference"
            placement="top-start"
            placeholder="Add reference"
            class="search-reference">

            <i @click="viewReference" slot="suffix" class="el-input__icon el-icon-arrow-right"></i>
        </el-autocomplete>
    </el-dialog>

    <el-dialog
        width="500px"
        style="margin-top: 10vh;"
        title="Sign your data"
        :visible.sync="isSignWindowOpen"
        append-to-body>

        <div class="sign-alert">
            <p>Click the lock icon next to your address bar to continue.</p>

            <div class="sign-alert__images">
                <img class="sign-alert__sign-icon" :src="LIQUIO_URL + '/icons/sign-icon.png'" />
                <div class="sign-alert__toolbar-image" :style="{ backgroundImage: `url(${LIQUIO_URL}/icons/toolbar.png)` }"></div>
            </div>
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
        isHidden: { type: Boolean },
        isUnavailable: { type: Boolean },
        currentNode: { type: Object },
        currentSelection: { type: String },
        currentVideoTime: { type: Number }
    },
    data () {
        return {
            isLoading: true,
            dialogVisible: false,
            results: [],
            searchQuery: '',
            referenceQuery: ''
        }
    },
    created () {
        this.LIQUIO_URL = LIQUIO_URL
    },
    mounted () {
        setTimeout(() => this.isLoading = false, 50)

        this.results = this.loadResults()
    },
    computed: {
        ...mapState(['currentReferenceTitle']),
        ...mapGetters(['currentTitle', 'canNavigateBack']),
        isSignWindowOpen: {
            get () {
                return this.$store.state.isSignWindowOpen
            },
            set (v) {
                this.$store.commit('SET_IS_SIGN_WINDOW_OPEN', v)
            }
        },
        node () {
            return this.$store.state.nodesByKey[this.currentTitle]
        },
        activeAnchor () {
            return this.currentSelection || this.currentVideoTime
        },
        currentVideoTimeText () {
            let minutes = Math.floor(this.currentVideoTime / 60)
            let seconds = Math.floor(this.currentVideoTime - minutes * 60)
            return `${('00' + minutes).slice(-2)}:${('00' + seconds).slice(-2)}`
        }
    },
    methods: {
        ...mapActions(['navigateBack']),
        startVoting () {
            let anchor = slug(this.currentSelection || this.currentVideoTimeText)
            this.$store.dispatch('setCurrentReferenceTitle', null)
            this.$store.dispatch('setCurrentTitle', this.$store.state.currentPage + '/' + anchor)
            this.open()
        },
        open () {
            this.dialogVisible = true
        },
        loadResults() {
            return [
                { "value": "vue", "link": "https://github.com/vuejs/vue" },
                { "value": "element", "link": "https://github.com/ElemeFE/element" },
                { "value": "cooking", "link": "https://github.com/ElemeFE/cooking" },
                { "value": "mint-ui", "link": "https://github.com/ElemeFE/mint-ui" },
                { "value": "vuex", "link": "https://github.com/vuejs/vuex" },
                { "value": "vue-router", "link": "https://github.com/vuejs/vue-router" },
                { "value": "babel", "link": "https://github.com/babel/babel" }
            ]
        },
        querySearchAsync(queryString, cb) {
            var results = this.results
            var results = queryString ? results.filter(this.createFilter(queryString)) : results
            cb(results)
        },
        createFilter(queryString) {
            return (link) => {
                return (link.value.toLowerCase().indexOf(queryString.toLowerCase()) === 0)
            };
        },
        viewSearch () {
            this.$store.dispatch('setCurrentTitle', this.searchQuery)
            this.searchQuery = ''
        },
        viewReference (e) {
            this.$store.dispatch('setCurrentReferenceTitle', this.referenceQuery)
            this.referenceQuery = ''
        }
    }
}
</script>

