<template>
<div class="liquio-bar" :style="isLoading ? { visibility: 'hidden' } : {}">
    <template v-if="!isUnavailable">
        <div class="liquio-bar__container" style="bottom: 10px;" v-if="currentNode || !isHidden">
            <div class="liquio-bar__main">
                <div class="liquio-bar__items">
                    <div class="liquio-bar__vote">
                        <span>{{ currentNode.title }}</span>
                        <div class="liquio-bar__results">
                            <results :unit-results="unitResults" width="100%" height="100%"></results>
                        </div>
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
            placeholder="Add reference"
            class="search-reference">

            <i @click="viewReference" slot="suffix" class="el-input__icon el-icon-share"></i>
        </el-autocomplete>
    </el-dialog>

    <el-dialog
        width="30%"
        title="Sign your data"
        :visible.sync="isSignWindowOpen"
        append-to-body>
        Use sign extension. If it's not installed download it here.
    </el-dialog>
</div>
</template>

<script>
import { Slider, Button, Select, Option, Input, Autocomplete, Dialog } from 'element-ui'
import Results from 'vue/results.vue'
import { allUnits } from 'store/constants'
import NodeElement from 'vue/node.vue'
import Reference from 'vue/reference.vue'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elInput: Input,
        elAutocomplete: Autocomplete,
        elDialog: Dialog,
        results: Results,
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
        unitResults () {
            if (!this.currentNode)
                return null
            let byUnits = this.currentNode.results
            let units = Object.keys(byUnits)
            if (units.length === 0)
                return null
            return {
                ...byUnits[units[0]],
                unit: units[0]
            }
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
            let title = this.currentSelection || this.currentVideoTimeText
            this.$store.dispatch('setCurrentTitle', title)
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

