# 階段六：流程管理頁

## Step 16：流程管理列表頁

### 16.1 src/views/process/index.vue

```vue
<template>
  <div>
    <div class="page-card search-bar">
      <el-input
        v-model="searchKey"
        placeholder="搜索流程名稱/Key"
        style="width: 240px"
        clearable
        @keyup.enter="fetchList"
      />
      <el-button type="primary" @click="fetchList">
        <el-icon><Search /></el-icon> 查詢
      </el-button>
      <el-button @click="$router.push('/designer')">
        <el-icon><Plus /></el-icon> 去設計器部署
      </el-button>
    </div>

    <div class="page-card">
      <el-table :data="tableData" border stripe v-loading="loading">
        <el-table-column prop="name" label="流程名稱" min-width="150" />
        <el-table-column prop="key" label="流程 Key" width="160" />
        <el-table-column prop="version" label="版本" width="80" align="center">
          <template #default="{ row }">
            <el-tag size="small">v{{ row.version }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="suspended" label="狀態" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.suspended ? 'warning' : 'success'" size="small">
              {{ row.suspended ? '已掛起' : '激活' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="resourceName" label="文件名" min-width="180" show-overflow-tooltip />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="viewXml(row)">查看 XML</el-button>
            <el-button link type="primary" size="small" @click="previewDiagram(row)">預覽圖</el-button>
            <el-button link type="danger" size="small" @click="handleDelete(row)">刪除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 查看 XML 對話框 -->
    <el-dialog v-model="xmlDialog.visible" title="流程 XML" width="800px">
      <pre class="xml-code">{{ xmlDialog.content }}</pre>
    </el-dialog>

    <!-- 預覽流程圖對話框 -->
    <el-dialog v-model="diagramDialog.visible" title="流程圖預覽" width="900px">
      <BpmnViewer v-if="diagramDialog.visible" :xml="diagramDialog.xml" />
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { listProcessDefinitions, deleteDeployment, getProcessResource } from '@/api/process'
import type { ProcessDefinitionVO } from '@/api/types/workflow'
import BpmnViewer from '@/components/BpmnDesigner/BpmnViewer.vue'

const loading = ref(false)
const searchKey = ref('')
const tableData = ref<ProcessDefinitionVO[]>([])

const xmlDialog = ref({ visible: false, content: '' })
const diagramDialog = ref({ visible: false, xml: '' })

onMounted(fetchList)

async function fetchList() {
  loading.value = true
  try {
    const list = await listProcessDefinitions()
    tableData.value = searchKey.value
      ? list.filter(d => d.name?.includes(searchKey.value) || d.key?.includes(searchKey.value))
      : list
  } finally {
    loading.value = false
  }
}

async function viewXml(row: ProcessDefinitionVO) {
  const xml = await getProcessResource(row.id)
  xmlDialog.value = { visible: true, content: xml }
}

async function previewDiagram(row: ProcessDefinitionVO) {
  const xml = await getProcessResource(row.id)
  diagramDialog.value = { visible: true, xml }
}

async function handleDelete(row: ProcessDefinitionVO) {
  await ElMessageBox.confirm(`確定刪除流程「${row.name}」及其所有實例嗎？`, '警告', { type: 'warning' })
  await deleteDeployment(row.deploymentId)
  ElMessage.success('刪除成功')
  fetchList()
}
</script>

<style scoped lang="scss">
.xml-code {
  background: #f5f7fa;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  max-height: 500px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
```

---

## Step 17：（已整合到 Step 16）XML 對話框

XML 查看功能已內嵌在流程管理頁的 `<pre>` 標籤中，無需額外安裝 CodeMirror。如需語法高亮，可安裝：

```bash
npm install @codemirror/view @codemirror/state @codemirror/lang-xml
```

---

## Step 18：只讀流程圖預覽組件

### 18.1 src/components/BpmnDesigner/BpmnViewer.vue

```vue
<template>
  <div ref="viewerRef" class="bpmn-viewer-container" />
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import BpmnNavigatedViewer from 'bpmn-js/lib/NavigatedViewer'

const props = defineProps<{ xml: string }>()
const viewerRef = ref<HTMLElement>()
let viewer: BpmnNavigatedViewer | null = null

onMounted(() => {
  viewer = new BpmnNavigatedViewer({ container: viewerRef.value! })
  loadXml(props.xml)
})

watch(() => props.xml, (xml) => {
  loadXml(xml)
})

async function loadXml(xml: string) {
  if (!xml || !viewer) return
  await viewer.importXML(xml)
  const canvas = viewer.get('canvas') as any
  canvas.zoom('fit-viewport')
}

onBeforeUnmount(() => {
  viewer?.destroy()
})
</script>

<style scoped lang="scss">
.bpmn-viewer-container {
  width: 100%;
  height: 500px;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
}
</style>
```

### 驗收

1. 流程管理頁能正確顯示已部署的流程列表
2. 點擊「查看 XML」，對話框顯示格式化的 BPMN XML 內容
3. 點擊「預覽圖」，BpmnViewer 正確渲染流程圖並自適應窗口大小
4. 點擊「刪除」有確認提示，刪除後列表刷新
