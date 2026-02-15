# JUC 练习题参考答案（困难难度）

> 本文档包含 ⭐⭐⭐⭐ 困难难度题目的参考答案
> 困难难度：性能优化，边界处理

---

## 场景一：计数器/累加器

### 题目 1.8 ⭐⭐⭐⭐ 实现一个无锁的并发栈（Treiber Stack）

```java
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.AtomicStampedReference;

/**
 * Treiber Stack - 经典的无锁并发栈实现
 * 使用CAS操作保证线程安全
 */
public class ConcurrentStack<E> {
    private final AtomicReference<Node<E>> top = new AtomicReference<>(null);

    private static class Node<E> {
        final E item;
        Node<E> next;

        Node(E item) {
            this.item = item;
        }
    }

    /**
     * 入栈操作
     * 使用CAS自旋直到成功
     */
    public void push(E item) {
        Node<E> newHead = new Node<>(item);
        Node<E> oldHead;
        do {
            oldHead = top.get();
            newHead.next = oldHead;
        } while (!top.compareAndSet(oldHead, newHead));
    }

    /**
     * 出栈操作
     * 使用CAS自旋直到成功或栈空
     */
    public E pop() {
        Node<E> oldHead;
        Node<E> newHead;
        do {
            oldHead = top.get();
            if (oldHead == null) {
                return null; // 栈空
            }
            newHead = oldHead.next;
        } while (!top.compareAndSet(oldHead, newHead));
        return oldHead.item;
    }

    /**
     * 查看栈顶元素（不移除）
     */
    public E peek() {
        Node<E> head = top.get();
        return head != null ? head.item : null;
    }

    public boolean isEmpty() {
        return top.get() == null;
    }

    public static void main(String[] args) throws InterruptedException {
        ConcurrentStack<Integer> stack = new ConcurrentStack<>();

        // 多线程测试
        int threadCount = 10;
        int opsPerThread = 10000;
        Thread[] threads = new Thread[threadCount];

        // 一半线程push，一半线程pop
        for (int i = 0; i < threadCount; i++) {
            int threadId = i;
            threads[i] = new Thread(() -> {
                if (threadId % 2 == 0) {
                    for (int j = 0; j < opsPerThread; j++) {
                        stack.push(threadId * opsPerThread + j);
                    }
                } else {
                    for (int j = 0; j < opsPerThread; j++) {
                        stack.pop();
                    }
                }
            });
        }

        long start = System.currentTimeMillis();
        for (Thread t : threads) t.start();
        for (Thread t : threads) t.join();
        long elapsed = System.currentTimeMillis() - start;

        System.out.println("耗时: " + elapsed + "ms");
        System.out.println("栈是否为空: " + stack.isEmpty());
    }
}

/**
 * 解决ABA问题的版本
 * 使用AtomicStampedReference添加版本号
 */
class ConcurrentStackWithStamp<E> {
    private final AtomicStampedReference<Node<E>> top =
        new AtomicStampedReference<>(null, 0);

    private static class Node<E> {
        final E item;
        Node<E> next;

        Node(E item) {
            this.item = item;
        }
    }

    public void push(E item) {
        Node<E> newHead = new Node<>(item);
        int[] stampHolder = new int[1];
        Node<E> oldHead;
        int oldStamp;
        do {
            oldHead = top.get(stampHolder);
            oldStamp = stampHolder[0];
            newHead.next = oldHead;
        } while (!top.compareAndSet(oldHead, newHead, oldStamp, oldStamp + 1));
    }

    public E pop() {
        int[] stampHolder = new int[1];
        Node<E> oldHead;
        Node<E> newHead;
        int oldStamp;
        do {
            oldHead = top.get(stampHolder);
            oldStamp = stampHolder[0];
            if (oldHead == null) {
                return null;
            }
            newHead = oldHead.next;
        } while (!top.compareAndSet(oldHead, newHead, oldStamp, oldStamp + 1));
        return oldHead.item;
    }

    public E peek() {
        Node<E> head = top.getReference();
        return head != null ? head.item : null;
    }
}

/*
 * ABA问题分析：
 *
 * 基础版本的Treiber Stack确实存在ABA问题，但在大多数场景下是安全的。
 *
 * ABA问题场景：
 * 1. 线程A执行pop()，读取top=A，准备CAS(A, B)
 * 2. 线程A被挂起
 * 3. 线程B执行pop()，栈变为B->C
 * 4. 线程C执行pop()，栈变为C
 * 5. 线程D执行push(A)，栈变为A->C（注意：这个A是新节点！）
 * 6. 线程A恢复，CAS(A, B)成功（因为top确实是A）
 * 7. 但栈变成了B，而B.next指向的是旧的C，不是当前的C！
 *
 * 为什么基础版本通常安全？
 * 因为在Java中，pop()后的节点不会被重用（GC会回收），
 * 所以实际上不会出现"旧节点被重新push"的情况。
 *
 * 何时需要AtomicStampedReference版本？
 * 1. 使用对象池复用节点时
 * 2. 在没有GC的语言（如C++）中实现时
 * 3. 需要100%正确性保证的关键系统
 */
```

---

### 题目 1.9 ⭐⭐⭐⭐ 高性能ID生成器（Snowflake）

```java
import java.util.concurrent.atomic.AtomicLong;

/**
 * Snowflake ID生成器
 *
 * ID结构（64位）：
 * 0 - 41位时间戳 - 5位数据中心ID - 5位机器ID - 12位序列号
 *
 * 支持：
 * - 单机每毫秒生成4096个ID
 * - 支持1024台机器（32个数据中心 × 32台机器）
 * - 可用约69年
 */
public class SnowflakeIdGenerator {
    // 起始时间戳（2024-01-01 00:00:00）
    private static final long EPOCH = 1704067200000L;

    // 各部分位数
    private static final int DATACENTER_ID_BITS = 5;
    private static final int MACHINE_ID_BITS = 5;
    private static final int SEQUENCE_BITS = 12;

    // 最大值
    private static final long MAX_DATACENTER_ID = ~(-1L << DATACENTER_ID_BITS); // 31
    private static final long MAX_MACHINE_ID = ~(-1L << MACHINE_ID_BITS);       // 31
    private static final long MAX_SEQUENCE = ~(-1L << SEQUENCE_BITS);           // 4095

    // 位移量
    private static final int MACHINE_ID_SHIFT = SEQUENCE_BITS;                           // 12
    private static final int DATACENTER_ID_SHIFT = SEQUENCE_BITS + MACHINE_ID_BITS;      // 17
    private static final int TIMESTAMP_SHIFT = SEQUENCE_BITS + MACHINE_ID_BITS + DATACENTER_ID_BITS; // 22

    private final long datacenterId;
    private final long machineId;

    // 使用AtomicLong打包lastTimestamp和sequence
    // 高52位：时间戳，低12位：序列号
    private final AtomicLong state = new AtomicLong(0);

    public SnowflakeIdGenerator(long datacenterId, long machineId) {
        if (datacenterId < 0 || datacenterId > MAX_DATACENTER_ID) {
            throw new IllegalArgumentException("Datacenter ID must be between 0 and " + MAX_DATACENTER_ID);
        }
        if (machineId < 0 || machineId > MAX_MACHINE_ID) {
            throw new IllegalArgumentException("Machine ID must be between 0 and " + MAX_MACHINE_ID);
        }
        this.datacenterId = datacenterId;
        this.machineId = machineId;
    }

    /**
     * 生成下一个ID
     * 使用CAS无锁实现，高并发下性能优异
     */
    public long nextId() {
        while (true) {
            long currentState = state.get();
            long lastTimestamp = currentState >>> SEQUENCE_BITS;
            long sequence = currentState & MAX_SEQUENCE;

            long currentTimestamp = currentTimeMillis();

            if (currentTimestamp < lastTimestamp) {
                // 时钟回拨处理
                currentTimestamp = handleClockBackward(lastTimestamp, currentTimestamp);
            }

            long newSequence;
            long newTimestamp;

            if (currentTimestamp == lastTimestamp) {
                // 同一毫秒内，序列号递增
                newSequence = (sequence + 1) & MAX_SEQUENCE;
                if (newSequence == 0) {
                    // 序列号溢出，等待下一毫秒
                    currentTimestamp = waitNextMillis(lastTimestamp);
                }
                newTimestamp = currentTimestamp;
            } else {
                // 新的毫秒，序列号重置
                newSequence = 0;
                newTimestamp = currentTimestamp;
            }

            long newState = (newTimestamp << SEQUENCE_BITS) | newSequence;

            if (state.compareAndSet(currentState, newState)) {
                // CAS成功，生成ID
                return ((newTimestamp - EPOCH) << TIMESTAMP_SHIFT)
                     | (datacenterId << DATACENTER_ID_SHIFT)
                     | (machineId << MACHINE_ID_SHIFT)
                     | newSequence;
            }
            // CAS失败，重试
        }
    }

    /**
     * 处理时钟回拨
     */
    private long handleClockBackward(long lastTimestamp, long currentTimestamp) {
        long offset = lastTimestamp - currentTimestamp;
        if (offset <= 5) {
            // 回拨时间较短，等待
            try {
                Thread.sleep(offset << 1);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            currentTimestamp = currentTimeMillis();
            if (currentTimestamp < lastTimestamp) {
                throw new RuntimeException("Clock moved backwards. Refusing to generate id");
            }
        } else {
            throw new RuntimeException("Clock moved backwards by " + offset + "ms. Refusing to generate id");
        }
        return currentTimestamp;
    }

    /**
     * 等待下一毫秒
     */
    private long waitNextMillis(long lastTimestamp) {
        long timestamp = currentTimeMillis();
        while (timestamp <= lastTimestamp) {
            timestamp = currentTimeMillis();
        }
        return timestamp;
    }

    private long currentTimeMillis() {
        return System.currentTimeMillis();
    }

    /**
     * 解析ID的各个部分
     */
    public static long[] parseId(long id) {
        long timestamp = (id >> TIMESTAMP_SHIFT) + EPOCH;
        long datacenterId = (id >> DATACENTER_ID_SHIFT) & MAX_DATACENTER_ID;
        long machineId = (id >> MACHINE_ID_SHIFT) & MAX_MACHINE_ID;
        long sequence = id & MAX_SEQUENCE;
        return new long[]{timestamp, datacenterId, machineId, sequence};
    }

    public static void main(String[] args) throws InterruptedException {
        SnowflakeIdGenerator generator = new SnowflakeIdGenerator(1, 1);

        // 测试生成速度
        int count = 1000000;
        long[] ids = new long[count];

        long start = System.currentTimeMillis();
        for (int i = 0; i < count; i++) {
            ids[i] = generator.nextId();
        }
        long elapsed = System.currentTimeMillis() - start;

        System.out.println("生成 " + count + " 个ID耗时: " + elapsed + "ms");
        System.out.println("QPS: " + (count * 1000L / elapsed));

        // 检查唯一性
        java.util.Set<Long> uniqueIds = new java.util.HashSet<>();
        for (long id : ids) {
            if (!uniqueIds.add(id)) {
                System.out.println("发现重复ID: " + id);
            }
        }
        System.out.println("唯一ID数量: " + uniqueIds.size());

        // 解析示例ID
        long sampleId = ids[0];
        long[] parts = parseId(sampleId);
        System.out.println("\n示例ID: " + sampleId);
        System.out.println("  时间戳: " + new java.util.Date(parts[0]));
        System.out.println("  数据中心ID: " + parts[1]);
        System.out.println("  机器ID: " + parts[2]);
        System.out.println("  序列号: " + parts[3]);

        // 多线程测试
        System.out.println("\n=== 多线程测试 ===");
        int threadCount = 10;
        int idsPerThread = 100000;
        java.util.concurrent.ConcurrentHashMap<Long, Boolean> allIds =
            new java.util.concurrent.ConcurrentHashMap<>();

        Thread[] threads = new Thread[threadCount];
        start = System.currentTimeMillis();

        for (int i = 0; i < threadCount; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < idsPerThread; j++) {
                    long id = generator.nextId();
                    if (allIds.putIfAbsent(id, Boolean.TRUE) != null) {
                        System.out.println("多线程下发现重复ID!");
                    }
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) t.join();
        elapsed = System.currentTimeMillis() - start;

        System.out.println("多线程生成 " + (threadCount * idsPerThread) + " 个ID耗时: " + elapsed + "ms");
        System.out.println("唯一ID数量: " + allIds.size());
    }
}
```

