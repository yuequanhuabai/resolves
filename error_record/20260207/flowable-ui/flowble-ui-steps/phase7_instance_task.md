# 階段七：流程實例 & 任務管理 & 歷史查詢

## Step 19：流程實例管理頁

### 19.1 src/views/instance/index.vue

```vue
<template>
  <div>
    <div class="page-card search-bar">
      <el-select v-model="queryForm.processKey" placeholder="選擇流程" clearable style="width:200px">
        <el-option
          v-for="d in definitions"
          :key="d.key"
          :label="d.name"
          :value="d.key"
        />
      </el-select>
      <el-button type="primary" @click="fetchList">查詢</el-button>
      <el-button type="success" @click="showStartDialog = true">發起流程</el-button>
    </div>

    <div class="page-card">
      <el-table :data="tableData" border stripe v-loading="loading">
        <el-table-column prop="instanceId" label="實例 ID" width="180" show-overflow-tooltip />
        <el-table-column prop="processDefinitionName" label="流程名稱" min-width="140" />
        <el-table-column prop="businessKey" label="業務 Key" min-width="140" />
        <el-table-column prop="startTime" label="發起時間" width="170" />
        <el-table-column prop="suspended" label="狀態" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.suspended ? 'warning' : 'success'" size="small">
              {{ row.suspended ? '已掛起' : '運行中' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button v-if="!row.suspended" link type="warning" size="small" @click="handleSuspend(row)">掛起</el-button>
            <el-button v-else link type="success" size="small" @click="handleActivate(row)">激活</el-button>
            <el-button link type="danger" size="small" @click="handleDelete(row)">終止</el-button>
            <el-button link type="primary" size="small" @click="viewDiagram(row)">查看圖</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 發起流程對話框 -->
    <el-dialog v-model="showStartDialog" title="發起流程" width="500px">
      <el-form :model="startForm" label-width="90px">
        <el-form-item label="選擇流程" required>
          <el-select v-model="startForm.processKey" style="width:100%">
            <el-option v-for="d in definitions" :key="d.key" :label="d.name" :value="d.key" />
          </el-select>
        </el-form-item>
        <el-form-item label="業務 Key">
          <el-input v-model="startForm.businessKey" placeholder="如訂單號、請假單號" />
        </el-form-item>
        <el-form-item label="審批人">
          <el-input v-model="startForm.manager" placeholder="流程變量 manager" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showStartDialog = false">取消</el-button>
        <el-button type="primary" @click="handleStart">確認發起</el-button>
      </template>
    </el-dialog>

    <!-- 流程圖對話框（高亮當前節點） -->
    <el-dialog v-model="diagramDialog.visible" title="流程進度" width="900px">
      <img v-if="diagramDialog.url" :src="diagramDialog.url" style="max-width:100%" />
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { listInstances, startProcess, suspendInstance, activateInstance, deleteInstance } from '@/api/instance'
import { listProcessDefinitions } from '@/api/process'
import { getDiagramUrl } from '@/api/history'
import type { ProcessDefinitionVO, ProcessInstanceVO } from '@/api/types/workflow'

const loading = ref(false)
const tableData = ref<ProcessInstanceVO[]>([])
const definitions = ref<ProcessDefinitionVO[]>([])
const queryForm = ref({ processKey: '' })
const showStartDialog = ref(false)
const startForm = ref({ processKey: '', businessKey: '', manager: '' })
const diagramDialog = ref({ visible: false, url: '' })

onMounted(async () => {
  definitions.value = await listProcessDefinitions()
  fetchList()
})

async function fetchList() {
  loading.value = true
  try {
    tableData.value = await listInstances(queryForm.value.processKey || undefined)
  } finally {
    loading.value = false
  }
}

async function handleStart() {
  await startProcess({
    processKey: startForm.value.processKey,
    businessKey: startForm.value.businessKey,
    variables: { manager: startForm.value.manager }
  })
  ElMessage.success('流程發起成功')
  showStartDialog.value = false
  fetchList()
}

async function handleSuspend(row: ProcessInstanceVO) {
  await suspendInstance(row.instanceId)
  ElMessage.success('已掛起')
  fetchList()
}

async function handleActivate(row: ProcessInstanceVO) {
  await activateInstance(row.instanceId)
  ElMessage.success('已激活')
  fetchList()
}

async function handleDelete(row: ProcessInstanceVO) {
  await ElMessageBox.confirm('確定終止此流程實例嗎？', '警告', { type: 'warning' })
  await deleteInstance(row.instanceId)
  ElMessage.success('已終止')
  fetchList()
}

function viewDiagram(row: ProcessInstanceVO) {
  diagramDialog.value = { visible: true, url: getDiagramUrl(row.instanceId) }
}
</script>
```

