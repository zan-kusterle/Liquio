<template>
<div class="liquio-bar">
    <template v-if="!isUnavailable">
        <div v-if="activeNode && activeNode.data" ref="barContainer" class="liquio-bar__container liquio-bar__container--node" @click="viewActive">
            <results :results="activeNode.results" :unit="activeNode.definition.unit" size="small"></results>
            <inline-node :node="activeNode.definition" size="small"></inline-node>
        </div>
        <div v-else-if="currentAnchor" ref="barContainer" class="liquio-bar__container liquio-bar__container--quick">
            <template v-if="isSelectionAnchor">
                <el-button size="small" type="success" @click="voteDirectly(1)"><i class="el-icon-caret-top" style="font-size: 20px; line-height: 14px;"></i></el-button>
                <el-button size="small" type="danger" @click="voteDirectly(0)"><i class="el-icon-caret-bottom" style="font-size: 20px; line-height: 14px;"></i></el-button>
                <el-button size="small" type="primary" @click="viewAnchor">Open selection</el-button>
            </template>
            <el-button v-else size="small" @click="viewAnchor">Open video at {{ currentAnchor }}</el-button>
        </div>

        <el-dialog v-if="definition" :visible.sync="dialogVisible" :before-close="beforeCloseDialog" custom-class="dialog">
            <Annotate ref="annotate" />
        </el-dialog>

        <el-dialog :visible.sync="signDialogVisible" custom-class="sign-message-dialog">
            <Sign />
        </el-dialog>
    </template>
</div>
</template>

<script>
import { Button, Dialog } from 'element-ui'
import InlineNode from './generic/inline_node.vue'
import Results from './generic/results.vue'
import Annotate from './vote_root.vue'
import Sign from './sign_root.vue'
import { mapState, mapGetters, mapActions } from 'vuex'

export default {
    components: {
        elButton: Button,
        elDialog: Dialog,
        InlineNode,
        Results,
        Annotate,
        Sign,
    },
    mounted () {
        this.$el.addEventListener('mousemove', this.onMouseMove)
    },
    beforeDestroy () {
        this.$el.removeEventListener('mousemove', this.onMouseMove)
    },
    computed: {
		...mapState(['isUnavailable']),
        ...mapState('annotate', ['definition', 'activeDefinition']),
        ...mapGetters('annotate', ['activeNode', 'isSelectionAnchor', 'currentAnchor', 'currentPageDefinition']),
        dialogVisible: {
            get () {
                return this.$store.state.annotate.dialogVisible
            },
            set (v) {
                this.$store.commit('annotate/SET_DIALOG_VISIBLE', v)
            },
        },
        signDialogVisible: {
            get () {
                return this.$store.state.sign.signDialogVisible
            },
            set (v) {
                this.$store.state.sign.signDialogVisible = v
            },
        },
    },
    methods: {
        ...mapActions('annotate', ['openDialog', 'setDefinition', 'setVote', 'clearCurrentSelection']),
        viewAnchor () {
            this.setDefinition({
                ...this.currentPageDefinition,
                anchor: this.currentAnchor
            })
            this.clearCurrentSelection()
            this.openDialog()
        },
        voteDirectly (choice) {
            this.setVote({
                definition: { ...this.currentPageDefinition, anchor: this.currentAnchor },
                choice: choice,
            })
            this.clearCurrentSelection()
        },
        viewActive () {
            this.setDefinition(this.activeDefinition)
            this.openDialog()
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
        },
    }
}
</script>
