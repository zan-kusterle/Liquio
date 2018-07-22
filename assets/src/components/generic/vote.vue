<template>
    <div class="vote-component" :class="{ 'vote-component--micro': !isQuantity && !isPrecise }">
        <div v-if="existingValue" class="vote-component__icon" style="margin-right: 15px;" @click="$emit('unset')">
            <i class="el-icon-delete"></i>
        </div>

        <template v-if="isQuantity">
            <el-input-number v-model="inputValue" @keyup.delete.stop.native="() => {}"></el-input-number>

            <div class="vote-component__icon" style="margin-left: 15px;" @click="$emit('set', inputValue)">
                <i class="el-icon-check" style="font-weight: bold; font-size: 28px;"></i>
            </div>
        </template>
        <template v-else-if="isPrecise">
            <div class="vote-component__icon" style="margin-right: 15px;" @click="isPrecise = false">
                <i class="el-icon-more-outline"></i>
            </div>

            <el-slider v-model="sliderValue" class="vote-component__slider"></el-slider>

            <div class="vote-component__icon" style="margin-left: 15px;" @click="$emit('set', sliderValue / 100)">
                <i class="el-icon-check" style="font-size: 28px;"></i>
            </div>
        </template>
        <template v-else>
            <div class="vote-component__icon" style="margin-right: 15px;" @click="isPrecise = true">
                <i class="el-icon-more"></i>
            </div>

            <div class="vote-component__icon" @click="$emit('set', 1.0)">
                <i class="el-icon-caret-top" style="color: #22b822;"></i>
            </div>

            <div class="vote-component__icon" @click="$emit('set', 0.0)">
                <i class="el-icon-caret-bottom" style="color: #d80909; position: relative; top: -1px;"></i>
            </div>
        </template>
    </div>
</template>

<script>
import { Button, Slider, Input, InputNumber } from 'element-ui'

export default {
    components: {
        elButton: Button,
        elSlider: Slider,
        elInput: Input,
        elInputNumber: InputNumber,
    },
    props: {
        isQuantity: { type: Boolean, default: false },
        existingValue: { type: Number, required: false },
    },
    data () {
        return {
            isPrecise: false,
            sliderValue: this.existingValue ? this.existingValue * 100 : 50,
            inputValue: this.existingValue || 0,
        }
    },
    watch: {
        existingValue (v) {
            if (this.isQuantity) {
                this.inputValue = v
            } else {
                this.sliderValue = v * 100
            }
        }
    }
}
</script>
