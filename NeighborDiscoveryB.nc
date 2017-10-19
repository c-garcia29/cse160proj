#include "includes/packet.h"
#include "includes/neighbor.h"

generic module NeighborDiscoveryB() {
    provides interface NeighborDiscovery;
    uses interface SimpleSend as Sender;
    uses interface Pool<neighbor> as NeighborPool;
    uses interface List<neighbor*> as NeighborList;
}

implementation {
	pack sendPackage;
   	bool foundNeighbor;
   	uint16_t i;
   	uint16_t size; 
	

 	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);
	
	command void NeighborDiscovery.receivedReply(pack *myMsg) {
		neighbor *neighbor_new;
	        neighbor *neighbor_ptr;
	        bool found = FALSE;		
	//	dbg(NEIGHBOR_CHANNEL, "Received Response Packet: received acknowledgment packet from %d\n", myMsg->src);
		size = call NeighborList.size();

		for(i = 0; i < size; i++){
			neighbor_ptr = call NeighborList.get(i);
			if(neighbor_ptr->node == myMsg->src){
				found = TRUE;
				neighbor_ptr->age = 0;
				break;
			}
		}
	    
	        if(!found){
			dbg(NEIGHBOR_CHANNEL, "New Neighbor: adding neighbor %d  to the Neighbor List\n", myMsg->src);
			neighbor_new = call NeighborPool.get();
			neighbor_new->node = myMsg->src;
			neighbor_new->age = 0;
			call NeighborList.pushback(neighbor_new);		
	        }	    
	}


	command uint8_t NeighborDiscovery.checkNeighbors() {
	
       		//Increment age of all the neighbors if the list is not empty
       		if(!call NeighborList.isEmpty()){
			uint8_t removed = 99;
			uint16_t age;
			neighbor* neighbor_ptr;
			neighbor* neighbor_temp;
			size = call NeighborList.size();

			for(i = 0; i < size; i++){
				neighbor_temp = call NeighborList.get(i);
				neighbor_temp->age = neighbor_temp->age + 1;
			
				age = neighbor_temp->age;
				if(age > 5){
					neighbor_ptr = call NeighborList.remove(i);
					dbg(NEIGHBOR_CHANNEL, "Dead Node: Node %d has been idle for 10 pings, declared dead. Dropping from list\n", neighbor_ptr->node);
					size--;
					i--;
					removed = neighbor_ptr->node;
					return removed;
				}
			}	
        	}
		return 99;
	}


	command void NeighborDiscovery.printNeighborList() {
		
		size = call NeighborList.size();
		if(size == 0) {
			dbg(NEIGHBOR_CHANNEL, "No Neighbors found\n");
		}
		//print out list 
		else {
			dbg(NEIGHBOR_CHANNEL, "Update Neighbor List. Dumping new neighbor list of size %d for Node %d\n", size, TOS_NODE_ID);
			for(i = 0; i < size; i++) {
				neighbor* neighbor_ptr = call NeighborList.get(i);
				dbg(NEIGHBOR_CHANNEL, "Neighbor: Node: %d, Age: %d\n", neighbor_ptr->node, neighbor_ptr->age);
			}
		}

	   }  


	command bool NeighborDiscovery.isFoundNeighbor(uint16_t neighborID) {
		neighbor *temp;		
		size = call NeighborList.size();
		for(i = 0; i < size; i++){
			temp = call NeighborList.get(i);
			if (temp->node == neighborID){
				return TRUE;
			}
		}
		return FALSE;
	}
	
}

