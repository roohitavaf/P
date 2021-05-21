event REQ; 
event WORK_DONE;
event ALL_WORK_DONE;
event REQ_DONE; 
event RESTART; 
event PUSH_START;
event INJECT_FAULT;

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

    start state Init {
        entry {
            var i: int;
            var targets : seq[machine]; 

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
                send workers[i], REQ; 
                i = i + 1; 
            }
            send this, REQ_DONE;
        }
        on REQ_DONE goto Waiting; 

        on WORK_DONE do  {
            received_num = received_num + 1;
        }
    }

    state Waiting {
        on WORK_DONE do {
            received_num = received_num + 1;
            assert received_num <= workers_num, format ("unexpected number of WORK_DONES: max {0}, but received {1}", workers_num, received_num);
            if (received_num == workers_num) {
                raise  ALL_WORK_DONE;
            } 
        }

        on ALL_WORK_DONE goto SendRequests;

        ignore REQ_DONE; //bug fix
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
        entry {
            send requester_machine, WORK_DONE; 
            raise WORK_DONE;
        }

        on WORK_DONE goto Waiting;
    }
}