# JUC 阶梯式练习题集

> 基于 `java.util.concurrent` 包的各个应用场景，按难度递进设计的练习题集。
>
> 难度说明：
> - ⭐ 简单：基础API使用
> - ⭐⭐ 中等：组合使用，理解原理
> - ⭐⭐⭐ 复杂：实际场景应用
> - ⭐⭐⭐⭐ 困难：性能优化，边界处理
> - ⭐⭐⭐⭐⭐ 地狱级：源码级理解，极端场景

---

## 场景一：计数器/累加器

### 题目 1.1 ⭐ 简单
**基础计数器**

使用 `AtomicInteger` 实现一个线程安全的计数器类 `Counter`，支持以下操作：
- `increment()`: 计数加1
- `decrement()`: 计数减1
- `get()`: 获取当前值
- `reset()`: 重置为0

要求：启动10个线程，每个线程对计数器执行1000次 `increment()`，最终结果应为10000。

```java
public class Counter {
    // 实现代码
}

// 测试代码
public static void main(String[] args) throws InterruptedException {
    Counter counter = new Counter();
    // 启动10个线程，每个执行1000次increment
    // 验证最终结果为10000
}
```

---

### 题目 1.2 ⭐ 简单
**CAS自旋实现**

不使用 `AtomicInteger`，使用 `Unsafe` 或 `VarHandle`（JDK9+）手动实现一个基于CAS的原子计数器。

要求：
1. 实现 `incrementAndGet()` 方法
2. 使用自旋 + CAS 实现
3. 理解CAS失败后的重试逻辑

```java
public class MyCASCounter {
    private volatile int value;

    public int incrementAndGet() {
        // 使用CAS自旋实现
    }
}
```

---

### 题目 1.3 ⭐ 简单
**原子数组操作**

使用 `AtomicIntegerArray` 实现一个多线程安全的直方图统计类。

场景：统计1-100的随机数分布，将数字分为10个区间 [1-10], [11-20], ..., [91-100]，多线程并发统计。

```java
public class Histogram {
    private AtomicIntegerArray buckets = new AtomicIntegerArray(10);

    public void record(int value) {
        // 将value放入对应的bucket
    }

    public void printDistribution() {
        // 打印各区间的统计数量
    }
}
```

---

### 题目 1.4 ⭐⭐ 中等
**LongAdder vs AtomicLong 性能对比**

编写一个性能测试程序，对比 `AtomicLong` 和 `LongAdder` 在高并发场景下的性能差异。

要求：
1. 分别使用 AtomicLong 和 LongAdder
2. 启动100个线程，每个线程执行100万次累加
3. 记录两种方式的耗时
4. 分析性能差异的原因

```java
public class AdderBenchmark {
    public static void main(String[] args) {
        // 测试 AtomicLong
        // 测试 LongAdder
        // 输出对比结果
    }
}
```

**思考题**：为什么 `LongAdder` 在高并发下性能更好？它是如何减少竞争的？

---

### 题目 1.5 ⭐⭐ 中等
**ABA问题演示与解决**

1. 编写代码演示ABA问题的发生场景
2. 使用 `AtomicStampedReference` 解决ABA问题

场景：模拟银行账户余额修改
- 线程A读取余额100，准备扣款50
- 线程B将余额从100改为50
- 线程C将余额从50改为100
- 线程A执行CAS(100, 50)会成功（但这是错误的！因为中间发生过变化）

```java
public class ABADemo {
    // 1. 演示ABA问题
    public static void demonstrateABAProblem() {
        // 实现
    }

    // 2. 使用AtomicStampedReference解决
    public static void solveWithStampedReference() {
        // 实现
    }
}
```

---

### 题目 1.6 ⭐⭐⭐ 复杂
**自定义累加器**

使用 `LongAccumulator` 实现以下功能：

1. 实现一个并发安全的最大值追踪器（多线程不断提交数值，追踪最大值）
2. 实现一个并发安全的乘积累加器（注意溢出处理）
3. 实现一个并发安全的平均值计算器（提示：需要追踪sum和count）

```java
public class CustomAccumulators {
    // 1. 最大值追踪器
    private LongAccumulator maxTracker = new LongAccumulator(
        // 实现累加函数
    );

    // 2. 乘积累加器

    // 3. 平均值计算器（这个比较复杂，需要组合使用）
}
```

---

### 题目 1.7 ⭐⭐⭐ 复杂
**字段原子更新器**

使用 `AtomicIntegerFieldUpdater` 在不修改原有类定义的情况下，为现有类添加原子操作能力。

场景：有一个遗留的 `User` 类，需要并发安全地更新其 `score` 字段：

```java
// 遗留类，不能修改
class User {
    volatile int score;
    String name;

    public User(String name, int score) {
        this.name = name;
        this.score = score;
    }
}

public class UserScoreUpdater {
    private static final AtomicIntegerFieldUpdater<User> SCORE_UPDATER =
        // 创建更新器

    // 实现原子性地增加分数
    public static void addScore(User user, int delta) {
        // 实现
    }

    // 实现CAS更新分数
    public static boolean compareAndSetScore(User user, int expect, int update) {
        // 实现
    }
}
```

**附加要求**：解释为什么 `score` 字段必须是 `volatile` 的？如果不是会怎样？

---

### 题目 1.8 ⭐⭐⭐⭐ 困难
**实现一个无锁的并发栈**

使用 `AtomicReference` 实现一个无锁的并发栈（Treiber Stack）。

要求：
1. 实现 `push(E item)` 和 `pop()` 方法
2. 使用CAS保证线程安全
3. 正确处理空栈的情况
4. 编写多线程测试验证正确性

```java
public class ConcurrentStack<E> {
    private AtomicReference<Node<E>> top = new AtomicReference<>();

    private static class Node<E> {
        final E item;
        Node<E> next;

        Node(E item) {
            this.item = item;
        }
    }

    public void push(E item) {
        // CAS实现
    }

    public E pop() {
        // CAS实现
    }
}
```

**附加挑战**：这个实现有ABA问题吗？如何解决？

---

### 题目 1.9 ⭐⭐⭐⭐ 困难
**实现一个高性能的ID生成器**

设计一个分布式友好的ID生成器，要求：
1. 单机每秒能生成100万+的唯一ID
2. ID趋势递增（不要求严格递增）
3. 支持多机部署不重复

提示：参考Snowflake算法，使用原子操作实现序列号部分。

```java
public class SnowflakeIdGenerator {
    private final long machineId;
    private final long datacenterId;
    private AtomicLong sequence = new AtomicLong(0);
    private volatile long lastTimestamp = -1L;

    public long nextId() {
        // 实现：时间戳 + 数据中心ID + 机器ID + 序列号
    }

    // 处理时钟回拨
    private void handleClockBackward(long currentTimestamp) {
        // 实现
    }
}
```

---

### 题目 1.10 ⭐⭐⭐⭐⭐ 地狱级
**实现 LongAdder 的简化版**

