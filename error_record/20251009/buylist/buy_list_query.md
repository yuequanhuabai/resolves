好的，让我复述一下我对你查询需求的理解：

📋 需求理解

🎯 核心改造目标

- 放弃现有方法，创建全新的查询链路
- 使用 MyBatis XML 手写 SQL，不依赖 MyBatis-Plus
- 新增方法名统一为：queryBuyListPage

  ---
🔍 查询条件（共5个参数）

| 参数            | 字段名          | 来源表              | 查询方式              | 必填
|
|---------------|--------------|------------------|-------------------|--------------------------------|
| Asset Type    | assetType    | buy_list_details | 精确匹配 (=)          | 否                              |
| Buy List ID   | businessId   | buy_list         | 右模糊查询 (LIKE 'A%') | 否                              |
| Buy List Name | name         | buy_list         | 右模糊查询 (LIKE 'A%') | 否                              |
| Status        | status       | buy_list         | 精确匹配 (=)          | 否                              |
| Business Type | businessType | buy_list         | 精确匹配 (=)          | 是（用于区分 Private/Retail Banking）
|

默认行为：
- 首次查询时，前4个条件默认为 null（不传值）
- businessType 始终会传值（1=Private Banking, 2=Retail Banking）

  ---
📊 返回结果

VO 类型：BuyListRespVO（保持不变）

包含字段（对应数据库表字段）：
- businessId - Buy List ID
- name - Buy List Name
- assetType - Asset Type（来自关联表）
- status - 状态
- maker - 提交人
- makerDatetime - Last Mod DateTime（提交时间）
- checker - 审核人
- checkerDatetime - Last Check DateTime（审核时间）

  ---
🔄 排序功能

可排序字段（8个）：
1. Buy List ID (business_id)
2. Buy List Name (name)
3. Asset Type (asset_type)
4. Status (status)
5. Maker (maker)
6. Last Mod DateTime (maker_datetime)
7. Checker (checker)
8. Last Check DateTime (checker_datetime)

排序机制：
- 前端表头显示上下箭头
- 点击表头触发重新查询，传递排序参数（例如：orderBy=business_id&orderDirection=ASC）
- 后端需要动态拼接 ORDER BY 子句

  ---
📄 分页功能

分页参数：
- pageNo：当前页码（从1开始）
- pageSize：每页条数，默认 10，支持切换 10/20/30

分页组件功能：
- Prev / Next 按钮
- 页码选择
- 每页条数切换
- 总记录数显示
- 如果数据超出可视区域，出现滚动条

  ---
🗄️ SQL 查询逻辑

核心逻辑：
查询主表：buy_list
联表查询：LEFT JOIN buy_list_details（因为 Asset Type 在详情表中）
关联条件：buy_list.id = buy_list_details.buy_list_id

关键点：
1. 主表是 buy_list，需要返回主表的完整记录
2. 详情表 buy_list_details 用于：
   - 提供 asset_type 字段的过滤条件
   - 可能需要去重（一个 buy_list 可能有多条 details）
3. 固定过滤条件：
   - del_flag = 0（只查有效记录）
   - business_type = ?（区分 Private/Retail Banking）
4. 默认排序（如果前端未指定）：valid_start_datetime DESC

潜在问题需要处理：
- 一个 buy_list 可能关联多条 details 记录
- 如果按 asset_type 过滤，需要确保主表记录不重复
- 建议使用 DISTINCT 或 GROUP BY 去重

  ---
📝 伪 SQL 示例

SELECT DISTINCT
bl.id,
bl.business_id,
bl.name,
bl.status,
bl.maker,
bl.maker_datetime,
bl.checker,
bl.checker_datetime,
bl.process_instance_id,
-- 其他 buy_list 表字段...
FROM
buy_list bl
LEFT JOIN
buy_list_details bld ON bl.id = bld.buy_list_id
WHERE
bl.del_flag = 0
AND bl.business_type = #{businessType}
<if test="assetType != null">
AND bld.asset_type = #{assetType}
</if>
<if test="businessId != null">
AND bl.business_id LIKE CONCAT(#{businessId}, '%')
</if>
<if test="name != null">
AND bl.name LIKE CONCAT(#{name}, '%')
</if>
<if test="status != null">
AND bl.status = #{status}
</if>
ORDER BY
<if test="orderBy != null">
${orderBy} ${orderDirection}
</if>
<if test="orderBy == null">
bl.valid_start_datetime DESC
</
LIMIT #{offset}, #{pageSize}

  ---
✅ 我的理解总结

你希望：
1. 创建全新的查询方法链路（Service → Mapper → XML）
2. 使用原生 SQL，不依赖 MyBatis-Plus 的查询构造器
3. 支持动态条件（4个可选条件 + 1个必填条件）
4. 支持右模糊查询（Buy List ID 和 Buy List Name）
5. 支持动态排序（8个字段可排序）
6. 支持分页（10/20/30条/页）
7. 联表查询（主表 buy_list + 详情表 buy_list_details）
8. 返回结果去重（避免因多条 details 导致主表记录重复）

  ---
我的理解是否正确？如果有偏差请指正，我会立即开始实现！