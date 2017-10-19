#include "includes/packet.h"
#include "includes/neighbor.h"
#include "includes/routing.h"

generic module LSRoutingB() {

	provides interface LSRouting;
	uses interface SimpleSend as Sender;
}
implementation {

	void makePack(pack *Package, unit16_t src, uint16_t, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length"
	
	command void LSRouting.initialize(routing *routingTable) {

	int i;
	for for(i = 1; i < MAX_TABLE_SIZE; i++){
			if(i == TOS_NODE_ID){
				routingTable->distance[i] = 0;
				routingTable->next[i] = i;
			}
			else{
				routingTable->distance[i] = MAX_TABLE_SIZE + 1;
				routingTable->next[i] = MAX_TABLE_SIZE + 1;
			}
		}
	}

	command bool LSRouting.add(routing *routingTable, uint8_t num, uint8_t distance, uint8_t next) {
		
		if(distance == 1){
			routingTable->distance[num] = 1;
			routingTable->next[num] = next;
		}
		else if(distance < routingTable->distance[num]){
			routingTable->distance[num] = distance;
			routingTable->next[num] = next;
		}
		else {
			return FALSE;
		}
	
		return TRUE;

	}

	command void LSRouting.buildPacket(pack* sendPackage, routing *routingTable, uint16_t seq, uint16_t num){
	
		uint8_t payload[2];
		payload[0] = num;
		payload[1] = routingTable->distance[num];
		makePack(sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 3, PROTOCOL_LINKSTATE, seq, payload, sizeof(payload));
	}

	command void LSRouting.routePacket(pack* myMsg, routing *routingTable){

		dbg(ROUTING_CHANNEL, "FORWARDING: Packet with Seq: %d, Src: %d, Dest: %d \n", myMsg->seq, myMsg->src, myMsg->dest);
		call Sender.send(*myMsg, routingTable->next[myMsg->dest]);
	}


	command void LSRouting.routePing(uint16_t destination, uint8_t *payload, uint16_t seqNum, routing *routingTable){

		pack sendPackage;
		dbg(ROUTING_CHANNEL, "ROUTE PING: Sending packet meant for %d to next Node: %d\n", destination, routingTable->next[destination]);	
		makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, seqNum, payload, sizeof(payload));
		call Sender.send(sendPackage, routingTable->next[destination]);
	}

	command void LSRouting.routePingReply(pack* myMsg, routing *routingTable){
	
		pack sendPackage;
		makePack(&sendPackage, TOS_NODE_ID, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
		call Sender.send(sendPackage, routingTable->next[myMsg->src]);
	}

	command void LSRouting.removeRoute(uint8_t node, routing *routingTable){
		
		uint8_t i;
		routingTable->distance[node] = MAX_TABLE_SIZE + 1;
		routingTable->next[node] = MAX_TABLE_SIZE + 1;
	}

	command void LSRouting.printTable(routing routingTable) {
   		
		int i;
   		for(i = 1; i < MAX_TABLE_SIZE; i++) {
   			dbg(ROUTING_CHANNEL, "Destination: %d, Next: %d, Distance: %d\n", i, routingTable.next[i], routingTable.distance[i]);
   		}
	}

	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
    		
		Package->src = src;
		Package->dest = dest;
    		Package->TTL = TTL;
    		Package->seq = seq;
    		Package->protocol = protocol;
    		memcpy(Package->payload, payload, length);
   }

}

