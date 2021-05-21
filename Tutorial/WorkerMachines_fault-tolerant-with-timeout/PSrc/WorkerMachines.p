event REQ: int; 
event WORK_DONE: int;
event ALL_WORK_DONE: int;
event REQ_DONE: int; 
event RESTART; 
event PUSH_START;
event INJECT_FAULT;
event TIMEOUT: int; 

machine FaultInjector {
    var machines : seq[machine];
    var fault_count: int;
    var max_faults_num: int; 

    start state Init {
        entry (targets: seq[machine]){
            var i : int; 

            fault_count = 0; 
            max_faults_num = 100;
            
            i=0; 
            while (i < sizeof(targets)){
                machines += (i ,targets[i]);
                i = i + 1;
            }
            goto InjectFaults; 
        }
    }

    state InjectFaults {
        entry {
            send this, INJECT_FAULT; 
        }
        on INJECT_FAULT do {
            var m : machine; 
            m = choose (machines); 
            send m, RESTART;    
            fault_count = fault_count + 1;
            if (fault_count < max_faults_num)
                send this, INJECT_FAULT;
        }
    }
}

machine Timer {
    var requester_machine: machine; 
    var term: int; 

    start state Init {
        entry (id: machine){
            requester_machine = id; 
            goto Waiting; 
        }
    }

    state Waiting {
        on REQ goto TimerOn; 
    }

    state TimerOn {
        entry (t: int){
            term = t; 
        }

        on null do {
            send requester_machine, TIMEOUT, term; 
            raise TIMEOUT, term; 
        }

        on TIMEOUT goto Waiting;

        ignore REQ;  
    }
}

machine MainMachine {
    var workers : seq[machine]; 
    var workers_num: int; 
    var received_num: int; 
    var term : int; 
    var timer: machine; 
    var max_term: int;

    start state Init {
        entry {
            var i: int;
            var targets : seq[machine]; 

            term = 0;
            max_term = 100;
            targets += (0, this); 
            workers_num = 10;
            i = 0; 
            while (i < workers_num) {
                workers += (i, new Worker(this)); 
                targets += (i+1, workers[i]); 
                i = i + 1;
            }

            new FaultInjector(targets);
            timer = new Timer(this);
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

        ignore TIMEOUT;
    }

    state Waiting {
        entry {
            send timer, REQ, term; 
        }

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

        on TIMEOUT do (t: int){
            if (term == t && term < max_term){
                raise RESTART; 
            }
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