# 階段三：佈局框架

## Step 6：主佈局

### 6.1 src/layout/index.vue

```vue
<template>
  <el-container class="app-wrapper">
    <!-- 左側菜單 -->
    <el-aside :width="isCollapse ? '64px' : '200px'" class="sidebar">
      <div class="logo">
        <span v-if="!isCollapse">流程引擎</span>
        <span v-else>FE</span>
      </div>
      <Sidebar />
    </el-aside>

    <!-- 右側主區域 -->
    <el-container>
      <!-- 頂部導航 -->
      <el-header class="navbar">
        <el-icon class="collapse-btn" @click="isCollapse = !isCollapse">
          <Fold v-if="!isCollapse" />
          <Expand v-else />
        </el-icon>
        <el-breadcrumb separator="/">
          <el-breadcrumb-item>{{ currentRoute?.meta?.title }}</el-breadcrumb-item>
        </el-breadcrumb>
      </el-header>

      <!-- 主內容區 -->
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import Sidebar from './components/Sidebar.vue'

const isCollapse = ref(false)
const currentRoute = useRoute()
</script>

<style scoped lang="scss">
.app-wrapper {
  height: 100vh;
}
.sidebar {
  background: #304156;
  transition: width 0.3s;
  overflow: hidden;
}
.logo {
  height: 60px;
  line-height: 60px;
  text-align: center;
  color: #fff;
  font-size: 18px;
  font-weight: bold;
  background: #2b3a4e;
  overflow: hidden;
  white-space: nowrap;
}
.navbar {
  display: flex;
  align-items: center;
  gap: 16px;
  background: #fff;
  border-bottom: 1px solid #ebeef5;
  padding: 0 16px;
}
.collapse-btn {
  font-size: 20px;
  cursor: pointer;
  color: #606266;
}
.main-content {
  background: #f5f7fa;
  padding: 16px;
}
</style>
```

---

## Step 7：側邊欄菜單

### 7.1 src/layout/components/Sidebar.vue

```vue
<template>
  <el-menu
    :default-active="activeMenu"
    :collapse="isCollapse"
    background-color="#304156"
    text-color="#bfcbd9"
    active-text-color="#409EFF"
    router
  >
    <el-menu-item
      v-for="route in menuRoutes"
      :key="route.path"
      :index="route.path"
    >
      <el-icon>
        <component :is="route.meta?.icon" />
      </el-icon>
      <template #title>{{ route.meta?.title }}</template>
    </el-menu-item>
  </el-menu>
</template>

<script setup lang="ts">
import { computed, inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

// 從 layout 接收 collapse 狀態（通過 provide/inject 或 props）
const isCollapse = inject('isCollapse', false)

const menuRoutes = computed(() => {
  const rootRoute = router.getRoutes().find(r => r.path === '/')
  return rootRoute?.children || []
})

const activeMenu = computed(() => route.path)
</script>
```

---

## Step 8：全局樣式

### 8.1 src/styles/index.scss

```scss
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body, #app {
  height: 100%;
  font-family: "Microsoft YaHei", "微軟雅黑", sans-serif;
}

// 頁面卡片
.page-card {
  background: #fff;
  border-radius: 4px;
  padding: 16px;
  margin-bottom: 16px;
  box-shadow: 0 1px 4px rgba(0, 21, 41, .08);
}

// 搜索區域
.search-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  padding-bottom: 16px;
  border-bottom: 1px solid #ebeef5;
  margin-bottom: 16px;
}
```

### 8.2 src/styles/bpmn.scss — bpmn-js 畫布樣式

```scss
// bpmn-js 畫布容器必須設置高度
.bpmn-canvas-container {
  width: 100%;
  height: calc(100vh - 180px);
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  overflow: hidden;
  position: relative;
  background: #fff;
}

// 覆蓋 bpmn-js 默認工具提示樣式
.djs-tooltip {
  font-size: 12px;
}

// 選中元素高亮顏色
.djs-element.selected .djs-outline {
  stroke: #409EFF !important;
}
```
