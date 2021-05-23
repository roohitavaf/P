event REQ; 
event WORK_DONE;
event CALL_DONE;
event ALL_WORK_DONE;
event REQ_DONE; 
event PING;
event PONG; 

machine MainMachine {
    var workers : seq[machine]; 
    var workers_num: int; 
    var received_num: int; 

    start state Init {
        entry {
            var i: int;
            workers_num = 10;
            i = 0; 
            while (i < workers_num) {
                workers += (i, new Worker(this)); 
                i = i + 1;
            }
            goto SendRequests;
        }
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

        on WORK_DONE do {
            received_num = received_num + 1;
        }

        ignore PONG;
    }

    state Waiting {
        entry { //liveness bug fix
            if (received_num == workers_num) {
                send this,  ALL_WORK_DONE;
            } 
        }
        on WORK_DONE do {
            received_num = received_num + 1;
            assert received_num <= workers_num, format ("unexpected number of WORK_DONES: max {0}, but received {1}", workers_num, received_num);
            assert received_num <= workers_num, format ("unexpected number of WORK_DONES: max {0}, but received {1}", workers_num, received_num);
            if (received_num == workers_num) {
                send this,  ALL_WORK_DONE;
            } 
        }

        on ALL_WORK_DONE goto SendRequests;

        on null do {
            send workers[0], PING;
        }

        ignore PONG;
    }
}

machine Worker {
    var requester_machine: machine; 

    start state Init {
        entry (id: machine){
            requester_machine = id; 
            goto Waiting;
        }
    }
    state Waiting {
        on REQ push Working; 
        on PING do {
            send requester_machine, PONG;
        }

        on WORK_DONE do {
            send requester_machine, WORK_DONE;
        }
    }

    state Working {
        entry {
            send this, CALL_DONE;
        }

        on CALL_DONE do {
            raise WORK_DONE;
        }
    }
}