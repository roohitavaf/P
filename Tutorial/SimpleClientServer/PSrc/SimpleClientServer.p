event EVENT1: int;
event Request: machine; 
event Response: int; 
 
machine Client {
    var myMap : map[string, int];
    var server: machine; 
 
    start state Init {
        entry {
            server = new Server(); 
            send server, Request, this;
            receive {
                case Response: (payload: int) {
                    raise EVENT1, payload;
                }
            }        
        }
 
        on EVENT1 do (payload: int) {
            goto State2, testFunction(payload);
        } 
    }
 
    state State2 {
        entry (payload: int){
            assert (1==2), format ("received EVENT1 with age {0}", payload);
        }
    }
}
 
machine Server {
    start state init {
        on Request do (payload: machine){
            send payload, Response, 34; 
        }
    }
}
 
fun testFunction (num: int) :int {
    return num;
}
