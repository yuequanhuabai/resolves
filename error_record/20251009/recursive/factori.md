  @Test
    public void test1() {
        long factorial = factorial(4);
        System.out.println("factorial:" + factorial);

    }

    public long factorial(int n) {
        long facor = 1;
        if (n == 0 || n == 1) {
            return facor;
        }
        if (n >= 2) {
            facor = n * factorial(n - 1);
        }
        return facor;

    }