深入理解 `LongAdder` 原理，自己实现一个简化版的 `MyLongAdder`。

要求：
1. 实现分段累加思想（Cell数组）
2. 实现 `add(long x)` 和 `sum()` 方法
3. 实现动态扩容（当竞争激烈时增加Cell数量）
4. 使用 `@Contended` 注解（或手动填充）解决伪共享问题

```java
public class MyLongAdder {
    // 使用填充解决伪共享
    @sun.misc.Contended  // 或手动填充
    static final class Cell {
        volatile long value;
        // 实现CAS更新
    }

    private volatile Cell[] cells;
    private volatile long base;

    public void add(long x) {
        // 1. 先尝试更新base（无竞争时）
        // 2. 有竞争时，定位到Cell并更新
        // 3. 如果Cell也竞争失败，考虑扩容
    }

    public long sum() {
        // 累加base和所有Cell的值
    }

    // 初始化或扩容cells数组
    private void longAccumulate(long x, boolean wasUncontended) {
        // 核心逻辑
    }
}
```

**附加问题**：
1. 为什么Cell数组大小必须是2的幂次？
2. 为什么要使用伪共享填充？填充多少字节？
3. `sum()` 方法返回的值是精确的吗？为什么？

---

## 场景二：读多写少

### 题目 2.1 ⭐ 简单
**基础读写锁使用**

使用 `ReentrantReadWriteLock` 实现一个线程安全的缓存类：

```java
public class SimpleCache<K, V> {
    private final Map<K, V> cache = new HashMap<>();
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();

    public V get(K key) {
        // 使用读锁
    }

    public void put(K key, V value) {
        // 使用写锁
    }

    public void remove(K key) {
        // 使用写锁
    }
}
```

---

### 题目 2.2 ⭐ 简单
**锁降级实践**

演示读写锁的锁降级过程：持有写锁时获取读锁，然后释放写锁。

场景：实现一个配置管理器，更新配置后需要立即读取验证：

```java
public class ConfigManager {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private Map<String, String> config = new HashMap<>();

    // 更新配置并返回更新后的值（需要锁降级）
    public String updateAndGet(String key, String value) {
        // 1. 获取写锁
        // 2. 更新配置
        // 3. 获取读锁（在持有写锁时）
        // 4. 释放写锁
        // 5. 读取并返回
        // 6. 释放读锁
    }
}
```

**思考题**：为什么不支持锁升级（持有读锁时获取写锁）？会发生什么？

---

### 题目 2.3 ⭐ 简单
**CopyOnWriteArrayList 使用**

使用 `CopyOnWriteArrayList` 实现一个事件监听器管理器：

```java
public class EventManager {
    private final CopyOnWriteArrayList<EventListener> listeners =
        new CopyOnWriteArrayList<>();

    public void addListener(EventListener listener) {
        // 添加监听器
    }

    public void removeListener(EventListener listener) {
        // 移除监听器
    }

    public void fireEvent(Event event) {
        // 通知所有监听器（迭代时不需要加锁）
    }
}

interface EventListener {
    void onEvent(Event event);
}
```

**思考题**：为什么 `CopyOnWriteArrayList` 适合这个场景？如果监听器数量很大且频繁增删会怎样？

---

### 题目 2.4 ⭐⭐ 中等
**StampedLock 乐观读**

使用 `StampedLock` 的乐观读模式优化一个坐标点类：

```java
public class Point {
    private double x, y;
    private final StampedLock sl = new StampedLock();

    // 移动点（写操作）
    public void move(double deltaX, double deltaY) {
        long stamp = sl.writeLock();
        try {
            x += deltaX;
            y += deltaY;
        } finally {
            sl.unlockWrite(stamp);
        }
    }

    // 计算到原点的距离（读操作，使用乐观读）
    public double distanceFromOrigin() {
        // 1. 尝试乐观读
        // 2. 读取x, y
        // 3. 验证stamp
        // 4. 如果验证失败，升级为悲观读锁
        // 5. 计算并返回距离
    }

    // 计算到另一个点的距离（需要锁两个对象，注意死锁）
    public double distanceTo(Point other) {
        // 实现
    }
}
```

---

### 题目 2.5 ⭐⭐ 中等
**读写锁性能测试**

编写性能测试，对比以下方案在不同读写比例下的性能：
1. `synchronized`
2. `ReentrantLock`
3. `ReentrantReadWriteLock`
4. `StampedLock`

```java
public class RWLockBenchmark {
    // 测试配置
    private static final int READERS = 10;
    private static final int WRITERS = 2;
    private static final int OPERATIONS = 100000;

    // 分别测试四种锁
    public void benchmarkSynchronized() { }
    public void benchmarkReentrantLock() { }
    public void benchmarkReadWriteLock() { }
    public void benchmarkStampedLock() { }

    // 汇总结果
    public void printResults() { }
}
```

**分析要求**：
1. 在读多写少（100:1）时，哪种锁性能最好？
2. 在读写均衡（1:1）时呢？
3. 为什么会有这样的差异？

---

### 题目 2.6 ⭐⭐⭐ 复杂
**实现带过期时间的缓存**

使用读写锁实现一个带过期时间的缓存：

```java
public class ExpiringCache<K, V> {
    private final Map<K, CacheEntry<V>> cache = new HashMap<>();
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final ScheduledExecutorService cleaner =
        Executors.newSingleThreadScheduledExecutor();

    static class CacheEntry<V> {
        V value;
        long expireTime;
    }

    public V get(K key) {
        // 读锁 + 检查过期
    }

    public void put(K key, V value, long ttlMillis) {
        // 写锁 + 设置过期时间
    }

    // 后台清理过期条目
    private void cleanExpired() {
        // 需要写锁，但要注意不要长时间持有
    }

    public void shutdown() {
        // 清理资源
    }
}
```

**附加要求**：
1. 清理过期条目时如何避免长时间阻塞写入？
2. 如何处理"读取时发现过期"的情况？

---

### 题目 2.7 ⭐⭐⭐ 复杂
**实现一个读写分离的计数器**

实现一个支持精确读取的高并发计数器，写入不阻塞，读取返回精确值：

```java
public class PreciseCounter {
    // 提示：使用多个分段 + 读写锁

    public void increment() {
        // 只锁定一个分段，写入快
    }

    public long get() {
        // 需要读取所有分段的一致性快照
        // 返回精确值
    }
}
```

**思考题**：`LongAdder.sum()` 返回的是精确值吗？你的实现如何保证精确？

---

### 题目 2.8 ⭐⭐⭐⭐ 困难
**实现可中断的读写锁**

基于 `ReentrantReadWriteLock`，实现一个支持超时和中断的读写锁包装器：

```java
public class InterruptibleRWLock {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();

    public <T> T readWithTimeout(Supplier<T> reader, long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        // 带超时的读操作
    }

    public void writeWithTimeout(Runnable writer, long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        // 带超时的写操作
    }

    // 可中断的读操作
    public <T> T readInterruptibly(Supplier<T> reader) throws InterruptedException {
        // 实现
    }
}
```

