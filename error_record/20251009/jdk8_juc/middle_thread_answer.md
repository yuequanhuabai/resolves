# JUC 练习题参考答案（复杂难度）

> 本文档包含 ⭐⭐⭐ 复杂难度题目的参考答案
> 复杂难度：实际场景应用

---

## 场景一：计数器/累加器

### 题目 1.6 ⭐⭐⭐ 自定义累加器

```java
import java.util.concurrent.atomic.LongAccumulator;
import java.util.concurrent.atomic.LongAdder;

public class CustomAccumulators {

    // 1. 最大值追踪器
    private final LongAccumulator maxTracker = new LongAccumulator(
        Math::max,      // 累加函数：取两者最大值
        Long.MIN_VALUE  // 初始值：最小的long
    );

    // 2. 最小值追踪器
    private final LongAccumulator minTracker = new LongAccumulator(
        Math::min,
        Long.MAX_VALUE
    );

    // 3. 乘积累加器（注意：初始值必须是1，不是0）
    private final LongAccumulator productAccumulator = new LongAccumulator(
        (left, right) -> {
            // 溢出检测
            long result = left * right;
            if (left != 0 && result / left != right) {
                return Long.MAX_VALUE; // 溢出时返回最大值
            }
            return result;
        },
        1L  // 乘法的单位元是1
    );

    // 4. 平均值计算器（需要追踪sum和count）
    private final LongAdder sum = new LongAdder();
    private final LongAdder count = new LongAdder();

    public void recordForMax(long value) {
        maxTracker.accumulate(value);
    }

    public void recordForMin(long value) {
        minTracker.accumulate(value);
    }

    public void recordForProduct(long value) {
        productAccumulator.accumulate(value);
    }

    public void recordForAverage(long value) {
        sum.add(value);
        count.increment();
    }

    public long getMax() {
        return maxTracker.get();
    }

    public long getMin() {
        return minTracker.get();
    }

    public long getProduct() {
        return productAccumulator.get();
    }

    public double getAverage() {
        long totalCount = count.sum();
        if (totalCount == 0) return 0.0;
        return (double) sum.sum() / totalCount;
    }

    public void reset() {
        maxTracker.reset();
        minTracker.reset();
        productAccumulator.reset();
        sum.reset();
        count.reset();
    }

    public static void main(String[] args) throws InterruptedException {
        CustomAccumulators accumulators = new CustomAccumulators();
        int threadCount = 10;
        Thread[] threads = new Thread[threadCount];

        for (int i = 0; i < threadCount; i++) {
            int threadId = i;
            threads[i] = new Thread(() -> {
                for (int j = 1; j <= 100; j++) {
                    long value = threadId * 100 + j;
                    accumulators.recordForMax(value);
                    accumulators.recordForMin(value);
                    accumulators.recordForAverage(value);
                }
                // 乘积单独测试（避免溢出）
                for (int j = 1; j <= 5; j++) {
                    accumulators.recordForProduct(j);
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();

        System.out.println("最大值: " + accumulators.getMax());     // 999
        System.out.println("最小值: " + accumulators.getMin());     // 1
        System.out.println("平均值: " + accumulators.getAverage()); // 500
        System.out.println("乘积: " + accumulators.getProduct());   // 120^10 会溢出
    }
}
```

---

### 题目 1.7 ⭐⭐⭐ 字段原子更新器

```java
import java.util.concurrent.atomic.AtomicIntegerFieldUpdater;

// 遗留类，假设不能修改
class User {
    volatile int score;  // 必须是volatile！
    String name;

    public User(String name, int score) {
        this.name = name;
        this.score = score;
    }

    @Override
    public String toString() {
        return "User{name='" + name + "', score=" + score + "}";
    }
}

public class UserScoreUpdater {
    // 创建字段更新器
    // 参数：目标类，字段类型，字段名
    private static final AtomicIntegerFieldUpdater<User> SCORE_UPDATER =
        AtomicIntegerFieldUpdater.newUpdater(User.class, "score");

    // 原子性地增加分数
    public static int addScore(User user, int delta) {
        return SCORE_UPDATER.addAndGet(user, delta);
    }

    // CAS更新分数
    public static boolean compareAndSetScore(User user, int expect, int update) {
        return SCORE_UPDATER.compareAndSet(user, expect, update);
    }

    // 获取并增加
    public static int getAndAddScore(User user, int delta) {
        return SCORE_UPDATER.getAndAdd(user, delta);
    }

    // 获取当前分数
    public static int getScore(User user) {
        return SCORE_UPDATER.get(user);
    }

    // 设置分数
    public static void setScore(User user, int newScore) {
        SCORE_UPDATER.set(user, newScore);
    }

    // 原子性地更新（使用函数）
    public static int updateScore(User user, java.util.function.IntUnaryOperator updateFunction) {
        return SCORE_UPDATER.updateAndGet(user, updateFunction);
    }

    public static void main(String[] args) throws InterruptedException {
        User user = new User("Alice", 100);
        System.out.println("初始: " + user);

        // 多线程并发增加分数
        Thread[] threads = new Thread[10];
        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    addScore(user, 1);
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();
        System.out.println("并发增加后: " + user); // score应该是10100

        // 测试CAS
        boolean success = compareAndSetScore(user, 10100, 0);
        System.out.println("CAS重置: " + success + ", " + user);

        // 使用函数更新
        updateScore(user, score -> score + 50);
        System.out.println("函数更新后: " + user);
    }
}

/*
 * 附加问题答案：
 *
 * 为什么score字段必须是volatile的？
 *
 * 1. AtomicIntegerFieldUpdater内部使用Unsafe的CAS操作
 * 2. CAS需要保证内存可见性
 * 3. volatile保证了：
 *    - 写入对其他线程立即可见
 *    - 防止指令重排序
 *
 * 如果不是volatile会怎样？
 * - 创建Updater时会抛出 IllegalArgumentException
 * - 错误信息: "Must be volatile type"
 *
 * 其他限制：
 * - 字段不能是static的
 * - 字段不能是private的（如果Updater在其他类中）
 * - 字段必须是int类型（对于AtomicIntegerFieldUpdater）
 */
```

---

## 场景二：读多写少

### 题目 2.6 ⭐⭐⭐ 带过期时间的缓存

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.locks.*;

