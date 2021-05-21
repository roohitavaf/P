// spec WaitingForAllDone observes  REQ, ALL_WORK_DONE {
//     start state Init {
//         entry {
//             goto Done; 
//         }
//     }

//     cold state Done {
//         on REQ goto Waiting; 
//     }

//     hot state Waiting {
//         on ALL_WORK_DONE goto Done; 
//     }
// }