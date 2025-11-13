# Buy List 批量导入功能技术文档

## 1. 流程说明

### 1.1 用户操作流程
```
1. 点击 buyListName → 进入详情页
2. 点击 Upload 按钮 → 打开上传弹窗
3. 下载模板/使用导出的数据
4. 选择 CSV 文件上传
   ↓
5. 前端：发送文件流到后端
   ↓
6. 后端：解析 + 校验
   - ✅ 成功：返回 { valid: true, data: [...] }
   - ❌ 失败：返回 { valid: false, errors: [{row, field, message}] }
   ↓
7. 前端接收结果：
   - 有错误：显示错误提示（第X行错误）
   - 无错误：
     a. 清空原有 buyListdetails 数组
     b. 用导入数据完全覆盖
     c. 关闭上传弹窗
     d. 自动进入编辑模式
   ↓
8. 用户检查数据 → 点击"保存"按钮
   ↓
9. 调用原有 /update 接口（触发版本控制 + 审批流程）
```

### 1.2 核心逻辑
- **后端**：只做文件解析+数据校验，不做数据持久化
- **前端**：负责数据覆盖，用导入数据完全替换原有数据
- **保存**：复用现有 `/update` 接口，触发版本控制和审批流程

### 1.3 数据覆盖规则
⚠️ **导入的数据完全覆盖原有数据**
- 不管原来是否有 buylist_detail 数据
- 导入后前端清空旧数据，只展示导入的数据
- 用户点击"保存"后才真正写入数据库

---

## 2. 后端实现

### 2.1 Controller
```java
// BuyListController.java

@PostMapping("/parse-file")
@Operation(summary = "解析并校验CSV文件")
@PreAuthorize("@ss.hasPermission('buy:list:import')")
public CommonResult<ParseResultVO> parseFile(
    @RequestParam("file") MultipartFile file) {

    ParseResultVO result = listService.parseAndValidateFile(file);
    return success(result);
}

// ⚠️ 不需要新增 /import 接口，复用现有 /update
```

### 2.2 Service 接口
```java
// BuyListService.java

/**
 * 解析并校验CSV文件
 */
ParseResultVO parseAndValidateFile(MultipartFile file);
```

### 2.3 Service 实现
```java
// BuyListServiceImpl.java

@Override
public ParseResultVO parseAndValidateFile(MultipartFile file) {
    ParseResultVO result = new ParseResultVO();

    try {
        // 1. 解析CSV文件
        List<BuyListImportDTO> rows = parseCsvFile(file);

        if (rows.isEmpty()) {
            throw new ServerException(400, "文件为空或格式错误");
        }

        // 2. 数据校验
        List<ImportErrorVO> errors = validateRows(rows);

        // 3. 返回结果
        if (!errors.isEmpty()) {
            result.setValid(false);
            result.setErrors(errors);
        } else {
            result.setValid(true);
            result.setData(rows);
        }

        return result;

    } catch (Exception e) {
        log.error("解析文件失败", e);
        throw new ServerException(500, "文件解析失败: " + e.getMessage());
    }
}

/**
 * 解析CSV文件
 */
private List<BuyListImportDTO> parseCsvFile(MultipartFile file) {
    List<BuyListImportDTO> result = new ArrayList<>();

    try (BufferedReader br = new BufferedReader(
            new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {

        String line;
        boolean isHeader = true;

        while ((line = br.readLine()) != null) {
            // 跳过表头
            if (isHeader) {
                isHeader = false;
                continue;
            }

            // 跳过空行
            if (line.trim().isEmpty()) {
                continue;
            }

            // 解析CSV行
            String[] fields = line.split(",");
            if (fields.length >= 2) {
                BuyListImportDTO dto = new BuyListImportDTO();
                dto.setAssetType(fields[0].trim());
                dto.setProductCode(fields[1].trim());
                result.add(dto);
            }
        }

        return result;

    } catch (IOException e) {
        throw new ServerException(400, "文件读取失败");
    }
}

/**
 * 校验数据
 */
private List<ImportErrorVO> validateRows(List<BuyListImportDTO> rows) {
    List<ImportErrorVO> errors = new ArrayList<>();

    for (int i = 0; i < rows.size(); i++) {
        int rowNum = i + 2; // CSV从第2行开始（第1行是表头）
        BuyListImportDTO row = rows.get(i);

        // 1. 必填校验
        if (StringUtils.isBlank(row.getAssetType())) {
            errors.add(new ImportErrorVO(rowNum, "assetType", "资产类型不能为空"));
        }

        if (StringUtils.isBlank(row.getProductCode())) {
            errors.add(new ImportErrorVO(rowNum, "productCode", "产品代码不能为空"));
        }

        // 2. 字典值校验
        if (StringUtils.isNotBlank(row.getAssetType())
            && !isDictValueValid(DICT_TYPE.ASSET_TYPE, row.getAssetType())) {
            errors.add(new ImportErrorVO(rowNum, "assetType",
                "资产类型不在字典范围内，请检查拼写或联系管理员"));
        }
    }

    return errors;
}

/**
 * 校验字典值是否有效
 * ⚠️ 需要注入 DictDataService
 */
private boolean isDictValueValid(String dictType, String value) {
    // 调用字典服务校验
    return dictDataService.validateDictData(dictType, value);
}
```

