# 10个线程 x 1000次自增，最终结果为10000

## 题目要求

启动10个线程，每个线程对计数器执行1000次 `increment()`，最终结果应为10000。

---

## 错误示范：直接 count++

```java
public class WrongCounter {
    private int count = 0;

    public void increment() {
        count++; // 非原子操作：读→加→写，会被打断
    }

    public int getCount() {
        return count;
    }

    public static void main(String[] args) throws InterruptedException {
        WrongCounter counter = new WrongCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        // 结果 < 10000，每次运行结果不同
        System.out.println("结果: " + counter.getCount());
    }
}
```

---

## 解法一：synchronized 方法

```java
public class SynchronizedMethodCounter {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public synchronized int getCount() {
        return count;
    }

    public static void main(String[] args) throws InterruptedException {
        SynchronizedMethodCounter counter = new SynchronizedMethodCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("结果: " + counter.getCount()); // 10000
    }
}
```

**原理**：锁住整个方法，同一时刻只有一个线程能执行 increment()。

---

## 解法二：synchronized 代码块

```java
public class SynchronizedBlockCounter {
    private int count = 0;
    private final Object lock = new Object();

    public void increment() {
        synchronized (lock) {
            count++;
        }
    }

    public int getCount() {
        synchronized (lock) {
            return count;
        }
    }

    public static void main(String[] args) throws InterruptedException {
        SynchronizedBlockCounter counter = new SynchronizedBlockCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("结果: " + counter.getCount()); // 10000
    }
}
```

**原理**：和解法一本质相同，只是锁的粒度更精确，锁的是自定义的 lock 对象而非 this。

---

## 解法三：ReentrantLock

```java
import java.util.concurrent.locks.ReentrantLock;

public class ReentrantLockCounter {
    private int count = 0;
    private final ReentrantLock lock = new ReentrantLock();

    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }

    public int getCount() {
        lock.lock();
        try {
            return count;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ReentrantLockCounter counter = new ReentrantLockCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("结果: " + counter.getCount()); // 10000
    }
}
```

**原理**：基于 AQS + park/unpark 实现的显式锁。拿不到锁的线程 park() 挂起，释放锁时 unpark() 唤醒队列头部线程。

---

## 解法四：AtomicInteger（CAS）—— 最优解

```java
import java.util.concurrent.atomic.AtomicInteger;

public class AtomicCounter {
    private AtomicInteger count = new AtomicInteger(0);

    public void increment() {
        count.incrementAndGet();
    }

    public int getCount() {
        return count.get();
    }

    public static void main(String[] args) throws InterruptedException {
        AtomicCounter counter = new AtomicCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("结果: " + counter.getCount()); // 10000
    }
}
```

**原理**：底层用 CPU 的 CAS 指令，乐观策略。失败了重新读、重新试，线程不会挂起。10个线程竞争单变量自增，这是 CAS 最擅长的场景。

---

## 解法五：LongAdder（分段 CAS）

```java
import java.util.concurrent.atomic.LongAdder;

public class LongAdderCounter {
    private LongAdder count = new LongAdder();

    public void increment() {
        count.increment();
    }

    public long getCount() {
        return count.sum();
    }

    public static void main(String[] args) throws InterruptedException {
        LongAdderCounter counter = new LongAdderCounter();
        Thread[] threads = new Thread[10];

        for (int i = 0; i < 10; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 1000; j++) {
                    counter.increment();
                }
            });
            threads[i].start();
        }

        for (Thread t : threads) {
            t.join();
        }

        System.out.println("结果: " + counter.getCount()); // 10000
    }
}
```

**原理**：CAS 竞争激烈时，把计数分散到多个 Cell 格子里，每个线程尽量操作不同的格子，最后 sum() 求和。线程特别多时性能优于 AtomicInteger。

---

## 五种解法对比

| 解法 | 原理 | 线程会挂起吗 | 适用场景 |
|---|---|---|---|
| synchronized 方法 | JVM 内置互斥锁 | 会 | 简单场景，代码最少 |
| synchronized 代码块 | JVM 内置互斥锁 | 会 | 需要精确控制锁范围 |
| ReentrantLock | AQS + park/unpark | 会 | 需要公平锁、可中断、多条件 |
| AtomicInteger | CAS 硬件指令 | 不会 | 单变量操作，竞争不激烈 |
| LongAdder | 分段 CAS | 不会 | 单变量操作，竞争非常激烈 |

**本题推荐**：AtomicInteger（解法四），因为操作简单、竞争适中、性能最好。
