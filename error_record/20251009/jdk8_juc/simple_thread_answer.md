# JUC 练习题参考答案（简单 + 中等）

> 本文档包含 ⭐简单 和 ⭐⭐中等 难度题目的参考答案

---

## 场景一：计数器/累加器

### 题目 1.1 ⭐ 基础计数器

```java
import java.util.concurrent.atomic.AtomicInteger;

public class Counter {
    private final AtomicInteger count = new AtomicInteger(0);

    public void increment() {
        count.incrementAndGet();
    }

    public void decrement() {
        count.decrementAndGet();
    }

    public int get() {
        return count.get();
    }

    public void reset() {
        count.set(0);
    }

    // 测试代码
    public static void main(String[] args) throws InterruptedException {
        Counter counter = new Counter();
        int threadCount = 10;
        int incrementsPerThread = 1000;
        Thread[] threads = new Thread[threadCount];

        for (int i = 0; i < threadCount; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < incrementsPerThread; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("最终结果: " + counter.get()); // 应该是10000
    }
}
```

---

### 题目 1.2 ⭐ CAS自旋实现

```java
import java.lang.invoke.MethodHandles;
import java.lang.invoke.VarHandle;

public class MyCASCounter {
    private volatile int value;

    // JDK9+ VarHandle方式
    private static final VarHandle VALUE_HANDLE;
    static {
        try {
            VALUE_HANDLE = MethodHandles.lookup()
                .findVarHandle(MyCASCounter.class, "value", int.class);
        } catch (Exception e) {
            throw new Error(e);
        }
    }

    public int incrementAndGet() {
        int oldValue;
        int newValue;
        do {
            oldValue = value;           // 读取当前值
            newValue = oldValue + 1;    // 计算新值
            // CAS尝试更新，失败则重试（自旋）
        } while (!VALUE_HANDLE.compareAndSet(this, oldValue, newValue));
        return newValue;
    }

    public int get() {
        return value;
    }

    public static void main(String[] args) throws InterruptedException {
        MyCASCounter counter = new MyCASCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.incrementAndGet();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();
        System.out.println("结果: " + counter.get()); // 10000
    }
}
```

---

### 题目 1.3 ⭐ 原子数组操作

```java
import java.util.Random;
import java.util.concurrent.atomic.AtomicIntegerArray;

public class Histogram {
    // 10个区间: [1-10], [11-20], ..., [91-100]
    private final AtomicIntegerArray buckets = new AtomicIntegerArray(10);

    public void record(int value) {
        if (value < 1 || value > 100) return;
        int index = (value - 1) / 10;  // 计算所属区间
        buckets.incrementAndGet(index);
    }

    public void printDistribution() {
        for (int i = 0; i < 10; i++) {
            int start = i * 10 + 1;
            int end = (i + 1) * 10;
            System.out.printf("[%3d-%3d]: %d%n", start, end, buckets.get(i));
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Histogram histogram = new Histogram();
        Random random = new Random();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 10000; j++) {
                    int value = random.nextInt(100) + 1; // 1-100
                    histogram.record(value);
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();
        histogram.printDistribution();
    }
}
```

---

### 题目 1.4 ⭐⭐ LongAdder vs AtomicLong

```java
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.LongAdder;

public class AdderBenchmark {

    public static void main(String[] args) throws InterruptedException {
        int threadCount = 100;
        int operationsPerThread = 1_000_000;

        // 测试 AtomicLong
        long atomicTime = testAtomicLong(threadCount, operationsPerThread);
        System.out.println("AtomicLong 耗时: " + atomicTime + " ms");

        // 测试 LongAdder
        long adderTime = testLongAdder(threadCount, operationsPerThread);
        System.out.println("LongAdder 耗时: " + adderTime + " ms");

        System.out.println("LongAdder 快 " + (atomicTime / (double) adderTime) + " 倍");
    }

    static long testAtomicLong(int threads, int ops) throws InterruptedException {
        AtomicLong counter = new AtomicLong(0);
        Thread[] threadArray = new Thread[threads];

        long start = System.currentTimeMillis();
        for (int i = 0; i < threads; i++) {
            threadArray[i] = new Thread(() -> {
                for (int j = 0; j < ops; j++) {
                    counter.incrementAndGet();
                }
            });
            threadArray[i].start();
        }
        for (Thread t : threadArray) t.join();
        long end = System.currentTimeMillis();

        System.out.println("AtomicLong 结果: " + counter.get());
        return end - start;
    }

    static long testLongAdder(int threads, int ops) throws InterruptedException {
        LongAdder adder = new LongAdder();
        Thread[] threadArray = new Thread[threads];

        long start = System.currentTimeMillis();
        for (int i = 0; i < threads; i++) {
            threadArray[i] = new Thread(() -> {
                for (int j = 0; j < ops; j++) {
                    adder.increment();
                }
            });
            threadArray[i].start();
        }
        for (Thread t : threadArray) t.join();
        long end = System.currentTimeMillis();

        System.out.println("LongAdder 结果: " + adder.sum());
        return end - start;
    }
}

/*
 * 分析：
 * LongAdder 性能更好的原因：
 * 1. AtomicLong 只有一个 value，所有线程竞争同一个变量，CAS失败率高
 * 2. LongAdder 内部使用 Cell[] 数组，每个线程可能操作不同的 Cell
 * 3. 减少了CAS竞争，提高了并发度
 * 4. sum() 时才汇总所有 Cell 的值
 */
```

---

### 题目 1.5 ⭐⭐ ABA问题演示与解决

```java
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicStampedReference;

public class ABADemo {

    // 1. 演示ABA问题
    public static void demonstrateABAProblem() throws InterruptedException {
        AtomicInteger balance = new AtomicInteger(100);

        // 线程A：读取余额100，准备扣款50
        Thread threadA = new Thread(() -> {
            int oldValue = balance.get(); // 读取100
            try {
                Thread.sleep(100); // 模拟处理时间
            } catch (InterruptedException e) {}

            // 此时余额已经经历了 100->50->100 的变化
            // 但CAS只比较值，不知道中间发生过变化
            boolean success = balance.compareAndSet(oldValue, oldValue - 50);
            System.out.println("线程A CAS结果: " + success + ", 余额: " + balance.get());
        });

        // 线程B：将余额从100改为50
        Thread threadB = new Thread(() -> {
            try { Thread.sleep(20); } catch (InterruptedException e) {}
            balance.compareAndSet(100, 50);
            System.out.println("线程B: 100 -> 50, 余额: " + balance.get());
        });

        // 线程C：将余额从50改为100（回到原值）
        Thread threadC = new Thread(() -> {
            try { Thread.sleep(50); } catch (InterruptedException e) {}
            balance.compareAndSet(50, 100);
            System.out.println("线程C: 50 -> 100, 余额: " + balance.get());
        });

        threadA.start();
        threadB.start();
        threadC.start();

        threadA.join();
        threadB.join();
        threadC.join();

        System.out.println("最终余额: " + balance.get());
        // 线程A的CAS会成功，但这可能是错误的业务逻辑！
    }

    // 2. 使用AtomicStampedReference解决ABA问题
    public static void solveWithStampedReference() throws InterruptedException {
        // 初始值100，版本号0
        AtomicStampedReference<Integer> balance =
            new AtomicStampedReference<>(100, 0);

        Thread threadA = new Thread(() -> {
            int[] stampHolder = new int[1];
            Integer oldValue = balance.get(stampHolder); // 读取值和版本号
            int oldStamp = stampHolder[0];
            System.out.println("线程A读取: 值=" + oldValue + ", 版本=" + oldStamp);

            try { Thread.sleep(100); } catch (InterruptedException e) {}

            // CAS同时比较值和版本号
            boolean success = balance.compareAndSet(oldValue, oldValue - 50,
                                                     oldStamp, oldStamp + 1);
            System.out.println("线程A CAS结果: " + success);
        });

        Thread threadB = new Thread(() -> {
            try { Thread.sleep(20); } catch (InterruptedException e) {}
            int[] stampHolder = new int[1];
            Integer value = balance.get(stampHolder);
            balance.compareAndSet(value, 50, stampHolder[0], stampHolder[0] + 1);
            System.out.println("线程B: 100 -> 50");
        });

        Thread threadC = new Thread(() -> {
            try { Thread.sleep(50); } catch (InterruptedException e) {}
            int[] stampHolder = new int[1];
            Integer value = balance.get(stampHolder);
            balance.compareAndSet(value, 100, stampHolder[0], stampHolder[0] + 1);
            System.out.println("线程C: 50 -> 100");
        });

        threadA.start();
        threadB.start();
        threadC.start();

        threadA.join();
        threadB.join();
        threadC.join();

        int[] stamp = new int[1];
        System.out.println("最终: 值=" + balance.get(stamp) + ", 版本=" + stamp[0]);
        // 线程A的CAS会失败，因为版本号变了
    }

    public static void main(String[] args) throws InterruptedException {
        System.out.println("=== ABA问题演示 ===");
        demonstrateABAProblem();

        Thread.sleep(500);

        System.out.println("\n=== 使用AtomicStampedReference解决 ===");
        solveWithStampedReference();
    }
}
```

