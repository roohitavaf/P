event REQ: int; 
event WORK_DONE: int;
event ALL_WORK_DONE: int;
event REQ_DONE: int; 
event RESTART; 
event PUSH_START;

machine FaultInjector {
    var machines : seq[machine]; 

    start state Init {
        entry (targets: seq[machine]){
            var i : int; 
            
            i=0; 
            while (i < sizeof(targets)){
                machines += (i ,targets[i]);
                i = i + 1;
            }
            goto InjectFaults; 
        }
    }

    state InjectFaults {
        on null do {
            var m : machine; 
            m = choose (machines); 
            send m, RESTART; 
        }
    }
}

machine MainMachine {
    var workers : seq[machine]; 
    var workers_num: int; 
    var received_num: int; 
    var term : int; 

    start state Init {
        entry {
            var i: int;
            var targets : seq[machine]; 

            term = 0;
            targets += (0, this); 
            workers_num = 10;
            i = 0; 
            while (i < workers_num) {
                workers += (i, new Worker(this)); 
                targets += (i+1, workers[i]); 
                i = i + 1;
            }

            new FaultInjector(targets);
            raise RESTART; 
        }

        on RESTART do {
            term = term + 1 ;
            received_num = 0;
            raise PUSH_START; 
        }

        on PUSH_START push SendRequests;
    }

    state SendRequests {
        entry {
            var i: int;
            received_num = 0;
            i = 0; 
            while (i < workers_num) {
                send workers[i], REQ, term; 
                i = i + 1; 
            }
            send this, REQ_DONE, term;
        }
        on REQ_DONE do (t: int) {
            if (t == term) 
                goto Waiting; 
        }

        on WORK_DONE do (t: int) {
            if (t == term) //bug fix (2)
                received_num = received_num + 1;
        }
    }

    state Waiting {
        on WORK_DONE do (t: int) {
            if (t == term) {
                received_num = received_num + 1;
                assert received_num <= workers_num, format ("unexpected number of WORK_DONES: max {0}, but received {1}", workers_num, received_num);
                if (received_num == workers_num) {
                    raise  ALL_WORK_DONE, term;
                } 
            }
        }

        on ALL_WORK_DONE do (t: int){
            if (t == term)
                goto SendRequests;
        } 

        ignore REQ_DONE; //bug fix (1)
    }
}

machine Worker {
    var requester_machine: machine; 

    start state Init {
        entry (id: machine){
            requester_machine = id; 
            raise RESTART;
        }

        on RESTART push Waiting; 
    }

    state Waiting {
        on REQ goto Working; 
    }

    state Working {
        entry (t: int) {
            send requester_machine, WORK_DONE, t; 
            raise WORK_DONE, t;
        }

        on WORK_DONE goto Waiting;
    }
}