---

### 题目 2.9 ⭐⭐⭐⭐ 困难
**StampedLock 转换模式**

深入使用 `StampedLock` 的所有模式，实现一个支持条件等待的数据容器：

```java
public class StampedContainer<T> {
    private T data;
    private final StampedLock sl = new StampedLock();

    // 乐观读
    public T optimisticRead() {
        // 实现
    }

    // 读锁转写锁
    public T readThenWrite(Function<T, T> transformer) {
        // 1. 获取读锁
        // 2. 读取数据
        // 3. 尝试转换为写锁
        // 4. 如果转换失败，释放读锁，获取写锁
        // 5. 执行转换
    }

    // 写锁转读锁（锁降级）
    public T writeAndRead(T newValue) {
        // 实现
    }
}
```

**附加问题**：`StampedLock` 不支持重入，这在实际使用中会带来什么问题？如何避免？

---

### 题目 2.10 ⭐⭐⭐⭐⭐ 地狱级
**实现一个支持快照的并发Map**

实现一个支持一致性快照读取的并发Map：

```java
public class SnapshotMap<K, V> {

    // 普通的写操作
    public void put(K key, V value) {
        // 实现
    }

    // 普通的读操作
    public V get(K key) {
        // 实现
    }

    // 获取某一时刻的一致性快照
    // 快照创建后，即使原Map被修改，快照内容不变
    public Map<K, V> snapshot() {
        // 实现
    }

    // 在快照上进行范围查询
    public List<V> rangeQuery(K from, K to) {
        // 实现
    }
}
```

**要求**：
1. 写操作不能阻塞太久
2. 快照必须是某一时刻的一致视图
3. 快照不能是简单的全量复制（内存效率）
4. 提示：可以参考MVCC（多版本并发控制）思想

---

## 场景三：线程协作/等待

### 题目 3.1 ⭐ 简单
**CountDownLatch 基础使用**

使用 `CountDownLatch` 实现一个并行任务执行器，等待所有任务完成后汇总结果：

```java
public class ParallelTaskExecutor {

    public List<String> executeAll(List<Callable<String>> tasks)
            throws InterruptedException {
        // 1. 创建CountDownLatch
        // 2. 启动所有任务
        // 3. 等待所有任务完成
        // 4. 收集并返回结果
    }
}
```

---

### 题目 3.2 ⭐ 简单
**CyclicBarrier 基础使用**

使用 `CyclicBarrier` 实现一个模拟赛跑的程序：

```java
public class Race {
    private final int runnerCount;
    private final CyclicBarrier barrier;

    public Race(int runnerCount) {
        this.runnerCount = runnerCount;
        this.barrier = new CyclicBarrier(runnerCount,
            () -> System.out.println("所有选手准备就绪，比赛开始！"));
    }

    public void start() {
        for (int i = 0; i < runnerCount; i++) {
            int runnerId = i;
            new Thread(() -> {
                // 1. 准备阶段（随机时间）
                // 2. 到达起跑线，等待其他选手
                // 3. 所有人就绪后，开始跑步
                // 4. 跑步（随机时间）
                // 5. 到达终点
            }).start();
        }
    }
}
```

---

### 题目 3.3 ⭐ 简单
**Semaphore 基础使用**

使用 `Semaphore` 实现一个数据库连接池的简单模拟：

```java
public class ConnectionPool {
    private final Semaphore semaphore;
    private final Queue<Connection> pool;

    public ConnectionPool(int size) {
        this.semaphore = new Semaphore(size);
        this.pool = new LinkedList<>();
        // 初始化连接
    }

    public Connection acquire() throws InterruptedException {
        // 获取许可 + 获取连接
    }

    public void release(Connection conn) {
        // 归还连接 + 释放许可
    }
}
```

---

### 题目 3.4 ⭐⭐ 中等
**Exchanger 数据交换**

使用 `Exchanger` 实现一个生产者-消费者的数据交换场景：

```java
public class DataExchanger {
    private final Exchanger<List<String>> exchanger = new Exchanger<>();

    // 生产者：填充数据后交换空列表
    public void producer() {
        List<String> buffer = new ArrayList<>();
        while (true) {
            // 填充数据到buffer
            for (int i = 0; i < 10; i++) {
                buffer.add("data-" + System.nanoTime());
            }
            // 交换：把满的buffer换成空的
            buffer = exchanger.exchange(buffer);
            // 现在buffer是空的，继续填充
        }
    }

    // 消费者：处理数据后交换空列表
    public void consumer() {
        List<String> buffer = new ArrayList<>();
        while (true) {
            // 交换：把空的buffer换成满的
            buffer = exchanger.exchange(buffer);
            // 处理数据
            for (String data : buffer) {
                process(data);
            }
            buffer.clear();
        }
    }
}
```

---

### 题目 3.5 ⭐⭐ 中等
**CountDownLatch 实现超时等待**

扩展 `CountDownLatch` 的使用，实现带超时的多任务等待：

```java
public class TimeoutTaskExecutor {

    public Map<String, Object> executeWithTimeout(
            Map<String, Callable<?>> tasks,
            long timeout,
            TimeUnit unit) throws InterruptedException {

        Map<String, Object> results = new ConcurrentHashMap<>();
        CountDownLatch latch = new CountDownLatch(tasks.size());

        // 1. 启动所有任务
        // 2. 带超时等待
        // 3. 返回已完成的结果（可能不是全部）
        // 4. 对于超时未完成的任务，记录为null或特殊值

        return results;
    }
}
```

---

### 题目 3.6 ⭐⭐⭐ 复杂
**CyclicBarrier 实现分阶段计算**

使用 `CyclicBarrier` 实现一个矩阵的分阶段并行计算：

场景：计算矩阵的每一行的和，然后计算所有行和的总和。

```java
public class MatrixCalculator {
    private final int[][] matrix;
    private final int[] rowSums;
    private final CyclicBarrier barrier;

    public int calculate() {
        // 阶段1：每个线程计算一行的和
        // 屏障等待
        // 阶段2：一个线程计算总和

        // 使用CyclicBarrier的回调功能
    }
}
```

---

### 题目 3.7 ⭐⭐⭐ 复杂
**Phaser 动态注册**

使用 `Phaser` 实现一个支持动态加入/退出的多阶段任务：

```java
public class DynamicPhaserTask {
    private final Phaser phaser = new Phaser(1); // 主线程注册

    public void runTask() {
        // 阶段1：初始3个工作线程
        for (int i = 0; i < 3; i++) {
            startWorker("worker-" + i);
        }

        // 等待阶段1完成
        phaser.arriveAndAwaitAdvance();
        System.out.println("阶段1完成");

        // 阶段2：动态增加2个工作线程
        for (int i = 3; i < 5; i++) {
            startWorker("worker-" + i);
        }

        // 等待阶段2完成
        phaser.arriveAndAwaitAdvance();
        System.out.println("阶段2完成");

        // 主线程退出
        phaser.arriveAndDeregister();
    }

    private void startWorker(String name) {
        phaser.register(); // 动态注册
        new Thread(() -> {
            // 工作
            phaser.arriveAndAwaitAdvance();
            // 更多工作...
            phaser.arriveAndDeregister(); // 退出
        }, name).start();
    }
}
```