---

## 场景二：读多写少

### 题目 2.1 ⭐ 基础读写锁使用

```java
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class SimpleCache<K, V> {
    private final Map<K, V> cache = new HashMap<>();
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final ReentrantReadWriteLock.ReadLock readLock = rwLock.readLock();
    private final ReentrantReadWriteLock.WriteLock writeLock = rwLock.writeLock();

    public V get(K key) {
        readLock.lock();
        try {
            return cache.get(key);
        } finally {
            readLock.unlock();
        }
    }

    public void put(K key, V value) {
        writeLock.lock();
        try {
            cache.put(key, value);
        } finally {
            writeLock.unlock();
        }
    }

    public void remove(K key) {
        writeLock.lock();
        try {
            cache.remove(key);
        } finally {
            writeLock.unlock();
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

    public static void main(String[] args) throws InterruptedException {
        SimpleCache<String, Integer> cache = new SimpleCache<>();

        // 写线程
        Thread writer = new Thread(() -> {
            for (int i = 0; i < 100; i++) {
                cache.put("key" + i, i);
            }
        });

        // 读线程
        Thread reader = new Thread(() -> {
            for (int i = 0; i < 100; i++) {
                cache.get("key" + i);
            }
        });

        writer.start();
        reader.start();
        writer.join();
        reader.join();

        System.out.println("缓存大小: " + cache.size());
    }
}
```

---

### 题目 2.2 ⭐ 锁降级实践

```java
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.locks.ReentrantReadWriteLock;

public class ConfigManager {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final ReentrantReadWriteLock.ReadLock readLock = rwLock.readLock();
    private final ReentrantReadWriteLock.WriteLock writeLock = rwLock.writeLock();
    private Map<String, String> config = new HashMap<>();

    /**
     * 更新配置并返回更新后的值（使用锁降级）
     * 锁降级：写锁 -> 读锁 -> 释放写锁 -> 释放读锁
     */
    public String updateAndGet(String key, String value) {
        // 1. 获取写锁
        writeLock.lock();
        try {
            // 2. 更新配置
            config.put(key, value);

            // 3. 获取读锁（在持有写锁时获取，这是允许的）
            readLock.lock();
        } finally {
            // 4. 释放写锁（此时仍持有读锁）
            writeLock.unlock();
        }

        try {
            // 5. 读取并返回（此时只持有读锁，其他读操作可以并发）
            return config.get(key);
        } finally {
            // 6. 释放读锁
            readLock.unlock();
        }
    }

    public String get(String key) {
        readLock.lock();
        try {
            return config.get(key);
        } finally {
            readLock.unlock();
        }
    }

    public static void main(String[] args) {
        ConfigManager manager = new ConfigManager();
        String result = manager.updateAndGet("timeout", "3000");
        System.out.println("更新后的值: " + result);
    }
}

/*
 * 思考题答案：
 * 为什么不支持锁升级（读锁→写锁）？
 *
 * 假设线程A和线程B都持有读锁，现在都想升级为写锁：
 * - 线程A等待线程B释放读锁
 * - 线程B等待线程A释放读锁
 * → 死锁！
 *
 * 所以ReentrantReadWriteLock禁止锁升级，尝试会导致永久阻塞。
 */
```

---

### 题目 2.3 ⭐ CopyOnWriteArrayList 使用

```java
import java.util.concurrent.CopyOnWriteArrayList;

public class EventManager {
    private final CopyOnWriteArrayList<EventListener> listeners =
        new CopyOnWriteArrayList<>();

    public void addListener(EventListener listener) {
        listeners.add(listener);
    }

    public void removeListener(EventListener listener) {
        listeners.remove(listener);
    }

    public void fireEvent(Event event) {
        // 迭代时不需要加锁，因为CopyOnWriteArrayList保证迭代时的快照一致性
        for (EventListener listener : listeners) {
            try {
                listener.onEvent(event);
            } catch (Exception e) {
                System.err.println("监听器异常: " + e.getMessage());
            }
        }
    }

    // 事件接口
    interface EventListener {
        void onEvent(Event event);
    }

    // 事件类
    static class Event {
        private final String type;
        private final Object data;

        Event(String type, Object data) {
            this.type = type;
            this.data = data;
        }

        public String getType() { return type; }
        public Object getData() { return data; }
    }

    public static void main(String[] args) {
        EventManager manager = new EventManager();

        // 添加监听器
        manager.addListener(event ->
            System.out.println("监听器1收到: " + event.getType()));
        manager.addListener(event ->
            System.out.println("监听器2收到: " + event.getType()));

        // 触发事件
        manager.fireEvent(new Event("click", null));
        manager.fireEvent(new Event("submit", "formData"));
    }
}

/*
 * 思考题答案：
 *
 * 为什么CopyOnWriteArrayList适合这个场景？
 * 1. 监听器通常注册后很少变动（写少）
 * 2. 事件触发时需要遍历所有监听器（读多）
 * 3. 迭代时不会抛出ConcurrentModificationException
 *
 * 如果监听器数量很大且频繁增删会怎样？
 * 1. 每次修改都会复制整个数组，内存开销大
 * 2. 频繁GC
 * 3. 性能急剧下降
 * → 这种情况应该使用ConcurrentHashMap或读写锁
 */
```

---

### 题目 2.4 ⭐⭐ StampedLock 乐观读

```java
import java.util.concurrent.locks.StampedLock;

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

    // 计算到原点的距离（使用乐观读）
    public double distanceFromOrigin() {
        // 1. 尝试乐观读（不加锁）
        long stamp = sl.tryOptimisticRead();

        // 2. 读取x, y（可能读到不一致的值）
        double currentX = x;
        double currentY = y;

        // 3. 验证stamp：检查在读取期间是否有写操作
        if (!sl.validate(stamp)) {
            // 验证失败，说明有写操作发生，升级为悲观读锁
            stamp = sl.readLock();
            try {
                currentX = x;
                currentY = y;
            } finally {
                sl.unlockRead(stamp);
            }
        }

        // 4. 计算并返回距离
        return Math.sqrt(currentX * currentX + currentY * currentY);
    }

    // 设置坐标
    public void set(double x, double y) {
        long stamp = sl.writeLock();
        try {
            this.x = x;
            this.y = y;
        } finally {
            sl.unlockWrite(stamp);
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Point point = new Point();
        point.set(3, 4);

        // 启动写线程
        Thread writer = new Thread(() -> {
            for (int i = 0; i < 1000; i++) {
                point.move(0.001, 0.001);
            }
        });

        // 启动读线程
        Thread reader = new Thread(() -> {
            for (int i = 0; i < 1000; i++) {
                double distance = point.distanceFromOrigin();
                // System.out.println("距离: " + distance);
            }
        });

        writer.start();
        reader.start();
        writer.join();
        reader.join();

        System.out.println("最终距离: " + point.distanceFromOrigin());
    }
}
```

---

### 题目 2.5 ⭐⭐ 读写锁性能测试

