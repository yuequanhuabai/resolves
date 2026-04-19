# 階段五：Flowable 屬性面板

## Step 13：屬性面板框架

### 13.1 src/components/PropertiesPanel/index.vue

```vue
<template>
  <div class="properties-panel-wrapper">
    <div class="panel-header">
      <span>屬性設置</span>
      <small class="element-type">{{ elementType }}</small>
    </div>

    <div class="panel-body">
      <!-- 根據元素類型展示不同面板 -->
      <ProcessPanel
        v-if="elementType === 'Process'"
        :element="element"
        :modeler="modeler"
      />
      <UserTaskPanel
        v-else-if="elementType === 'UserTask'"
        :element="element"
        :modeler="modeler"
      />
      <SequenceFlowPanel
        v-else-if="elementType === 'SequenceFlow'"
        :element="element"
        :modeler="modeler"
      />
      <div v-else class="empty-tip">
        選中元素查看屬性
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import ProcessPanel from './panels/ProcessPanel.vue'
import UserTaskPanel from './panels/UserTaskPanel.vue'
import SequenceFlowPanel from './panels/SequenceFlowPanel.vue'

const props = defineProps<{
  element: any
  modeler: any
}>()

const elementType = computed(() => {
  if (!props.element) return ''
  return props.element.type?.replace('bpmn:', '') || ''
})
</script>

<style scoped lang="scss">
.properties-panel-wrapper {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.panel-header {
  padding: 12px 16px;
  background: #f5f7fa;
  border-bottom: 1px solid #dcdfe6;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
  font-size: 14px;
}
.element-type {
  color: #909399;
  font-size: 12px;
  font-weight: normal;
}
.panel-body {
  flex: 1;
  padding: 16px;
  overflow-y: auto;
}
.empty-tip {
  text-align: center;
  color: #c0c4cc;
  padding: 40px 0;
  font-size: 13px;
}
</style>
```

---

## Step 14：用戶任務屬性面板

### 14.1 src/components/PropertiesPanel/panels/UserTaskPanel.vue

```vue
<template>
  <el-form :model="form" label-width="90px" size="small">
    <el-form-item label="任務名稱">
      <el-input v-model="form.name" @change="updateProperty('name', form.name)" />
    </el-form-item>

    <el-divider content-position="left">辦理人配置</el-divider>

    <el-form-item label="指定辦理人">
      <el-input
        v-model="form.assignee"
        placeholder="如：${manager} 或固定用戶名"
        @change="updateFlowableProperty('assignee', form.assignee)"
      />
      <div class="tip">支持流程變量表達式，如 ${manager}</div>
    </el-form-item>

    <el-form-item label="候選用戶">
      <el-input
        v-model="form.candidateUsers"
        placeholder="多個用逗號分隔：user1,user2"
        @change="updateFlowableProperty('candidateUsers', form.candidateUsers)"
      />
    </el-form-item>

    <el-form-item label="候選角色組">
      <el-input
        v-model="form.candidateGroups"
        placeholder="多個用逗號分隔：group1,group2"
        @change="updateFlowableProperty('candidateGroups', form.candidateGroups)"
      />
    </el-form-item>

    <el-divider content-position="left">其他</el-divider>

    <el-form-item label="表單 Key">
      <el-input
        v-model="form.formKey"
        placeholder="如：leave-form"
        @change="updateFlowableProperty('formKey', form.formKey)"
      />
    </el-form-item>

    <el-form-item label="到期時間">
      <el-input
        v-model="form.dueDate"
        placeholder="如：${dueDate} 或 2024-12-31"
        @change="updateFlowableProperty('dueDate', form.dueDate)"
      />
    </el-form-item>
  </el-form>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'

const props = defineProps<{ element: any; modeler: any }>()

const form = reactive({
  name: '',
  assignee: '',
  candidateUsers: '',
  candidateGroups: '',
  formKey: '',
  dueDate: ''
})

// 元素變化時，同步讀取已有屬性
watch(() => props.element, (el) => {
  if (!el) return
  const bo = el.businessObject
  form.name = bo?.name || ''
  form.assignee = bo?.assignee || ''
  form.candidateUsers = bo?.candidateUsers || ''
  form.candidateGroups = bo?.candidateGroups || ''
  form.formKey = bo?.formKey || ''
  form.dueDate = bo?.dueDate || ''
}, { immediate: true })

// 更新 BPMN 標準屬性（name 等）
function updateProperty(key: string, value: string) {
  const modeling = props.modeler?.get('modeling')
  modeling?.updateProperties(props.element, { [key]: value })
}

// 更新 Flowable 擴展屬性（flowable:assignee 等）
function updateFlowableProperty(key: string, value: string) {
  const modeling = props.modeler?.get('modeling')
  modeling?.updateProperties(props.element, { [key]: value || undefined })
}
</script>

<style scoped lang="scss">
.tip {
  font-size: 11px;
  color: #909399;
  margin-top: 4px;
}
</style>
```