---

## 场景二：读多写少

### 题目 2.8 ⭐⭐⭐⭐ 可中断的读写锁

```java
import java.util.concurrent.*;
import java.util.concurrent.locks.*;
import java.util.function.Supplier;

/**
 * 支持超时和中断的读写锁包装器
 */
public class InterruptibleRWLock {
    private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock();
    private final ReentrantReadWriteLock.ReadLock readLock = rwLock.readLock();
    private final ReentrantReadWriteLock.WriteLock writeLock = rwLock.writeLock();

    /**
     * 带超时的读操作
     */
    public <T> T readWithTimeout(Supplier<T> reader, long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        if (readLock.tryLock(timeout, unit)) {
            try {
                return reader.get();
            } finally {
                readLock.unlock();
            }
        } else {
            throw new TimeoutException("获取读锁超时");
        }
    }

    /**
     * 带超时的写操作
     */
    public void writeWithTimeout(Runnable writer, long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        if (writeLock.tryLock(timeout, unit)) {
            try {
                writer.run();
            } finally {
                writeLock.unlock();
            }
        } else {
            throw new TimeoutException("获取写锁超时");
        }
    }

    /**
     * 带超时的写操作（有返回值）
     */
    public <T> T writeWithTimeout(Supplier<T> writer, long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        if (writeLock.tryLock(timeout, unit)) {
            try {
                return writer.get();
            } finally {
                writeLock.unlock();
            }
        } else {
            throw new TimeoutException("获取写锁超时");
        }
    }

    /**
     * 可中断的读操作
     */
    public <T> T readInterruptibly(Supplier<T> reader) throws InterruptedException {
        readLock.lockInterruptibly();
        try {
            return reader.get();
        } finally {
            readLock.unlock();
        }
    }

    /**
     * 可中断的写操作
     */
    public void writeInterruptibly(Runnable writer) throws InterruptedException {
        writeLock.lockInterruptibly();
        try {
            writer.run();
        } finally {
            writeLock.unlock();
        }
    }

    /**
     * 尝试读操作（非阻塞）
     */
    public <T> T tryRead(Supplier<T> reader, T defaultValue) {
        if (readLock.tryLock()) {
            try {
                return reader.get();
            } finally {
                readLock.unlock();
            }
        }
        return defaultValue;
    }

    /**
     * 尝试写操作（非阻塞）
     */
    public boolean tryWrite(Runnable writer) {
        if (writeLock.tryLock()) {
            try {
                writer.run();
                return true;
            } finally {
                writeLock.unlock();
            }
        }
        return false;
    }

    /**
     * 获取锁状态信息
     */
    public String getLockStatus() {
        return String.format("ReadLocks=%d, WriteLocked=%b, QueueLength=%d",
            rwLock.getReadLockCount(),
            rwLock.isWriteLocked(),
            rwLock.getQueueLength());
    }

    public static void main(String[] args) throws Exception {
        InterruptibleRWLock lock = new InterruptibleRWLock();
        String[] data = {"初始值"};

        // 测试带超时的读写
        System.out.println("=== 带超时的读写 ===");

        // 先获取写锁并持有
        Thread writer = new Thread(() -> {
            try {
                lock.writeWithTimeout(() -> {
                    System.out.println("写线程获取锁，持有3秒...");
                    try {
                        Thread.sleep(3000);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                    data[0] = "新值";
                }, 1, TimeUnit.SECONDS);
            } catch (Exception e) {
                System.out.println("写线程异常: " + e.getMessage());
            }
        });
        writer.start();
        Thread.sleep(100);

        // 尝试带超时的读
        Thread reader = new Thread(() -> {
            try {
                String value = lock.readWithTimeout(() -> data[0], 1, TimeUnit.SECONDS);
                System.out.println("读取成功: " + value);
            } catch (TimeoutException e) {
                System.out.println("读取超时!");
            } catch (InterruptedException e) {
                System.out.println("读取被中断!");
            }
        });
        reader.start();

        writer.join();
        reader.join();

        // 测试可中断
        System.out.println("\n=== 测试可中断 ===");

        Thread longWriter = new Thread(() -> {
            try {
                lock.writeInterruptibly(() -> {
                    System.out.println("长时间写操作开始...");
                    try {
                        Thread.sleep(10000);
                    } catch (InterruptedException e) {
                        System.out.println("写操作被中断!");
                        Thread.currentThread().interrupt();
                    }
                });
            } catch (InterruptedException e) {
                System.out.println("获取写锁时被中断!");
            }
        });
        longWriter.start();
        Thread.sleep(100);

        Thread waitingReader = new Thread(() -> {
            try {
                lock.readInterruptibly(() -> {
                    System.out.println("读取: " + data[0]);
                    return null;
                });
            } catch (InterruptedException e) {
                System.out.println("等待读锁时被中断!");
            }
        });
        waitingReader.start();

        Thread.sleep(500);
        System.out.println("锁状态: " + lock.getLockStatus());

        // 中断等待的读线程
        waitingReader.interrupt();
        waitingReader.join();

        // 中断写线程
        longWriter.interrupt();
        longWriter.join();

        System.out.println("最终锁状态: " + lock.getLockStatus());
    }
}
```

---

### 题目 2.9 ⭐⭐⭐⭐ StampedLock 转换模式

