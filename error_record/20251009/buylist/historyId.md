好的，我理解你的需求了。让我给你一个清晰的实现思路：

业务分析

根据代码分析，状态流转如下：

业务状态 (bizStatus)：
- 0 = system（初始状态）
- 1 = submit（提交）
- 2 = approval（审批通过）
- 3 = reject（审批拒绝）
- 4 = restart（重新发起）

审批状态 (status)：
- 1 = PENDING（待审批）
- 2 = APPROVED（审批通过）
- 3 = REJECTED（审批拒绝）

获取"上条确认数据"的思路

场景1：编辑提交操作 (status == null 时)

根据当前数据的 bizStatus 判断：

// 在 insertNewBuyListByOriginalBizStatus 方法中，当 status == null 时

if (bizStatus == 0) {
// 首次提交，没有上条数据
historyId = null;

} else if (bizStatus == 2 || bizStatus == 3) {
// 审批通过/拒绝后重新发起
// 上条数据 = 当前这条审批的数据
historyId = originalBuyListDo.getId();

} else if (bizStatus == 1 || bizStatus == 4) {
// 再次编辑（在审批之前）
// 上条数据 = 查找同一个 businessId 下，最近的一条 bizStatus=2 或 3 的记录
// 需要通过 businessId + recordVersion 倒序查询
historyId = findLastApprovedOrRejectedRecord(originalBuyListDo.getBusinessId(),
originalBuyListDo.getRecordVersion());
}

场景2：审批操作 (status != null 时)

// 在 insertNewBuyListByOriginalBizStatus 方法中，当 status != null 时

if (bizStatus == 1 || bizStatus == 4) {
// 当前是 pending 状态，审批员正在审批
// 上条数据 = 查找这次提交之前的最后一次编辑数据
// 由于当前数据就是最后一次编辑提交的结果，所以上条数据就是当前数据本身
historyId = originalBuyListDo.getId();
}

具体实现方案

方法1：通过 businessId 查询历史审批记录

/**
* 查找上一次审批的记录（同意或拒绝）
*
* @param businessId 业务ID
* @param currentVersion 当前版本号
* @return 上一次审批记录的ID，如果没有则返回null
  */
  private String findLastApprovedOrRejectedRecord(String businessId, Integer currentVersion) {
  // 查询同一个 businessId 下，版本号小于当前版本，且 bizStatus=2 或 3 的最新一条记录
  LambdaQueryWrapper<BuyListDO> wrapper = new LambdaQueryWrapper<>();
  wrapper.eq(BuyListDO::getBusinessId, businessId)
  .lt(BuyListDO::getRecordVersion, currentVersion)
  .in(BuyListDO::getBizStatus, Arrays.asList(
  StatusEnum.approval.getValue(),   // 2
  StatusEnum.reject.getValue()      // 3
  ))
  .orderByDesc(BuyListDO::getRecordVersion)
  .last("LIMIT 1");

  BuyListDO lastApproved = listMapper.selectOne(wrapper);
  return lastApproved != null ? lastApproved.getId() : null;
  }

方法2：完整的 historyId 设置逻辑

在 insertNewBuyListByOriginalBizStatus 方法中添加：

// 操作人员的入口（编辑提交）
if (null == status) {
// ... 现有逻辑 ...

      // 设置 historyId
      if (StatusEnum.system.getValue().equals(bizStatus)) {
          // 首次提交
          buyListDO.setHistoryId(null);

      } else if (StatusEnum.approval.getValue().equals(bizStatus)
              || StatusEnum.reject.getValue().equals(bizStatus)) {
          // 审批后重新发起，上条数据就是当前审批的这条
          buyListDO.setHistoryId(originalBuyListDo.getId());

      } else if (StatusEnum.submit.getValue().equals(bizStatus)
              || StatusEnum.restart.getValue().equals(bizStatus)) {
          // 再次编辑，查找最近的审批记录
          String lastApprovedId = findLastApprovedOrRejectedRecord(
              originalBuyListDo.getBusinessId(),
              originalBuyListDo.getRecordVersion()
          );
          buyListDO.setHistoryId(lastApprovedId);
      }
}

// 审批人员的入口
else {
// ... 现有逻辑 ...

      // 审批时，上条数据就是当前这条提交的数据
      buyListDO.setHistoryId(originalBuyListDo.getId());
}

总结

核心思路是：

1. 编辑提交时：向前查找最近的审批记录（bizStatus=2或3）
2. 审批操作时：当前记录就是最后一次编辑的数据，所以 historyId 就是当前记录的 id
3. 首次提交时：historyId 为 null

这样就能追溯到每次操作的"上条确认数据"，形成完整的操作链路。

需要我帮你实现这个逻辑吗？