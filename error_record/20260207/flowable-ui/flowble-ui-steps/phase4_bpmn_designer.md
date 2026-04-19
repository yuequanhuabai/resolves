 # 階段四：bpmn-js 設計器核心

## Step 9：BpmnDesigner.vue 組件 + 畫布初始化

### 9.1 src/components/BpmnDesigner/index.vue

```vue
<template>
  <div class="designer-container">
    <!-- 工具欄 -->
    <DesignerToolbar
      :modeler="modeler"
      @deploy="handleDeploy"
      @import="handleImport"
    />

    <!-- bpmn-js 畫布 -->
    <div ref="canvasRef" class="bpmn-canvas-container" />

    <!-- 屬性面板（右側） -->
    <PropertiesPanel
      v-if="selectedElement"
      :element="selectedElement"
      :modeler="modeler"
      class="properties-panel"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import BpmnModeler from 'bpmn-js/lib/Modeler'
import { ElMessage } from 'element-plus'
import flowableModdle from './FlowableModdle.json'
import DesignerToolbar from './toolbar.vue'
import PropertiesPanel from '@/components/PropertiesPanel/index.vue'
import { deployByXml } from '@/api/process'

const canvasRef = ref<HTMLElement>()
const modeler = ref<BpmnModeler | null>(null)
const selectedElement = ref<any>(null)

// 默認空白流程 XML
const DEFAULT_XML = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:flowable="http://flowable.org/bpmn"
             targetNamespace="http://flowable.org/test">
  <process id="new-process" name="新建流程" isExecutable="true">
    <startEvent id="startEvent" name="開始" />
  </process>
</definitions>`

onMounted(async () => {
  modeler.value = new BpmnModeler({
    container: canvasRef.value!,
    moddleExtensions: {
      flowable: flowableModdle
    }
  })

  // 加載默認空白流程
  await modeler.value.importXML(DEFAULT_XML)

  // 監聽元素選中事件，驅動屬性面板
  const eventBus = modeler.value.get('eventBus') as any
  eventBus.on('selection.changed', ({ newSelection }: any) => {
    selectedElement.value = newSelection[0] || null
  })
})

onBeforeUnmount(() => {
  modeler.value?.destroy()
})

// 部署流程到後端
async function handleDeploy(name: string) {
  if (!modeler.value) return
  const { xml } = await modeler.value.saveXML({ format: true })
  // 從 XML 中提取 process id 作為 processKey
  const match = xml?.match(/process id="([^"]+)"/)
  const processKey = match?.[1] || 'process-' + Date.now()
  await deployByXml(name, processKey, xml!)
  ElMessage.success('流程部署成功')
}

// 導入 BPMN 文件
async function handleImport(xml: string) {
  await modeler.value?.importXML(xml)
}
</script>

<style scoped lang="scss">
.designer-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  position: relative;
}
.bpmn-canvas-container {
  flex: 1;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  overflow: hidden;
}
.properties-panel {
  position: absolute;
  right: 0;
  top: 48px;
  width: 280px;
  height: calc(100% - 48px);
  background: #fff;
  border-left: 1px solid #dcdfe6;
  box-shadow: -2px 0 8px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  z-index: 10;
}
</style>
```

---

## Step 10：FlowableModdle.json — Flowable 屬性擴展

**文件路徑**：`src/components/BpmnDesigner/FlowableModdle.json`

```json
{
  "name": "Flowable",
  "uri": "http://flowable.org/bpmn",
  "prefix": "flowable",
  "xml": {
    "tagAlias": "lowerCase"
  },
  "associations": [],
  "types": [
    {
      "name": "Process",
      "extends": ["bpmn:Process"],
      "properties": [
        { "name": "candidateStarterGroups", "isAttr": true, "type": "String" },
        { "name": "candidateStarterUsers", "isAttr": true, "type": "String" }
      ]
    },
    {
      "name": "UserTask",
      "extends": ["bpmn:UserTask"],
      "properties": [
        { "name": "assignee", "isAttr": true, "type": "String" },
        { "name": "candidateUsers", "isAttr": true, "type": "String" },
        { "name": "candidateGroups", "isAttr": true, "type": "String" },
        { "name": "dueDate", "isAttr": true, "type": "String" },
        { "name": "priority", "isAttr": true, "type": "String" },
        { "name": "formKey", "isAttr": true, "type": "String" },
        { "name": "skipExpression", "isAttr": true, "type": "String" }
      ]
    },
    {
      "name": "ServiceTask",
      "extends": ["bpmn:ServiceTask"],
      "properties": [
        { "name": "class", "isAttr": true, "type": "String" },
        { "name": "expression", "isAttr": true, "type": "String" },
        { "name": "delegateExpression", "isAttr": true, "type": "String" },
        { "name": "async", "isAttr": true, "type": "Boolean" }
      ]
    },
    {
      "name": "SequenceFlow",
      "extends": ["bpmn:SequenceFlow"],
      "properties": [
        { "name": "conditionExpression", "type": "bpmn:FormalExpression" }
      ]
    }
  ]
}
```

> **關鍵說明**：此擴展文件告訴 bpmn-js 如何識別和保存 `flowable:assignee` 等 Flowable 專屬屬性到 BPMN XML 中。沒有這個文件，屬性面板的修改不會保存到 XML。

---

## Step 11：設計器工具欄

### 11.1 src/components/BpmnDesigner/toolbar.vue

```vue
<template>
  <div class="toolbar">
    <el-button-group>
      <el-button size="small" @click="handleNew">
        <el-icon><Plus /></el-icon> 新建
      </el-button>
      <el-button size="small" @click="handleImport">
        <el-icon><Upload /></el-icon> 導入
      </el-button>
      <el-button size="small" @click="handleExport">
        <el-icon><Download /></el-icon> 導出 XML
      </el-button>
      <el-button size="small" @click="handleSave">
        <el-icon><DocumentChecked /></el-icon> 保存
      </el-button>
    </el-button-group>

    <el-button-group class="ml-8">
      <el-button size="small" @click="handleZoomIn">
        <el-icon><ZoomIn /></el-icon>
      </el-button>
      <el-button size="small" @click="handleZoomOut">
        <el-icon><ZoomOut /></el-icon>
      </el-button>
      <el-button size="small" @click="handleFitView">
        <el-icon><FullScreen /></el-icon> 適應窗口
      </el-button>
    </el-button-group>

    <el-button type="primary" size="small" class="ml-8" @click="showDeployDialog = true">
      <el-icon><Promotion /></el-icon> 部署發布
    </el-button>

    <!-- 隱藏的文件輸入框 -->
    <input ref="fileInput" type="file" accept=".bpmn,.xml" hidden @change="onFileChange" />

    <!-- 部署確認對話框 -->
    <el-dialog v-model="showDeployDialog" title="部署流程" width="400px">
      <el-form :model="deployForm" label-width="80px">
        <el-form-item label="流程名稱" required>
          <el-input v-model="deployForm.name" placeholder="請輸入流程名稱" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDeployDialog = false">取消</el-button>
        <el-button type="primary" @click="confirmDeploy">確認部署</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type BpmnModeler from 'bpmn-js/lib/Modeler'

