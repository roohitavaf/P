spec WaitingForAllDone observes  REQ, ALL_WORK_DONE {
    start state Init {
        on REQ goto Waiting; 
    }

    hot state Waiting {
        on ALL_WORK_DONE goto Init; 
    }
}