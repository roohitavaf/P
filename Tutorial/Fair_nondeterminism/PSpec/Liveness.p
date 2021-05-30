spec Liveness observes  GO_A, GO_B {
    start state Init {
        on GO_A goto A; 
        on GO_B goto B;
    }

    hot state A {
        on GO_B goto B;
        ignore GO_A;
    }

    cold state B {
        on GO_A goto A; 
        ignore GO_B; 
    }
}