const props = defineProps<{ modeler: BpmnModeler | null }>()
const emit = defineEmits<{
  (e: 'deploy', name: string): void
  (e: 'import', xml: string): void
}>()

const fileInput = ref<HTMLInputElement>()
const showDeployDialog = ref(false)
const deployForm = ref({ name: '' })

const EMPTY_XML = `<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:flowable="http://flowable.org/bpmn"
             targetNamespace="http://flowable.org/test">
  <process id="new-process" name="新建流程" isExecutable="true">
    <startEvent id="startEvent" name="開始" />
  </process>
</definitions>`

function handleNew() {
  props.modeler?.importXML(EMPTY_XML)
}

function handleImport() {
  fileInput.value?.click()
}

async function onFileChange(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  const xml = await file.text()
  emit('import', xml)
}

async function handleExport() {
  const { xml } = await props.modeler!.saveXML({ format: true })
  const blob = new Blob([xml!], { type: 'application/xml' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'process.bpmn20.xml'
  a.click()
  URL.revokeObjectURL(url)
}

async function handleSave() {
  const { xml } = await props.modeler!.saveXML({ format: true })
  console.log('當前 BPMN XML：', xml)
}

function handleZoomIn() {
  const zoom = props.modeler?.get('zoomScroll') as any
  zoom?.zoom(0.2)
}

function handleZoomOut() {
  const zoom = props.modeler?.get('zoomScroll') as any
  zoom?.zoom(-0.2)
}

function handleFitView() {
  const canvas = props.modeler?.get('canvas') as any
  canvas?.zoom('fit-viewport')
}

function confirmDeploy() {
  if (!deployForm.value.name) return
  emit('deploy', deployForm.value.name)
  showDeployDialog.value = false
  deployForm.value.name = ''
}
</script>

<style scoped lang="scss">
.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px;
  background: #fff;
  border-bottom: 1px solid #dcdfe6;
  flex-wrap: wrap;
}
.ml-8 { margin-left: 8px; }
</style>
```

---

## Step 12：設計器頁面

### 12.1 src/views/designer/index.vue

```vue
<template>
  <div class="designer-page">
    <BpmnDesigner />
  </div>
</template>

<script setup lang="ts">
import BpmnDesigner from '@/components/BpmnDesigner/index.vue'
</script>

<style scoped lang="scss">
.designer-page {
  height: calc(100vh - 100px);
  background: #fff;
  border-radius: 4px;
  overflow: hidden;
}
</style>
```

### 驗收

1. 進入 `/designer` 頁面，bpmn-js 畫布正常顯示，有默認開始事件節點
2. 從左側工具欄可以拖拽節點到畫布
3. 點擊「導出 XML」能下載 BPMN 文件
4. 點擊「部署發布」彈出對話框，填寫名稱後點確認，後端返回 200