public class ExpiringCache<K, V> {
    private final Map<K, CacheEntry<V>> cache = new HashMap<>();
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final ReadLock readLock = rwLock.readLock();
    private final WriteLock writeLock = rwLock.writeLock();
    private final ScheduledExecutorService cleaner =
        Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "cache-cleaner");
            t.setDaemon(true);
            return t;
        });

    static class CacheEntry<V> {
        final V value;
        final long expireTime;

        CacheEntry(V value, long expireTime) {
            this.value = value;
            this.expireTime = expireTime;
        }

        boolean isExpired() {
            return System.currentTimeMillis() > expireTime;
        }
    }

    public ExpiringCache() {
        // 每秒清理一次过期条目
        cleaner.scheduleAtFixedRate(this::cleanExpired, 1, 1, TimeUnit.SECONDS);
    }

    public V get(K key) {
        readLock.lock();
        try {
            CacheEntry<V> entry = cache.get(key);
            if (entry == null) {
                return null;
            }
            // 读取时发现过期，返回null（延迟删除）
            if (entry.isExpired()) {
                // 注意：这里不能删除，因为只有读锁
                // 让清理线程去删除，或者下次写入时删除
                return null;
            }
            return entry.value;
        } finally {
            readLock.unlock();
        }
    }

    public void put(K key, V value, long ttlMillis) {
        long expireTime = System.currentTimeMillis() + ttlMillis;
        writeLock.lock();
        try {
            cache.put(key, new CacheEntry<>(value, expireTime));
        } finally {
            writeLock.unlock();
        }
    }

    public V remove(K key) {
        writeLock.lock();
        try {
            CacheEntry<V> entry = cache.remove(key);
            return entry != null ? entry.value : null;
        } finally {
            writeLock.unlock();
        }
    }

    // 后台清理过期条目
    private void cleanExpired() {
        // 先用读锁快速收集过期的key
        List<K> expiredKeys = new ArrayList<>();

        readLock.lock();
        try {
            for (Map.Entry<K, CacheEntry<V>> entry : cache.entrySet()) {
                if (entry.getValue().isExpired()) {
                    expiredKeys.add(entry.getKey());
                }
            }
        } finally {
            readLock.unlock();
        }

        // 如果有过期的key，用写锁删除
        if (!expiredKeys.isEmpty()) {
            writeLock.lock();
            try {
                for (K key : expiredKeys) {
                    CacheEntry<V> entry = cache.get(key);
                    // 再次检查是否过期（可能已被更新）
                    if (entry != null && entry.isExpired()) {
                        cache.remove(key);
                    }
                }
            } finally {
                writeLock.unlock();
            }
            System.out.println("[Cleaner] 清理了 " + expiredKeys.size() + " 个过期条目");
        }
    }

    public int size() {
        readLock.lock();
        try {
            return cache.size();
        } finally {
            readLock.unlock();
        }
    }

    public void shutdown() {
        cleaner.shutdown();
    }

    public static void main(String[] args) throws InterruptedException {
        ExpiringCache<String, String> cache = new ExpiringCache<>();

        // 放入不同过期时间的数据
        cache.put("key1", "value1", 1000);  // 1秒过期
        cache.put("key2", "value2", 3000);  // 3秒过期
        cache.put("key3", "value3", 5000);  // 5秒过期

        System.out.println("初始大小: " + cache.size());
        System.out.println("key1: " + cache.get("key1"));
        System.out.println("key2: " + cache.get("key2"));

        Thread.sleep(1500);
        System.out.println("\n1.5秒后:");
        System.out.println("key1: " + cache.get("key1")); // null（已过期）
        System.out.println("key2: " + cache.get("key2")); // value2

        Thread.sleep(2000);
        System.out.println("\n3.5秒后:");
        System.out.println("key2: " + cache.get("key2")); // null（已过期）
        System.out.println("key3: " + cache.get("key3")); // value3
        System.out.println("当前大小: " + cache.size());

        cache.shutdown();
    }
}
```

---

### 题目 2.7 ⭐⭐⭐ 读写分离的计数器

```java
import java.util.concurrent.locks.*;

/**
 * 支持精确读取的高并发计数器
 * 写入时只锁一个分段，读取时锁定所有分段获取一致性快照
 */
public class PreciseCounter {
    private static final int SEGMENT_COUNT = 16;

    private final long[] counts = new long[SEGMENT_COUNT];
    private final ReentrantReadWriteLock[] locks = new ReentrantReadWriteLock[SEGMENT_COUNT];

    public PreciseCounter() {
        for (int i = 0; i < SEGMENT_COUNT; i++) {
            locks[i] = new ReentrantReadWriteLock();
        }
    }

    // 根据线程ID选择分段
    private int getSegmentIndex() {
        return (int) (Thread.currentThread().getId() % SEGMENT_COUNT);
    }

    public void increment() {
        int index = getSegmentIndex();
        locks[index].writeLock().lock();
        try {
            counts[index]++;
        } finally {
            locks[index].writeLock().unlock();
        }
    }

    public void add(long delta) {
        int index = getSegmentIndex();
        locks[index].writeLock().lock();
        try {
            counts[index] += delta;
        } finally {
            locks[index].writeLock().unlock();
        }
    }

    /**
     * 获取精确值 - 需要锁定所有分段
     * 保证返回某一时刻的一致性快照
     */
    public long get() {
        // 按顺序获取所有读锁，避免死锁
        for (int i = 0; i < SEGMENT_COUNT; i++) {
            locks[i].readLock().lock();
        }

        try {
            long total = 0;
            for (int i = 0; i < SEGMENT_COUNT; i++) {
                total += counts[i];
            }
            return total;
        } finally {
            // 逆序释放锁
            for (int i = SEGMENT_COUNT - 1; i >= 0; i--) {
                locks[i].readLock().unlock();
            }
        }
    }

    /**
     * 获取近似值 - 不加锁，可能读到不一致的值
     * 性能更好，适合对精度要求不高的场景
     */
    public long getApproximate() {
        long total = 0;
        for (int i = 0; i < SEGMENT_COUNT; i++) {
            total += counts[i];
        }
        return total;
    }

    public static void main(String[] args) throws InterruptedException {
        PreciseCounter counter = new PreciseCounter();
        int threadCount = 10;
        int incrementsPerThread = 100000;
        Thread[] threads = new Thread[threadCount];

        long start = System.currentTimeMillis();

        for (int i = 0; i < threadCount; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < incrementsPerThread; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();

        long elapsed = System.currentTimeMillis() - start;
        long expected = (long) threadCount * incrementsPerThread;

        System.out.println("期望值: " + expected);
        System.out.println("精确值: " + counter.get());
        System.out.println("近似值: " + counter.getApproximate());
        System.out.println("耗时: " + elapsed + "ms");
    }
}

/*
 * 思考题答案：
 *
 * LongAdder.sum() 返回的是精确值吗？
 *
 * 不是！sum()方法不加锁，只是遍历所有Cell求和。
 * 在遍历过程中，其他线程可能正在修改某些Cell，
 * 所以返回的是一个"近似值"或"最终一致性"的值。
 *
 * 本实现如何保证精确？
 * 通过同时持有所有分段的读锁，保证在读取过程中
 * 没有任何写操作能够进行，从而获得一致性快照。
 * 代价是读取时需要获取所有锁，性能较差。
 */
```

---

## 场景三：线程协作/等待

### 题目 3.6 ⭐⭐⭐ CyclicBarrier 实现分阶段计算

```java
import java.util.concurrent.*;

/**
 * 使用CyclicBarrier实现矩阵的分阶段并行计算
 * 阶段1：每个线程计算一行的和
 * 阶段2：汇总所有行的和
 */
public class MatrixCalculator {
    private final int[][] matrix;
    private final int[] rowSums;
    private final int rowCount;
    private volatile int totalSum;
    private final CyclicBarrier barrier;
    private final ExecutorService executor;

    public MatrixCalculator(int[][] matrix) {
        this.matrix = matrix;
        this.rowCount = matrix.length;
        this.rowSums = new int[rowCount];

        // 创建屏障，当所有工作线程到达时执行汇总
        this.barrier = new CyclicBarrier(rowCount, () -> {
            // 这个Runnable在所有线程到达屏障后执行
            // 由最后一个到达的线程执行
            int sum = 0;
            for (int rowSum : rowSums) {
                sum += rowSum;
            }
            totalSum = sum;
            System.out.println("[屏障回调] 汇总完成，总和: " + totalSum);
        });

        this.executor = Executors.newFixedThreadPool(rowCount);
    }