---

## Step 20：任務管理頁

### 20.1 src/views/task/index.vue

```vue
<template>
  <div>
    <div class="page-card search-bar">
      <el-input v-model="assignee" placeholder="查詢用戶待辦（輸入用戶名）" style="width:220px" clearable />
      <el-button type="primary" @click="fetchTasks">查詢待辦</el-button>
    </div>

    <div class="page-card">
      <el-table :data="tableData" border stripe v-loading="loading">
        <el-table-column prop="taskName" label="任務名稱" min-width="140" />
        <el-table-column prop="assignee" label="辦理人" width="120" />
        <el-table-column prop="businessKey" label="業務 Key" min-width="140" />
        <el-table-column prop="createTime" label="創建時間" width="170" />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button link type="success" size="small" @click="openApproveDialog(row, 'approve')">審批通過</el-button>
            <el-button link type="danger" size="small" @click="openApproveDialog(row, 'reject')">駁回</el-button>
            <el-button link type="warning" size="small" @click="openDelegateDialog(row)">轉辦</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 審批/駁回對話框 -->
    <el-dialog v-model="approveDialog.visible" :title="approveDialog.type === 'approve' ? '審批通過' : '駁回任務'" width="420px">
      <el-form label-width="80px">
        <el-form-item label="審批意見">
          <el-input v-model="approveDialog.comment" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="approveDialog.visible = false">取消</el-button>
        <el-button :type="approveDialog.type === 'approve' ? 'primary' : 'danger'" @click="handleApprove">確認</el-button>
      </template>
    </el-dialog>

    <!-- 轉辦對話框 -->
    <el-dialog v-model="delegateDialog.visible" title="轉辦任務" width="360px">
      <el-form label-width="80px">
        <el-form-item label="轉辦給">
          <el-input v-model="delegateDialog.targetUser" placeholder="輸入用戶名" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="delegateDialog.visible = false">取消</el-button>
        <el-button type="primary" @click="handleDelegate">確認轉辦</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { getTodoTasks, completeTask, rejectTask, delegateTask } from '@/api/task'
import type { TaskVO } from '@/api/types/workflow'

const loading = ref(false)
const assignee = ref('')
const tableData = ref<TaskVO[]>([])

const approveDialog = ref({ visible: false, task: null as TaskVO | null, type: 'approve', comment: '' })
const delegateDialog = ref({ visible: false, task: null as TaskVO | null, targetUser: '' })

async function fetchTasks() {
  if (!assignee.value) return
  loading.value = true
  try {
    tableData.value = await getTodoTasks(assignee.value)
  } finally {
    loading.value = false
  }
}

function openApproveDialog(task: TaskVO, type: 'approve' | 'reject') {
  approveDialog.value = { visible: true, task, type, comment: '' }
}

async function handleApprove() {
  const { task, type, comment } = approveDialog.value
  if (!task) return
  if (type === 'approve') {
    await completeTask({ taskId: task.taskId, comment, variables: { approved: true } })
    ElMessage.success('審批通過')
  } else {
    await rejectTask(task.taskId, comment)
    ElMessage.success('已駁回')
  }
  approveDialog.value.visible = false
  fetchTasks()
}

function openDelegateDialog(task: TaskVO) {
  delegateDialog.value = { visible: true, task, targetUser: '' }
}

async function handleDelegate() {
  const { task, targetUser } = delegateDialog.value
  if (!task || !targetUser) return
  await delegateTask(task.taskId, targetUser)
  ElMessage.success('轉辦成功')
  delegateDialog.value.visible = false
  fetchTasks()
}
</script>
```