### 2.4 VO/DTO 类

#### ParseResultVO.java
```java
package cn.bochk.pap.server.business.vo.resp;

import lombok.Data;
import java.util.List;

@Data
public class ParseResultVO {
    /** 是否校验通过 */
    private Boolean valid;

    /** 错误列表 */
    private List<ImportErrorVO> errors;

    /** 解析后的数据 */
    private List<BuyListImportDTO> data;
}
```

#### ImportErrorVO.java
```java
package cn.bochk.pap.server.business.vo.resp;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ImportErrorVO {
    /** 错误行号 */
    private Integer row;

    /** 错误字段 */
    private String field;

    /** 错误信息 */
    private String message;
}
```

#### BuyListImportDTO.java
```java
package cn.bochk.pap.server.business.dto;

import lombok.Data;

@Data
public class BuyListImportDTO {
    /** 资产类型 */
    private String assetType;

    /** 产品代码 */
    private String productCode;
}
```

---

## 3. 前端实现

### 3.1 API 定义
```typescript
// poc-pro-ui/src/api/buylist/index.ts

export const ListApi = {
  // ... 现有方法 ...

  // 解析校验文件
  parseFile: async (file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return request.post({ url: '/buyList/parse-file', data: formData })
  }

  // ⚠️ 保存时复用现有接口
  // updateBuyList: async (data: List) => { ... }  // 已存在
}
```

### 3.2 上传逻辑
```javascript
// poc-pro-ui/src/views/buylist/detail/index.vue

// 确认上传
const confirmUpload = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请选择文件')
    return
  }

  loading.value = true

  try {
    // 1. 调用后端解析接口
    const parseResult = await ListApi.parseFile(selectedFile.value)

    // 2. 校验结果处理
    if (!parseResult.valid) {
      // 显示错误
      showParseErrors(parseResult.errors)
      return
    }

    // ⚠️ 3. 关键：清空原有数据，完全覆盖
    buyListdetails.value = parseResult.data.map(item => ({
      id: null,  // 新数据没有ID
      buyListId: buyListId.value,
      assetType: item.assetType,
      productCode: item.productCode,
      recordVersion: recordVersion.value
    }))

    ElMessage.success(`成功导入 ${parseResult.data.length} 条数据`)

    // 4. 关闭弹窗
    showUploadDialog.value = false
    selectedFile.value = null
    fileList.value = []

    // 5. 自动进入编辑模式
    isEditMode.value = true

  } catch (error) {
    console.error('文件解析失败:', error)
    ElMessage.error('文件解析失败: ' + (error.message || '未知错误'))
  } finally {
    loading.value = false
  }
}

// 显示校验错误
const showParseErrors = (errors) => {
  const errorMsg = errors.map(e =>
    `第 ${e.row} 行 [${e.field}]: ${e.message}`
  ).join('\n')

  ElMessageBox.alert(
    errorMsg,
    '文件校验失败',
    {
      type: 'error',
      confirmButtonText: '修改后重新上传',
      dangerouslyUseHTMLString: false
    }
  )
}

// ⚠️ 保存按钮复用现有逻辑（不需要修改）
const submitForm = async () => {
  if (submitting.value) return

  try {
    await ElMessageBox.confirm(
      'Changes you made will be saved.',
      'Do you want to save the changes?',
      { confirmButtonText: 'Yes', cancelButtonText: 'Cancel', type: 'warning' }
    )

    submitting.value = true

    // 提交数据（包含导入的数据）
    const submitData = buyListdetails.value.map(item => ({
      ...item,
      recordVersion: recordVersion.value
    }))

    // ⚠️ 复用现有接口，会触发版本控制和审批流程
    await ListApi.updateBuyList(submitData)
    ElMessage.success('Save successful')

    isEditMode.value = false
    setTimeout(() => {
      goBack()
    }, 1000)

  } catch (error) {
    if (error !== 'cancel') {
      console.error('保存失败:', error)
      ElMessage.error('保存失败，请重试')
    }
  } finally {
    submitting.value = false
  }
}
```

