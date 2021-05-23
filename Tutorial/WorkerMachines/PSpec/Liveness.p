spec Liveness observes  REQ, ALL_WORK_DONE {
    start cold state Init {
        on REQ goto Waiting; 
    }

    hot state Waiting {
        on ALL_WORK_DONE goto Init; 
        ignore REQ;
    }
}