---

### 题目 3.8 ⭐⭐⭐⭐ 困难
**实现一个可重用的CountDownLatch**

`CountDownLatch` 是一次性的，实现一个可以重置重用的版本：

```java
public class ReusableCountDownLatch {
    private final int initialCount;
    // 提示：可以使用ReentrantLock + Condition实现

    public ReusableCountDownLatch(int count) {
        this.initialCount = count;
    }

    public void countDown() {
        // 计数减1，如果到0则唤醒等待线程
    }

    public void await() throws InterruptedException {
        // 等待计数到0
    }

    public boolean await(long timeout, TimeUnit unit) throws InterruptedException {
        // 带超时等待
    }

    public void reset() {
        // 重置计数，允许再次使用
    }
}
```

---

### 题目 3.9 ⭐⭐⭐⭐ 困难
**实现一个分布式屏障**

基于Redis（或其他存储）实现一个分布式的CyclicBarrier：

```java
public class DistributedBarrier {
    private final String barrierName;
    private final int parties;
    private final RedisClient redis; // 假设有Redis客户端

    public DistributedBarrier(String name, int parties) {
        this.barrierName = name;
        this.parties = parties;
    }

    public void await() throws InterruptedException {
        // 1. 增加Redis中的计数
        // 2. 如果计数 == parties，通知所有等待者
        // 3. 否则，等待通知
        // 4. 处理超时和异常
    }

    public void reset() {
        // 重置屏障
    }
}
```

**附加要求**：
1. 处理节点宕机的情况
2. 实现超时机制
3. 保证exactly-once语义

---

### 题目 3.10 ⭐⭐⭐⭐⭐ 地狱级
**实现一个完整的Phaser**

从零实现一个简化版的 `Phaser`，支持以下功能：

```java
public class MyPhaser {

    // 注册一个参与者
    public int register() {
        // 实现
    }

    // 批量注册
    public int bulkRegister(int parties) {
        // 实现
    }

    // 到达并等待其他参与者
    public int arriveAndAwaitAdvance() {
        // 实现
    }

    // 到达但不等待
    public int arrive() {
        // 实现
    }

    // 到达并注销
    public int arriveAndDeregister() {
        // 实现
    }

    // 等待进入下一阶段
    public int awaitAdvance(int phase) {
        // 实现
    }

    // 获取当前阶段
    public int getPhase() {
        // 实现
    }

    // 获取已注册的参与者数量
    public int getRegisteredParties() {
        // 实现
    }

    // 获取已到达的参与者数量
    public int getArrivedParties() {
        // 实现
    }
}
```

**要求**：
1. 使用CAS实现无锁设计
2. 支持分层（父子Phaser）
3. 正确处理所有边界情况

---

## 场景四：资源池/限流

### 题目 4.1 ⭐ 简单
**Semaphore 实现简单限流**

使用 `Semaphore` 实现一个简单的接口限流器：

```java
public class RateLimiter {
    private final Semaphore semaphore;

    public RateLimiter(int maxConcurrent) {
        this.semaphore = new Semaphore(maxConcurrent);
    }

    public <T> T execute(Callable<T> task) throws Exception {
        // 获取许可
        // 执行任务
        // 释放许可
    }

    public <T> T tryExecute(Callable<T> task, long timeout, TimeUnit unit)
            throws Exception {
        // 带超时的尝试获取
    }
}
```

---

### 题目 4.2 ⭐ 简单
**公平与非公平信号量**

对比公平信号量和非公平信号量的行为差异：

```java
public class SemaphoreFairnessDemo {

    public void testUnfair() {
        Semaphore unfairSem = new Semaphore(1, false);
        // 创建多个线程竞争
        // 观察获取许可的顺序
    }

    public void testFair() {
        Semaphore fairSem = new Semaphore(1, true);
        // 创建多个线程竞争
        // 观察获取许可的顺序（应该是FIFO）
    }
}
```

**思考题**：公平信号量的性能代价是什么？什么场景下必须使用公平信号量？

---

### 题目 4.3 ⭐ 简单
**Semaphore 实现对象池**

使用 `Semaphore` 实现一个通用的对象池：

```java
public class ObjectPool<T> {
    private final Semaphore semaphore;
    private final BlockingQueue<T> pool;

    public ObjectPool(Supplier<T> factory, int size) {
        this.semaphore = new Semaphore(size);
        this.pool = new LinkedBlockingQueue<>();
        // 初始化对象
    }

    public T borrow() throws InterruptedException {
        // 获取对象
    }

    public void returnObject(T obj) {
        // 归还对象
    }
}
```

---

### 题目 4.4 ⭐⭐ 中等
**滑动窗口限流器**

实现一个基于滑动窗口的限流器：

```java
public class SlidingWindowRateLimiter {
    private final int maxRequests;
    private final long windowSizeMs;

    public SlidingWindowRateLimiter(int maxRequests, long windowSizeMs) {
        this.maxRequests = maxRequests;
        this.windowSizeMs = windowSizeMs;
    }

    public boolean tryAcquire() {
        // 检查当前窗口内的请求数
        // 如果小于maxRequests，允许并记录
        // 否则拒绝
    }
}
```

---

### 题目 4.5 ⭐⭐ 中等
**令牌桶限流器**

实现一个令牌桶算法的限流器：

```java
public class TokenBucketRateLimiter {
    private final int capacity;        // 桶容量
    private final int refillRate;      // 每秒补充的令牌数
    private final Semaphore tokens;
    private final ScheduledExecutorService scheduler;

    public TokenBucketRateLimiter(int capacity, int refillRate) {
        // 初始化
    }

    public boolean tryAcquire() {
        // 尝试获取一个令牌
    }

    public boolean tryAcquire(int permits) {
        // 尝试获取多个令牌
    }

    public void acquire() throws InterruptedException {
        // 阻塞获取
    }

    private void refill() {
        // 定期补充令牌
    }
}
```

---

### 题目 4.6 ⭐⭐⭐ 复杂
**分布式限流器**

基于Redis实现一个分布式限流器：

```java
public class DistributedRateLimiter {
    private final String key;
    private final int maxRequests;
    private final long windowSizeMs;
    private final RedisClient redis;

    public boolean tryAcquire() {
        // 使用Redis的INCR + EXPIRE实现
        // 或使用Lua脚本保证原子性
    }

    // Lua脚本实现
    private static final String LUA_SCRIPT = """
        local key = KEYS[1]
        local limit = tonumber(ARGV[1])
        local window = tonumber(ARGV[2])
        -- 实现限流逻辑
    """;
}
```

---

### 题目 4.7 ⭐⭐⭐ 复杂
**带优先级的资源池**

