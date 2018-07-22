<template>
    <div>
        <div class="search">
            <div slot="prefix" class="back-button">
                <i class="el-input__icon el-icon-back" :style="availableHistory.back ? {} : { opacity: 0.5 }" @click="navigateHistory(-1)"></i>
                <i class="el-input__icon el-icon-back" :style="availableHistory.forward ? {} : { opacity: 0.5 }" style="transform: scaleX(-1)" @click="navigateHistory(1)"></i>
                <i class="el-input__icon el-icon-time" :style="recentDefinitions.length > 0 ? {} : { opacity: 0.5, pointerEvents: 'none' }" @click="isRecentDialogOpen = true"></i>
            </div>

            <el-autocomplete
                v-model="searchQuery"
                :fetch-suggestions="querySearchAsync"
                @keyup.delete.stop.native="() => {}"
                placeholder="Vote on any text">

                <el-dropdown slot="append" trigger="click" @command="viewNewNode($event)">
                    <el-button type="primary">
                        Choose unit<i class="el-icon-arrow-down el-icon--right"></i>
                    </el-button>
                    <el-dropdown-menu slot="dropdown">
                        <el-dropdown-item v-for="unit in allUnits" :key="unit.key" :command="unit.text">{{ unit.text }}</el-dropdown-item>
                    </el-dropdown-menu>
                </el-dropdown>
            </el-autocomplete>
        </div>

        <node ref="node" ></node>

        <el-dialog :visible.sync="isRecentDialogOpen" custom-class="reference-dialog">
            <p>Recent nodes</p>

            <div v-for="(definition, index) in recentDefinitions" :key="index" @click="setDefinition(definition)">
                <inline-node :node="definition" :show-unit="true" size="small" class="liquio-node__main"></inline-node>
            </div>
        </el-dialog>
    </div>
</template>

<script>
import { Slider, Button, Select, Option, OptionGroup, Input, Autocomplete, Dialog, Dropdown, DropdownItem, DropdownMenu } from 'element-ui'
import InlineNode from './generic/inline_node.vue'
import NodeElement from './node.vue'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elSlider: Slider,
        elButton: Button,
        elSelect: Select,
        elOption: Option,
        elOptionGroup: OptionGroup,
        elInput: Input,
        elAutocomplete: Autocomplete,
        elDialog: Dialog,
        elDropdown: Dropdown,
        elDropdownItem: DropdownItem,
        elDropdownMenu: DropdownMenu,
        inlineNode: InlineNode,
        node: NodeElement,
    },
    data () {
        return {
            searchQuery: '',
            isRecentDialogOpen: false,
        }
    },
    computed: {
        ...mapGetters('annotate', ['allUnits', 'availableHistory', 'recentDefinitions']),
    },
    methods: {
        ...mapActions('annotate', ['navigateHistory', 'search', 'setDefinition']),
        querySearchAsync(queryString, cb) {
            this.search(queryString).then(results => {
                let items = results ? results.map(r => ({ value: r.title })) : []
                cb(items)
            })
        },
        viewNewNode (unitValue) {
            if (this.searchQuery.length > 0) {
                this.setDefinition({ title: this.searchQuery, unit: unitValue })
                this.resetState()
            }
        },
        resetState () {
            this.searchQuery = '',
            this.referenceQuery = ''
        },
    }
}
</script>