---

## Step 21：歷史查詢頁

### 21.1 src/views/history/index.vue

```vue
<template>
  <div>
    <div class="page-card search-bar">
      <el-input v-model="searchKey" placeholder="流程 Key" style="width:200px" clearable />
      <el-button type="primary" @click="fetchHistory">查詢</el-button>
    </div>

    <div class="page-card">
      <el-table :data="tableData" border stripe v-loading="loading" @row-click="viewDetail">
        <el-table-column prop="processDefinitionName" label="流程名稱" min-width="140" />
        <el-table-column prop="businessKey" label="業務 Key" min-width="140" />
        <el-table-column prop="startUserId" label="發起人" width="120" />
        <el-table-column prop="startTime" label="發起時間" width="170" />
        <el-table-column prop="endTime" label="結束時間" width="170" />
        <el-table-column label="耗時" width="100">
          <template #default="{ row }">
            {{ row.duration ? Math.round(row.duration / 1000) + 's' : '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click.stop="viewDetail(row)">查看記錄</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 審批記錄 + 流程圖對話框 -->
    <el-dialog v-model="detailDialog.visible" title="流程詳情" width="800px">
      <el-tabs>
        <el-tab-pane label="審批記錄">
          <el-timeline>
            <el-timeline-item
              v-for="item in detailDialog.activities"
              :key="item.activityId"
              :timestamp="item.startTime"
              :type="item.activityType === 'userTask' ? 'primary' : 'info'"
            >
              <div>
                <strong>{{ item.activityName || item.activityId }}</strong>
                <span v-if="item.assignee" class="ml-8 text-gray">辦理人：{{ item.assignee }}</span>
              </div>
              <div v-if="item.endTime" class="text-gray text-sm">結束：{{ item.endTime }}</div>
            </el-timeline-item>
          </el-timeline>
        </el-tab-pane>

        <el-tab-pane label="流程圖高亮">
          <!-- Step 22：調用後端圖片接口 -->
          <img
            v-if="detailDialog.instanceId"
            :src="`/workflow/api/history/diagram/${detailDialog.instanceId}`"
            style="max-width:100%;border:1px solid #eee;border-radius:4px"
          />
        </el-tab-pane>
      </el-tabs>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { listFinishedInstances, getActivities } from '@/api/history'

const loading = ref(false)
const searchKey = ref('')
const tableData = ref<any[]>([])
const detailDialog = ref({ visible: false, instanceId: '', activities: [] as any[] })

async function fetchHistory() {
  loading.value = true
  try {
    tableData.value = await listFinishedInstances(searchKey.value || undefined)
  } finally {
    loading.value = false
  }
}

async function viewDetail(row: any) {
  const activities = await getActivities(row.instanceId)
  detailDialog.value = { visible: true, instanceId: row.instanceId, activities }
}
</script>

<style scoped lang="scss">
.ml-8 { margin-left: 8px; }
.text-gray { color: #909399; }
.text-sm { font-size: 12px; }
</style>
```

---

## Step 22：流程圖高亮回放

已整合在 Step 21 的歷史詳情對話框中：

```html
<img :src="`/workflow/api/history/diagram/${instanceId}`" />
```

後端接口（`GET /api/history/diagram/{instanceId}`）直接返回 PNG 圖片，前端用 `<img>` 標籤顯示。

### 驗收（全流程端到端測試）

```
1. 設計器頁：設計流程圖，添加開始事件 → 用戶任務（assignee=${manager}）→ 結束事件
2. 設計器工具欄點「部署發布」，填寫流程名稱，確認
3. 流程管理頁：確認流程已出現在列表，點「預覽圖」驗證圖形正確
4. 實例管理頁：選擇流程，填寫 businessKey 和 manager 值，點「發起流程」
5. 任務管理頁：輸入 manager 的用戶名，查詢待辦，點「審批通過」
6. 歷史查詢頁：查詢已完成流程，點「查看記錄」，查看審批記錄時間線和流程圖高亮
```