实现一个支持优先级的资源获取池：

```java
public class PriorityResourcePool<T> {

    public T acquire(int priority) throws InterruptedException {
        // 高优先级的请求优先获取资源
    }

    public T tryAcquire(int priority, long timeout, TimeUnit unit)
            throws InterruptedException {
        // 带超时的优先级获取
    }

    public void release(T resource) {
        // 释放资源并唤醒最高优先级的等待者
    }
}
```

---

### 题目 4.8 ⭐⭐⭐⭐ 困难
**自适应限流器**

实现一个能够根据系统负载自动调整限流阈值的限流器：

```java
public class AdaptiveRateLimiter {
    private volatile int currentLimit;
    private final int minLimit;
    private final int maxLimit;

    // 监控指标
    private final AtomicLong successCount = new AtomicLong();
    private final AtomicLong failureCount = new AtomicLong();
    private final AtomicLong totalLatency = new AtomicLong();

    public boolean tryAcquire() {
        // 基于当前限制判断
    }

    public void recordSuccess(long latencyMs) {
        // 记录成功，如果延迟低可以提高限制
    }

    public void recordFailure() {
        // 记录失败，降低限制
    }

    // 定期调整限制
    private void adjustLimit() {
        // 基于成功率和延迟调整
        // 使用类似TCP拥塞控制的算法
    }
}
```

---

### 题目 4.9 ⭐⭐⭐⭐ 困难
**多维度限流**

实现一个支持多维度限流的限流器（如：用户维度 + 接口维度 + 全局维度）：

```java
public class MultiDimensionRateLimiter {

    public boolean tryAcquire(String userId, String apiPath) {
        // 检查用户级别限流
        // 检查接口级别限流
        // 检查全局级别限流
        // 全部通过才允许
    }

    // 配置不同维度的限流规则
    public void setUserLimit(String userId, int limit) { }
    public void setApiLimit(String apiPath, int limit) { }
    public void setGlobalLimit(int limit) { }
}
```

---

### 题目 4.10 ⭐⭐⭐⭐⭐ 地狱级
**实现一个带预热的限流器**

实现类似Guava RateLimiter的SmoothWarmingUp限流器：

```java
public class WarmingUpRateLimiter {
    private final double permitsPerSecond;
    private final long warmupPeriodMicros;

    // 冷启动时QPS较低，逐渐提升到稳定值
    // 使用梯形积分计算等待时间

    public double acquire() {
        // 返回等待的秒数
    }

    public double acquire(int permits) {
        // 获取多个许可
    }

    public boolean tryAcquire(long timeout, TimeUnit unit) {
        // 带超时的尝试获取
    }

    // 核心：计算获取permits个许可需要等待的时间
    private long reserveAndGetWaitLength(int permits, long nowMicros) {
        // 考虑预热期的梯形积分
    }
}
```

**要求**：
1. 冷启动时（长时间未使用后），QPS从较低值逐渐提升
2. 稳定期保持配置的QPS
3. 支持突发流量（有一定的许可积累）
4. 画出预热期的QPS变化曲线

---

## 场景五：生产者-消费者

### 题目 5.1 ⭐ 简单
**ArrayBlockingQueue 基础使用**

使用 `ArrayBlockingQueue` 实现一个简单的生产者-消费者：

```java
public class ProducerConsumer {
    private final BlockingQueue<String> queue = new ArrayBlockingQueue<>(10);

    public void produce(String item) throws InterruptedException {
        queue.put(item); // 队列满则阻塞
    }

    public String consume() throws InterruptedException {
        return queue.take(); // 队列空则阻塞
    }
}
```

编写测试：3个生产者，2个消费者，验证数据不丢失。

---

### 题目 5.2 ⭐ 简单
**LinkedBlockingQueue vs ArrayBlockingQueue**

对比两种队列的性能和适用场景：

```java
public class QueueComparison {

    public void testArrayBlockingQueue() {
        // 测试ArrayBlockingQueue
        // 记录吞吐量
    }

    public void testLinkedBlockingQueue() {
        // 测试LinkedBlockingQueue
        // 记录吞吐量
    }
}
```

**思考题**：
1. 为什么 `LinkedBlockingQueue` 在某些场景下性能更好？（提示：锁的粒度）
2. 什么场景下应该选择 `ArrayBlockingQueue`？

---

### 题目 5.3 ⭐ 简单
**PriorityBlockingQueue 使用**

使用 `PriorityBlockingQueue` 实现一个任务优先级处理系统：

```java
public class PriorityTaskProcessor {
    private final PriorityBlockingQueue<Task> queue =
        new PriorityBlockingQueue<>();

    static class Task implements Comparable<Task> {
        int priority;
        String name;

        @Override
        public int compareTo(Task other) {
            // 优先级高的先执行
        }
    }

    public void submit(Task task) {
        queue.put(task);
    }

    public void process() throws InterruptedException {
        while (true) {
            Task task = queue.take();
            // 处理任务
        }
    }
}
```

---

### 题目 5.4 ⭐⭐ 中等
**DelayQueue 实现延迟任务**

使用 `DelayQueue` 实现一个延迟任务调度器：

```java
public class DelayedTaskScheduler {
    private final DelayQueue<DelayedTask> queue = new DelayQueue<>();

    static class DelayedTask implements Delayed {
        private final long executeTime;
        private final Runnable task;

        @Override
        public long getDelay(TimeUnit unit) {
            // 返回剩余延迟时间
        }

        @Override
        public int compareTo(Delayed other) {
            // 按执行时间排序
        }
    }

    public void schedule(Runnable task, long delay, TimeUnit unit) {
        // 添加延迟任务
    }

    public void start() {
        // 启动调度线程
        while (true) {
            DelayedTask task = queue.take();
            task.task.run();
        }
    }
}
```

---

### 题目 5.5 ⭐⭐ 中等
**SynchronousQueue 直接传递**

使用 `SynchronousQueue` 实现一个严格的一对一传递系统：

```java
public class DirectHandoff {
    private final SynchronousQueue<String> queue = new SynchronousQueue<>();

    // 生产者必须等到消费者来取
    public void produce(String item) throws InterruptedException {
        queue.put(item);
    }

    // 消费者必须等到生产者放入
    public String consume() throws InterruptedException {
        return queue.take();
    }
}
```

**思考题**：
1. `SynchronousQueue` 的容量是多少？
2. 线程池中的 `CachedThreadPool` 为什么使用 `SynchronousQueue`？

---

### 题目 5.6 ⭐⭐⭐ 复杂
**LinkedTransferQueue 高级用法**

使用 `LinkedTransferQueue` 实现一个支持"等待消费者"的生产者：

```java
public class TransferExample {
    private final TransferQueue<String> queue = new LinkedTransferQueue<>();

    // 普通生产（不等待消费者）
    public void offer(String item) {
        queue.offer(item);
    }

    // 等待消费者取走（同步传递）
    public void transfer(String item) throws InterruptedException {
        queue.transfer(item); // 阻塞直到有消费者取走
    }

    // 尝试直接传递给等待的消费者
    public boolean tryTransfer(String item) {
        return queue.tryTransfer(item); // 如果有消费者等待，直接给它
    }
}
```

