event GO_A; 
event GO_B; 
event GO_INIT; 

machine MainMachine {
    start state Init {
        entry {
            if ($){
                send this, GO_A; 
            }else {
                send this, halt; 
            }
        }

        on GO_A goto A; 
        on GO_B goto B; 
    }

    state A {
        entry {
            send this, GO_INIT; 
        }

        on GO_INIT goto Init; 
    }
    
    state  B{
        entry {
            send this, GO_INIT; 
        }

        on GO_INIT goto Init; 
    }
}