```java
import java.util.concurrent.locks.StampedLock;
import java.util.function.Function;

/**
 * 深入使用StampedLock的所有模式
 * 包括：乐观读、悲观读、写锁、锁转换
 */
public class StampedContainer<T> {
    private T data;
    private final StampedLock sl = new StampedLock();

    public StampedContainer(T initialData) {
        this.data = initialData;
    }

    /**
     * 乐观读 - 最高性能的读操作
     * 不阻塞写操作，但需要验证
     */
    public T optimisticRead() {
        // 1. 获取乐观读stamp
        long stamp = sl.tryOptimisticRead();

        // 2. 读取数据（可能是脏数据）
        T currentData = data;

        // 3. 验证stamp是否仍然有效
        if (!sl.validate(stamp)) {
            // 验证失败，升级为悲观读锁
            stamp = sl.readLock();
            try {
                currentData = data;
            } finally {
                sl.unlockRead(stamp);
            }
        }

        return currentData;
    }

    /**
     * 悲观读
     */
    public T pessimisticRead() {
        long stamp = sl.readLock();
        try {
            return data;
        } finally {
            sl.unlockRead(stamp);
        }
    }

    /**
     * 写操作
     */
    public void write(T newData) {
        long stamp = sl.writeLock();
        try {
            this.data = newData;
        } finally {
            sl.unlockWrite(stamp);
        }
    }

    /**
     * 读锁转写锁（条件写入）
     * 先读取数据，根据条件决定是否写入
     */
    public T readThenWrite(Function<T, T> transformer) {
        // 1. 先获取读锁
        long stamp = sl.readLock();
        try {
            while (true) {
                T currentData = data;

                // 2. 尝试转换为写锁
                long writeStamp = sl.tryConvertToWriteLock(stamp);

                if (writeStamp != 0L) {
                    // 转换成功
                    stamp = writeStamp;
                    T newData = transformer.apply(currentData);
                    this.data = newData;
                    return newData;
                } else {
                    // 转换失败，释放读锁，获取写锁
                    sl.unlockRead(stamp);
                    stamp = sl.writeLock();
                    // 重新读取数据（可能已被其他线程修改）
                }
            }
        } finally {
            sl.unlock(stamp); // unlock可以释放任何类型的锁
        }
    }

    /**
     * 写锁转读锁（锁降级）
     * 写入后立即读取，但允许其他读操作并发
     */
    public T writeAndRead(T newValue) {
        long stamp = sl.writeLock();
        try {
            this.data = newValue;

            // 转换为读锁
            long readStamp = sl.tryConvertToReadLock(stamp);
            if (readStamp != 0L) {
                stamp = readStamp;
                // 现在持有读锁，其他读操作可以并发
                return this.data;
            } else {
                // 转换失败（理论上不会发生）
                return this.data;
            }
        } finally {
            sl.unlock(stamp);
        }
    }

    /**
     * 条件更新 - 使用乐观读 + 写锁
     * 类似CAS操作
     */
    public boolean compareAndSet(T expected, T newValue) {
        // 先用乐观读检查
        long stamp = sl.tryOptimisticRead();
        T current = data;

        if (!sl.validate(stamp) || current != expected) {
            // 需要更精确的检查
            stamp = sl.writeLock();
            try {
                if (data != expected) {
                    return false;
                }
                data = newValue;
                return true;
            } finally {
                sl.unlockWrite(stamp);
            }
        }

        // 乐观读显示匹配，尝试写入
        stamp = sl.writeLock();
        try {
            if (data != expected) {
                return false;
            }
            data = newValue;
            return true;
        } finally {
            sl.unlockWrite(stamp);
        }
    }

    /**
     * 带超时的读操作
     */
    public T readWithTimeout(long timeout, java.util.concurrent.TimeUnit unit)
            throws InterruptedException {
        long stamp = sl.tryReadLock(timeout, unit);
        if (stamp == 0L) {
            throw new InterruptedException("获取读锁超时");
        }
        try {
            return data;
        } finally {
            sl.unlockRead(stamp);
        }
    }

    public static void main(String[] args) throws InterruptedException {
        StampedContainer<Integer> container = new StampedContainer<>(0);

        // 测试乐观读
        System.out.println("=== 乐观读测试 ===");
        System.out.println("当前值: " + container.optimisticRead());

        // 测试读后写
        System.out.println("\n=== 读后写测试 ===");
        Integer result = container.readThenWrite(v -> v + 10);
        System.out.println("转换后: " + result);

        // 测试写后读
        System.out.println("\n=== 写后读测试 ===");
        result = container.writeAndRead(100);
        System.out.println("写入并读取: " + result);

        // 测试CAS
        System.out.println("\n=== CAS测试 ===");
        boolean success = container.compareAndSet(100, 200);
        System.out.println("CAS(100, 200): " + success + ", 当前值: " + container.optimisticRead());
        success = container.compareAndSet(100, 300);
        System.out.println("CAS(100, 300): " + success + ", 当前值: " + container.optimisticRead());

        // 多线程测试
        System.out.println("\n=== 多线程测试 ===");
        StampedContainer<Long> counter = new StampedContainer<>(0L);
        int threadCount = 10;
        int opsPerThread = 10000;
        Thread[] threads = new Thread[threadCount];

        for (int i = 0; i < threadCount; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < opsPerThread; j++) {
                    counter.readThenWrite(v -> v + 1);
                }
            });
        }

        long start = System.currentTimeMillis();
        for (Thread t : threads) t.start();
        for (Thread t : threads) t.join();
        long elapsed = System.currentTimeMillis() - start;

        System.out.println("最终值: " + counter.optimisticRead());
        System.out.println("期望值: " + (threadCount * opsPerThread));
        System.out.println("耗时: " + elapsed + "ms");
    }
}

/*
 * StampedLock不支持重入的问题及解决方案：
 *
 * 问题：
 * long stamp = sl.readLock();
 * // ...
 * long stamp2 = sl.readLock(); // 死锁！
 *
 * 解决方案：
 * 1. 确保同一线程不会重复获取锁
 * 2. 使用ThreadLocal记录当前线程是否已持有锁
 * 3. 如果需要重入，考虑使用ReentrantReadWriteLock
 *
 * 示例（ThreadLocal方案）：
 *
 * private final ThreadLocal<Long> currentStamp = new ThreadLocal<>();
 *
 * public void safeRead() {
 *     Long existing = currentStamp.get();
 *     if (existing != null && existing != 0L) {
 *         // 当前线程已持有锁，直接使用
 *         doRead();
 *         return;
 *     }
 *
 *     long stamp = sl.readLock();
 *     currentStamp.set(stamp);
 *     try {
 *         doRead();
 *     } finally {
 *         currentStamp.remove();
 *         sl.unlockRead(stamp);
 *     }
 * }
 */
```

---

## 场景三：线程协作/等待

### 题目 3.8 ⭐⭐⭐⭐ 可重用的CountDownLatch

```java
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.*;

/**
 * 可重用的CountDownLatch
 * 支持reset()方法重置计数器
 */
public class ReusableCountDownLatch {
    private final int initialCount;
    private int count;
    private int generation; // 代数，用于区分不同轮次
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition done = lock.newCondition();

    public ReusableCountDownLatch(int count) {
        if (count < 0) {
            throw new IllegalArgumentException("count < 0");
        }
        this.initialCount = count;
        this.count = count;
        this.generation = 0;
    }

    /**
     * 计数减1
     */
    public void countDown() {
        lock.lock();
        try {
            if (count > 0) {
                count--;
                if (count == 0) {
                    done.signalAll(); // 唤醒所有等待线程
                }
            }
        } finally {
            lock.unlock();
        }
    }

    /**
     * 等待计数到0
     */
    public void await() throws InterruptedException {
        lock.lock();
        try {
            int currentGen = generation;
            while (count > 0 && generation == currentGen) {
                done.await();
            }
        } finally {
            lock.unlock();
        }
    }

    /**
     * 带超时的等待
     */
    public boolean await(long timeout, TimeUnit unit) throws InterruptedException {
        long remainingNanos = unit.toNanos(timeout);
        lock.lock();
        try {
            int currentGen = generation;
            while (count > 0 && generation == currentGen) {
                if (remainingNanos <= 0) {
                    return false;
                }
                remainingNanos = done.awaitNanos(remainingNanos);
            }
            return true;
        } finally {
            lock.unlock();
        }
    }

    /**
     * 重置计数器
     * 会唤醒所有等待线程（它们会发现generation变了）
     */
    public void reset() {
        lock.lock();
        try {
            count = initialCount;
            generation++;
            done.signalAll(); // 唤醒所有等待线程
        } finally {
            lock.unlock();
        }
    }

    /**
     * 获取当前计数
     */
    public int getCount() {
        lock.lock();
        try {
            return count;
        } finally {
            lock.unlock();
        }
    }

    /**
     * 获取初始计数
     */
    public int getInitialCount() {
        return initialCount;
    }

    public static void main(String[] args) throws InterruptedException {
        ReusableCountDownLatch latch = new ReusableCountDownLatch(3);

        // 第一轮
        System.out.println("=== 第一轮 ===");

        for (int i = 0; i < 3; i++) {
            int id = i;
            new Thread(() -> {
                try {
                    Thread.sleep(100 * (id + 1));
                    System.out.println("任务" + id + " 完成");
                    latch.countDown();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }).start();
        }

        latch.await();
        System.out.println("第一轮全部完成!");

        // 重置
        latch.reset();
        System.out.println("\n=== 第二轮（重置后）===");

        for (int i = 0; i < 3; i++) {
            int id = i;
            new Thread(() -> {
                try {
                    Thread.sleep(50 * (id + 1));
                    System.out.println("任务" + id + " 完成");
                    latch.countDown();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }).start();
        }

        latch.await();
        System.out.println("第二轮全部完成!");

        // 测试超时
        latch.reset();
        System.out.println("\n=== 超时测试 ===");

        boolean completed = latch.await(200, TimeUnit.MILLISECONDS);
        System.out.println("超时等待结果: " + completed);
        System.out.println("剩余计数: " + latch.getCount());

        // 测试在等待时reset
        latch.reset();
        System.out.println("\n=== Reset中断测试 ===");

        Thread waiter = new Thread(() -> {
            try {
                System.out.println("等待线程开始等待...");
                latch.await();
                System.out.println("等待线程结束（被reset唤醒）");
            } catch (InterruptedException e) {
                System.out.println("等待线程被中断");
            }
        });
        waiter.start();

        Thread.sleep(100);
        System.out.println("执行reset...");
        latch.reset();

        waiter.join();
    }
}
```

---

### 题目 3.9 ⭐⭐⭐⭐ 分布式屏障（模拟实现）

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 基于模拟Redis的分布式CyclicBarrier
 * 实际使用时需要替换为真实的Redis客户端
 */
public class DistributedBarrier {
    private final String barrierName;
    private final int parties;
    private final SimulatedRedis redis;
    private final String nodeId;
    private final ScheduledExecutorService scheduler;

    // 心跳间隔
    private static final long HEARTBEAT_INTERVAL_MS = 1000;
    // 节点超时时间
    private static final long NODE_TIMEOUT_MS = 5000;

    public DistributedBarrier(String name, int parties) {
        this.barrierName = "barrier:" + name;
        this.parties = parties;
        this.redis = SimulatedRedis.getInstance();
        this.nodeId = UUID.randomUUID().toString().substring(0, 8);
        this.scheduler = Executors.newSingleThreadScheduledExecutor();

        // 启动心跳
        startHeartbeat();
    }