**应用场景**：实现一个消息确认机制，生产者等待消费者确认收到。

---

### 题目 5.7 ⭐⭐⭐ 复杂
**多生产者多消费者模式**

实现一个支持多生产者多消费者的任务处理系统，带有优雅关闭功能：

```java
public class WorkerPool {
    private final BlockingQueue<Runnable> taskQueue;
    private final List<Thread> workers;
    private volatile boolean shutdown = false;

    public WorkerPool(int workerCount, int queueCapacity) {
        // 初始化
    }

    public void submit(Runnable task) {
        if (shutdown) throw new RejectedExecutionException();
        taskQueue.put(task);
    }

    public void shutdown() {
        // 不再接受新任务
        // 等待队列中的任务处理完
    }

    public void shutdownNow() {
        // 立即停止
        // 返回未处理的任务
    }
}
```

---

### 题目 5.8 ⭐⭐⭐⭐ 困难
**实现一个批量消费的消费者**

实现一个能够批量获取数据的消费者，提高处理效率：

```java
public class BatchConsumer<T> {
    private final BlockingQueue<T> queue;
    private final int batchSize;
    private final long maxWaitMs;

    // 批量获取：尽量获取batchSize个元素，但最多等待maxWaitMs
    public List<T> takeBatch() throws InterruptedException {
        List<T> batch = new ArrayList<>();

        // 1. 至少获取一个（阻塞）
        // 2. 尝试获取更多（非阻塞或短暂等待）
        // 3. 达到batchSize或超时则返回

        return batch;
    }
}
```

---

### 题目 5.9 ⭐⭐⭐⭐ 困难
**实现一个带背压的生产者-消费者**

实现背压（Backpressure）机制，当消费者处理不过来时，生产者自动降速：

```java
public class BackpressureQueue<T> {
    private final BlockingQueue<T> queue;
    private final AtomicInteger pendingCount = new AtomicInteger();
    private final int highWaterMark;
    private final int lowWaterMark;

    public void produce(T item) throws InterruptedException {
        // 如果积压过多，等待
        while (pendingCount.get() > highWaterMark) {
            waitForDrain();
        }
        queue.put(item);
        pendingCount.incrementAndGet();
    }

    public T consume() throws InterruptedException {
        T item = queue.take();
        int count = pendingCount.decrementAndGet();
        if (count <= lowWaterMark) {
            notifyProducers();
        }
        return item;
    }
}
```

---

### 题目 5.10 ⭐⭐⭐⭐⭐ 地狱级
**实现一个无锁的MPSC队列**

实现一个多生产者单消费者（MPSC）的无锁队列：

```java
public class MpscQueue<E> {

    private static class Node<E> {
        volatile E value;
        volatile Node<E> next;
    }

    private volatile Node<E> head;
    private volatile Node<E> tail;

    public MpscQueue() {
        Node<E> dummy = new Node<>();
        head = tail = dummy;
    }

    // 多个生产者可以并发调用
    public void offer(E item) {
        // 使用CAS实现无锁入队
    }

    // 只有一个消费者调用
    public E poll() {
        // 单消费者可以简化逻辑
    }

    public E peek() {
        // 查看但不移除
    }
}
```

**要求**：
1. 多生产者并发安全
2. 不使用锁
3. 处理好ABA问题
4. 高性能（减少CAS竞争）

---

## 场景六：缓存/共享Map

### 题目 6.1 ⭐ 简单
**ConcurrentHashMap 基础使用**

使用 `ConcurrentHashMap` 实现一个简单的词频统计：

```java
public class WordCounter {
    private final ConcurrentHashMap<String, AtomicInteger> wordCounts =
        new ConcurrentHashMap<>();

    public void count(String word) {
        // 统计词频
    }

    public int getCount(String word) {
        // 获取词频
    }
}
```

---

### 题目 6.2 ⭐ 简单
**computeIfAbsent 使用**

使用 `ConcurrentHashMap.computeIfAbsent` 实现一个懒加载缓存：

```java
public class LazyCache<K, V> {
    private final ConcurrentHashMap<K, V> cache = new ConcurrentHashMap<>();
    private final Function<K, V> loader;

    public LazyCache(Function<K, V> loader) {
        this.loader = loader;
    }

    public V get(K key) {
        return cache.computeIfAbsent(key, loader);
    }
}
```

**思考题**：`computeIfAbsent` 的计算函数中能否调用同一个Map的其他方法？会发生什么？

---

### 题目 6.3 ⭐ 简单
**ConcurrentSkipListMap 使用**

使用 `ConcurrentSkipListMap` 实现一个有序的排行榜：

```java
public class Leaderboard {
    // 分数 -> 用户列表（相同分数可能有多个用户）
    private final ConcurrentSkipListMap<Integer, Set<String>> scoreBoard =
        new ConcurrentSkipListMap<>(Collections.reverseOrder());

    public void updateScore(String userId, int score) {
        // 更新用户分数
    }

    public List<String> getTopN(int n) {
        // 获取前N名
    }
}
```

---

### 题目 6.4 ⭐⭐ 中等
**ConcurrentHashMap 复合操作**

使用 `ConcurrentHashMap` 的原子复合操作实现以下功能：

```java
public class AtomicMapOperations {
    private final ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();

    // 原子地增加值
    public int addAndGet(String key, int delta) {
        return map.merge(key, delta, Integer::sum);
    }

    // 原子地设置最大值
    public int setMax(String key, int value) {
        return map.merge(key, value, Math::max);
    }

    // 原子地追加到列表（值是List）
    public void appendToList(String key, String item) {
        // 使用compute
    }
}
```

---

### 题目 6.5 ⭐⭐ 中等
**并发Map的遍历**

演示 `ConcurrentHashMap` 遍历时的弱一致性：

```java
public class ConcurrentMapIteration {

    public void demonstrateWeakConsistency() {
        ConcurrentHashMap<Integer, String> map = new ConcurrentHashMap<>();
        // 初始化数据

        // 启动一个线程不断修改map

        // 另一个线程遍历map
        // 观察遍历过程中是否能看到新增/删除的元素
    }
}
```

**思考题**：
1. 遍历过程中修改Map会抛出 `ConcurrentModificationException` 吗？
2. 遍历能保证看到开始遍历时的所有元素吗？

---

### 题目 6.6 ⭐⭐⭐ 复杂
**实现一个LRU缓存**

基于 `ConcurrentHashMap` 和 `ConcurrentLinkedDeque` 实现一个线程安全的LRU缓存：

