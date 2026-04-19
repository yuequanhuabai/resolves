# 階段二：基礎設施

## Step 3：Axios 封裝

### 3.1 src/utils/request.ts — Axios 實例 + 攔截器

```typescript
import axios, { type AxiosResponse, type InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'

// 後端統一響應結構
export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
}

const request = axios.create({
  baseURL: '/workflow',       // 通過 vite proxy 轉發到 http://localhost:9090/workflow
  timeout: 30000,
  headers: { 'Content-Type': 'application/json;charset=utf-8' }
})

// 請求攔截器（預留 token 位置）
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    return config
  },
  (error) => Promise.reject(error)
)

// 響應攔截器
request.interceptors.response.use(
  (response: AxiosResponse<any>) => {
    // 非 JSON（XML / 圖片 / 文本）直接返回原始數據，不走統一拆包
    const contentType = response.headers['content-type'] || ''
    if (
      response.config.responseType === 'text' ||
      response.config.responseType === 'blob' ||
      response.config.responseType === 'arraybuffer' ||
      contentType.includes('xml') ||
      contentType.includes('image')
    ) {
      return response.data
    }

    const res = response.data as ApiResponse
    if (res?.code !== 200) {
      ElMessage.error(res?.message || '請求失敗')
      return Promise.reject(new Error(res?.message))
    }
    return res.data
  },
  (error) => {
    ElMessage.error(error.message || '網絡錯誤')
    return Promise.reject(error)
  }
)

export default request
```

---

## Step 4：後端 API 模塊

### 4.1 src/api/types/workflow.d.ts — 類型定義

```typescript
// 流程定義
export interface ProcessDefinitionVO {
  id: string
  key: string
  name: string
  version: number
  deploymentId: string
  resourceName: string
  suspended: boolean
}

// 流程實例
export interface ProcessInstanceVO {
  instanceId: string
  processDefinitionId: string
  processDefinitionKey: string
  processDefinitionName: string
  businessKey: string
  startUserId: string
  startTime: string
  suspended: boolean
}

// 任務
export interface TaskVO {
  taskId: string
  taskName: string
  taskDefinitionKey: string
  assignee: string
  processInstanceId: string
  processDefinitionId: string
  businessKey: string
  createTime: string
  suspended: boolean
}

// 發起流程請求
export interface StartProcessRequest {
  processKey: string
  businessKey: string
  variables?: Record<string, any>
}

// 完成任務請求
export interface CompleteTaskRequest {
  taskId: string
  comment?: string
  variables?: Record<string, any>
}
```

### 4.2 src/api/process.ts

```typescript
import request from '@/utils/request'
import type { ProcessDefinitionVO } from './types/workflow'

// 查詢流程定義列表
export function listProcessDefinitions() {
  return request.get<any, ProcessDefinitionVO[]>('/api/process/list')
}

// 通過文件上傳部署流程
export function deployProcess(name: string, file: File) {
  const formData = new FormData()
  formData.append('name', name)
  formData.append('file', file)
  return request.post<any, string>('/api/process/deploy', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}

// 通過 XML 字符串部署（前端設計器核心入口）
export function deployByXml(name: string, processKey: string, bpmnXml: string) {
  return request.post<any, string>(
    `/api/process/deploy-xml?name=${encodeURIComponent(name)}&processKey=${encodeURIComponent(processKey)}`,
    bpmnXml,
    { headers: { 'Content-Type': 'application/xml' } }
  )
}

// 刪除部署
export function deleteDeployment(deploymentId: string) {
  return request.delete<any, void>(`/api/process/delete/${deploymentId}`)
}

// 獲取流程 XML（後端返回裸 XML，需繞過統一響應拆包）
export function getProcessResource(processDefinitionId: string) {
  return request.get<any, string>(
    `/api/process/resource/${processDefinitionId}`,
    { responseType: 'text' }
  )
}
```

### 4.3 src/api/instance.ts

```typescript
import request from '@/utils/request'
import type { ProcessInstanceVO, StartProcessRequest } from './types/workflow'

export function startProcess(data: StartProcessRequest) {
  return request.post<any, ProcessInstanceVO>('/api/instance/start', data)
}

export function listInstances(processKey?: string) {
  return request.get<any, ProcessInstanceVO[]>('/api/instance/list', { params: { processKey } })
}

export function suspendInstance(instanceId: string) {
  return request.put<any, void>(`/api/instance/suspend/${instanceId}`)
}

export function activateInstance(instanceId: string) {
  return request.put<any, void>(`/api/instance/activate/${instanceId}`)
}

export function deleteInstance(instanceId: string, reason?: string) {
  return request.delete<any, void>(`/api/instance/delete/${instanceId}`, { params: { reason } })
}
```

### 4.4 src/api/task.ts

```typescript
import request from '@/utils/request'
import type { TaskVO, CompleteTaskRequest } from './types/workflow'

export function getTodoTasks(assignee: string) {
  return request.get<any, TaskVO[]>('/api/task/todo', { params: { assignee } })
}

export function completeTask(data: CompleteTaskRequest) {
  return request.post<any, void>('/api/task/complete', data)
}

export function rejectTask(taskId: string, comment?: string) {
  return request.post<any, void>('/api/task/reject', null, { params: { taskId, comment } })
}

export function delegateTask(taskId: string, targetUserId: string) {
  return request.post<any, void>('/api/task/delegate', null, { params: { taskId, targetUserId } })
}
```

### 4.5 src/api/history.ts

```typescript
import request from '@/utils/request'

export function listFinishedInstances(processKey?: string) {
  return request.get<any, any[]>('/api/history/instances', { params: { processKey } })
}

export function getActivities(instanceId: string) {
  return request.get<any, any[]>(`/api/history/activities/${instanceId}`)
}

export function getComments(instanceId: string) {
  return request.get<any, any[]>(`/api/history/comments/${instanceId}`)
}

// 流程圖高亮 URL（直接用於 <img :src=""> 標籤）
export function getDiagramUrl(instanceId: string) {
  return `/workflow/api/history/diagram/${instanceId}`
}
```

---

## Step 5：Pinia + Vue Router

### 5.1 src/stores/process.ts

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { ProcessDefinitionVO } from '@/api/types/workflow'
import { listProcessDefinitions } from '@/api/process'

export const useProcessStore = defineStore('process', () => {
  const definitions = ref<ProcessDefinitionVO[]>([])

  async function fetchDefinitions() {
    definitions.value = await listProcessDefinitions()
  }

  return { definitions, fetchDefinitions }
})
```

### 5.2 src/router/index.ts

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import Layout from '@/layout/index.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: Layout,
      redirect: '/designer',
      children: [
        {
          path: 'designer',
          name: 'Designer',
          component: () => import('@/views/designer/index.vue'),
          meta: { title: '流程設計器', icon: 'Edit' }
        },
        {
          path: 'process',
          name: 'Process',
          component: () => import('@/views/process/index.vue'),
          meta: { title: '流程管理', icon: 'Document' }
        },
        {
          path: 'instance',
          name: 'Instance',
          component: () => import('@/views/instance/index.vue'),
          meta: { title: '流程實例', icon: 'List' }
        },
        {
          path: 'task',
          name: 'Task',
          component: () => import('@/views/task/index.vue'),
          meta: { title: '任務管理', icon: 'Check' }
        },
        {
          path: 'history',
          name: 'History',
          component: () => import('@/views/history/index.vue'),
          meta: { title: '歷史查詢', icon: 'Clock' }
        }
      ]
    },
    { path: '/:pathMatch(.*)*', redirect: '/' }
  ]
})

export default router
```