---

## Step 15：連線條件 + 流程屬性面板

### 15.1 src/components/PropertiesPanel/panels/SequenceFlowPanel.vue

```vue
<template>
  <el-form :model="form" label-width="90px" size="small">
    <el-form-item label="連線名稱">
      <el-input v-model="form.name" @change="updateProperty('name', form.name)" />
    </el-form-item>

    <el-form-item label="條件表達式">
      <el-input
        v-model="form.conditionExpression"
        type="textarea"
        :rows="3"
        placeholder="如：${approved == true}"
        @change="updateCondition"
      />
      <div class="tip">用於排他網關出口，控制流程走向</div>
    </el-form-item>
  </el-form>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'

const props = defineProps<{ element: any; modeler: any }>()

const form = reactive({
  name: '',
  conditionExpression: ''
})

watch(() => props.element, (el) => {
  if (!el) return
  const bo = el.businessObject
  form.name = bo?.name || ''
  form.conditionExpression = bo?.conditionExpression?.body || ''
}, { immediate: true })

function updateProperty(key: string, value: string) {
  props.modeler?.get('modeling')?.updateProperties(props.element, { [key]: value })
}

function updateCondition() {
  const modeling = props.modeler?.get('modeling')
  const moddle = props.modeler?.get('moddle')
  if (!modeling || !moddle) return

  if (form.conditionExpression) {
    const condExpr = moddle.create('bpmn:FormalExpression', {
      body: form.conditionExpression
    })
    modeling.updateProperties(props.element, { conditionExpression: condExpr })
  } else {
    modeling.updateProperties(props.element, { conditionExpression: undefined })
  }
}
</script>

<style scoped lang="scss">
.tip {
  font-size: 11px;
  color: #909399;
  margin-top: 4px;
}
</style>
```

### 15.2 src/components/PropertiesPanel/panels/ProcessPanel.vue

```vue
<template>
  <el-form :model="form" label-width="90px" size="small">
    <el-form-item label="流程名稱">
      <el-input v-model="form.name" @change="updateProperty('name', form.name)" />
    </el-form-item>

    <el-form-item label="流程 ID">
      <el-input v-model="form.id" disabled />
      <div class="tip">部署後作為 processKey，建議使用有意義的英文標識</div>
    </el-form-item>

    <el-form-item label="是否可執行">
      <el-switch v-model="form.isExecutable" @change="updateProperty('isExecutable', form.isExecutable)" />
    </el-form-item>
  </el-form>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'

const props = defineProps<{ element: any; modeler: any }>()

const form = reactive({
  id: '',
  name: '',
  isExecutable: true
})

watch(() => props.element, (el) => {
  if (!el) return
  const bo = el.businessObject
  form.id = bo?.id || ''
  form.name = bo?.name || ''
  form.isExecutable = bo?.isExecutable !== false
}, { immediate: true })

function updateProperty(key: string, value: any) {
  props.modeler?.get('modeling')?.updateProperties(props.element, { [key]: value })
}
</script>

<style scoped lang="scss">
.tip {
  font-size: 11px;
  color: #909399;
  margin-top: 4px;
}
</style>
```

### 驗收

1. 點擊畫布上的開始事件 → 屬性面板顯示對應面板
2. 拖入一個「用戶任務」節點，點選後在屬性面板輸入 `${manager}`，導出 XML 確認包含 `flowable:assignee="${manager}"`
3. 在排他網關出口連線上輸入條件表達式，導出 XML 確認包含 `<conditionExpression>${approved == true}</conditionExpression>`