```java
public class ConcurrentLRUCache<K, V> {
    private final int capacity;
    private final ConcurrentHashMap<K, V> cache;
    private final ConcurrentLinkedDeque<K> accessOrder;

    public ConcurrentLRUCache(int capacity) {
        this.capacity = capacity;
        this.cache = new ConcurrentHashMap<>();
        this.accessOrder = new ConcurrentLinkedDeque<>();
    }

    public V get(K key) {
        // 获取并更新访问顺序
    }

    public void put(K key, V value) {
        // 放入并维护LRU顺序
        // 如果超过容量，淘汰最久未访问的
    }
}
```

**挑战**：如何保证get和put操作的原子性？

---

### 题目 6.7 ⭐⭐⭐ 复杂
**分布式一致性Hash**

使用 `ConcurrentSkipListMap` 实现一个一致性Hash环：

```java
public class ConsistentHash<T> {
    private final ConcurrentSkipListMap<Long, T> ring = new ConcurrentSkipListMap<>();
    private final int virtualNodes;

    public ConsistentHash(int virtualNodes) {
        this.virtualNodes = virtualNodes;
    }

    public void addNode(T node) {
        // 添加节点及其虚拟节点
    }

    public void removeNode(T node) {
        // 移除节点
    }

    public T getNode(String key) {
        // 根据key找到对应的节点
    }

    private long hash(String key) {
        // Hash函数
    }
}
```

---

### 题目 6.8 ⭐⭐⭐⭐ 困难
**ConcurrentHashMap 的并行操作**

使用 `ConcurrentHashMap` 的并行批量操作：

```java
public class ParallelMapOperations {

    // 并行遍历
    public void parallelForEach(ConcurrentHashMap<String, Integer> map) {
        map.forEach(4, // parallelism threshold
            (k, v) -> System.out.println(k + "=" + v));
    }

    // 并行搜索
    public String parallelSearch(ConcurrentHashMap<String, Integer> map, int target) {
        return map.search(4, (k, v) -> v == target ? k : null);
    }

    // 并行归约
    public int parallelReduce(ConcurrentHashMap<String, Integer> map) {
        return map.reduceValues(4, Integer::sum);
    }

    // 并行转换和归约
    public int parallelMapReduce(ConcurrentHashMap<String, Integer> map) {
        return map.reduceValues(4,
            v -> v * 2,  // transformer
            Integer::sum // reducer
        );
    }
}
```

---

### 题目 6.9 ⭐⭐⭐⭐ 困难
**实现一个支持过期的ConcurrentMap**

实现一个条目会自动过期的ConcurrentMap：

```java
public class ExpiringConcurrentMap<K, V> {

    public void put(K key, V value, long ttl, TimeUnit unit) {
        // 带过期时间的put
    }

    public V get(K key) {
        // 获取，如果已过期返回null并删除
    }

    public V getOrDefault(K key, V defaultValue) {
        // 获取或返回默认值
    }

    // 后台清理任务
    private void startCleaner() {
        // 定期清理过期条目
    }
}
```

**要求**：
1. 高并发安全
2. 过期条目及时清理（不能内存泄漏）
3. 读取性能要好（大部分是读）

---

### 题目 6.10 ⭐⭐⭐⭐⭐ 地狱级
**实现ConcurrentHashMap的分段锁版本**

实现一个简化版的JDK7风格的ConcurrentHashMap（分段锁）：

```java
public class SegmentedHashMap<K, V> {
    private static final int SEGMENT_COUNT = 16;

    private final Segment<K, V>[] segments;

    static class Segment<K, V> extends ReentrantLock {
        volatile HashEntry<K, V>[] table;
        int count;

        V get(Object key, int hash) {
            // 不需要加锁的读
        }

        V put(K key, int hash, V value, boolean onlyIfAbsent) {
            // 需要加锁的写
        }
    }

    static class HashEntry<K, V> {
        final int hash;
        final K key;
        volatile V value;
        volatile HashEntry<K, V> next;
    }

    public V get(Object key) {
        // 定位segment，然后读取
    }

    public V put(K key, V value) {
        // 定位segment，然后写入
    }

    public int size() {
        // 计算总大小（需要特殊处理）
    }
}
```

**要求**：
1. 读操作不加锁（利用volatile）
2. 写操作只锁定一个Segment
3. size() 的实现要考虑一致性
4. 理解为什么JDK8改用CAS+synchronized

---

## 场景七：异步任务编排

### 题目 7.1 ⭐ 简单
**CompletableFuture 基础使用**

使用 `CompletableFuture` 实现异步任务：

```java
public class AsyncBasics {

    public CompletableFuture<String> fetchUserAsync(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            // 模拟网络请求
            return "User: " + userId;
        });
    }

    public void chainedOperations() {
        CompletableFuture.supplyAsync(() -> "Hello")
            .thenApply(s -> s + " World")
            .thenAccept(System.out::println);
    }
}
```

---

### 题目 7.2 ⭐ 简单
**异常处理**

使用 `CompletableFuture` 的异常处理机制：

```java
public class AsyncExceptionHandling {

    public CompletableFuture<String> fetchWithFallback(String url) {
        return CompletableFuture.supplyAsync(() -> {
                // 可能抛出异常
                return fetchFromUrl(url);
            })
            .exceptionally(ex -> {
                // 异常时的默认值
                return "Default Value";
            });
    }

    public CompletableFuture<String> fetchWithRecovery(String url) {
        return CompletableFuture.supplyAsync(() -> fetchFromUrl(url))
            .handle((result, ex) -> {
                if (ex != null) {
                    // 处理异常
                    return "Error: " + ex.getMessage();
                }
                return result;
            });
    }
}
```

---

### 题目 7.3 ⭐ 简单
**组合多个Future**

使用 `thenCombine` 和 `allOf` 组合多个异步操作：

```java
public class CombiningFutures {

    // 两个异步操作的结果合并
    public CompletableFuture<String> fetchUserAndOrders(String userId) {
        CompletableFuture<User> userFuture = fetchUser(userId);
        CompletableFuture<List<Order>> ordersFuture = fetchOrders(userId);

        return userFuture.thenCombine(ordersFuture, (user, orders) ->
            user.getName() + " has " + orders.size() + " orders"
        );
    }

    // 等待所有完成
    public CompletableFuture<Void> fetchAll(List<String> urls) {
        List<CompletableFuture<String>> futures = urls.stream()
            .map(this::fetchFromUrl)
            .collect(Collectors.toList());

        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]));
    }
}
```

---

### 题目 7.4 ⭐⭐ 中等
**anyOf 实现超时或降级**

使用 `anyOf` 实现"最快返回"或超时机制：

```java
public class FastestWins {

    // 从多个源获取数据，返回最快的
    public CompletableFuture<String> fetchFromFastestSource(String key) {
        CompletableFuture<String> source1 = fetchFromSource1(key);
        CompletableFuture<String> source2 = fetchFromSource2(key);
        CompletableFuture<String> source3 = fetchFromSource3(key);

        return CompletableFuture.anyOf(source1, source2, source3)
            .thenApply(result -> (String) result);
    }

    // 带超时的请求
    public CompletableFuture<String> fetchWithTimeout(String url, long timeoutMs) {
        CompletableFuture<String> dataFuture = fetchFromUrl(url);
        CompletableFuture<String> timeoutFuture = timeoutAfter(timeoutMs);

        return CompletableFuture.anyOf(dataFuture, timeoutFuture)
            .thenApply(result -> (String) result);
    }

    private CompletableFuture<String> timeoutAfter(long ms) {
        // 实现超时Future
    }
}
```