    public int calculate() throws InterruptedException {
        CountDownLatch completionLatch = new CountDownLatch(rowCount);

        for (int i = 0; i < rowCount; i++) {
            final int rowIndex = i;
            executor.submit(() -> {
                try {
                    // 阶段1：计算当前行的和
                    int sum = 0;
                    for (int value : matrix[rowIndex]) {
                        sum += value;
                    }
                    rowSums[rowIndex] = sum;
                    System.out.println("线程 " + rowIndex + " 完成第 " + rowIndex +
                                      " 行计算，行和: " + sum);

                    // 等待所有线程完成阶段1
                    barrier.await();

                    // 阶段2：（由屏障回调完成汇总）
                    // 所有线程都可以访问totalSum了

                } catch (InterruptedException | BrokenBarrierException e) {
                    Thread.currentThread().interrupt();
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        completionLatch.await();
        executor.shutdown();
        return totalSum;
    }

    public static void main(String[] args) throws InterruptedException {
        // 创建一个5x5的矩阵
        int[][] matrix = {
            {1, 2, 3, 4, 5},      // 行和: 15
            {6, 7, 8, 9, 10},     // 行和: 40
            {11, 12, 13, 14, 15}, // 行和: 65
            {16, 17, 18, 19, 20}, // 行和: 90
            {21, 22, 23, 24, 25}  // 行和: 115
        };                        // 总和: 325

        MatrixCalculator calculator = new MatrixCalculator(matrix);
        int result = calculator.calculate();

        System.out.println("\n最终结果: " + result);
        System.out.println("期望结果: 325");
    }
}
```

---

### 题目 3.7 ⭐⭐⭐ Phaser 动态注册

```java
import java.util.concurrent.Phaser;

/**
 * 使用Phaser实现支持动态加入/退出的多阶段任务
 */
public class DynamicPhaserTask {
    private final Phaser phaser;

    public DynamicPhaserTask() {
        // 创建Phaser，主线程注册为参与者
        this.phaser = new Phaser(1) {
            // 可以重写onAdvance来控制Phaser的终止条件
            @Override
            protected boolean onAdvance(int phase, int registeredParties) {
                System.out.println("[Phaser] 阶段 " + phase + " 完成，" +
                                  "当前注册方: " + registeredParties);
                // 返回true表示终止Phaser
                // 返回false表示继续
                return registeredParties == 0;
            }
        };
    }

    public void runTask() throws InterruptedException {
        System.out.println("=== 阶段 0 开始 ===");
        System.out.println("初始参与者数: " + phaser.getRegisteredParties());

        // 阶段0：启动3个初始工作线程
        for (int i = 0; i < 3; i++) {
            startWorker("worker-" + i, 2); // 工作2个阶段后退出
        }

        // 主线程推进到阶段1
        phaser.arriveAndAwaitAdvance();
        System.out.println("\n=== 阶段 1 开始 ===");
        System.out.println("当前参与者数: " + phaser.getRegisteredParties());

        // 阶段1：动态增加2个工作线程
        for (int i = 3; i < 5; i++) {
            startWorker("worker-" + i, 1); // 工作1个阶段后退出
        }

        // 主线程推进到阶段2
        phaser.arriveAndAwaitAdvance();
        System.out.println("\n=== 阶段 2 开始 ===");
        System.out.println("当前参与者数: " + phaser.getRegisteredParties());

        // 主线程推进到阶段3
        phaser.arriveAndAwaitAdvance();
        System.out.println("\n=== 阶段 3 开始 ===");

        // 主线程退出
        phaser.arriveAndDeregister();
        System.out.println("主线程退出，剩余参与者: " + phaser.getRegisteredParties());
    }

    private void startWorker(String name, int workPhases) {
        phaser.register(); // 动态注册
        System.out.println(name + " 注册，当前参与者: " + phaser.getRegisteredParties());

        new Thread(() -> {
            try {
                for (int i = 0; i < workPhases; i++) {
                    // 模拟工作
                    System.out.println("  " + name + " 正在执行阶段 " +
                                      phaser.getPhase() + " 的工作");
                    Thread.sleep(100 + (int)(Math.random() * 100));

                    // 等待其他参与者
                    phaser.arriveAndAwaitAdvance();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                // 工作完成，注销
                phaser.arriveAndDeregister();
                System.out.println("  " + name + " 退出");
            }
        }, name).start();
    }

    public static void main(String[] args) throws InterruptedException {
        DynamicPhaserTask task = new DynamicPhaserTask();
        task.runTask();

        // 等待所有工作线程完成
        Thread.sleep(1000);
        System.out.println("\n所有任务完成");
    }
}
```

---

## 场景四：资源池/限流

### 题目 4.6 ⭐⭐⭐ 分布式限流器

```java
import java.util.concurrent.*;

/**
 * 基于Redis的分布式限流器（模拟实现）
 * 实际使用时需要替换为真实的Redis客户端
 */
public class DistributedRateLimiter {
    private final String key;
    private final int maxRequests;
    private final long windowSizeMs;

    // 模拟Redis客户端（实际应使用Jedis/Lettuce）
    private final SimulatedRedis redis;

    public DistributedRateLimiter(String key, int maxRequests, long windowSizeMs) {
        this.key = "rate_limit:" + key;
        this.maxRequests = maxRequests;
        this.windowSizeMs = windowSizeMs;
        this.redis = new SimulatedRedis();
    }

    /**
     * 尝试获取许可
     * 使用滑动窗口算法
     */
    public boolean tryAcquire() {
        long now = System.currentTimeMillis();
        long windowStart = now - windowSizeMs;

        // Lua脚本保证原子性
        return redis.executeScript(key, maxRequests, windowStart, now);
    }

    /**
     * 固定窗口算法实现（简单版）
     */
    public boolean tryAcquireFixedWindow() {
        long now = System.currentTimeMillis();
        long windowKey = now / windowSizeMs; // 窗口ID
        String actualKey = key + ":" + windowKey;

        long count = redis.incr(actualKey);
        if (count == 1) {
            // 第一次访问，设置过期时间
            redis.expire(actualKey, windowSizeMs);
        }

        return count <= maxRequests;
    }

    // 模拟的Redis客户端
    static class SimulatedRedis {
        private final ConcurrentHashMap<String, Object> store = new ConcurrentHashMap<>();
        private final ConcurrentHashMap<String, Long> expireTime = new ConcurrentHashMap<>();

        /**
         * 模拟Lua脚本执行（滑动窗口）
         * 实际Redis中应该使用 ZREMRANGEBYSCORE + ZCARD + ZADD
         */
        public synchronized boolean executeScript(String key, int limit,
                                                   long windowStart, long now) {
            // 清理过期数据
            cleanExpired();

            @SuppressWarnings("unchecked")
            ConcurrentLinkedQueue<Long> timestamps =
                (ConcurrentLinkedQueue<Long>) store.computeIfAbsent(
                    key, k -> new ConcurrentLinkedQueue<Long>());

            // 移除窗口外的时间戳
            while (!timestamps.isEmpty() && timestamps.peek() < windowStart) {
                timestamps.poll();
            }

            // 检查当前窗口内的请求数
            if (timestamps.size() < limit) {
                timestamps.offer(now);
                return true;
            }

            return false;
        }

        public synchronized long incr(String key) {
            cleanExpired();
            Long value = (Long) store.compute(key, (k, v) ->
                v == null ? 1L : ((Long) v) + 1);
            return value;
        }

        public synchronized void expire(String key, long ttlMs) {
            expireTime.put(key, System.currentTimeMillis() + ttlMs);
        }

        private void cleanExpired() {
            long now = System.currentTimeMillis();
            expireTime.entrySet().removeIf(entry -> {
                if (entry.getValue() < now) {
                    store.remove(entry.getKey());
                    return true;
                }
                return false;
            });
        }
    }

    // Lua脚本（实际Redis中使用）
    private static final String LUA_SCRIPT = """
        local key = KEYS[1]
        local limit = tonumber(ARGV[1])
        local window_start = tonumber(ARGV[2])
        local now = tonumber(ARGV[3])

        -- 移除窗口外的数据
        redis.call('ZREMRANGEBYSCORE', key, '-inf', window_start)

        -- 获取当前窗口内的请求数
        local count = redis.call('ZCARD', key)

        if count < limit then
            -- 添加当前请求
            redis.call('ZADD', key, now, now .. '-' .. math.random())
            -- 设置过期时间
            redis.call('PEXPIRE', key, ARGV[4])
            return 1
        else
            return 0
        end
        """;

    public static void main(String[] args) throws InterruptedException {
        // 每秒最多5个请求
        DistributedRateLimiter limiter = new DistributedRateLimiter("api", 5, 1000);

        System.out.println("=== 滑动窗口限流测试 ===");
        for (int i = 0; i < 10; i++) {
            boolean allowed = limiter.tryAcquire();
            System.out.println("请求 " + i + ": " + (allowed ? "通过" : "拒绝"));
            Thread.sleep(100);
        }

        Thread.sleep(1000);
        System.out.println("\n等待1秒后...");

        for (int i = 0; i < 5; i++) {
            boolean allowed = limiter.tryAcquire();
            System.out.println("请求: " + (allowed ? "通过" : "拒绝"));
        }
    }
}
```

---

### 题目 4.7 ⭐⭐⭐ 带优先级的资源池

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.locks.*;

/**
 * 支持优先级的资源获取池
 * 高优先级的请求优先获取资源
 */
public class PriorityResourcePool<T> {
    private final Queue<T> resources;
    private final int capacity;
    private final ReentrantLock lock = new ReentrantLock();

    // 使用优先级队列管理等待者
    private final PriorityBlockingQueue<Waiter> waiters =
        new PriorityBlockingQueue<>();

    static class Waiter implements Comparable<Waiter> {
        final int priority;       // 数字越小优先级越高
        final long timestamp;     // 到达时间
        final Condition condition;
        volatile boolean signaled = false;

        Waiter(int priority, Condition condition) {
            this.priority = priority;
            this.timestamp = System.nanoTime();
            this.condition = condition;
        }

        @Override
        public int compareTo(Waiter other) {
            // 先比较优先级
            int cmp = Integer.compare(this.priority, other.priority);
            if (cmp != 0) return cmp;
            // 优先级相同，先来的先服务
            return Long.compare(this.timestamp, other.timestamp);
        }
    }

    public PriorityResourcePool(Supplier<T> factory, int capacity) {
        this.capacity = capacity;
        this.resources = new LinkedList<>();
        for (int i = 0; i < capacity; i++) {
            resources.offer(factory.get());
        }
    }

    public T acquire(int priority) throws InterruptedException {
        lock.lock();
        try {
            // 如果有资源且没有更高优先级的等待者
            while (resources.isEmpty() || hasHigherPriorityWaiter(priority)) {
                if (resources.isEmpty()) {
                    // 没有资源，必须等待
                    Condition condition = lock.newCondition();
                    Waiter waiter = new Waiter(priority, condition);
                    waiters.offer(waiter);

                    try {
                        while (!waiter.signaled) {
                            condition.await();
                        }
                    } finally {
                        waiters.remove(waiter);
                    }
                } else {
                    // 有资源但有更高优先级的等待者，让出
                    Condition condition = lock.newCondition();
                    Waiter waiter = new Waiter(priority, condition);
                    waiters.offer(waiter);

                    // 通知最高优先级的等待者
                    signalHighestPriority();

                    try {
                        while (!waiter.signaled && hasHigherPriorityWaiter(priority)) {
                            condition.await();
                        }
                    } finally {
                        waiters.remove(waiter);
                    }
                }
            }

            return resources.poll();
        } finally {
            lock.unlock();
        }
    }

    public T tryAcquire(int priority, long timeout, TimeUnit unit)
            throws InterruptedException {
        long deadline = System.nanoTime() + unit.toNanos(timeout);

        lock.lock();
        try {
            while (resources.isEmpty() || hasHigherPriorityWaiter(priority)) {
                long remaining = deadline - System.nanoTime();
                if (remaining <= 0) {
                    return null; // 超时
                }

                Condition condition = lock.newCondition();
                Waiter waiter = new Waiter(priority, condition);
                waiters.offer(waiter);

                try {
                    while (!waiter.signaled) {
                        if (!condition.await(remaining, TimeUnit.NANOSECONDS)) {
                            return null; // 超时
                        }
                        remaining = deadline - System.nanoTime();
                    }
                } finally {
                    waiters.remove(waiter);
                }
            }

            return resources.poll();
        } finally {
            lock.unlock();
        }
    }

    public void release(T resource) {
        lock.lock();
        try {
            resources.offer(resource);
            // 通知最高优先级的等待者
            signalHighestPriority();
        } finally {
            lock.unlock();
        }
    }

    private boolean hasHigherPriorityWaiter(int priority) {
        Waiter highest = waiters.peek();
        return highest != null && highest.priority < priority;
    }

    private void signalHighestPriority() {
        Waiter highest = waiters.peek();
        if (highest != null) {
            highest.signaled = true;
            highest.condition.signal();
        }
    }

    public int available() {
        lock.lock();
        try {
            return resources.size();
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        PriorityResourcePool<String> pool = new PriorityResourcePool<>(
            () -> "Resource-" + UUID.randomUUID().toString().substring(0, 4),
            2
        );

        // 模拟不同优先级的请求
        Thread low1 = new Thread(() -> {
            try {
                System.out.println("低优先级1 请求资源...");
                String r = pool.acquire(10);
                System.out.println("低优先级1 获得: " + r);
                Thread.sleep(500);
                pool.release(r);
                System.out.println("低优先级1 释放: " + r);
            } catch (InterruptedException e) {}
        });

        Thread high = new Thread(() -> {
            try {
                Thread.sleep(50); // 稍后请求
                System.out.println("高优先级 请求资源...");
                String r = pool.acquire(1);
                System.out.println("高优先级 获得: " + r);
                Thread.sleep(200);
                pool.release(r);
                System.out.println("高优先级 释放: " + r);
            } catch (InterruptedException e) {}
        });

        Thread low2 = new Thread(() -> {
            try {
                Thread.sleep(100); // 更晚请求
                System.out.println("低优先级2 请求资源...");
                String r = pool.acquire(10);
                System.out.println("低优先级2 获得: " + r);
                pool.release(r);
            } catch (InterruptedException e) {}
        });

        low1.start();
        high.start();
        low2.start();

        low1.join();
        high.join();
        low2.join();
    }
}
```

---

## 场景五：生产者-消费者

### 题目 5.6 ⭐⭐⭐ LinkedTransferQueue 高级用法

```java
import java.util.concurrent.*;

/**
 * 使用LinkedTransferQueue实现消息确认机制
 * 生产者可以等待消费者确认收到消息
 */
public class TransferExample {
    private final TransferQueue<Message> queue = new LinkedTransferQueue<>();

    static class Message {
        final String content;
        final long timestamp;
        final CompletableFuture<Boolean> ackFuture;

        Message(String content, boolean needAck) {
            this.content = content;
            this.timestamp = System.currentTimeMillis();
            this.ackFuture = needAck ? new CompletableFuture<>() : null;
        }

        void acknowledge() {
            if (ackFuture != null) {
                ackFuture.complete(true);
            }
        }

        boolean waitForAck(long timeout, TimeUnit unit) throws InterruptedException {
            if (ackFuture == null) return true;
            try {
                return ackFuture.get(timeout, unit);
            } catch (ExecutionException | TimeoutException e) {
                return false;
            }
        }
    }

    // 普通发送（不等待消费者）
    public void offer(String content) {
        queue.offer(new Message(content, false));
        System.out.println("[Producer] 发送消息(不等待): " + content);
    }

    // 同步发送（等待消费者取走）
    public void transfer(String content) throws InterruptedException {
        Message msg = new Message(content, false);
        System.out.println("[Producer] 发送消息(等待消费者取走): " + content);
        queue.transfer(msg); // 阻塞直到消费者取走
        System.out.println("[Producer] 消息已被取走: " + content);
    }

    // 发送并等待确认
    public boolean sendWithAck(String content, long timeout, TimeUnit unit)
            throws InterruptedException {
        Message msg = new Message(content, true);
        System.out.println("[Producer] 发送消息(等待确认): " + content);

        // 尝试直接传递给等待的消费者
        if (queue.tryTransfer(msg, timeout, unit)) {
            // 等待消费者确认
            boolean acked = msg.waitForAck(timeout, unit);
            System.out.println("[Producer] 消息确认结果: " + acked);
            return acked;
        } else {
            System.out.println("[Producer] 传递超时: " + content);
            return false;
        }
    }

    // 消费者
    public void consume() throws InterruptedException {
        while (true) {
            Message msg = queue.take();
            System.out.println("[Consumer] 收到消息: " + msg.content);

            // 模拟处理
            Thread.sleep(100);

            // 发送确认
            msg.acknowledge();
            System.out.println("[Consumer] 已确认消息: " + msg.content);
        }
    }

    // 带超时的消费
    public Message poll(long timeout, TimeUnit unit) throws InterruptedException {
        return queue.poll(timeout, unit);
    }

    // 检查是否有等待的消费者
    public boolean hasWaitingConsumer() {
        return queue.hasWaitingConsumer();
    }

    public static void main(String[] args) throws InterruptedException {
        TransferExample example = new TransferExample();

        // 启动消费者
        Thread consumer = new Thread(() -> {
            try {
                example.consume();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "Consumer");
        consumer.setDaemon(true);
        consumer.start();

        // 等待消费者就绪
        Thread.sleep(100);

        // 测试普通发送
        System.out.println("=== 测试普通发送 ===");
        example.offer("消息1");

        Thread.sleep(200);

        // 测试同步发送
        System.out.println("\n=== 测试同步发送 ===");
        example.transfer("消息2");

        Thread.sleep(200);

        // 测试发送并确认
        System.out.println("\n=== 测试发送并确认 ===");
        boolean acked = example.sendWithAck("消息3", 5, TimeUnit.SECONDS);
        System.out.println("最终确认状态: " + acked);
    }
}
```

---

### 题目 5.7 ⭐⭐⭐ 多生产者多消费者模式

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 支持多生产者多消费者的任务处理系统，带有优雅关闭功能
 */
public class WorkerPool {
    private final BlockingQueue<Runnable> taskQueue;
    private final List<Thread> workers;
    private final AtomicInteger activeWorkers = new AtomicInteger(0);
    private volatile boolean shutdown = false;
    private volatile boolean shutdownNow = false;

    public WorkerPool(int workerCount, int queueCapacity) {
        this.taskQueue = new LinkedBlockingQueue<>(queueCapacity);
        this.workers = new ArrayList<>(workerCount);

        // 创建工作线程
        for (int i = 0; i < workerCount; i++) {
            Thread worker = new Thread(this::workerLoop, "Worker-" + i);
            workers.add(worker);
            worker.start();
        }
    }

    private void workerLoop() {
        while (!shutdownNow) {
            try {
                // 如果已经shutdown，使用poll而不是take
                Runnable task;
                if (shutdown) {
                    task = taskQueue.poll(100, TimeUnit.MILLISECONDS);
                    if (task == null && taskQueue.isEmpty()) {
                        break; // 队列空了，可以退出
                    }
                } else {
                    task = taskQueue.poll(1, TimeUnit.SECONDS);
                }

                if (task != null) {
                    activeWorkers.incrementAndGet();
                    try {
                        task.run();
                    } catch (Exception e) {
                        System.err.println(Thread.currentThread().getName() +
                                          " 任务执行异常: " + e.getMessage());
                    } finally {
                        activeWorkers.decrementAndGet();
                    }
                }
            } catch (InterruptedException e) {
                if (shutdownNow) {
                    break;
                }
            }
        }
        System.out.println(Thread.currentThread().getName() + " 退出");
    }

    public void submit(Runnable task) {
        if (shutdown) {
            throw new RejectedExecutionException("WorkerPool已关闭");
        }
        try {
            if (!taskQueue.offer(task, 1, TimeUnit.SECONDS)) {
                throw new RejectedExecutionException("任务队列已满");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RejectedExecutionException("提交任务被中断");
        }
    }

    /**
     * 优雅关闭：不再接受新任务，等待队列中的任务处理完
     */
    public void shutdown() {
        shutdown = true;
        System.out.println("开始优雅关闭...");
    }

    /**
     * 立即关闭：中断所有工作线程，返回未处理的任务
     */
    public List<Runnable> shutdownNow() {
        shutdown = true;
        shutdownNow = true;

        // 中断所有工作线程
        for (Thread worker : workers) {
            worker.interrupt();
        }

        // 收集未处理的任务
        List<Runnable> remaining = new ArrayList<>();
        taskQueue.drainTo(remaining);

        System.out.println("立即关闭，未处理任务数: " + remaining.size());
        return remaining;
    }

    /**
     * 等待所有任务完成
     */
    public boolean awaitTermination(long timeout, TimeUnit unit)
            throws InterruptedException {
        long deadline = System.nanoTime() + unit.toNanos(timeout);

        for (Thread worker : workers) {
            long remaining = deadline - System.nanoTime();
            if (remaining <= 0) {
                return false;
            }
            worker.join(TimeUnit.NANOSECONDS.toMillis(remaining));
            if (worker.isAlive()) {
                return false;
            }
        }
        return true;
    }

    public boolean isShutdown() {
        return shutdown;
    }

    public boolean isTerminated() {
        if (!shutdown) return false;
        for (Thread worker : workers) {
            if (worker.isAlive()) return false;
        }
        return true;
    }

    public int getActiveCount() {
        return activeWorkers.get();
    }

    public int getQueueSize() {
        return taskQueue.size();
    }

    public static void main(String[] args) throws InterruptedException {
        WorkerPool pool = new WorkerPool(3, 100);

        // 提交任务
        for (int i = 0; i < 10; i++) {
            int taskId = i;
            pool.submit(() -> {
                System.out.println("执行任务 " + taskId +
                                  " (" + Thread.currentThread().getName() + ")");
                try {
                    Thread.sleep(200);
                } catch (InterruptedException e) {
                    System.out.println("任务 " + taskId + " 被中断");
                }
            });
        }

        Thread.sleep(500);
        System.out.println("活跃工作线程: " + pool.getActiveCount());
        System.out.println("队列大小: " + pool.getQueueSize());

        // 优雅关闭
        pool.shutdown();

        // 等待完成
        if (pool.awaitTermination(5, TimeUnit.SECONDS)) {
            System.out.println("所有任务完成");
        } else {
            System.out.println("超时，强制关闭");
            pool.shutdownNow();
        }
    }
}
```

---

## 场景六：缓存/共享Map

### 题目 6.6 ⭐⭐⭐ LRU缓存

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 基于ConcurrentHashMap的线程安全LRU缓存
 * 使用访问计数器模拟LRU顺序
 */
public class ConcurrentLRUCache<K, V> {
    private final int capacity;
    private final ConcurrentHashMap<K, CacheEntry<K, V>> cache;
    private final AtomicInteger accessCounter = new AtomicInteger(0);

    // 用于淘汰时找到最久未访问的条目
    private final ConcurrentSkipListMap<Long, K> accessOrder =
        new ConcurrentSkipListMap<>();

    static class CacheEntry<K, V> {
        final K key;
        volatile V value;
        volatile long accessId;

        CacheEntry(K key, V value, long accessId) {
            this.key = key;
            this.value = value;
            this.accessId = accessId;
        }
    }

    public ConcurrentLRUCache(int capacity) {
        this.capacity = capacity;
        this.cache = new ConcurrentHashMap<>(capacity);
    }

    public V get(K key) {
        CacheEntry<K, V> entry = cache.get(key);
        if (entry == null) {
            return null;
        }

        // 更新访问顺序
        updateAccess(entry);
        return entry.value;
    }

    public void put(K key, V value) {
        long newAccessId = accessCounter.incrementAndGet();

        CacheEntry<K, V> newEntry = new CacheEntry<>(key, value, newAccessId);
        CacheEntry<K, V> oldEntry = cache.put(key, newEntry);

        // 移除旧的访问记录
        if (oldEntry != null) {
            accessOrder.remove(oldEntry.accessId);
        }

        // 添加新的访问记录
        accessOrder.put(newAccessId, key);

        // 如果超过容量，淘汰最久未访问的
        evictIfNeeded();
    }

    private void updateAccess(CacheEntry<K, V> entry) {
        long oldAccessId = entry.accessId;
        long newAccessId = accessCounter.incrementAndGet();

        // 更新访问ID
        entry.accessId = newAccessId;

        // 更新访问顺序映射
        accessOrder.remove(oldAccessId);
        accessOrder.put(newAccessId, entry.key);
    }

    private void evictIfNeeded() {
        while (cache.size() > capacity) {
            // 找到最小的accessId（最久未访问）
            var firstEntry = accessOrder.pollFirstEntry();
            if (firstEntry == null) break;

            K keyToEvict = firstEntry.getValue();
            CacheEntry<K, V> entry = cache.get(keyToEvict);

            // 再次检查（可能已经被更新）
            if (entry != null && entry.accessId == firstEntry.getKey()) {
                cache.remove(keyToEvict, entry);
                System.out.println("淘汰: " + keyToEvict);
            }
        }
    }

    public int size() {
        return cache.size();
    }

    public boolean containsKey(K key) {
        return cache.containsKey(key);
    }

    public V remove(K key) {
        CacheEntry<K, V> entry = cache.remove(key);
        if (entry != null) {
            accessOrder.remove(entry.accessId);
            return entry.value;
        }
        return null;
    }

    public static void main(String[] args) {
        ConcurrentLRUCache<String, Integer> cache = new ConcurrentLRUCache<>(3);

        cache.put("a", 1);
        cache.put("b", 2);
        cache.put("c", 3);
        System.out.println("初始状态，大小: " + cache.size());

        // 访问a，使其变为最近使用
        cache.get("a");

        // 添加d，应该淘汰b（最久未访问）
        cache.put("d", 4);
        System.out.println("添加d后:");
        System.out.println("  包含a: " + cache.containsKey("a")); // true
        System.out.println("  包含b: " + cache.containsKey("b")); // false
        System.out.println("  包含c: " + cache.containsKey("c")); // true
        System.out.println("  包含d: " + cache.containsKey("d")); // true

        // 多线程测试
        System.out.println("\n多线程测试:");
        ConcurrentLRUCache<Integer, Integer> cache2 = new ConcurrentLRUCache<>(100);
        Thread[] threads = new Thread[10];
        for (int i = 0; i < 10; i++) {
            int threadId = i;
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 100; j++) {
                    int key = threadId * 100 + j;
                    cache2.put(key, key);
                    cache2.get(key);
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            try { t.join(); } catch (InterruptedException e) {}
        }

        System.out.println("最终大小: " + cache2.size()); // 应该是100
    }
}
```

---

### 题目 6.7 ⭐⭐⭐ 一致性Hash

```java
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.concurrent.ConcurrentSkipListMap;

/**
 * 使用ConcurrentSkipListMap实现一致性Hash环
 */
public class ConsistentHash<T> {
    private final ConcurrentSkipListMap<Long, T> ring = new ConcurrentSkipListMap<>();
    private final int virtualNodes;  // 每个真实节点的虚拟节点数
    private final Set<T> realNodes = ConcurrentHashMap.newKeySet();

    public ConsistentHash(int virtualNodes) {
        this.virtualNodes = virtualNodes;
    }

    public void addNode(T node) {
        if (realNodes.add(node)) {
            for (int i = 0; i < virtualNodes; i++) {
                long hash = hash(node.toString() + "#VN" + i);
                ring.put(hash, node);
            }
            System.out.println("添加节点: " + node + " (虚拟节点: " + virtualNodes + ")");
        }
    }

    public void removeNode(T node) {
        if (realNodes.remove(node)) {
            for (int i = 0; i < virtualNodes; i++) {
                long hash = hash(node.toString() + "#VN" + i);
                ring.remove(hash);
            }
            System.out.println("移除节点: " + node);
        }
    }

    public T getNode(String key) {
        if (ring.isEmpty()) {
            return null;
        }

        long hash = hash(key);

        // 找到第一个大于等于hash的节点
        Map.Entry<Long, T> entry = ring.ceilingEntry(hash);

        // 如果没有找到（hash大于所有节点），则返回第一个节点（环形）
        if (entry == null) {
            entry = ring.firstEntry();
        }

        return entry.getValue();
    }

    /**
     * 获取key应该路由到的多个节点（用于复制）
     */
    public List<T> getNodes(String key, int count) {
        if (ring.isEmpty() || count <= 0) {
            return Collections.emptyList();
        }

        long hash = hash(key);
        List<T> nodes = new ArrayList<>();
        Set<T> seen = new HashSet<>();

        // 从hash位置开始顺时针遍历
        NavigableMap<Long, T> tailMap = ring.tailMap(hash, true);
        for (T node : tailMap.values()) {
            if (seen.add(node)) {
                nodes.add(node);
                if (nodes.size() >= count) {
                    return nodes;
                }
            }
        }

        // 如果还不够，从头开始
        for (T node : ring.values()) {
            if (seen.add(node)) {
                nodes.add(node);
                if (nodes.size() >= count) {
                    return nodes;
                }
            }
        }

        return nodes;
    }

    private long hash(String key) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(key.getBytes(StandardCharsets.UTF_8));
            // 取前8字节作为long
            long hash = 0;
            for (int i = 0; i < 8; i++) {
                hash = (hash << 8) | (digest[i] & 0xFF);
            }
            return hash;
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public int getNodeCount() {
        return realNodes.size();
    }

    public int getRingSize() {
        return ring.size();
    }

    /**
     * 打印节点分布情况
     */
    public void printDistribution(List<String> testKeys) {
        Map<T, Integer> distribution = new HashMap<>();
        for (T node : realNodes) {
            distribution.put(node, 0);
        }

        for (String key : testKeys) {
            T node = getNode(key);
            distribution.merge(node, 1, Integer::sum);
        }

        System.out.println("分布情况:");
        for (Map.Entry<T, Integer> entry : distribution.entrySet()) {
            double percent = 100.0 * entry.getValue() / testKeys.size();
            System.out.printf("  %s: %d (%.2f%%)%n",
                             entry.getKey(), entry.getValue(), percent);
        }
    }

    public static void main(String[] args) {
        ConsistentHash<String> hash = new ConsistentHash<>(150);

        // 添加节点
        hash.addNode("Server-A");
        hash.addNode("Server-B");
        hash.addNode("Server-C");

        System.out.println("节点数: " + hash.getNodeCount());
        System.out.println("环大小: " + hash.getRingSize());

        // 测试key分布
        System.out.println("\n测试key路由:");
        for (int i = 0; i < 5; i++) {
            String key = "user-" + i;
            System.out.println("  " + key + " -> " + hash.getNode(key));
        }

        // 测试分布均匀性
        System.out.println("\n分布均匀性测试 (10000个key):");
        List<String> testKeys = new ArrayList<>();
        for (int i = 0; i < 10000; i++) {
            testKeys.add("key-" + i);
        }
        hash.printDistribution(testKeys);

        // 测试节点变化的影响
        System.out.println("\n移除Server-B后:");
        hash.removeNode("Server-B");
        hash.printDistribution(testKeys);

        // 测试复制
        System.out.println("\n获取2个副本节点:");
        List<String> replicas = hash.getNodes("important-data", 2);
        System.out.println("  important-data -> " + replicas);
    }
}
```

---

## 场景七：异步任务编排

### 题目 7.6 ⭐⭐⭐ 重试机制

```java
import java.util.concurrent.*;
import java.util.function.*;

/**
 * 使用CompletableFuture实现带重试的异步操作
 */
public class RetryableAsync {

    private static final ScheduledExecutorService scheduler =
        Executors.newSingleThreadScheduledExecutor();

    /**
     * 带重试的异步操作
     * @param action 要执行的异步操作
     * @param maxRetries 最大重试次数
     * @param delayMs 重试间隔（毫秒）
     */
    public <T> CompletableFuture<T> retryAsync(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long delayMs) {

        CompletableFuture<T> future = new CompletableFuture<>();
        executeWithRetry(action, maxRetries, delayMs, future, 0);
        return future;
    }

    private <T> void executeWithRetry(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long delayMs,
            CompletableFuture<T> resultFuture,
            int attempt) {

        action.get().whenComplete((result, ex) -> {
            if (ex == null) {
                // 成功
                resultFuture.complete(result);
            } else if (attempt < maxRetries) {
                // 失败但还有重试机会
                System.out.println("第 " + (attempt + 1) + " 次失败: " +
                                  ex.getMessage() + "，" + delayMs + "ms后重试");

                scheduler.schedule(() -> {
                    executeWithRetry(action, maxRetries, delayMs,
                                    resultFuture, attempt + 1);
                }, delayMs, TimeUnit.MILLISECONDS);
            } else {
                // 重试次数用尽
                System.out.println("重试次数用尽，操作失败");
                resultFuture.completeExceptionally(ex);
            }
        });
    }

    /**
     * 指数退避重试
     * 每次重试的等待时间翻倍
     */
    public <T> CompletableFuture<T> retryWithBackoff(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long initialDelayMs,
            long maxDelayMs) {

        CompletableFuture<T> future = new CompletableFuture<>();
        executeWithBackoff(action, maxRetries, initialDelayMs, maxDelayMs, future, 0);
        return future;
    }

    private <T> void executeWithBackoff(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long initialDelayMs,
            long maxDelayMs,
            CompletableFuture<T> resultFuture,
            int attempt) {

        action.get().whenComplete((result, ex) -> {
            if (ex == null) {
                resultFuture.complete(result);
            } else if (attempt < maxRetries) {
                // 指数退避：delay = initialDelay * 2^attempt
                long delay = Math.min(initialDelayMs * (1L << attempt), maxDelayMs);

                System.out.println("第 " + (attempt + 1) + " 次失败，" +
                                  delay + "ms后重试 (指数退避)");

                scheduler.schedule(() -> {
                    executeWithBackoff(action, maxRetries, initialDelayMs,
                                      maxDelayMs, resultFuture, attempt + 1);
                }, delay, TimeUnit.MILLISECONDS);
            } else {
                resultFuture.completeExceptionally(ex);
            }
        });
    }

    /**
     * 带条件的重试（只有特定异常才重试）
     */
    public <T> CompletableFuture<T> retryOnException(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long delayMs,
            Predicate<Throwable> shouldRetry) {

        CompletableFuture<T> future = new CompletableFuture<>();
        executeWithCondition(action, maxRetries, delayMs, shouldRetry, future, 0);
        return future;
    }

    private <T> void executeWithCondition(
            Supplier<CompletableFuture<T>> action,
            int maxRetries,
            long delayMs,
            Predicate<Throwable> shouldRetry,
            CompletableFuture<T> resultFuture,
            int attempt) {

        action.get().whenComplete((result, ex) -> {
            if (ex == null) {
                resultFuture.complete(result);
            } else {
                Throwable cause = ex instanceof CompletionException ?
                                  ex.getCause() : ex;

                if (attempt < maxRetries && shouldRetry.test(cause)) {
                    System.out.println("可重试异常: " + cause.getClass().getSimpleName());
                    scheduler.schedule(() -> {
                        executeWithCondition(action, maxRetries, delayMs,
                                            shouldRetry, resultFuture, attempt + 1);
                    }, delayMs, TimeUnit.MILLISECONDS);
                } else {
                    resultFuture.completeExceptionally(ex);
                }
            }
        });
    }

    // 辅助方法：创建延迟的CompletableFuture
    public CompletableFuture<Void> delay(long millis) {
        CompletableFuture<Void> future = new CompletableFuture<>();
        scheduler.schedule(() -> future.complete(null), millis, TimeUnit.MILLISECONDS);
        return future;
    }

    public static void main(String[] args) {
        RetryableAsync retryable = new RetryableAsync();

        // 模拟不稳定的操作（前两次失败，第三次成功）
        int[] attempts = {0};
        Supplier<CompletableFuture<String>> unstableOperation = () ->
            CompletableFuture.supplyAsync(() -> {
                attempts[0]++;
                if (attempts[0] < 3) {
                    throw new RuntimeException("模拟失败 #" + attempts[0]);
                }
                return "成功！";
            });

        System.out.println("=== 固定间隔重试 ===");
        String result = retryable.retryAsync(unstableOperation, 5, 500)
                                  .join();
        System.out.println("结果: " + result);

        // 重置
        attempts[0] = 0;

        System.out.println("\n=== 指数退避重试 ===");
        result = retryable.retryWithBackoff(unstableOperation, 5, 100, 2000)
                          .join();
        System.out.println("结果: " + result);

        // 关闭scheduler
        scheduler.shutdown();
    }
}
```

---

### 题目 7.7 ⭐⭐⭐ ExecutorCompletionService 按完成顺序处理

```java
import java.util.*;
import java.util.concurrent.*;

/**
 * 使用ExecutorCompletionService按任务完成顺序处理结果
 */
public class CompletionOrderProcessing {
    private final ExecutorService executor;

    public CompletionOrderProcessing(int poolSize) {
        this.executor = Executors.newFixedThreadPool(poolSize);
    }

    /**
     * 按完成顺序处理任务结果
     */
    public <T> List<T> processInCompletionOrder(List<Callable<T>> tasks)
            throws InterruptedException {

        CompletionService<T> completionService =
            new ExecutorCompletionService<>(executor);

        // 提交所有任务
        for (Callable<T> task : tasks) {
            completionService.submit(task);
        }

        // 按完成顺序处理
        List<T> results = new ArrayList<>();
        for (int i = 0; i < tasks.size(); i++) {
            try {
                Future<T> future = completionService.take(); // 阻塞等待下一个完成的
                T result = future.get();
                results.add(result);
                System.out.println("收到结果: " + result);
            } catch (ExecutionException e) {
                System.err.println("任务执行失败: " + e.getCause().getMessage());
            }
        }

        return results;
    }

    /**
     * 带超时的批量处理，返回在超时前完成的结果
     */
    public <T> List<T> processWithTimeout(List<Callable<T>> tasks,
                                           long timeout, TimeUnit unit)
            throws InterruptedException {

        CompletionService<T> completionService =
            new ExecutorCompletionService<>(executor);

        // 提交所有任务
        List<Future<T>> futures = new ArrayList<>();
        for (Callable<T> task : tasks) {
            futures.add(completionService.submit(task));
        }

        long deadline = System.nanoTime() + unit.toNanos(timeout);
        List<T> results = new ArrayList<>();

        for (int i = 0; i < tasks.size(); i++) {
            long remaining = deadline - System.nanoTime();
            if (remaining <= 0) {
                System.out.println("超时！已完成 " + results.size() + "/" + tasks.size());
                break;
            }

            Future<T> future = completionService.poll(remaining, TimeUnit.NANOSECONDS);
            if (future == null) {
                System.out.println("超时！已完成 " + results.size() + "/" + tasks.size());
                break;
            }

            try {
                results.add(future.get());
            } catch (ExecutionException e) {
                System.err.println("任务失败: " + e.getCause().getMessage());
            }
        }

        // 取消未完成的任务
        for (Future<T> future : futures) {
            future.cancel(true);
        }

        return results;
    }

    /**
     * 返回第一个成功的结果，取消其他任务
     */
    public <T> T invokeAny(List<Callable<T>> tasks)
            throws InterruptedException, ExecutionException {

        CompletionService<T> completionService =
            new ExecutorCompletionService<>(executor);

        List<Future<T>> futures = new ArrayList<>();
        try {
            // 提交所有任务
            for (Callable<T> task : tasks) {
                futures.add(completionService.submit(task));
            }

            // 等待第一个成功的
            int remaining = tasks.size();
            ExecutionException lastException = null;

            while (remaining > 0) {
                Future<T> future = completionService.take();
                remaining--;

                try {
                    return future.get(); // 返回第一个成功的
                } catch (ExecutionException e) {
                    lastException = e;
                    // 继续等待下一个
                }
            }

            // 所有任务都失败了
            throw lastException;
        } finally {
            // 取消所有未完成的任务
            for (Future<T> future : futures) {
                future.cancel(true);
            }
        }
    }

    public void shutdown() {
        executor.shutdown();
    }

    public static void main(String[] args) throws Exception {
        CompletionOrderProcessing processor = new CompletionOrderProcessing(5);

        // 创建不同执行时间的任务
        List<Callable<String>> tasks = Arrays.asList(
            () -> { Thread.sleep(300); return "Task-A (300ms)"; },
            () -> { Thread.sleep(100); return "Task-B (100ms)"; },
            () -> { Thread.sleep(500); return "Task-C (500ms)"; },
            () -> { Thread.sleep(200); return "Task-D (200ms)"; },
            () -> { Thread.sleep(50);  return "Task-E (50ms)"; }
        );

        System.out.println("=== 按完成顺序处理 ===");
        long start = System.currentTimeMillis();
        List<String> results = processor.processInCompletionOrder(tasks);
        System.out.println("总耗时: " + (System.currentTimeMillis() - start) + "ms");
        System.out.println("结果顺序: " + results);

        System.out.println("\n=== 带超时处理 (250ms) ===");
        List<Callable<String>> tasks2 = new ArrayList<>(tasks);
        start = System.currentTimeMillis();
        results = processor.processWithTimeout(tasks2, 250, TimeUnit.MILLISECONDS);
        System.out.println("总耗时: " + (System.currentTimeMillis() - start) + "ms");
        System.out.println("完成的任务: " + results);

        System.out.println("\n=== 返回第一个成功的 ===");
        List<Callable<String>> tasks3 = new ArrayList<>(tasks);
        start = System.currentTimeMillis();
        String first = processor.invokeAny(tasks3);
        System.out.println("第一个完成: " + first);
        System.out.println("耗时: " + (System.currentTimeMillis() - start) + "ms");

        processor.shutdown();
    }
}
```

---

## 总结

本文档涵盖了 JUC 包中 7 个核心场景的 **复杂** 难度练习题参考答案：

| 场景 | 题号 | 主题 |
|------|------|------|
| 计数器/累加器 | 1.6, 1.7 | LongAccumulator自定义、AtomicFieldUpdater |
| 读多写少 | 2.6, 2.7 | 带过期时间的缓存、读写分离计数器 |
| 线程协作 | 3.6, 3.7 | CyclicBarrier分阶段计算、Phaser动态注册 |
| 资源池/限流 | 4.6, 4.7 | 分布式限流、带优先级的资源池 |
| 生产者-消费者 | 5.6, 5.7 | TransferQueue消息确认、优雅关闭的WorkerPool |
| 缓存/共享Map | 6.6, 6.7 | 并发LRU缓存、一致性Hash |
| 异步编排 | 7.6, 7.7 | 重试机制、CompletionService按完成顺序处理 |

**学习建议**：
1. 这些题目模拟真实生产场景，建议先理解需求再看答案
2. 注意边界条件和并发安全的处理
3. 思考如何进一步优化性能或扩展功能