```java
import java.util.concurrent.locks.*;

public class RWLockBenchmark {
    private static final int READERS = 10;
    private static final int WRITERS = 2;
    private static final int OPERATIONS = 100000;

    private int sharedData = 0;

    // synchronized
    private synchronized int syncRead() { return sharedData; }
    private synchronized void syncWrite(int v) { sharedData = v; }

    // ReentrantLock
    private final ReentrantLock reentrantLock = new ReentrantLock();
    private int lockRead() {
        reentrantLock.lock();
        try { return sharedData; } finally { reentrantLock.unlock(); }
    }
    private void lockWrite(int v) {
        reentrantLock.lock();
        try { sharedData = v; } finally { reentrantLock.unlock(); }
    }

    // ReadWriteLock
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private int rwRead() {
        rwLock.readLock().lock();
        try { return sharedData; } finally { rwLock.readLock().unlock(); }
    }
    private void rwWrite(int v) {
        rwLock.writeLock().lock();
        try { sharedData = v; } finally { rwLock.writeLock().unlock(); }
    }

    // StampedLock
    private final StampedLock stampedLock = new StampedLock();
    private int stampedRead() {
        long stamp = stampedLock.tryOptimisticRead();
        int value = sharedData;
        if (!stampedLock.validate(stamp)) {
            stamp = stampedLock.readLock();
            try { value = sharedData; } finally { stampedLock.unlockRead(stamp); }
        }
        return value;
    }
    private void stampedWrite(int v) {
        long stamp = stampedLock.writeLock();
        try { sharedData = v; } finally { stampedLock.unlockWrite(stamp); }
    }

    public long benchmark(String name,
                          Runnable readOp,
                          Runnable writeOp) throws InterruptedException {
        Thread[] threads = new Thread[READERS + WRITERS];
        long start = System.currentTimeMillis();

        // 读线程
        for (int i = 0; i < READERS; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < OPERATIONS; j++) readOp.run();
            });
        }
        // 写线程
        for (int i = 0; i < WRITERS; i++) {
            int idx = READERS + i;
            threads[idx] = new Thread(() -> {
                for (int j = 0; j < OPERATIONS / 10; j++) writeOp.run();
            });
        }

        for (Thread t : threads) t.start();
        for (Thread t : threads) t.join();

        long elapsed = System.currentTimeMillis() - start;
        System.out.println(name + ": " + elapsed + " ms");
        return elapsed;
    }

    public static void main(String[] args) throws InterruptedException {
        RWLockBenchmark bench = new RWLockBenchmark();

        System.out.println("=== 读多写少场景 (读:写 = 10:1) ===");
        bench.benchmark("synchronized",    bench::syncRead,    () -> bench.syncWrite(1));
        bench.benchmark("ReentrantLock",   bench::lockRead,    () -> bench.lockWrite(1));
        bench.benchmark("ReadWriteLock",   bench::rwRead,      () -> bench.rwWrite(1));
        bench.benchmark("StampedLock",     bench::stampedRead, () -> bench.stampedWrite(1));
    }
}

/*
 * 分析：
 * 1. 读多写少(100:1)时：StampedLock > ReadWriteLock > ReentrantLock ≈ synchronized
 *    - StampedLock的乐观读在无竞争时几乎无开销
 *    - ReadWriteLock允许读读并发
 *
 * 2. 读写均衡(1:1)时：ReentrantLock ≈ synchronized > ReadWriteLock > StampedLock
 *    - 读写锁的锁升级/降级有额外开销
 *    - 简单锁反而更高效
 */
```

---

## 场景三：线程协作/等待

### 题目 3.1 ⭐ CountDownLatch 基础使用

```java
import java.util.*;
import java.util.concurrent.*;

public class ParallelTaskExecutor {

    public List<String> executeAll(List<Callable<String>> tasks)
            throws InterruptedException {

        int taskCount = tasks.size();
        CountDownLatch latch = new CountDownLatch(taskCount);
        List<String> results = Collections.synchronizedList(new ArrayList<>());

        // 启动所有任务
        for (Callable<String> task : tasks) {
            new Thread(() -> {
                try {
                    String result = task.call();
                    results.add(result);
                } catch (Exception e) {
                    results.add("Error: " + e.getMessage());
                } finally {
                    latch.countDown(); // 任务完成，计数减1
                }
            }).start();
        }

        // 等待所有任务完成
        latch.await();

        return results;
    }

    public static void main(String[] args) throws InterruptedException {
        ParallelTaskExecutor executor = new ParallelTaskExecutor();

        List<Callable<String>> tasks = Arrays.asList(
            () -> { Thread.sleep(100); return "Task1完成"; },
            () -> { Thread.sleep(200); return "Task2完成"; },
            () -> { Thread.sleep(150); return "Task3完成"; }
        );

        long start = System.currentTimeMillis();
        List<String> results = executor.executeAll(tasks);
        long elapsed = System.currentTimeMillis() - start;

        System.out.println("结果: " + results);
        System.out.println("总耗时: " + elapsed + "ms (并行执行，约200ms)");
    }
}
```

---

### 题目 3.2 ⭐ CyclicBarrier 基础使用

```java
import java.util.Random;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

public class Race {
    private final int runnerCount;
    private final CyclicBarrier barrier;
    private final Random random = new Random();

    public Race(int runnerCount) {
        this.runnerCount = runnerCount;
        // 所有选手到达后执行的动作
        this.barrier = new CyclicBarrier(runnerCount,
            () -> System.out.println("\n>>> 所有选手准备就绪，比赛开始！<<<\n"));
    }

    public void start() {
        for (int i = 0; i < runnerCount; i++) {
            int runnerId = i + 1;
            new Thread(() -> {
                try {
                    // 1. 准备阶段（随机时间）
                    int prepareTime = random.nextInt(1000);
                    System.out.println("选手" + runnerId + " 正在热身...");
                    Thread.sleep(prepareTime);

                    // 2. 到达起跑线，等待其他选手
                    System.out.println("选手" + runnerId + " 已到达起跑线");
                    barrier.await(); // 等待所有人就绪

                    // 3. 所有人就绪后，开始跑步
                    int runTime = random.nextInt(2000) + 1000;
                    System.out.println("选手" + runnerId + " 开始冲刺！");
                    Thread.sleep(runTime);

                    // 4. 到达终点
                    System.out.println("选手" + runnerId + " 到达终点！用时: " + runTime + "ms");

                } catch (InterruptedException | BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }, "Runner-" + runnerId).start();
        }
    }

    public static void main(String[] args) {
        Race race = new Race(5);
        race.start();
    }
}
```

---

### 题目 3.3 ⭐ Semaphore 基础使用

```java
import java.util.LinkedList;
import java.util.Queue;
import java.util.concurrent.Semaphore;

public class ConnectionPool {
    private final Semaphore semaphore;
    private final Queue<Connection> pool;

    public ConnectionPool(int size) {
        this.semaphore = new Semaphore(size);
        this.pool = new LinkedList<>();

        // 初始化连接
        for (int i = 0; i < size; i++) {
            pool.offer(new Connection("Connection-" + i));
        }
    }

    public Connection acquire() throws InterruptedException {
        semaphore.acquire(); // 获取许可，如果没有则阻塞
        synchronized (pool) {
            return pool.poll();
        }
    }

    public void release(Connection conn) {
        synchronized (pool) {
            pool.offer(conn);
        }
        semaphore.release(); // 释放许可
    }

    public int availableConnections() {
        return semaphore.availablePermits();
    }

    // 模拟连接类
    static class Connection {
        private final String name;

        Connection(String name) {
            this.name = name;
        }

        public void execute(String sql) {
            System.out.println(name + " 执行: " + sql);
        }

        @Override
        public String toString() {
            return name;
        }
    }

    public static void main(String[] args) {
        ConnectionPool pool = new ConnectionPool(3); // 最多3个连接

        // 创建10个线程同时请求连接
        for (int i = 0; i < 10; i++) {
            int taskId = i;
            new Thread(() -> {
                try {
                    System.out.println("任务" + taskId + " 请求连接...");
                    Connection conn = pool.acquire();
                    System.out.println("任务" + taskId + " 获得 " + conn);

                    // 使用连接
                    Thread.sleep(1000);

                    pool.release(conn);
                    System.out.println("任务" + taskId + " 释放 " + conn);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

---

### 题目 3.4 ⭐⭐ Exchanger 数据交换

```java
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Exchanger;

public class DataExchanger {
    private final Exchanger<List<String>> exchanger = new Exchanger<>();
    private volatile boolean running = true;

