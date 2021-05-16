
machine HelloWorld {
    start state Init {
        entry {
           assert (1==2), format("Hello {0}", "World");
        }
    }
}