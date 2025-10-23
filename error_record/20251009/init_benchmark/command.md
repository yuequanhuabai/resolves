你把是否初始化这个逻辑改下，直接基于benchmark_id从benchmark_detail表里面查数据吧，如果没有数据就是初始化，有数据就非初始化，保存操作；
情况1（初始化）. benchmark表操作没问题，benchmark_detail表的操作，因为没有del_flag字段，这个del_flag = 0操作不需要，只要record_version = 0这个即可，其它的没问题；
情况2 （非初始化），Benchmark表操作没问题；Benchmark_detail表操作 没问题，record_version=新记录的benchmark表的record_version，它比原来的record_version大1吧

确认细节：
 问题1：Benchmark_detail表的del_flag字段
 回答1： Benchmark_detail表不要del_flag字段

问题2：情况1的验证逻辑
回答2： 改为查询Benchmark_detail表来验证是否初始化，不会有这个情况

问题3：情况1的record_version更新
回答3： 如果是初始化，record_version全部设置为0，不管它之前是啥;

问题4：查询逻辑
  查询benchmark_details时，是否需要添加过滤条件：
  // 只查询del_flag=0的benchmark关联的details
  SELECT * FROM benchmark_details
  WHERE benchmark_id IN (
    SELECT id FROM benchmark WHERE business_id = ? AND del_flag = 0
  )
回答4: 这个肯定要加条件过滤，查询del_flag=0和对应benchmark_id的数据