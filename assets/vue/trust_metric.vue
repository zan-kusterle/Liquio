<template>
    <div>
        <span slot="footer" class="dialog-footer">
            <el-button type="success" @click="choose">Choose</el-button>
            <el-button @click="$emit('close')">Cancel</el-button>
        </span>
    </div>
</template>

<script>
import { Button, Input } from 'element-ui'

export default {
    components: {
        elButton: Button,
        elInput: Input
    },
    props: {
        trustMetricUrl: { type: String, required: true }
    },
    data () {
        return {
            url: null
        }
    },
    watch: {
        trustMetricUrl (v) {
            this.url = v
        }
    },
    methods: {
        choose () {
            this.$emit('set-trust-metric', this.url)
        }
    }
}
</script>