### 3.3 模板下载
```javascript
// 修正模板内容（第 686-708 行）
const downloadTemplate = () => {
  const templateData = [
    ['Asset Type', 'Product Code'],  // 表头
    ['股票', '00001'],                // 示例1
    ['债券', '00002'],                // 示例2
    ['基金', '00003']                 // 示例3
  ]

  // 生成CSV（带BOM，支持中文）
  const csvContent = '\uFEFF' + templateData
    .map(row => row.join(','))
    .join('\n')

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = 'buylist_import_template.csv'
  link.click()

  ElMessage.success('模板下载成功')
}
```

---

## 4. 文件修改清单

### 后端
| 文件 | 操作 | 位置 |
|------|------|------|
| `BuyListController.java` | 新增接口 | 新增 `parseFile()` 方法 |
| `BuyListService.java` | 新增方法签名 | 新增 `parseAndValidateFile()` |
| `BuyListServiceImpl.java` | 实现逻辑 | 新增 3 个方法 |
| `ParseResultVO.java` | 新建文件 | `vo/resp/` 目录 |
| `ImportErrorVO.java` | 新建文件 | `vo/resp/` 目录 |
| `BuyListImportDTO.java` | 新建文件 | `dto/` 目录 |

### 前端
| 文件 | 操作 | 位置 |
|------|------|------|
| `api/buylist/index.ts` | 新增方法 | 新增 `parseFile()` |
| `detail/index.vue` | 修改逻辑 | `confirmUpload()` 第 733-789 行 |
| `detail/index.vue` | 修改模板 | `downloadTemplate()` 第 686-708 行 |

---

## 5. 字段映射和校验规则

### 5.1 CSV 字段
| 列 | 字段名 | 类型 | 必填 | 说明 |
|----|--------|------|------|------|
| A | Asset Type | String | 是 | 资产类型，需在字典 ASSET_TYPE 中 |
| B | Product Code | String | 是 | 产品代码 |

### 5.2 校验规则
| 字段 | 规则 |
|------|------|
| assetType | 必填 + 字典值校验（DICT_TYPE.ASSET_TYPE） |
| productCode | 必填 |

---

## 6. 错误处理示例

### 6.1 错误 CSV
```csv
Asset Type,Product Code
,00001          ← 第2行 assetType 为空
股票,           ← 第3行 productCode 为空
XX类型,00003   ← 第4行 assetType 不在字典
```

### 6.2 后端返回
```json
{
  "code": 0,
  "data": {
    "valid": false,
    "errors": [
      {"row": 2, "field": "assetType", "message": "资产类型不能为空"},
      {"row": 3, "field": "productCode", "message": "产品代码不能为空"},
      {"row": 4, "field": "assetType", "message": "资产类型不在字典范围内，请检查拼写或联系管理员"}
    ]
  }
}
```

### 6.3 前端显示
```
文件校验失败

第 2 行 [assetType]: 资产类型不能为空
第 3 行 [productCode]: 产品代码不能为空
第 4 行 [assetType]: 资产类型不在字典范围内，请检查拼写或联系管理员
```

---

## 7. 关键点总结

### 7.1 优势
1. **改动最小**：只需1个后端接口，复用现有保存逻辑
2. **逻辑清晰**：后端只负责校验，前端负责数据管理
3. **审批流程**：自动触发，无需额外处理
4. **版本控制**：自动生成新版本，保持一致性

### 7.2 核心实现
1. **后端**：
   - 解析CSV文件（跳过表头和空行）
   - 校验 assetType（必填+字典值） 和 productCode（必填）
   - 返回错误列表或解析数据

2. **前端**：
   - 接收解析结果
   - **完全覆盖原有数据**（关键）
   - 调用现有保存接口

### 7.3 注意事项
⚠️ **必须注入 DictDataService** 用于字典值校验
⚠️ **数据完全覆盖**，导入后原有数据被清空
⚠️ **保存时触发审批流程**，会生成新版本和流程实例

---

## 8. 测试场景

- [ ] 上传空文件
- [ ] 上传只有表头的文件
- [ ] 缺少 assetType
- [ ] 缺少 productCode
- [ ] assetType 不在字典范围
- [ ] 正常导入 10+ 条数据
- [ ] 导入后点击保存，检查版本号是否+1
- [ ] 保存后检查审批流程是否启动
- [ ] 特殊字符处理（逗号、引号）
- [ ] 中文编码问题（UTF-8 BOM）