    /**
     * 等待所有参与者到达
     */
    public void await() throws InterruptedException, TimeoutException {
        await(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
    }

    /**
     * 带超时的等待
     */
    public void await(long timeout, TimeUnit unit)
            throws InterruptedException, TimeoutException {
        long deadline = System.currentTimeMillis() + unit.toMillis(timeout);

        // 1. 注册到达
        int arrived = redis.registerArrival(barrierName, nodeId, parties);
        System.out.println("[" + nodeId + "] 到达屏障，当前到达数: " + arrived + "/" + parties);

        // 2. 等待所有参与者
        while (true) {
            // 检查是否全部到达
            int currentCount = redis.getArrivedCount(barrierName);
            if (currentCount >= parties) {
                System.out.println("[" + nodeId + "] 所有参与者已到达，通过屏障");
                return;
            }

            // 检查超时
            long remaining = deadline - System.currentTimeMillis();
            if (remaining <= 0) {
                redis.deregister(barrierName, nodeId);
                throw new TimeoutException("等待超时");
            }

            // 检查是否有节点宕机
            int activeNodes = redis.getActiveNodeCount(barrierName, NODE_TIMEOUT_MS);
            if (activeNodes < currentCount) {
                System.out.println("[" + nodeId + "] 检测到节点宕机，active=" +
                                  activeNodes + ", arrived=" + currentCount);
            }

            // 短暂等待后重试
            Thread.sleep(Math.min(100, remaining));
        }
    }

    /**
     * 重置屏障
     */
    public void reset() {
        redis.resetBarrier(barrierName);
        System.out.println("[" + nodeId + "] 屏障已重置");
    }

    private void startHeartbeat() {
        scheduler.scheduleAtFixedRate(() -> {
            redis.heartbeat(barrierName, nodeId);
        }, 0, HEARTBEAT_INTERVAL_MS, TimeUnit.MILLISECONDS);
    }

    public void shutdown() {
        scheduler.shutdown();
        redis.deregister(barrierName, nodeId);
    }

    /**
     * 模拟的Redis客户端
     */
    static class SimulatedRedis {
        private static final SimulatedRedis INSTANCE = new SimulatedRedis();

        // 屏障状态：barrierName -> Set<nodeId>
        private final ConcurrentHashMap<String, Set<String>> arrivedNodes =
            new ConcurrentHashMap<>();

        // 心跳时间：barrierName:nodeId -> lastHeartbeat
        private final ConcurrentHashMap<String, Long> heartbeats =
            new ConcurrentHashMap<>();

        private final ReentrantLock lock = new ReentrantLock();

        public static SimulatedRedis getInstance() {
            return INSTANCE;
        }

        public int registerArrival(String barrier, String nodeId, int parties) {
            lock.lock();
            try {
                Set<String> nodes = arrivedNodes.computeIfAbsent(barrier,
                    k -> ConcurrentHashMap.newKeySet());
                nodes.add(nodeId);
                heartbeats.put(barrier + ":" + nodeId, System.currentTimeMillis());
                return nodes.size();
            } finally {
                lock.unlock();
            }
        }

        public int getArrivedCount(String barrier) {
            Set<String> nodes = arrivedNodes.get(barrier);
            return nodes != null ? nodes.size() : 0;
        }

        public int getActiveNodeCount(String barrier, long timeoutMs) {
            Set<String> nodes = arrivedNodes.get(barrier);
            if (nodes == null) return 0;

            long now = System.currentTimeMillis();
            int active = 0;
            for (String nodeId : nodes) {
                Long lastHb = heartbeats.get(barrier + ":" + nodeId);
                if (lastHb != null && now - lastHb < timeoutMs) {
                    active++;
                }
            }
            return active;
        }

        public void heartbeat(String barrier, String nodeId) {
            heartbeats.put(barrier + ":" + nodeId, System.currentTimeMillis());
        }

        public void deregister(String barrier, String nodeId) {
            lock.lock();
            try {
                Set<String> nodes = arrivedNodes.get(barrier);
                if (nodes != null) {
                    nodes.remove(nodeId);
                }
                heartbeats.remove(barrier + ":" + nodeId);
            } finally {
                lock.unlock();
            }
        }

        public void resetBarrier(String barrier) {
            lock.lock();
            try {
                arrivedNodes.remove(barrier);
                heartbeats.entrySet().removeIf(e -> e.getKey().startsWith(barrier + ":"));
            } finally {
                lock.unlock();
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        int parties = 3;
        CountDownLatch allDone = new CountDownLatch(parties);

        System.out.println("=== 分布式屏障测试 ===\n");

        for (int i = 0; i < parties; i++) {
            int nodeNum = i;
            new Thread(() -> {
                DistributedBarrier barrier = new DistributedBarrier("test", parties);
                try {
                    // 模拟不同的到达时间
                    Thread.sleep(nodeNum * 500);
                    System.out.println("节点" + nodeNum + " 开始等待...");

                    barrier.await(10, TimeUnit.SECONDS);

                    System.out.println("节点" + nodeNum + " 通过屏障!");
                } catch (Exception e) {
                    System.out.println("节点" + nodeNum + " 异常: " + e.getMessage());
                } finally {
                    barrier.shutdown();
                    allDone.countDown();
                }
            }, "Node-" + i).start();
        }

        allDone.await();
        System.out.println("\n所有节点完成");
    }
}
```

---

## 场景四：资源池/限流

### 题目 4.8 ⭐⭐⭐⭐ 自适应限流器

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * 自适应限流器
 * 根据系统负载自动调整限流阈值
 * 类似TCP拥塞控制的AIMD算法
 */
public class AdaptiveRateLimiter {
    private volatile int currentLimit;
    private final int minLimit;
    private final int maxLimit;

    // 监控指标
    private final AtomicLong successCount = new AtomicLong(0);
    private final AtomicLong failureCount = new AtomicLong(0);
    private final AtomicLong totalLatency = new AtomicLong(0);

    // 当前窗口的计数
    private final AtomicInteger currentCount = new AtomicInteger(0);

    // 调整参数
    private static final double SUCCESS_RATE_THRESHOLD = 0.95; // 成功率阈值
    private static final long LATENCY_THRESHOLD_MS = 100;      // 延迟阈值
    private static final double INCREASE_FACTOR = 1.1;          // 增加因子（慢增）
    private static final double DECREASE_FACTOR = 0.5;          // 减少因子（快减）

    private final ScheduledExecutorService scheduler;

    public AdaptiveRateLimiter(int initialLimit, int minLimit, int maxLimit) {
        this.currentLimit = initialLimit;
        this.minLimit = minLimit;
        this.maxLimit = maxLimit;

        // 每秒调整一次限制
        this.scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(this::adjustLimit, 1, 1, TimeUnit.SECONDS);
    }

    /**
     * 尝试获取许可
     */
    public boolean tryAcquire() {
        int current = currentCount.get();
        if (current >= currentLimit) {
            return false;
        }
        return currentCount.compareAndSet(current, current + 1);
    }

    /**
     * 释放许可
     */
    public void release() {
        currentCount.decrementAndGet();
    }

    /**
     * 记录成功
     */
    public void recordSuccess(long latencyMs) {
        successCount.incrementAndGet();
        totalLatency.addAndGet(latencyMs);
        release();
    }

    /**
     * 记录失败
     */
    public void recordFailure() {
        failureCount.incrementAndGet();
        release();
    }

    /**
     * 自适应调整限制
     */
    private void adjustLimit() {
        long success = successCount.getAndSet(0);
        long failure = failureCount.getAndSet(0);
        long latency = totalLatency.getAndSet(0);

        long total = success + failure;
        if (total == 0) {
            return; // 没有请求，不调整
        }

        double successRate = (double) success / total;
        double avgLatency = success > 0 ? (double) latency / success : 0;

        int oldLimit = currentLimit;
        int newLimit;

        if (successRate >= SUCCESS_RATE_THRESHOLD && avgLatency < LATENCY_THRESHOLD_MS) {
            // 系统健康，可以增加限制（慢增）
            newLimit = Math.min((int) (currentLimit * INCREASE_FACTOR), maxLimit);
        } else if (successRate < SUCCESS_RATE_THRESHOLD || avgLatency > LATENCY_THRESHOLD_MS * 2) {
            // 系统过载，减少限制（快减）
            newLimit = Math.max((int) (currentLimit * DECREASE_FACTOR), minLimit);
        } else {
            // 保持不变
            newLimit = currentLimit;
        }

        if (newLimit != oldLimit) {
            currentLimit = newLimit;
            System.out.printf("[调整] limit: %d -> %d (success=%.2f%%, avgLatency=%.1fms)%n",
                            oldLimit, newLimit, successRate * 100, avgLatency);
        }
    }

    public int getCurrentLimit() {
        return currentLimit;
    }

    public int getCurrentCount() {
        return currentCount.get();
    }

    public void shutdown() {
        scheduler.shutdown();
    }

    // 执行带限流的操作
    public <T> T execute(Callable<T> task) throws Exception {
        if (!tryAcquire()) {
            throw new RejectedExecutionException("限流拒绝");
        }

        long start = System.currentTimeMillis();
        try {
            T result = task.call();
            recordSuccess(System.currentTimeMillis() - start);
            return result;
        } catch (Exception e) {
            recordFailure();
            throw e;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        AdaptiveRateLimiter limiter = new AdaptiveRateLimiter(10, 5, 100);

        // 模拟不同负载情况
        ExecutorService executor = Executors.newFixedThreadPool(50);

        System.out.println("=== 阶段1：低负载，高成功率 ===");
        simulateLoad(limiter, executor, 20, 10, 0.99, 50);
        Thread.sleep(5000);

        System.out.println("\n=== 阶段2：高负载，成功率下降 ===");
        simulateLoad(limiter, executor, 100, 10, 0.7, 200);
        Thread.sleep(5000);

        System.out.println("\n=== 阶段3：恢复正常 ===");
        simulateLoad(limiter, executor, 30, 10, 0.95, 50);
        Thread.sleep(5000);

        limiter.shutdown();
        executor.shutdown();

        System.out.println("\n最终限制: " + limiter.getCurrentLimit());
    }

    private static void simulateLoad(AdaptiveRateLimiter limiter,
                                      ExecutorService executor,
                                      int requestsPerSecond,
                                      int durationSeconds,
                                      double successRate,
                                      long avgLatencyMs) {

        AtomicInteger accepted = new AtomicInteger(0);
        AtomicInteger rejected = new AtomicInteger(0);
        Random random = new Random();

        for (int second = 0; second < durationSeconds; second++) {
            for (int i = 0; i < requestsPerSecond; i++) {
                executor.submit(() -> {
                    if (limiter.tryAcquire()) {
                        accepted.incrementAndGet();
                        try {
                            // 模拟处理
                            long latency = (long) (avgLatencyMs * (0.5 + random.nextDouble()));
                            Thread.sleep(latency);

                            if (random.nextDouble() < successRate) {
                                limiter.recordSuccess(latency);
                            } else {
                                limiter.recordFailure();
                            }
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                    } else {
                        rejected.incrementAndGet();
                    }
                });
            }

            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                break;
            }

            System.out.printf("  [秒%d] 当前限制=%d, 接受=%d, 拒绝=%d%n",
                            second + 1, limiter.getCurrentLimit(),
                            accepted.getAndSet(0), rejected.getAndSet(0));
        }
    }
}
```

---

### 题目 4.9 ⭐⭐⭐⭐ 多维度限流器

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 多维度限流器
 * 支持：用户级别、接口级别、全局级别的限流
 */
public class MultiDimensionRateLimiter {

    // 各维度的限流配置
    private final ConcurrentHashMap<String, Integer> userLimits = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Integer> apiLimits = new ConcurrentHashMap<>();
    private volatile int globalLimit = 1000;

    // 当前计数
    private final ConcurrentHashMap<String, AtomicInteger> userCounts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, AtomicInteger> apiCounts = new ConcurrentHashMap<>();
    private final AtomicInteger globalCount = new AtomicInteger(0);

    // 默认限制
    private static final int DEFAULT_USER_LIMIT = 100;
    private static final int DEFAULT_API_LIMIT = 500;

    private final ScheduledExecutorService scheduler;

    public MultiDimensionRateLimiter() {
        // 每秒重置计数
        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(this::resetCounts, 1, 1, TimeUnit.SECONDS);
    }

    /**
     * 尝试获取许可
     * @return RateLimitResult 包含是否通过和被哪个维度限制
     */
    public RateLimitResult tryAcquire(String userId, String apiPath) {
        // 1. 检查用户级别限流
        int userLimit = userLimits.getOrDefault(userId, DEFAULT_USER_LIMIT);
        AtomicInteger userCount = userCounts.computeIfAbsent(userId, k -> new AtomicInteger(0));

        if (userCount.get() >= userLimit) {
            return RateLimitResult.rejected("USER", userId, userLimit);
        }

        // 2. 检查接口级别限流
        int apiLimit = apiLimits.getOrDefault(apiPath, DEFAULT_API_LIMIT);
        AtomicInteger apiCount = apiCounts.computeIfAbsent(apiPath, k -> new AtomicInteger(0));

        if (apiCount.get() >= apiLimit) {
            return RateLimitResult.rejected("API", apiPath, apiLimit);
        }

        // 3. 检查全局级别限流
        if (globalCount.get() >= globalLimit) {
            return RateLimitResult.rejected("GLOBAL", "global", globalLimit);
        }

        // 4. 原子性地增加所有计数
        // 使用CAS确保不超过限制
        while (true) {
            int currentUser = userCount.get();
            int currentApi = apiCount.get();
            int currentGlobal = globalCount.get();

            // 再次检查
            if (currentUser >= userLimit) {
                return RateLimitResult.rejected("USER", userId, userLimit);
            }
            if (currentApi >= apiLimit) {
                return RateLimitResult.rejected("API", apiPath, apiLimit);
            }
            if (currentGlobal >= globalLimit) {
                return RateLimitResult.rejected("GLOBAL", "global", globalLimit);
            }

            // 尝试增加计数
            if (userCount.compareAndSet(currentUser, currentUser + 1)) {
                if (apiCount.compareAndSet(currentApi, currentApi + 1)) {
                    if (globalCount.compareAndSet(currentGlobal, currentGlobal + 1)) {
                        return RateLimitResult.allowed();
                    } else {
                        // 回滚
                        apiCount.decrementAndGet();
                        userCount.decrementAndGet();
                    }
                } else {
                    // 回滚
                    userCount.decrementAndGet();
                }
            }
            // CAS失败，重试
        }
    }

    /**
     * 释放许可
     */
    public void release(String userId, String apiPath) {
        userCounts.computeIfPresent(userId, (k, v) -> {
            v.decrementAndGet();
            return v;
        });
        apiCounts.computeIfPresent(apiPath, (k, v) -> {
            v.decrementAndGet();
            return v;
        });
        globalCount.decrementAndGet();
    }

    private void resetCounts() {
        userCounts.values().forEach(c -> c.set(0));
        apiCounts.values().forEach(c -> c.set(0));
        globalCount.set(0);
    }

    // 配置方法
    public void setUserLimit(String userId, int limit) {
        userLimits.put(userId, limit);
    }

    public void setApiLimit(String apiPath, int limit) {
        apiLimits.put(apiPath, limit);
    }

    public void setGlobalLimit(int limit) {
        this.globalLimit = limit;
    }

    // 移除配置（使用默认值）
    public void removeUserLimit(String userId) {
        userLimits.remove(userId);
    }

    public void removeApiLimit(String apiPath) {
        apiLimits.remove(apiPath);
    }

    // 获取当前状态
    public int getUserCount(String userId) {
        AtomicInteger count = userCounts.get(userId);
        return count != null ? count.get() : 0;
    }

    public int getApiCount(String apiPath) {
        AtomicInteger count = apiCounts.get(apiPath);
        return count != null ? count.get() : 0;
    }

    public int getGlobalCount() {
        return globalCount.get();
    }

    public void shutdown() {
        scheduler.shutdown();
    }

    /**
     * 限流结果
     */
    static class RateLimitResult {
        final boolean allowed;
        final String dimension;  // USER, API, GLOBAL
        final String key;
        final int limit;

        private RateLimitResult(boolean allowed, String dimension, String key, int limit) {
            this.allowed = allowed;
            this.dimension = dimension;
            this.key = key;
            this.limit = limit;
        }

        static RateLimitResult allowed() {
            return new RateLimitResult(true, null, null, 0);
        }

        static RateLimitResult rejected(String dimension, String key, int limit) {
            return new RateLimitResult(false, dimension, key, limit);
        }

        @Override
        public String toString() {
            if (allowed) {
                return "ALLOWED";
            }
            return String.format("REJECTED[%s:%s, limit=%d]", dimension, key, limit);
        }
    }

    public static void main(String[] args) throws InterruptedException {
        MultiDimensionRateLimiter limiter = new MultiDimensionRateLimiter();

        // 配置限制
        limiter.setUserLimit("user1", 5);   // user1每秒最多5个请求
        limiter.setUserLimit("user2", 10);  // user2每秒最多10个请求
        limiter.setApiLimit("/api/slow", 3); // slow接口每秒最多3个请求
        limiter.setGlobalLimit(20);          // 全局每秒最多20个请求

        System.out.println("=== 测试用户级别限流 ===");
        for (int i = 0; i < 8; i++) {
            RateLimitResult result = limiter.tryAcquire("user1", "/api/normal");
            System.out.println("user1 请求" + i + ": " + result);
        }

        System.out.println("\n=== 测试接口级别限流 ===");
        for (int i = 0; i < 5; i++) {
            RateLimitResult result = limiter.tryAcquire("user2", "/api/slow");
            System.out.println("user2 -> /api/slow 请求" + i + ": " + result);
        }

        System.out.println("\n=== 测试全局级别限流 ===");
        // 先重置计数
        Thread.sleep(1100);

        for (int i = 0; i < 25; i++) {
            String user = "user" + (i % 10);
            String api = "/api/path" + (i % 5);
            RateLimitResult result = limiter.tryAcquire(user, api);
            if (!result.allowed) {
                System.out.println("请求" + i + " [" + user + " -> " + api + "]: " + result);
            }
        }

        System.out.println("\n当前状态:");
        System.out.println("  全局计数: " + limiter.getGlobalCount());

        limiter.shutdown();
    }
}
```

---

## 场景五：生产者-消费者

### 题目 5.8 ⭐⭐⭐⭐ 批量消费的消费者

```java
import java.util.*;
import java.util.concurrent.*;

/**
 * 批量消费的消费者
 * 尽量获取batchSize个元素，但最多等待maxWaitMs
 */
public class BatchConsumer<T> {
    private final BlockingQueue<T> queue;
    private final int batchSize;
    private final long maxWaitMs;

    public BatchConsumer(BlockingQueue<T> queue, int batchSize, long maxWaitMs) {
        this.queue = queue;
        this.batchSize = batchSize;
        this.maxWaitMs = maxWaitMs;
    }

    /**
     * 批量获取数据
     * 至少获取1个，最多获取batchSize个
     * 如果队列空，最多等待maxWaitMs
     */
    public List<T> takeBatch() throws InterruptedException {
        List<T> batch = new ArrayList<>(batchSize);
        long deadline = System.currentTimeMillis() + maxWaitMs;

        // 1. 至少获取一个（阻塞等待）
        T first = queue.poll(maxWaitMs, TimeUnit.MILLISECONDS);
        if (first == null) {
            return batch; // 超时，返回空列表
        }
        batch.add(first);

        // 2. 尽量获取更多（非阻塞或短暂等待）
        while (batch.size() < batchSize) {
            long remaining = deadline - System.currentTimeMillis();
            if (remaining <= 0) {
                break; // 超时
            }

            // 先尝试非阻塞获取
            T item = queue.poll();
            if (item != null) {
                batch.add(item);
                continue;
            }

            // 队列当前为空，短暂等待
            item = queue.poll(Math.min(remaining, 10), TimeUnit.MILLISECONDS);
            if (item != null) {
                batch.add(item);
            } else {
                // 等待后还是空，可能没有更多数据了
                // 如果已经有数据，就返回；否则继续等待
                if (batch.size() > 0) {
                    break;
                }
            }
        }

        return batch;
    }

    /**
     * 批量获取（带最小批量要求）
     * 至少等到minBatch个元素，或者超时
     */
    public List<T> takeBatchWithMin(int minBatch) throws InterruptedException {
        List<T> batch = new ArrayList<>(batchSize);
        long deadline = System.currentTimeMillis() + maxWaitMs;

        while (batch.size() < minBatch) {
            long remaining = deadline - System.currentTimeMillis();
            if (remaining <= 0) {
                break;
            }

            T item = queue.poll(remaining, TimeUnit.MILLISECONDS);
            if (item != null) {
                batch.add(item);
            } else {
                break; // 超时
            }
        }

        // 继续尝试获取更多（非阻塞）
        while (batch.size() < batchSize) {
            T item = queue.poll();
            if (item == null) break;
            batch.add(item);
        }

        return batch;
    }

    /**
     * 使用drainTo的高效实现
     */
    public List<T> takeBatchEfficient() throws InterruptedException {
        List<T> batch = new ArrayList<>(batchSize);

        // 1. 先阻塞获取一个
        T first = queue.poll(maxWaitMs, TimeUnit.MILLISECONDS);
        if (first == null) {
            return batch;
        }
        batch.add(first);

        // 2. 使用drainTo批量获取剩余
        queue.drainTo(batch, batchSize - 1);

        return batch;
    }

    public static void main(String[] args) throws InterruptedException {
        BlockingQueue<Integer> queue = new LinkedBlockingQueue<>();
        BatchConsumer<Integer> consumer = new BatchConsumer<>(queue, 10, 1000);

        // 生产者：不定期生产数据
        Thread producer = new Thread(() -> {
            Random random = new Random();
            for (int i = 0; i < 50; i++) {
                try {
                    queue.put(i);
                    System.out.println("生产: " + i);
                    // 随机间隔
                    Thread.sleep(random.nextInt(100));
                } catch (InterruptedException e) {
                    break;
                }
            }
            System.out.println("生产完成");
        });

        // 消费者：批量消费
        Thread consumerThread = new Thread(() -> {
            int totalConsumed = 0;
            while (totalConsumed < 50) {
                try {
                    List<Integer> batch = consumer.takeBatchEfficient();
                    if (!batch.isEmpty()) {
                        System.out.println("批量消费 " + batch.size() + " 个: " + batch);
                        totalConsumed += batch.size();
                    }
                } catch (InterruptedException e) {
                    break;
                }
            }
            System.out.println("消费完成，共消费: " + totalConsumed);
        });

        producer.start();
        consumerThread.start();

        producer.join();
        consumerThread.join();
    }
}
```

---

### 题目 5.9 ⭐⭐⭐⭐ 带背压的生产者-消费者

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.*;

/**
 * 带背压（Backpressure）的队列
 * 当消费者处理不过来时，生产者自动降速
 */
public class BackpressureQueue<T> {
    private final BlockingQueue<T> queue;
    private final AtomicInteger pendingCount = new AtomicInteger(0);

    private final int highWaterMark;  // 高水位：开始限制生产
    private final int lowWaterMark;   // 低水位：恢复生产

    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();

    private volatile boolean producerBlocked = false;

    public BackpressureQueue(int capacity, int highWaterMark, int lowWaterMark) {
        if (highWaterMark <= lowWaterMark) {
            throw new IllegalArgumentException("highWaterMark must > lowWaterMark");
        }
        this.queue = new LinkedBlockingQueue<>(capacity);
        this.highWaterMark = highWaterMark;
        this.lowWaterMark = lowWaterMark;
    }

    /**
     * 生产数据（带背压）
     */
    public void produce(T item) throws InterruptedException {
        // 如果积压过多，等待
        lock.lock();
        try {
            while (pendingCount.get() >= highWaterMark) {
                producerBlocked = true;
                System.out.println("[背压] 生产者阻塞，当前积压: " + pendingCount.get());
                notFull.await();
            }
            producerBlocked = false;
        } finally {
            lock.unlock();
        }

        // 放入队列
        queue.put(item);
        pendingCount.incrementAndGet();
    }

    /**
     * 带超时的生产
     */
    public boolean produce(T item, long timeout, TimeUnit unit) throws InterruptedException {
        long deadline = System.nanoTime() + unit.toNanos(timeout);

        lock.lock();
        try {
            while (pendingCount.get() >= highWaterMark) {
                long remaining = deadline - System.nanoTime();
                if (remaining <= 0) {
                    return false;
                }
                producerBlocked = true;
                notFull.awaitNanos(remaining);
            }
            producerBlocked = false;
        } finally {
            lock.unlock();
        }

        boolean offered = queue.offer(item, deadline - System.nanoTime(), TimeUnit.NANOSECONDS);
        if (offered) {
            pendingCount.incrementAndGet();
        }
        return offered;
    }

    /**
     * 消费数据
     */
    public T consume() throws InterruptedException {
        T item = queue.take();
        int count = pendingCount.decrementAndGet();

        // 如果降到低水位以下，通知生产者
        if (count <= lowWaterMark && producerBlocked) {
            lock.lock();
            try {
                notFull.signalAll();
            } finally {
                lock.unlock();
            }
        }

        return item;
    }

    /**
     * 批量消费
     */
    public int consumeBatch(java.util.List<T> batch, int maxSize) {
        int drained = queue.drainTo(batch, maxSize);
        int count = pendingCount.addAndGet(-drained);

        if (count <= lowWaterMark && producerBlocked) {
            lock.lock();
            try {
                notFull.signalAll();
            } finally {
                lock.unlock();
            }
        }

        return drained;
    }

    public int getPendingCount() {
        return pendingCount.get();
    }

    public boolean isProducerBlocked() {
        return producerBlocked;
    }

    public static void main(String[] args) throws InterruptedException {
        // 容量100，高水位80，低水位20
        BackpressureQueue<Integer> queue = new BackpressureQueue<>(100, 80, 20);

        // 快速生产者
        Thread producer = new Thread(() -> {
            for (int i = 0; i < 200; i++) {
                try {
                    queue.produce(i);
                    if (i % 20 == 0) {
                        System.out.println("[生产者] 已生产: " + i + ", 积压: " + queue.getPendingCount());
                    }
                } catch (InterruptedException e) {
                    break;
                }
            }
            System.out.println("[生产者] 完成");
        });

        // 慢速消费者
        Thread consumer = new Thread(() -> {
            int consumed = 0;
            while (consumed < 200) {
                try {
                    Integer item = queue.consume();
                    consumed++;
                    // 模拟慢速处理
                    Thread.sleep(20);
                    if (consumed % 20 == 0) {
                        System.out.println("[消费者] 已消费: " + consumed + ", 积压: " + queue.getPendingCount());
                    }
                } catch (InterruptedException e) {
                    break;
                }
            }
            System.out.println("[消费者] 完成");
        });

        producer.start();
        consumer.start();

        producer.join();
        consumer.join();

        System.out.println("最终积压: " + queue.getPendingCount());
    }
}
```

---

## 场景六：缓存/共享Map

### 题目 6.8 ⭐⭐⭐⭐ ConcurrentHashMap 的并行操作

```java
import java.util.concurrent.*;

/**
 * ConcurrentHashMap的并行批量操作演示
 * JDK8引入的forEach、search、reduce等并行操作
 */
public class ParallelMapOperations {
    private final ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();

    public ParallelMapOperations() {
        // 初始化测试数据
        for (int i = 0; i < 10000; i++) {
            map.put("key" + i, i);
        }
    }

    /**
     * 并行遍历
     * @param parallelismThreshold 并行阈值：元素数超过此值才并行
     */
    public void parallelForEach(long parallelismThreshold) {
        System.out.println("=== 并行遍历 (threshold=" + parallelismThreshold + ") ===");

        map.forEach(parallelismThreshold, (k, v) -> {
            // 注意：可能在多个线程中执行
            if (v % 1000 == 0) {
                System.out.println(Thread.currentThread().getName() +
                                  ": " + k + "=" + v);
            }
        });
    }

    /**
     * 并行搜索 - 找到满足条件的第一个元素
     * 一旦找到，会尽快终止其他搜索
     */
    public String parallelSearch(int target) {
        System.out.println("\n=== 并行搜索 (target=" + target + ") ===");

        return map.search(1, (k, v) -> {
            // 返回非null表示找到
            if (v == target) {
                System.out.println(Thread.currentThread().getName() + " 找到: " + k);
                return k;
            }
            return null;
        });
    }

    /**
     * 并行搜索keys
     */
    public String parallelSearchKeys(String prefix) {
        return map.searchKeys(1, k -> k.startsWith(prefix) ? k : null);
    }

    /**
     * 并行搜索values
     */
    public Integer parallelSearchValues(int minValue) {
        return map.searchValues(1, v -> v >= minValue ? v : null);
    }

    /**
     * 并行归约 - 计算所有值的和
     */
    public int parallelReduceValues() {
        System.out.println("\n=== 并行归约 (求和) ===");

        // 直接归约values
        Integer sum = map.reduceValues(1, Integer::sum);
        return sum != null ? sum : 0;
    }

    /**
     * 并行归约 - 自定义归约
     */
    public int parallelReduceValuesToInt() {
        // 转换为int后归约（避免装箱开销）
        return map.reduceValuesToInt(1,
            v -> v,           // transformer: value -> int
            0,                // identity
            Integer::sum      // reducer
        );
    }

    /**
     * 并行转换+归约
     */
    public long parallelMapReduce() {
        System.out.println("\n=== 并行转换+归约 (value平方和) ===");

        // 计算所有value的平方和
        return map.reduceValuesToLong(1,
            v -> (long) v * v,  // transformer
            0L,                 // identity
            Long::sum           // reducer
        );
    }

    /**
     * 并行entries归约
     */
    public String parallelReduceEntries() {
        // 找到value最大的entry
        var maxEntry = map.reduceEntries(1,
            (e1, e2) -> e1.getValue() > e2.getValue() ? e1 : e2);
        return maxEntry != null ? maxEntry.getKey() + "=" + maxEntry.getValue() : null;
    }

    /**
     * 条件计数
     */
    public long parallelCount(int threshold) {
        System.out.println("\n=== 并行计数 (value > " + threshold + ") ===");

        return map.reduceValuesToLong(1,
            v -> v > threshold ? 1L : 0L,
            0L,
            Long::sum
        );
    }

    /**
     * 使用mappingCount获取大小
     */
    public long getMappingCount() {
        // mappingCount()比size()更适合大map
        return map.mappingCount();
    }

    public static void main(String[] args) {
        ParallelMapOperations ops = new ParallelMapOperations();

        // 并行遍历
        ops.parallelForEach(100); // 阈值100，会并行

        // 并行搜索
        String found = ops.parallelSearch(5000);
        System.out.println("搜索结果: " + found);

        // 并行归约
        int sum = ops.parallelReduceValues();
        System.out.println("所有值的和: " + sum);

        // 转换+归约
        long squareSum = ops.parallelMapReduce();
        System.out.println("平方和: " + squareSum);

        // 条件计数
        long count = ops.parallelCount(5000);
        System.out.println("大于5000的数量: " + count);

        // 最大值
        String maxEntry = ops.parallelReduceEntries();
        System.out.println("最大值Entry: " + maxEntry);

        // 性能对比
        System.out.println("\n=== 性能对比 ===");
        ConcurrentHashMap<String, Integer> largeMap = new ConcurrentHashMap<>();
        for (int i = 0; i < 1000000; i++) {
            largeMap.put("key" + i, i);
        }

        // 串行求和
        long start = System.currentTimeMillis();
        long sum1 = 0;
        for (Integer v : largeMap.values()) {
            sum1 += v;
        }
        System.out.println("串行求和: " + sum1 + ", 耗时: " +
                          (System.currentTimeMillis() - start) + "ms");

        // 并行求和
        start = System.currentTimeMillis();
        long sum2 = largeMap.reduceValuesToLong(1, v -> v, 0L, Long::sum);
        System.out.println("并行求和: " + sum2 + ", 耗时: " +
                          (System.currentTimeMillis() - start) + "ms");
    }
}
```

---

### 题目 6.9 ⭐⭐⭐⭐ 支持过期的ConcurrentMap

```java
import java.util.*;
import java.util.concurrent.*;

/**
 * 支持条目自动过期的ConcurrentMap
 * 高并发安全，过期条目及时清理
 */
public class ExpiringConcurrentMap<K, V> {
    private final ConcurrentHashMap<K, ExpiringEntry<V>> map = new ConcurrentHashMap<>();
    private final ScheduledExecutorService cleaner;
    private final long cleanupIntervalMs;

    // 分段锁用于清理操作
    private static final int SEGMENT_COUNT = 16;
    private final Object[] segmentLocks = new Object[SEGMENT_COUNT];

    static class ExpiringEntry<V> {
        final V value;
        final long expireTime;
        volatile boolean removed = false;

        ExpiringEntry(V value, long expireTime) {
            this.value = value;
            this.expireTime = expireTime;
        }

        boolean isExpired() {
            return System.currentTimeMillis() > expireTime;
        }
    }

    public ExpiringConcurrentMap() {
        this(1000); // 默认每秒清理一次
    }

    public ExpiringConcurrentMap(long cleanupIntervalMs) {
        this.cleanupIntervalMs = cleanupIntervalMs;

        for (int i = 0; i < SEGMENT_COUNT; i++) {
            segmentLocks[i] = new Object();
        }

        cleaner = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "expiring-map-cleaner");
            t.setDaemon(true);
            return t;
        });

        cleaner.scheduleAtFixedRate(this::cleanup,
            cleanupIntervalMs, cleanupIntervalMs, TimeUnit.MILLISECONDS);
    }

    public void put(K key, V value, long ttl, TimeUnit unit) {
        long expireTime = System.currentTimeMillis() + unit.toMillis(ttl);
        map.put(key, new ExpiringEntry<>(value, expireTime));
    }

    public V get(K key) {
        ExpiringEntry<V> entry = map.get(key);
        if (entry == null) {
            return null;
        }

        if (entry.isExpired()) {
            // 懒删除：读取时发现过期，尝试删除
            if (map.remove(key, entry)) {
                entry.removed = true;
            }
            return null;
        }

        return entry.value;
    }

    public V getOrDefault(K key, V defaultValue) {
        V value = get(key);
        return value != null ? value : defaultValue;
    }

    public V remove(K key) {
        ExpiringEntry<V> entry = map.remove(key);
        if (entry != null) {
            entry.removed = true;
            return entry.value;
        }
        return null;
    }

    public boolean containsKey(K key) {
        return get(key) != null;
    }

    public int size() {
        // 注意：这个size包含已过期但未清理的条目
        // 如果需要精确值，应该遍历检查
        return map.size();
    }

    public int activeSize() {
        int count = 0;
        for (ExpiringEntry<V> entry : map.values()) {
            if (!entry.isExpired() && !entry.removed) {
                count++;
            }
        }
        return count;
    }

    /**
     * 刷新过期时间
     */
    public boolean refresh(K key, long ttl, TimeUnit unit) {
        ExpiringEntry<V> oldEntry = map.get(key);
        if (oldEntry == null || oldEntry.isExpired()) {
            return false;
        }

        long newExpireTime = System.currentTimeMillis() + unit.toMillis(ttl);
        ExpiringEntry<V> newEntry = new ExpiringEntry<>(oldEntry.value, newExpireTime);
        return map.replace(key, oldEntry, newEntry);
    }

    /**
     * 后台清理任务
     */
    private void cleanup() {
        int cleaned = 0;

        for (Map.Entry<K, ExpiringEntry<V>> entry : map.entrySet()) {
            if (entry.getValue().isExpired()) {
                // 使用remove(key, value)保证原子性
                if (map.remove(entry.getKey(), entry.getValue())) {
                    entry.getValue().removed = true;
                    cleaned++;
                }
            }
        }

        if (cleaned > 0) {
            System.out.println("[Cleaner] 清理了 " + cleaned + " 个过期条目");
        }
    }

    /**
     * 强制清理所有过期条目
     */
    public int forceCleanup() {
        int cleaned = 0;
        for (Map.Entry<K, ExpiringEntry<V>> entry : map.entrySet()) {
            if (entry.getValue().isExpired()) {
                if (map.remove(entry.getKey(), entry.getValue())) {
                    cleaned++;
                }
            }
        }
        return cleaned;
    }

    public void shutdown() {
        cleaner.shutdown();
    }

    public static void main(String[] args) throws InterruptedException {
        ExpiringConcurrentMap<String, String> cache = new ExpiringConcurrentMap<>(500);

        // 放入不同过期时间的数据
        cache.put("fast", "快速过期", 500, TimeUnit.MILLISECONDS);
        cache.put("medium", "中等过期", 2000, TimeUnit.MILLISECONDS);
        cache.put("slow", "慢速过期", 5000, TimeUnit.MILLISECONDS);

        System.out.println("初始状态:");
        System.out.println("  fast: " + cache.get("fast"));
        System.out.println("  medium: " + cache.get("medium"));
        System.out.println("  slow: " + cache.get("slow"));
        System.out.println("  size: " + cache.size());

        Thread.sleep(700);
        System.out.println("\n700ms后:");
        System.out.println("  fast: " + cache.get("fast"));   // null
        System.out.println("  medium: " + cache.get("medium")); // 有值
        System.out.println("  activeSize: " + cache.activeSize());

        // 刷新medium的过期时间
        cache.refresh("medium", 3000, TimeUnit.MILLISECONDS);
        System.out.println("  刷新medium的TTL为3秒");

        Thread.sleep(1500);
        System.out.println("\n2200ms后:");
        System.out.println("  medium: " + cache.get("medium")); // 还有值（被刷新了）
        System.out.println("  slow: " + cache.get("slow"));

        // 多线程测试
        System.out.println("\n=== 多线程测试 ===");
        ExpiringConcurrentMap<Integer, Integer> map = new ExpiringConcurrentMap<>();
        int threadCount = 10;
        Thread[] threads = new Thread[threadCount];

        for (int i = 0; i < threadCount; i++) {
            int id = i;
            threads[i] = new Thread(() -> {
                Random random = new Random();
                for (int j = 0; j < 1000; j++) {
                    int key = random.nextInt(100);
                    if (random.nextBoolean()) {
                        map.put(key, j, random.nextInt(100) + 50, TimeUnit.MILLISECONDS);
                    } else {
                        map.get(key);
                    }
                }
            });
        }

        long start = System.currentTimeMillis();
        for (Thread t : threads) t.start();
        for (Thread t : threads) t.join();
        System.out.println("多线程操作耗时: " + (System.currentTimeMillis() - start) + "ms");
        System.out.println("最终size: " + map.size());
        System.out.println("activeSize: " + map.activeSize());

        cache.shutdown();
        map.shutdown();
    }
}
```

---

## 场景七：异步任务编排

### 题目 7.8 ⭐⭐⭐⭐ 异步任务编排器（DAG）

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Supplier;

/**
 * 支持DAG依赖的任务编排器
 * 按照依赖关系自动调度执行
 */
public class TaskOrchestrator {

    public static class Task {
        final String name;
        final Supplier<CompletableFuture<?>> action;
        final List<String> dependencies;

        public Task(String name, Supplier<CompletableFuture<?>> action, String... dependencies) {
            this.name = name;
            this.action = action;
            this.dependencies = Arrays.asList(dependencies);
        }
    }

    private final Map<String, Task> tasks = new ConcurrentHashMap<>();
    private final Map<String, CompletableFuture<?>> futures = new ConcurrentHashMap<>();
    private final ExecutorService executor;

    public TaskOrchestrator() {
        this.executor = Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors());
    }

    public TaskOrchestrator(ExecutorService executor) {
        this.executor = executor;
    }

    public void addTask(Task task) {
        tasks.put(task.name, task);
    }

    /**
     * 便捷方法：添加任务
     */
    public void addTask(String name, Runnable action, String... dependencies) {
        addTask(new Task(name, () -> CompletableFuture.runAsync(action, executor), dependencies));
    }

    public <T> void addTask(String name, Supplier<T> action, String... dependencies) {
        addTask(new Task(name, () -> CompletableFuture.supplyAsync(action, executor), dependencies));
    }

    /**
     * 执行所有任务
     */
    public CompletableFuture<Void> execute() {
        // 验证DAG无环
        if (hasCycle()) {
            return CompletableFuture.failedFuture(
                new IllegalStateException("检测到循环依赖"));
        }

        // 启动所有任务
        for (Task task : tasks.values()) {
            scheduleTask(task);
        }

        // 等待所有任务完成
        return CompletableFuture.allOf(
            futures.values().toArray(new CompletableFuture[0]));
    }

    private CompletableFuture<?> scheduleTask(Task task) {
        return futures.computeIfAbsent(task.name, name -> {
            if (task.dependencies.isEmpty()) {
                // 无依赖，直接执行
                System.out.println("[启动] " + name + " (无依赖)");
                return task.action.get()
                    .whenComplete((r, e) -> {
                        if (e != null) {
                            System.out.println("[失败] " + name + ": " + e.getMessage());
                        } else {
                            System.out.println("[完成] " + name);
                        }
                    });
            }

            // 有依赖，等待所有依赖完成
            CompletableFuture<?>[] deps = task.dependencies.stream()
                .map(depName -> {
                    Task depTask = tasks.get(depName);
                    if (depTask == null) {
                        throw new IllegalStateException("依赖任务不存在: " + depName);
                    }
                    return scheduleTask(depTask);
                })
                .toArray(CompletableFuture[]::new);

            System.out.println("[等待依赖] " + name + " -> " + task.dependencies);

            return CompletableFuture.allOf(deps)
                .thenCompose(v -> {
                    System.out.println("[启动] " + name + " (依赖已完成)");
                    return task.action.get();
                })
                .whenComplete((r, e) -> {
                    if (e != null) {
                        System.out.println("[失败] " + name + ": " + e.getMessage());
                    } else {
                        System.out.println("[完成] " + name);
                    }
                });
        });
    }

    /**
     * 检测循环依赖
     */
    private boolean hasCycle() {
        Set<String> visited = new HashSet<>();
        Set<String> inStack = new HashSet<>();

        for (String taskName : tasks.keySet()) {
            if (hasCycleDFS(taskName, visited, inStack)) {
                return true;
            }
        }
        return false;
    }

    private boolean hasCycleDFS(String name, Set<String> visited, Set<String> inStack) {
        if (inStack.contains(name)) {
            return true; // 发现环
        }
        if (visited.contains(name)) {
            return false;
        }

        visited.add(name);
        inStack.add(name);

        Task task = tasks.get(name);
        if (task != null) {
            for (String dep : task.dependencies) {
                if (hasCycleDFS(dep, visited, inStack)) {
                    return true;
                }
            }
        }

        inStack.remove(name);
        return false;
    }

    /**
     * 获取任务结果
     */
    @SuppressWarnings("unchecked")
    public <T> T getResult(String taskName) throws ExecutionException, InterruptedException {
        CompletableFuture<?> future = futures.get(taskName);
        if (future == null) {
            throw new IllegalStateException("任务未执行: " + taskName);
        }
        return (T) future.get();
    }

    public void shutdown() {
        executor.shutdown();
    }

    public static void main(String[] args) throws Exception {
        TaskOrchestrator orchestrator = new TaskOrchestrator();

        /*
         * 任务依赖关系:
         *
         *     A ──────┐
         *             ├──→ D ──→ F
         *     B ──┬───┘         ↑
         *         │             │
         *         └──→ C ──→ E ─┘
         */

        orchestrator.addTask("A", () -> {
            sleep(100);
            System.out.println("  任务A执行");
            return "ResultA";
        });

        orchestrator.addTask("B", () -> {
            sleep(150);
            System.out.println("  任务B执行");
            return "ResultB";
        });

        orchestrator.addTask("C", () -> {
            sleep(80);
            System.out.println("  任务C执行");
            return "ResultC";
        }, "B");

        orchestrator.addTask("D", () -> {
            sleep(100);
            System.out.println("  任务D执行");
            return "ResultD";
        }, "A", "B");

        orchestrator.addTask("E", () -> {
            sleep(50);
            System.out.println("  任务E执行");
            return "ResultE";
        }, "C");

        orchestrator.addTask("F", () -> {
            sleep(50);
            System.out.println("  任务F执行");
            return "ResultF";
        }, "D", "E");

        System.out.println("=== 开始执行 ===\n");
        long start = System.currentTimeMillis();

        orchestrator.execute().join();

        long elapsed = System.currentTimeMillis() - start;
        System.out.println("\n=== 全部完成 ===");
        System.out.println("总耗时: " + elapsed + "ms");
        // 最长路径: B(150) -> C(80) -> E(50) -> F(50) = 330ms
        // 但D(100)等待A(100)和B(150)，所以是 max(150, 100+100) = 200
        // 实际最长: B(150) -> D(100) -> F(50) = 300ms 或 B(150) -> C(80) -> E(50) -> F(50) = 330ms

        orchestrator.shutdown();
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

---

### 题目 7.9 ⭐⭐⭐⭐ 可取消的异步操作

```java
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Function;

/**
 * 可取消的异步操作
 * 支持取消整个操作链
 */
public class CancellableAsync {

    /**
     * 可取消的任务包装
     */
    public static class CancellableTask<T> {
        private final CompletableFuture<T> future;
        private final AtomicBoolean cancelled = new AtomicBoolean(false);
        private volatile Thread executingThread;

        private CancellableTask(CompletableFuture<T> future) {
            this.future = future;
        }

        public CompletableFuture<T> getFuture() {
            return future;
        }

        public boolean cancel() {
            if (cancelled.compareAndSet(false, true)) {
                // 尝试中断执行线程
                Thread t = executingThread;
                if (t != null) {
                    t.interrupt();
                }

                // 完成future为取消状态
                future.completeExceptionally(new CancellationException("任务被取消"));
                return true;
            }
            return false;
        }

        public boolean isCancelled() {
            return cancelled.get();
        }

        public boolean isDone() {
            return future.isDone();
        }

        void setExecutingThread(Thread t) {
            this.executingThread = t;
        }
    }

    private final ExecutorService executor;

    public CancellableAsync() {
        this.executor = Executors.newCachedThreadPool();
    }

    public CancellableAsync(ExecutorService executor) {
        this.executor = executor;
    }

    /**
     * 提交可取消的任务
     */
    public <T> CancellableTask<T> submit(Callable<T> task) {
        CompletableFuture<T> future = new CompletableFuture<>();
        CancellableTask<T> cancellableTask = new CancellableTask<>(future);

        executor.submit(() -> {
            cancellableTask.setExecutingThread(Thread.currentThread());

            if (cancellableTask.isCancelled()) {
                return;
            }

            try {
                T result = task.call();
                if (!cancellableTask.isCancelled()) {
                    future.complete(result);
                }
            } catch (InterruptedException e) {
                if (!cancellableTask.isCancelled()) {
                    future.completeExceptionally(e);
                }
            } catch (Exception e) {
                future.completeExceptionally(e);
            }
        });

        return cancellableTask;
    }

    /**
     * 提交可取消的异步链
     */
    public <T> CancellableTask<T> submitChain(
            Callable<T> firstTask,
            Function<T, T>... transforms) {

        CompletableFuture<T> future = new CompletableFuture<>();
        CancellableTask<T> cancellableTask = new CancellableTask<>(future);

        executor.submit(() -> {
            cancellableTask.setExecutingThread(Thread.currentThread());

            try {
                // 执行第一个任务
                if (cancellableTask.isCancelled()) return;
                T result = firstTask.call();

                // 执行转换链
                for (Function<T, T> transform : transforms) {
                    if (cancellableTask.isCancelled()) return;
                    result = transform.apply(result);
                }

                if (!cancellableTask.isCancelled()) {
                    future.complete(result);
                }
            } catch (InterruptedException e) {
                if (!cancellableTask.isCancelled()) {
                    future.completeExceptionally(e);
                }
            } catch (Exception e) {
                future.completeExceptionally(e);
            }
        });

        return cancellableTask;
    }

    /**
     * 带超时的执行
     */
    public <T> T executeWithTimeout(Callable<T> task, long timeout, TimeUnit unit)
            throws ExecutionException, InterruptedException, TimeoutException {
        CancellableTask<T> cancellableTask = submit(task);

        try {
            return cancellableTask.getFuture().get(timeout, unit);
        } catch (TimeoutException e) {
            cancellableTask.cancel();
            throw e;
        }
    }

    /**
     * 同时执行多个任务，任意一个完成后取消其他
     */
    @SafeVarargs
    public final <T> T anyOf(Callable<T>... tasks)
            throws ExecutionException, InterruptedException {

        List<CancellableTask<T>> cancellableTasks = new ArrayList<>();

        for (Callable<T> task : tasks) {
            cancellableTasks.add(submit(task));
        }

        CompletableFuture<T>[] futures = cancellableTasks.stream()
            .map(CancellableTask::getFuture)
            .toArray(CompletableFuture[]::new);

        try {
            // 等待任意一个完成
            T result = (T) CompletableFuture.anyOf(futures).get();

            // 取消其他任务
            for (CancellableTask<T> ct : cancellableTasks) {
                if (!ct.isDone()) {
                    ct.cancel();
                }
            }

            return result;
        } catch (ExecutionException e) {
            // 取消所有任务
            for (CancellableTask<T> ct : cancellableTasks) {
                ct.cancel();
            }
            throw e;
        }
    }

    public void shutdown() {
        executor.shutdown();
    }

    public static void main(String[] args) throws Exception {
        CancellableAsync async = new CancellableAsync();

        // 测试基本取消
        System.out.println("=== 测试基本取消 ===");
        CancellableTask<String> task1 = async.submit(() -> {
            System.out.println("任务开始执行...");
            Thread.sleep(5000);
            return "完成";
        });

        Thread.sleep(100);
        System.out.println("取消任务: " + task1.cancel());
        System.out.println("是否取消: " + task1.isCancelled());

        try {
            task1.getFuture().get();
        } catch (Exception e) {
            System.out.println("获取结果异常: " + e.getCause().getClass().getSimpleName());
        }

        // 测试超时
        System.out.println("\n=== 测试超时取消 ===");
        try {
            async.executeWithTimeout(() -> {
                System.out.println("长时间任务开始...");
                Thread.sleep(5000);
                return "完成";
            }, 200, TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            System.out.println("任务超时被取消");
        }

        // 测试anyOf
        System.out.println("\n=== 测试anyOf（最快返回）===");
        String result = async.anyOf(
            () -> { Thread.sleep(300); return "任务1完成"; },
            () -> { Thread.sleep(100); return "任务2完成"; },
            () -> { Thread.sleep(200); return "任务3完成"; }
        );
        System.out.println("最快完成: " + result);

        Thread.sleep(500); // 等待其他任务被取消

        async.shutdown();
    }
}
```

---

## 总结

本文档涵盖了 JUC 包中 7 个核心场景的 **困难** 难度练习题参考答案：

| 场景 | 题号 | 主题 | 核心知识点 |
|------|------|------|-----------|
| 计数器/累加器 | 1.8 | Treiber Stack | 无锁栈、CAS自旋、ABA问题 |
| | 1.9 | Snowflake ID | 分布式ID、时钟回拨、位运算 |
| 读多写少 | 2.8 | 可中断读写锁 | tryLock超时、lockInterruptibly |
| | 2.9 | StampedLock转换 | 乐观读、锁升级/降级、不可重入 |
| 线程协作 | 3.8 | 可重用Latch | Condition、generation设计 |
| | 3.9 | 分布式屏障 | 心跳检测、节点宕机处理 |
| 资源池/限流 | 4.8 | 自适应限流 | AIMD算法、动态调整 |
| | 4.9 | 多维度限流 | 用户/接口/全局三级限流 |
| 生产者-消费者 | 5.8 | 批量消费 | drainTo、超时策略 |
| | 5.9 | 背压队列 | 高低水位、流量控制 |
| 缓存/共享Map | 6.8 | 并行Map操作 | forEach/search/reduce并行 |
| | 6.9 | 过期Map | 懒删除、后台清理 |
| 异步编排 | 7.8 | DAG编排器 | 依赖图、拓扑排序、环检测 |
| | 7.9 | 可取消异步 | 中断传播、anyOf竞争 |

**学习建议**：
1. 困难题目涉及较多边界情况和性能优化
2. 建议先理解基础版本，再考虑优化
3. 注意多线程环境下的各种边界条件
4. 参考JDK源码学习最佳实践