    // 生产者：填充数据后交换空列表
    public void producer() {
        List<String> buffer = new ArrayList<>();
        int count = 0;
        try {
            while (running && count < 5) { // 生产5批
                // 填充数据到buffer
                buffer.clear();
                for (int i = 0; i < 5; i++) {
                    buffer.add("数据-" + count + "-" + i);
                }
                System.out.println("[生产者] 生产了: " + buffer);

                // 交换：把满的buffer换成空的
                buffer = exchanger.exchange(buffer);
                System.out.println("[生产者] 交换后得到空buffer, size=" + buffer.size());
                count++;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        System.out.println("[生产者] 结束");
    }

    // 消费者：处理数据后交换空列表
    public void consumer() {
        List<String> buffer = new ArrayList<>();
        int count = 0;
        try {
            while (running && count < 5) { // 消费5批
                // 交换：把空的buffer换成满的
                buffer = exchanger.exchange(buffer);
                System.out.println("[消费者] 收到数据: " + buffer);

                // 处理数据
                for (String data : buffer) {
                    process(data);
                }
                buffer.clear(); // 清空准备下次交换
                count++;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        System.out.println("[消费者] 结束");
    }

    private void process(String data) {
        // 模拟处理
    }

    public void stop() {
        running = false;
    }

    public static void main(String[] args) throws InterruptedException {
        DataExchanger exchanger = new DataExchanger();

        Thread producer = new Thread(exchanger::producer, "Producer");
        Thread consumer = new Thread(exchanger::consumer, "Consumer");

        producer.start();
        consumer.start();

        producer.join();
        consumer.join();
    }
}
```

---

### 题目 3.5 ⭐⭐ CountDownLatch 超时等待

```java
import java.util.*;
import java.util.concurrent.*;

public class TimeoutTaskExecutor {

    public Map<String, Object> executeWithTimeout(
            Map<String, Callable<?>> tasks,
            long timeout,
            TimeUnit unit) throws InterruptedException {

        Map<String, Object> results = new ConcurrentHashMap<>();
        CountDownLatch latch = new CountDownLatch(tasks.size());

        // 1. 启动所有任务
        for (Map.Entry<String, Callable<?>> entry : tasks.entrySet()) {
            String taskName = entry.getKey();
            Callable<?> task = entry.getValue();

            new Thread(() -> {
                try {
                    Object result = task.call();
                    results.put(taskName, result);
                } catch (Exception e) {
                    results.put(taskName, "ERROR: " + e.getMessage());
                } finally {
                    latch.countDown();
                }
            }, taskName).start();
        }

        // 2. 带超时等待
        boolean allCompleted = latch.await(timeout, unit);

        // 3. 检查哪些任务没完成
        if (!allCompleted) {
            for (String taskName : tasks.keySet()) {
                if (!results.containsKey(taskName)) {
                    results.put(taskName, "TIMEOUT");
                }
            }
        }

        return results;
    }

    public static void main(String[] args) throws InterruptedException {
        TimeoutTaskExecutor executor = new TimeoutTaskExecutor();

        Map<String, Callable<?>> tasks = new HashMap<>();
        tasks.put("快速任务", () -> { Thread.sleep(100); return "快速完成"; });
        tasks.put("中速任务", () -> { Thread.sleep(300); return "中速完成"; });
        tasks.put("慢速任务", () -> { Thread.sleep(2000); return "慢速完成"; }); // 会超时

        Map<String, Object> results = executor.executeWithTimeout(
            tasks, 500, TimeUnit.MILLISECONDS);

        System.out.println("执行结果:");
        results.forEach((name, result) ->
            System.out.println("  " + name + ": " + result));
    }
}
```

---

## 场景四：资源池/限流

### 题目 4.1 ⭐ Semaphore 实现简单限流

```java
import java.util.concurrent.*;

public class RateLimiter {
    private final Semaphore semaphore;

    public RateLimiter(int maxConcurrent) {
        this.semaphore = new Semaphore(maxConcurrent);
    }

    public <T> T execute(Callable<T> task) throws Exception {
        semaphore.acquire(); // 获取许可
        try {
            return task.call(); // 执行任务
        } finally {
            semaphore.release(); // 释放许可
        }
    }

    public <T> T tryExecute(Callable<T> task, long timeout, TimeUnit unit)
            throws Exception {
        if (semaphore.tryAcquire(timeout, unit)) {
            try {
                return task.call();
            } finally {
                semaphore.release();
            }
        } else {
            throw new TimeoutException("获取许可超时");
        }
    }

    public static void main(String[] args) {
        RateLimiter limiter = new RateLimiter(3); // 最多3个并发

        // 启动10个任务
        for (int i = 0; i < 10; i++) {
            int taskId = i;
            new Thread(() -> {
                try {
                    String result = limiter.execute(() -> {
                        System.out.println("任务" + taskId + " 开始执行");
                        Thread.sleep(1000);
                        return "任务" + taskId + " 完成";
                    });
                    System.out.println(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

---

### 题目 4.2 ⭐ 公平与非公平信号量

```java
import java.util.concurrent.Semaphore;

public class SemaphoreFairnessDemo {

    public static void testUnfair() throws InterruptedException {
        System.out.println("=== 非公平信号量 ===");
        Semaphore unfairSem = new Semaphore(1, false); // 非公平

        for (int i = 0; i < 5; i++) {
            int id = i;
            new Thread(() -> {
                try {
                    System.out.println("线程" + id + " 尝试获取");
                    unfairSem.acquire();
                    System.out.println("线程" + id + " 获取成功");
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    unfairSem.release();
                }
            }, "Thread-" + i).start();
            Thread.sleep(10); // 让线程按顺序启动
        }
    }

    public static void testFair() throws InterruptedException {
        System.out.println("\n=== 公平信号量 ===");
        Semaphore fairSem = new Semaphore(1, true); // 公平

        for (int i = 0; i < 5; i++) {
            int id = i;
            new Thread(() -> {
                try {
                    System.out.println("线程" + id + " 尝试获取");
                    fairSem.acquire();
                    System.out.println("线程" + id + " 获取成功");
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    fairSem.release();
                }
            }, "Thread-" + i).start();
            Thread.sleep(10);
        }
    }

    public static void main(String[] args) throws InterruptedException {
        testUnfair();
        Thread.sleep(2000);
        testFair();
    }
}

/*
 * 公平信号量的性能代价：
 * 1. 需要维护FIFO队列，额外内存开销
 * 2. 线程上下文切换更频繁（必须唤醒队首线程）
 * 3. 吞吐量降低约10-30%
 *
 * 必须使用公平信号量的场景：
 * 1. 需要保证处理顺序（如排队系统）
 * 2. 防止线程饥饿
 * 3. 有严格的响应时间要求（避免无限等待）
 */
```

---

### 题目 4.3 ⭐ Semaphore 实现对象池

```java
import java.util.concurrent.*;
import java.util.function.Supplier;

public class ObjectPool<T> {
    private final Semaphore semaphore;
    private final BlockingQueue<T> pool;

    public ObjectPool(Supplier<T> factory, int size) {
        this.semaphore = new Semaphore(size);
        this.pool = new LinkedBlockingQueue<>();

        // 初始化对象
        for (int i = 0; i < size; i++) {
            pool.offer(factory.get());
        }
    }

    public T borrow() throws InterruptedException {
        semaphore.acquire(); // 获取许可
        return pool.poll();  // 获取对象（此时一定有对象）
    }

    public T borrow(long timeout, TimeUnit unit) throws InterruptedException {
        if (semaphore.tryAcquire(timeout, unit)) {
            return pool.poll();
        }
        return null; // 超时
    }

    public void returnObject(T obj) {
        if (obj != null) {
            pool.offer(obj);     // 归还对象
            semaphore.release(); // 释放许可
        }
    }

    public int available() {
        return semaphore.availablePermits();
    }

    public static void main(String[] args) throws InterruptedException {
        // 创建一个StringBuilder对象池
        ObjectPool<StringBuilder> pool = new ObjectPool<>(
            () -> new StringBuilder(100), 3);

        System.out.println("可用对象数: " + pool.available());

        // 模拟多线程使用
        for (int i = 0; i < 5; i++) {
            int taskId = i;
            new Thread(() -> {
                try {
                    StringBuilder sb = pool.borrow();
                    System.out.println("任务" + taskId + " 借用对象");

                    sb.append("Hello from task ").append(taskId);
                    Thread.sleep(500);

                    sb.setLength(0); // 重置
                    pool.returnObject(sb);
                    System.out.println("任务" + taskId + " 归还对象");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

---

### 题目 4.4 ⭐⭐ 滑动窗口限流器

```java
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicInteger;

public class SlidingWindowRateLimiter {
    private final int maxRequests;
    private final long windowSizeMs;
    private final ConcurrentLinkedQueue<Long> requestTimestamps;
    private final AtomicInteger counter;

    public SlidingWindowRateLimiter(int maxRequests, long windowSizeMs) {
        this.maxRequests = maxRequests;
        this.windowSizeMs = windowSizeMs;
        this.requestTimestamps = new ConcurrentLinkedQueue<>();
        this.counter = new AtomicInteger(0);
    }

    public synchronized boolean tryAcquire() {
        long now = System.currentTimeMillis();
        long windowStart = now - windowSizeMs;

        // 移除窗口外的旧请求
        while (!requestTimestamps.isEmpty() &&
               requestTimestamps.peek() < windowStart) {
            requestTimestamps.poll();
            counter.decrementAndGet();
        }

        // 检查当前窗口内的请求数
        if (counter.get() < maxRequests) {
            requestTimestamps.offer(now);
            counter.incrementAndGet();
            return true;
        }

        return false; // 超出限制
    }

    public int getCurrentCount() {
        return counter.get();
    }

    public static void main(String[] args) throws InterruptedException {
        // 每秒最多5个请求
        SlidingWindowRateLimiter limiter = new SlidingWindowRateLimiter(5, 1000);

        // 快速发送10个请求
        for (int i = 0; i < 10; i++) {
            boolean allowed = limiter.tryAcquire();
            System.out.println("请求" + i + ": " + (allowed ? "通过" : "拒绝") +
                              " (当前计数: " + limiter.getCurrentCount() + ")");
            Thread.sleep(100);
        }

        System.out.println("\n等待1秒后...\n");
        Thread.sleep(1000);

        // 再发送5个请求
        for (int i = 10; i < 15; i++) {
            boolean allowed = limiter.tryAcquire();
            System.out.println("请求" + i + ": " + (allowed ? "通过" : "拒绝"));
        }
    }
}
```

---

### 题目 4.5 ⭐⭐ 令牌桶限流器

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public class TokenBucketRateLimiter {
    private final int capacity;           // 桶容量
    private final AtomicInteger tokens;   // 当前令牌数
    private final ScheduledExecutorService scheduler;

    public TokenBucketRateLimiter(int capacity, int refillRate) {
        this.capacity = capacity;
        this.tokens = new AtomicInteger(capacity); // 初始填满

        // 定期补充令牌
        this.scheduler = Executors.newSingleThreadScheduledExecutor();
        long intervalMs = 1000 / refillRate; // 每隔多少毫秒补充一个
        scheduler.scheduleAtFixedRate(this::refill, intervalMs, intervalMs,
                                       TimeUnit.MILLISECONDS);
    }

    private void refill() {
        int current = tokens.get();
        if (current < capacity) {
            tokens.compareAndSet(current, current + 1);
        }
    }

    public boolean tryAcquire() {
        return tryAcquire(1);
    }

    public boolean tryAcquire(int permits) {
        while (true) {
            int current = tokens.get();
            if (current < permits) {
                return false; // 令牌不足
            }
            if (tokens.compareAndSet(current, current - permits)) {
                return true;
            }
            // CAS失败，重试
        }
    }

    public void acquire() throws InterruptedException {
        while (!tryAcquire()) {
            Thread.sleep(10); // 等待令牌
        }
    }

    public int availableTokens() {
        return tokens.get();
    }

    public void shutdown() {
        scheduler.shutdown();
    }

    public static void main(String[] args) throws InterruptedException {
        // 容量10，每秒补充5个令牌
        TokenBucketRateLimiter limiter = new TokenBucketRateLimiter(10, 5);

        System.out.println("初始令牌数: " + limiter.availableTokens());

        // 快速消耗所有令牌
        for (int i = 0; i < 12; i++) {
            boolean success = limiter.tryAcquire();
            System.out.println("请求" + i + ": " + (success ? "成功" : "失败") +
                              " (剩余令牌: " + limiter.availableTokens() + ")");
        }

        System.out.println("\n等待2秒让令牌恢复...\n");
        Thread.sleep(2000);

        System.out.println("恢复后令牌数: " + limiter.availableTokens());

        for (int i = 0; i < 5; i++) {
            boolean success = limiter.tryAcquire();
            System.out.println("请求: " + (success ? "成功" : "失败"));
        }

        limiter.shutdown();
    }
}
```

---

## 场景五：生产者-消费者

### 题目 5.1 ⭐ ArrayBlockingQueue 基础使用

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public class ProducerConsumer {
    private final BlockingQueue<String> queue = new ArrayBlockingQueue<>(10);
    private final AtomicInteger producedCount = new AtomicInteger(0);
    private final AtomicInteger consumedCount = new AtomicInteger(0);
    private volatile boolean running = true;

    public void produce(String item) throws InterruptedException {
        queue.put(item); // 队列满则阻塞
        producedCount.incrementAndGet();
    }

    public String consume() throws InterruptedException {
        String item = queue.take(); // 队列空则阻塞
        consumedCount.incrementAndGet();
        return item;
    }

    public void stop() {
        running = false;
    }

    public static void main(String[] args) throws InterruptedException {
        ProducerConsumer pc = new ProducerConsumer();
        int totalItems = 100;

        // 3个生产者
        Thread[] producers = new Thread[3];
        for (int i = 0; i < 3; i++) {
            int producerId = i;
            producers[i] = new Thread(() -> {
                try {
                    for (int j = 0; j < totalItems / 3; j++) {
                        pc.produce("P" + producerId + "-Item" + j);
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }, "Producer-" + i);
            producers[i].start();
        }

        // 2个消费者
        Thread[] consumers = new Thread[2];
        for (int i = 0; i < 2; i++) {
            consumers[i] = new Thread(() -> {
                try {
                    while (pc.running || !pc.queue.isEmpty()) {
                        String item = pc.queue.poll(100, TimeUnit.MILLISECONDS);
                        if (item != null) {
                            pc.consumedCount.incrementAndGet();
                        }
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }, "Consumer-" + i);
            consumers[i].start();
        }

        // 等待生产者完成
        for (Thread p : producers) p.join();

        // 给消费者时间处理剩余数据
        Thread.sleep(500);
        pc.stop();

        // 等待消费者完成
        for (Thread c : consumers) c.join();

        System.out.println("生产数量: " + pc.producedCount.get());
        System.out.println("消费数量: " + pc.consumedCount.get());
        System.out.println("队列剩余: " + pc.queue.size());
    }
}
```

---

### 题目 5.2 ⭐ LinkedBlockingQueue vs ArrayBlockingQueue

```java
import java.util.concurrent.*;

public class QueueComparison {
    private static final int PRODUCERS = 4;
    private static final int CONSUMERS = 4;
    private static final int ITEMS_PER_PRODUCER = 100000;

    public static long testQueue(BlockingQueue<Integer> queue, String name)
            throws InterruptedException {

        Thread[] producers = new Thread[PRODUCERS];
        Thread[] consumers = new Thread[CONSUMERS];

        long start = System.currentTimeMillis();

        // 生产者
        for (int i = 0; i < PRODUCERS; i++) {
            producers[i] = new Thread(() -> {
                try {
                    for (int j = 0; j < ITEMS_PER_PRODUCER; j++) {
                        queue.put(j);
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            producers[i].start();
        }

        // 消费者
        for (int i = 0; i < CONSUMERS; i++) {
            consumers[i] = new Thread(() -> {
                try {
                    for (int j = 0; j < ITEMS_PER_PRODUCER; j++) {
                        queue.take();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
            consumers[i].start();
        }

        for (Thread p : producers) p.join();
        for (Thread c : consumers) c.join();

        long elapsed = System.currentTimeMillis() - start;
        System.out.println(name + ": " + elapsed + " ms");
        return elapsed;
    }

    public static void main(String[] args) throws InterruptedException {
        // 预热
        testQueue(new ArrayBlockingQueue<>(1000), "预热");

        System.out.println("\n=== 正式测试 ===");
        testQueue(new ArrayBlockingQueue<>(1000), "ArrayBlockingQueue");
        testQueue(new LinkedBlockingQueue<>(1000), "LinkedBlockingQueue");
    }
}

/*
 * 分析：
 *
 * 1. 为什么LinkedBlockingQueue在某些场景性能更好？
 *    - ArrayBlockingQueue: 使用单个锁（put和take共用）
 *    - LinkedBlockingQueue: 使用两把锁（putLock和takeLock分离）
 *    - 生产和消费可以并行，减少锁竞争
 *
 * 2. 什么场景应该选择ArrayBlockingQueue？
 *    - 需要严格控制内存（数组预分配，无GC压力）
 *    - 队列较小时（锁竞争不激烈）
 *    - 需要公平性时（ArrayBlockingQueue支持公平锁）
 */
```

---

### 题目 5.3 ⭐ PriorityBlockingQueue 使用

```java
import java.util.concurrent.PriorityBlockingQueue;

public class PriorityTaskProcessor {
    private final PriorityBlockingQueue<Task> queue = new PriorityBlockingQueue<>();
    private volatile boolean running = true;

    static class Task implements Comparable<Task> {
        final int priority; // 数字越小优先级越高
        final String name;
        final long createTime;

        Task(int priority, String name) {
            this.priority = priority;
            this.name = name;
            this.createTime = System.nanoTime();
        }

        @Override
        public int compareTo(Task other) {
            // 先比较优先级
            int cmp = Integer.compare(this.priority, other.priority);
            if (cmp != 0) return cmp;
            // 优先级相同，先来的先处理
            return Long.compare(this.createTime, other.createTime);
        }

        @Override
        public String toString() {
            return String.format("Task[%s, priority=%d]", name, priority);
        }
    }

    public void submit(Task task) {
        queue.put(task);
        System.out.println("提交: " + task);
    }

    public void process() {
        while (running) {
            try {
                Task task = queue.poll(100, java.util.concurrent.TimeUnit.MILLISECONDS);
                if (task != null) {
                    System.out.println("处理: " + task);
                    Thread.sleep(100); // 模拟处理时间
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    public void stop() {
        running = false;
    }

    public static void main(String[] args) throws InterruptedException {
        PriorityTaskProcessor processor = new PriorityTaskProcessor();

        // 启动处理线程
        Thread processorThread = new Thread(processor::process);
        processorThread.start();

        // 提交不同优先级的任务
        processor.submit(new Task(5, "低优先级任务1"));
        processor.submit(new Task(1, "高优先级任务1"));
        processor.submit(new Task(3, "中优先级任务1"));
        processor.submit(new Task(1, "高优先级任务2"));
        processor.submit(new Task(5, "低优先级任务2"));

        Thread.sleep(1000);
        processor.stop();
        processorThread.join();
    }
}
```

---

### 题目 5.4 ⭐⭐ DelayQueue 实现延迟任务

```java
import java.util.concurrent.*;

public class DelayedTaskScheduler {
    private final DelayQueue<DelayedTask> queue = new DelayQueue<>();
    private volatile boolean running = true;

    static class DelayedTask implements Delayed {
        private final long executeTime; // 执行时间（绝对时间）
        private final Runnable task;
        private final String name;

        DelayedTask(Runnable task, String name, long delayMs) {
            this.task = task;
            this.name = name;
            this.executeTime = System.currentTimeMillis() + delayMs;
        }

        @Override
        public long getDelay(TimeUnit unit) {
            long remaining = executeTime - System.currentTimeMillis();
            return unit.convert(remaining, TimeUnit.MILLISECONDS);
        }

        @Override
        public int compareTo(Delayed other) {
            return Long.compare(this.executeTime,
                               ((DelayedTask) other).executeTime);
        }

        public void run() {
            System.out.println("[" + System.currentTimeMillis() + "] 执行: " + name);
            task.run();
        }
    }

    public void schedule(Runnable task, String name, long delayMs) {
        queue.put(new DelayedTask(task, name, delayMs));
        System.out.println("[" + System.currentTimeMillis() + "] 调度: " + name +
                          " (延迟" + delayMs + "ms)");
    }

    public void start() {
        new Thread(() -> {
            while (running) {
                try {
                    DelayedTask task = queue.poll(100, TimeUnit.MILLISECONDS);
                    if (task != null) {
                        task.run();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }, "Scheduler").start();
    }

    public void stop() {
        running = false;
    }

    public static void main(String[] args) throws InterruptedException {
        DelayedTaskScheduler scheduler = new DelayedTaskScheduler();
        scheduler.start();

        // 调度多个延迟任务
        scheduler.schedule(() -> System.out.println("  -> 任务A执行完毕"),
                          "任务A", 3000);
        scheduler.schedule(() -> System.out.println("  -> 任务B执行完毕"),
                          "任务B", 1000);
        scheduler.schedule(() -> System.out.println("  -> 任务C执行完毕"),
                          "任务C", 2000);

        Thread.sleep(5000);
        scheduler.stop();
    }
}
```

---

### 题目 5.5 ⭐⭐ SynchronousQueue 直接传递

```java
import java.util.concurrent.*;

public class DirectHandoff {
    private final SynchronousQueue<String> queue = new SynchronousQueue<>();

    // 生产者必须等到消费者来取
    public void produce(String item) throws InterruptedException {
        System.out.println(Thread.currentThread().getName() +
                          " 准备传递: " + item);
        queue.put(item); // 阻塞直到有消费者取走
        System.out.println(Thread.currentThread().getName() +
                          " 传递完成: " + item);
    }

    // 消费者必须等到生产者放入
    public String consume() throws InterruptedException {
        System.out.println(Thread.currentThread().getName() + " 等待接收...");
        String item = queue.take(); // 阻塞直到有生产者放入
        System.out.println(Thread.currentThread().getName() +
                          " 收到: " + item);
        return item;
    }

    public static void main(String[] args) {
        DirectHandoff handoff = new DirectHandoff();

        // 生产者线程
        new Thread(() -> {
            try {
                for (int i = 0; i < 3; i++) {
                    handoff.produce("Item-" + i);
                    Thread.sleep(100);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "Producer").start();

        // 消费者线程（延迟启动）
        new Thread(() -> {
            try {
                Thread.sleep(500); // 延迟启动，让生产者先阻塞
                for (int i = 0; i < 3; i++) {
                    handoff.consume();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "Consumer").start();
    }
}

/*
 * 思考题答案：
 *
 * 1. SynchronousQueue的容量是多少？
 *    容量是0！它不存储任何元素，只是一个"传递"通道。
 *
 * 2. CachedThreadPool为什么使用SynchronousQueue？
 *    - 任务提交时，如果有空闲线程，直接交给它执行
 *    - 如果没有空闲线程，SynchronousQueue.offer()会失败
 *    - 失败后会创建新线程
 *    - 这实现了"有空闲用空闲，没空闲就创建"的策略
 */
```

---

## 场景六：缓存/共享Map

### 题目 6.1 ⭐ ConcurrentHashMap 基础使用

```java
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

public class WordCounter {
    private final ConcurrentHashMap<String, AtomicInteger> wordCounts =
        new ConcurrentHashMap<>();

    public void count(String word) {
        // 方法1：使用computeIfAbsent
        wordCounts.computeIfAbsent(word, k -> new AtomicInteger(0))
                  .incrementAndGet();
    }

    public int getCount(String word) {
        AtomicInteger count = wordCounts.get(word);
        return count != null ? count.get() : 0;
    }

    public void printAll() {
        wordCounts.forEach((word, count) ->
            System.out.println(word + ": " + count.get()));
    }

    public static void main(String[] args) throws InterruptedException {
        WordCounter counter = new WordCounter();
        String text = "hello world hello java world hello";
        String[] words = text.split(" ");

        // 多线程并发统计
        Thread[] threads = new Thread[4];
        for (int i = 0; i < 4; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    for (String word : words) {
                        counter.count(word);
                    }
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();

        System.out.println("统计结果:");
        counter.printAll();
        // hello: 12000 (4线程 * 1000次 * 3个hello)
        // world: 8000
        // java: 4000
    }
}
```

---

### 题目 6.2 ⭐ computeIfAbsent 使用

```java
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;

public class LazyCache<K, V> {
    private final ConcurrentHashMap<K, V> cache = new ConcurrentHashMap<>();
    private final Function<K, V> loader;

    public LazyCache(Function<K, V> loader) {
        this.loader = loader;
    }

    public V get(K key) {
        // computeIfAbsent: 如果key不存在，用loader计算值并存入
        // 这是原子操作，保证loader只执行一次
        return cache.computeIfAbsent(key, loader);
    }

    public void invalidate(K key) {
        cache.remove(key);
    }

    public int size() {
        return cache.size();
    }

    public static void main(String[] args) throws InterruptedException {
        // 模拟昂贵的数据加载
        LazyCache<String, String> cache = new LazyCache<>(key -> {
            System.out.println("加载数据: " + key + " (线程: " +
                              Thread.currentThread().getName() + ")");
            try {
                Thread.sleep(100); // 模拟耗时操作
            } catch (InterruptedException e) {}
            return "Value-" + key;
        });

        // 多线程同时请求同一个key
        Thread[] threads = new Thread[5];
        for (int i = 0; i < 5; i++) {
            threads[i] = new Thread(() -> {
                String value = cache.get("key1");
                System.out.println(Thread.currentThread().getName() +
                                  " 获得: " + value);
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();
        // 只会看到一次"加载数据"，说明loader只执行了一次
    }
}

/*
 * 思考题答案：
 *
 * computeIfAbsent的计算函数中能否调用同一个Map的其他方法？
 *
 * 不推荐！可能导致死锁或数据不一致。
 *
 * 例如：
 * map.computeIfAbsent("a", k -> {
 *     map.computeIfAbsent("b", ...);  // 可能死锁！
 *     return "value";
 * });
 *
 * 因为computeIfAbsent会锁定某些桶，如果在计算函数中访问其他桶，
 * 可能导致锁的嵌套获取，从而死锁。
 *
 * 官方文档明确警告：mapping function不应该修改这个map！
 */
```

---

### 题目 6.3 ⭐ ConcurrentSkipListMap 使用

```java
import java.util.*;
import java.util.concurrent.ConcurrentSkipListMap;

public class Leaderboard {
    // 分数(取反便于降序) -> 用户集合
    private final ConcurrentSkipListMap<Integer, Set<String>> scoreBoard =
        new ConcurrentSkipListMap<>();

    // 用户 -> 分数（用于快速查找用户当前分数）
    private final Map<String, Integer> userScores =
        new ConcurrentHashMap<>();

    public void updateScore(String userId, int newScore) {
        // 1. 获取旧分数并移除
        Integer oldScore = userScores.put(userId, newScore);
        if (oldScore != null) {
            Set<String> users = scoreBoard.get(-oldScore);
            if (users != null) {
                users.remove(userId);
                if (users.isEmpty()) {
                    scoreBoard.remove(-oldScore);
                }
            }
        }

        // 2. 添加到新分数组（使用负数实现降序）
        scoreBoard.computeIfAbsent(-newScore,
            k -> Collections.newSetFromMap(new ConcurrentHashMap<>()))
            .add(userId);
    }

    public List<String> getTopN(int n) {
        List<String> result = new ArrayList<>();

        for (Map.Entry<Integer, Set<String>> entry : scoreBoard.entrySet()) {
            for (String userId : entry.getValue()) {
                result.add(userId + ": " + (-entry.getKey()));
                if (result.size() >= n) {
                    return result;
                }
            }
        }

        return result;
    }

    public int getScore(String userId) {
        return userScores.getOrDefault(userId, 0);
    }

    public static void main(String[] args) {
        Leaderboard board = new Leaderboard();

        // 更新分数
        board.updateScore("Alice", 100);
        board.updateScore("Bob", 150);
        board.updateScore("Charlie", 120);
        board.updateScore("David", 150); // 与Bob同分
        board.updateScore("Alice", 200); // Alice分数更新

        System.out.println("Top 5:");
        for (String entry : board.getTopN(5)) {
            System.out.println("  " + entry);
        }
    }
}
```

---

### 题目 6.4 ⭐⭐ ConcurrentHashMap 复合操作

```java
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class AtomicMapOperations {
    private final ConcurrentHashMap<String, Integer> intMap =
        new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, List<String>> listMap =
        new ConcurrentHashMap<>();

    // 原子地增加值
    public int addAndGet(String key, int delta) {
        return intMap.merge(key, delta, Integer::sum);
        // merge: 如果key不存在，设为delta
        //        如果key存在，用Integer::sum计算新值
    }

    // 原子地设置最大值
    public int setMax(String key, int value) {
        return intMap.merge(key, value, Math::max);
        // 如果新值大于旧值，更新；否则保持不变
    }

    // 原子地设置最小值
    public int setMin(String key, int value) {
        return intMap.merge(key, value, Math::min);
    }

    // 原子地追加到列表
    public void appendToList(String key, String item) {
        listMap.compute(key, (k, v) -> {
            if (v == null) {
                v = new ArrayList<>();
            }
            v.add(item);
            return v;
        });
    }

    // 原子地从列表移除
    public boolean removeFromList(String key, String item) {
        boolean[] removed = {false};
        listMap.computeIfPresent(key, (k, v) -> {
            removed[0] = v.remove(item);
            return v.isEmpty() ? null : v; // 空列表则删除key
        });
        return removed[0];
    }

    public static void main(String[] args) throws InterruptedException {
        AtomicMapOperations ops = new AtomicMapOperations();

        // 测试原子累加
        Thread[] threads = new Thread[10];
        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    ops.addAndGet("counter", 1);
                }
            });
            threads[i].start();
        }
        for (Thread t : threads) t.join();
        System.out.println("counter = " + ops.intMap.get("counter")); // 10000

        // 测试原子设置最大值
        for (int i = 0; i < 10; i++) {
            final int val = i * 10;
            new Thread(() -> ops.setMax("max", val)).start();
        }
        Thread.sleep(100);
        System.out.println("max = " + ops.intMap.get("max")); // 90

        // 测试原子追加列表
        ops.appendToList("tags", "java");
        ops.appendToList("tags", "concurrent");
        ops.appendToList("tags", "map");
        System.out.println("tags = " + ops.listMap.get("tags"));
    }
}
```

---

### 题目 6.5 ⭐⭐ 并发Map的遍历

```java
import java.util.concurrent.ConcurrentHashMap;

public class ConcurrentMapIteration {

    public static void demonstrateWeakConsistency() throws InterruptedException {
        ConcurrentHashMap<Integer, String> map = new ConcurrentHashMap<>();

        // 初始化数据
        for (int i = 0; i < 10; i++) {
            map.put(i, "value" + i);
        }

        // 写线程：不断修改map
        Thread writer = new Thread(() -> {
            for (int i = 10; i < 20; i++) {
                map.put(i, "new-value" + i);
                try { Thread.sleep(10); } catch (InterruptedException e) {}
            }
            // 删除一些旧key
            for (int i = 0; i < 5; i++) {
                map.remove(i);
            }
        }, "Writer");

        // 读线程：遍历map
        Thread reader = new Thread(() -> {
            System.out.println("开始遍历:");
            for (Integer key : map.keySet()) {
                String value = map.get(key);
                System.out.println("  key=" + key + ", value=" + value);
                try { Thread.sleep(20); } catch (InterruptedException e) {}
            }
            System.out.println("遍历结束");
        }, "Reader");

        writer.start();
        reader.start();

        writer.join();
        reader.join();

        System.out.println("\n最终map大小: " + map.size());
        System.out.println("最终map: " + map);
    }

    public static void main(String[] args) throws InterruptedException {
        demonstrateWeakConsistency();
    }
}

/*
 * 思考题答案：
 *
 * 1. 遍历过程中修改Map会抛出ConcurrentModificationException吗？
 *    不会！ConcurrentHashMap的迭代器是弱一致性的，不会抛出CME。
 *
 * 2. 遍历能保证看到开始遍历时的所有元素吗？
 *    不能保证！这就是"弱一致性"的含义：
 *    - 可能看到遍历开始后新增的元素
 *    - 可能看不到遍历开始后删除的元素
 *    - 对于某个key，get()可能返回null（被删除了）
 *
 *    如果需要一致性快照，应该：
 *    - 加锁遍历（性能差）
 *    - 使用Collections.unmodifiableMap(new HashMap<>(concurrentMap))复制
 */
```

---

## 场景七：异步任务编排

### 题目 7.1 ⭐ CompletableFuture 基础使用

```java
import java.util.concurrent.*;

public class AsyncBasics {

    public CompletableFuture<String> fetchUserAsync(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            // 模拟网络请求
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "User: " + userId;
        });
    }

    public void chainedOperations() {
        CompletableFuture.supplyAsync(() -> {
                    System.out.println("步骤1: 获取数据");
                    return "Hello";
                })
                .thenApply(s -> {
                    System.out.println("步骤2: 转换数据");
                    return s + " World";
                })
                .thenApply(s -> {
                    System.out.println("步骤3: 再次转换");
                    return s + "!";
                })
                .thenAccept(result -> {
                    System.out.println("步骤4: 最终结果: " + result);
                })
                .join(); // 等待完成
    }

    public static void main(String[] args) {
        AsyncBasics basics = new AsyncBasics();

        // 测试异步获取
        System.out.println("=== 异步获取用户 ===");
        CompletableFuture<String> future = basics.fetchUserAsync("123");
        System.out.println("请求已发出，继续其他工作...");
        String result = future.join();
        System.out.println("结果: " + result);

        // 测试链式操作
        System.out.println("\n=== 链式操作 ===");
        basics.chainedOperations();
    }
}
```

---

### 题目 7.2 ⭐ 异常处理

```java
import java.util.concurrent.*;

public class AsyncExceptionHandling {

    // 模拟可能失败的网络请求
    private String fetchFromUrl(String url) {
        if (url.contains("error")) {
            throw new RuntimeException("网络错误: " + url);
        }
        return "数据来自: " + url;
    }

    // 使用exceptionally处理异常
    public CompletableFuture<String> fetchWithFallback(String url) {
        return CompletableFuture.supplyAsync(() -> fetchFromUrl(url))
                .exceptionally(ex -> {
                    System.out.println("发生异常: " + ex.getMessage());
                    return "默认值";
                });
    }

    // 使用handle处理（无论成功或失败）
    public CompletableFuture<String> fetchWithHandle(String url) {
        return CompletableFuture.supplyAsync(() -> fetchFromUrl(url))
                .handle((result, ex) -> {
                    if (ex != null) {
                        System.out.println("Handle捕获异常: " + ex.getMessage());
                        return "Error: " + ex.getCause().getMessage();
                    }
                    return "Success: " + result;
                });
    }

    // 使用whenComplete（不改变结果，只做副作用）
    public CompletableFuture<String> fetchWithWhenComplete(String url) {
        return CompletableFuture.supplyAsync(() -> fetchFromUrl(url))
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        System.out.println("WhenComplete记录异常: " + ex.getMessage());
                        // 注意：whenComplete不改变结果，异常会继续传播
                    } else {
                        System.out.println("WhenComplete记录成功: " + result);
                    }
                });
    }

    public static void main(String[] args) {
        AsyncExceptionHandling handler = new AsyncExceptionHandling();

        System.out.println("=== exceptionally ===");
        String r1 = handler.fetchWithFallback("http://error.com").join();
        System.out.println("结果: " + r1);

        System.out.println("\n=== handle (失败) ===");
        String r2 = handler.fetchWithHandle("http://error.com").join();
        System.out.println("结果: " + r2);

        System.out.println("\n=== handle (成功) ===");
        String r3 = handler.fetchWithHandle("http://success.com").join();
        System.out.println("结果: " + r3);

        System.out.println("\n=== whenComplete ===");
        try {
            String r4 = handler.fetchWithWhenComplete("http://error.com").join();
            System.out.println("结果: " + r4);
        } catch (CompletionException e) {
            System.out.println("主线程捕获异常: " + e.getCause().getMessage());
        }
    }
}
```

---

### 题目 7.3 ⭐ 组合多个Future

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

public class CombiningFutures {

    // 模拟API
    private CompletableFuture<String> fetchUser(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(100);
            return "User-" + userId;
        });
    }

    private CompletableFuture<List<String>> fetchOrders(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(150);
            return Arrays.asList("Order1", "Order2", "Order3");
        });
    }

    private CompletableFuture<String> fetchFromUrl(String url) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(100);
            return "Data from " + url;
        });
    }

    // thenCombine: 两个异步操作的结果合并
    public CompletableFuture<String> fetchUserAndOrders(String userId) {
        CompletableFuture<String> userFuture = fetchUser(userId);
        CompletableFuture<List<String>> ordersFuture = fetchOrders(userId);

        return userFuture.thenCombine(ordersFuture, (user, orders) ->
                user + " has " + orders.size() + " orders: " + orders
        );
    }

    // allOf: 等待所有完成
    public CompletableFuture<List<String>> fetchAll(List<String> urls) {
        List<CompletableFuture<String>> futures = urls.stream()
                .map(this::fetchFromUrl)
                .collect(Collectors.toList());

        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
                .thenApply(v -> futures.stream()
                        .map(CompletableFuture::join)
                        .collect(Collectors.toList()));
    }

    // thenAcceptBoth: 类似thenCombine，但不返回值
    public CompletableFuture<Void> processUserAndOrders(String userId) {
        return fetchUser(userId).thenAcceptBoth(
                fetchOrders(userId),
                (user, orders) -> {
                    System.out.println("处理: " + user + " 的订单: " + orders);
                }
        );
    }

    private void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException e) {}
    }

    public static void main(String[] args) {
        CombiningFutures cf = new CombiningFutures();

        System.out.println("=== thenCombine ===");
        long start = System.currentTimeMillis();
        String result = cf.fetchUserAndOrders("123").join();
        System.out.println("结果: " + result);
        System.out.println("耗时: " + (System.currentTimeMillis() - start) + "ms");
        // 耗时约150ms（并行执行，取最长的）

        System.out.println("\n=== allOf ===");
        start = System.currentTimeMillis();
        List<String> urls = Arrays.asList("url1", "url2", "url3");
        List<String> results = cf.fetchAll(urls).join();
        System.out.println("结果: " + results);
        System.out.println("耗时: " + (System.currentTimeMillis() - start) + "ms");
        // 耗时约100ms（3个请求并行）

        System.out.println("\n=== thenAcceptBoth ===");
        cf.processUserAndOrders("456").join();
    }
}
```

---

### 题目 7.4 ⭐⭐ anyOf 实现超时或降级

```java
import java.util.concurrent.*;

public class FastestWins {

    // 模拟不同速度的数据源
    private CompletableFuture<String> fetchFromSource(String name, long delayMs) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                Thread.sleep(delayMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return "数据来自 " + name;
        });
    }

    // 从多个源获取数据，返回最快的
    public CompletableFuture<String> fetchFromFastestSource(String key) {
        CompletableFuture<String> source1 = fetchFromSource("Source1", 300);
        CompletableFuture<String> source2 = fetchFromSource("Source2", 100);
        CompletableFuture<String> source3 = fetchFromSource("Source3", 200);

        return CompletableFuture.anyOf(source1, source2, source3)
                .thenApply(result -> (String) result);
    }

    // 超时Future工厂
    private CompletableFuture<String> timeoutAfter(long ms) {
        CompletableFuture<String> future = new CompletableFuture<>();
        Executors.newSingleThreadScheduledExecutor().schedule(
                () -> future.complete("TIMEOUT"),
                ms, TimeUnit.MILLISECONDS
        );
        return future;
    }

    // 带超时的请求
    public CompletableFuture<String> fetchWithTimeout(String url, long timeoutMs) {
        CompletableFuture<String> dataFuture = fetchFromSource(url, 500);
        CompletableFuture<String> timeoutFuture = timeoutAfter(timeoutMs);

        return CompletableFuture.anyOf(dataFuture, timeoutFuture)
                .thenApply(result -> {
                    String r = (String) result;
                    if ("TIMEOUT".equals(r)) {
                        // 可以取消原请求
                        dataFuture.cancel(true);
                    }
                    return r;
                });
    }

    // JDK9+ 可以使用 orTimeout
    public CompletableFuture<String> fetchWithTimeoutJdk9(String url, long timeoutMs) {
        return fetchFromSource(url, 500)
                .orTimeout(timeoutMs, TimeUnit.MILLISECONDS)
                .exceptionally(ex -> {
                    if (ex.getCause() instanceof TimeoutException) {
                        return "TIMEOUT";
                    }
                    throw new CompletionException(ex);
                });
    }

    public static void main(String[] args) {
        FastestWins fw = new FastestWins();

        System.out.println("=== 最快返回 ===");
        long start = System.currentTimeMillis();
        String result = fw.fetchFromFastestSource("key").join();
        System.out.println("结果: " + result);
        System.out.println("耗时: " + (System.currentTimeMillis() - start) + "ms");
        // 约100ms，来自Source2

        System.out.println("\n=== 超时测试 (200ms超时) ===");
        start = System.currentTimeMillis();
        result = fw.fetchWithTimeout("slowUrl", 200).join();
        System.out.println("结果: " + result);
        System.out.println("耗时: " + (System.currentTimeMillis() - start) + "ms");
        // 约200ms，返回TIMEOUT
    }
}
```

---

### 题目 7.5 ⭐⭐ thenCompose 实现链式异步

```java
import java.util.concurrent.*;

public class ComposingFutures {

    // 模拟实体类
    static class User {
        String id, name;
        User(String id, String name) { this.id = id; this.name = name; }
    }

    static class Order {
        String id, userId;
        Order(String id, String userId) { this.id = id; this.userId = userId; }
    }

    static class OrderDetails {
        Order order;
        String details;
        OrderDetails(Order order, String details) {
            this.order = order;
            this.details = details;
        }
    }

    // 模拟API
    private CompletableFuture<User> fetchUser(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(100);
            return new User(userId, "User-" + userId);
        });
    }

    private CompletableFuture<Order> fetchLatestOrder(String userId) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(100);
            return new Order("ORD-001", userId);
        });
    }

    private CompletableFuture<OrderDetails> fetchOrderDetails(String orderId) {
        return CompletableFuture.supplyAsync(() -> {
            sleep(100);
            return new OrderDetails(
                    new Order(orderId, "user"),
                    "订单详情: 商品A x 2, 商品B x 1"
            );
        });
    }

    // 链式异步：获取用户 → 获取最新订单 → 获取订单详情
    public CompletableFuture<OrderDetails> getOrderDetails(String userId) {
        return fetchUser(userId)
                .thenCompose(user -> {
                    System.out.println("获取到用户: " + user.name);
                    return fetchLatestOrder(user.id);
                })
                .thenCompose(order -> {
                    System.out.println("获取到订单: " + order.id);
                    return fetchOrderDetails(order.id);
                });
    }

    // 对比 thenApply 和 thenCompose
    public void compareApplyAndCompose() {
        System.out.println("=== thenApply vs thenCompose ===");

        // thenApply: 返回值直接作为下一步的输入
        // 如果函数返回的是Future，会导致嵌套
        CompletableFuture<CompletableFuture<Order>> nested =
                fetchUser("123").thenApply(user -> fetchLatestOrder(user.id));
        // 类型是 CompletableFuture<CompletableFuture<Order>>，嵌套了！

        // thenCompose: 自动展平，类似flatMap
        CompletableFuture<Order> flat =
                fetchUser("123").thenCompose(user -> fetchLatestOrder(user.id));
        // 类型是 CompletableFuture<Order>，正确！

        System.out.println("nested类型: CompletableFuture<CompletableFuture<Order>>");
        System.out.println("flat类型: CompletableFuture<Order>");
    }

    private void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException e) {}
    }

    public static void main(String[] args) {
        ComposingFutures cf = new ComposingFutures();

        System.out.println("=== 链式异步调用 ===");
        long start = System.currentTimeMillis();
        OrderDetails details = cf.getOrderDetails("user-123").join();
        System.out.println("订单详情: " + details.details);
        System.out.println("总耗时: " + (System.currentTimeMillis() - start) + "ms");
        // 约300ms（三个异步调用串行）

        System.out.println();
        cf.compareApplyAndCompose();
    }
}
```

---

## 总结

本文档涵盖了 JUC 包中 7 个核心场景的 **简单** 和 **中等** 难度练习题参考答案：

| 场景 | 简单题 | 中等题 |
|------|--------|--------|
| 计数器/累加器 | 1.1, 1.2, 1.3 | 1.4, 1.5 |
| 读多写少 | 2.1, 2.2, 2.3 | 2.4, 2.5 |
| 线程协作/等待 | 3.1, 3.2, 3.3 | 3.4, 3.5 |
| 资源池/限流 | 4.1, 4.2, 4.3 | 4.4, 4.5 |
| 生产者-消费者 | 5.1, 5.2, 5.3 | 5.4, 5.5 |
| 缓存/共享Map | 6.1, 6.2, 6.3 | 6.4, 6.5 |
| 异步任务编排 | 7.1, 7.2, 7.3 | 7.4, 7.5 |

**学习建议**：
1. 先独立尝试实现，再对照答案
2. 理解每个API的设计意图和适用场景
3. 注意代码中的注释和思考题答案
4. 在实际项目中应用所学知识