---

### 题目 7.5 ⭐⭐ 中等
**thenCompose 实现链式异步**

使用 `thenCompose` 实现依赖的异步操作链：

```java
public class ComposingFutures {

    // 获取用户 → 获取用户的订单 → 获取订单的详情
    public CompletableFuture<OrderDetails> getOrderDetails(String userId) {
        return fetchUser(userId)
            .thenCompose(user -> fetchLatestOrder(user.getId()))
            .thenCompose(order -> fetchOrderDetails(order.getId()));
    }

    // 对比thenApply和thenCompose的区别
    public void compareApplyAndCompose() {
        // thenApply: 同步转换
        CompletableFuture<CompletableFuture<String>> nested =
            CompletableFuture.supplyAsync(() -> "id")
                .thenApply(id -> fetchData(id)); // 返回嵌套的Future

        // thenCompose: 异步链接，自动展平
        CompletableFuture<String> flat =
            CompletableFuture.supplyAsync(() -> "id")
                .thenCompose(id -> fetchData(id)); // 返回展平的Future
    }
}
```

---

### 题目 7.6 ⭐⭐⭐ 复杂
**实现重试机制**

使用 `CompletableFuture` 实现带重试的异步操作：

```java
public class RetryableAsync {

    public <T> CompletableFuture<T> retryAsync(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long delayMs) {

        return action.get()
            .thenApply(CompletableFuture::completedFuture)
            .exceptionally(ex -> {
                if (maxRetries > 0) {
                    // 延迟后重试
                    return delay(delayMs)
                        .thenCompose(v -> retryAsync(action, maxRetries - 1, delayMs));
                }
                throw new CompletionException(ex);
            })
            .thenCompose(Function.identity());
    }

    // 指数退避重试
    public <T> CompletableFuture<T> retryWithBackoff(
            Supplier<CompletableFuture<T>> action,
            int maxRetries) {
        // 实现指数退避
    }
}
```

---

### 题目 7.7 ⭐⭐⭐ 复杂
**ExecutorCompletionService 按完成顺序处理**

使用 `ExecutorCompletionService` 按任务完成顺序处理结果：

```java
public class CompletionOrderProcessing {
    private final ExecutorService executor = Executors.newFixedThreadPool(10);

    public void processInCompletionOrder(List<Callable<String>> tasks)
            throws InterruptedException {

        CompletionService<String> completionService =
            new ExecutorCompletionService<>(executor);

        // 提交所有任务
        for (Callable<String> task : tasks) {
            completionService.submit(task);
        }

        // 按完成顺序处理
        for (int i = 0; i < tasks.size(); i++) {
            Future<String> future = completionService.take();
            try {
                String result = future.get();
                processResult(result);
            } catch (ExecutionException e) {
                handleError(e);
            }
        }
    }
}
```

---

### 题目 7.8 ⭐⭐⭐⭐ 困难
**实现一个异步任务编排器**

实现一个支持DAG（有向无环图）依赖的任务编排器：

```java
public class TaskOrchestrator {

    // 任务定义
    public static class Task {
        String name;
        Supplier<CompletableFuture<?>> action;
        List<String> dependencies; // 依赖的任务名
    }

    private final Map<String, Task> tasks = new ConcurrentHashMap<>();
    private final Map<String, CompletableFuture<?>> futures = new ConcurrentHashMap<>();

    public void addTask(Task task) {
        tasks.put(task.name, task);
    }

    public CompletableFuture<Void> execute() {
        // 1. 构建依赖图
        // 2. 拓扑排序或并行执行无依赖的任务
        // 3. 任务完成后触发依赖它的任务
    }
}
```

---

### 题目 7.9 ⭐⭐⭐⭐ 困难
**实现带取消功能的异步操作**

实现可以取消的 `CompletableFuture` 链：

```java
public class CancellableAsync {

    public static class CancellableTask<T> {
        private final CompletableFuture<T> future;
        private final AtomicBoolean cancelled = new AtomicBoolean();

        public CompletableFuture<T> getFuture() {
            return future;
        }

        public void cancel() {
            // 设置取消标志
            // 中断正在执行的任务
            // 取消后续任务
        }

        public boolean isCancelled() {
            return cancelled.get();
        }
    }

    public <T> CancellableTask<T> submitCancellable(Callable<T> task) {
        // 创建可取消的任务
    }
}
```

---

### 题目 7.10 ⭐⭐⭐⭐⭐ 地狱级
**实现一个响应式流处理器**

实现一个简化版的响应式流（类似RxJava/Reactor）：

```java
public class SimpleReactiveStream<T> {

    // 创建流
    public static <T> SimpleReactiveStream<T> just(T... items) {
        // 实现
    }

    public static <T> SimpleReactiveStream<T> fromFuture(CompletableFuture<T> future) {
        // 实现
    }

    // 转换操作
    public <R> SimpleReactiveStream<R> map(Function<T, R> mapper) {
        // 实现
    }

    public <R> SimpleReactiveStream<R> flatMap(Function<T, SimpleReactiveStream<R>> mapper) {
        // 实现
    }

    public SimpleReactiveStream<T> filter(Predicate<T> predicate) {
        // 实现
    }

    // 组合操作
    public SimpleReactiveStream<T> merge(SimpleReactiveStream<T> other) {
        // 实现
    }

    public <R> SimpleReactiveStream<R> zip(SimpleReactiveStream<? extends R> other,
            BiFunction<T, R, R> combiner) {
        // 实现
    }

    // 终结操作
    public CompletableFuture<List<T>> toList() {
        // 实现
    }

    public void subscribe(Consumer<T> onNext, Consumer<Throwable> onError,
            Runnable onComplete) {
        // 实现订阅
    }

    // 背压支持
    public SimpleReactiveStream<T> onBackpressureBuffer(int capacity) {
        // 实现
    }

    public SimpleReactiveStream<T> onBackpressureDrop() {
        // 实现
    }
}
```

**要求**：
1. 支持异步执行
2. 支持链式调用
3. 正确处理异常
4. 实现背压机制
5. 支持取消订阅

---

## 附录：答案提示

每道题的详细答案和解析可以通过以下方式获取：
1. 尝试自己实现后，对照JDK源码
2. 参考《Java并发编程实战》
3. 阅读Doug Lea的论文

**学习建议**：
- 简单题：确保能独立完成
- 中等题：理解原理后实现
- 复杂题：参考资料后实现
- 困难题：深入源码学习
- 地狱级：研究论文和生产级实现

---

> 生成时间: 2024
>
> 配套JDK版本: JDK 8+
