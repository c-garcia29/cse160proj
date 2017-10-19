/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/neighbor.h"
#include "includes/routing.h"

module Node{
   uses interface Boot;
   uses interface List<pack> as PacketList;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface Timer<TMILLI> as NeighborTimer;
   uses interface Flooding as flooding;
   uses interface NeighbotDiscovery as nerighbordiscovery; 
   uses interface LSRouting as LSrouting;
}

implementation{
   pack sendPackage;
   bool foundNeighbor;

   unit16_t i; 
   unut16_t segNum = 0; 
   unit16_t size;
   routing RoutingTable;

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	bool pushPack(pack Package);
	bool findPack(pack *Package);
	void checkNeighbors();

   event void Boot.booted(){
      uint32_t start, offset, direct;
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      start = call Random.rand32() % 2000; 
      direct = call Random.rND16() % 2;
	if(direct) {
		offset = 2000 + (call Random.rand32() % 3000);
   }
	else{
		offset = 2000 - (call Random.rand32() % 3000);
}
call NeighborTimer.startPeriodicAT(start, offset);
dbg(NEIGHBOR_CHANNEL, "Neighbor timer started\n");

call LSrouting.initialize(&routingTable);
}
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event void NeighbotTimer.fired(){

	pack Package; 
	char* payload;
	uint8_t removed; 
	removed = call neightbordiscovery.checkNeighbors();
	
	dbg(ROUTING_CHANNEL, "Removed: %d\n", removed);
while (removed != 99){
	call LSrouting.removeRoute(removed, &routingTable);
	removed = call neighborDiscovery.checkNeighbors();
	dbg(ROUTING_CHANNEL, "Removed: %d\n", removed); 
	call Lsrouting.buildPacket(&sendPackage, &routingTable, segNum, removed);
	pushPack(sendPackage);
	segNum++;
	call Sender.send(sendPackage, AM_BROADCAST_ADDR);
} 
	payload = "Sending broadcast\n";
	segNum++;
	makePackage(&Package, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, segNum, (uint8_t*) payload, (uint8_t) sizeof(payload));
	pushPack(Package); 
	call Sender.send(Package, AM_BROADCAST_ADDR);
	
event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	if(len==sizeof(pack)){
		pack* myMsg=(pack*) payload;
		if(myMsg->TTL == 0){
			dbg(FLOODING_CHANNEL, "Expires Packet: Dropped packet seq %d from %d to %d\n", myMsg->seq, myMsg->src, myMsg->dest);

		} else if (myMsg->dest == AM_BROADCAST_ADDR){
			neighbor *neighbor_new;
			neighbor *neighbor_ptr;
			bool found = FALSE;

	if(myMsg->protocol == PROTOCOL_PING){
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t*) MyMsg->payload, sizeof(myMsg->payload)); 	
      		  	
			pushPack(sendPackage);
			call Sender.send(sendPackage, myMsg->src);
		}else if(myMsg->protocol == PROTOCOL_PINGREPLY){ 
			foundNeighbor = call neighbordiscovery.isFoundNeighbor(myMsg->src);
			if(!foundNeighbor){
				if(call Lsrouting.buildPacket(&sendPackage, &routingTable, segNum, myMsg->src);
				segNum++;
				pushPack(sendPackage);
				call Sender.send(sendPackage, AM_BROADCAST_ADDR);
			}
		}
			call neighbordiscovery.receiveReply(myMsg);
}
 		else if(myMsg->dest == TOS_NODE_ID){
			if(!isSeenPackage(myMsg)){
				if(myMsg->protocol == PROTOCOL_PING){
 					dbg(FLOODING_CHANNEL, "Packet was received from %d through flooding! \n", myMsg->src);
					dbg(NEIGHBOR_CHANNEL, "Send ACK:Sending Ping Reply to %d! \n", myMsg->src);
					dbg(ROUTING_CHANNEL, "Received: Received packet via routing. Sending ACK to %d! \n", myMsg->src);
					call LSrouting.routePingReply(myMsg, &routingTable);
				}
				else if(myMsg->protocol == PROTOCOL_PINGREPLY){
					dbg(NEIGHBOR_CHANNEL, "Received ACK: Received Ping Reply from %d! \n", myMsg->src);
					dbg(ROUTING_CHANNEL, "Acknowledged: Received Ping Reply from %d! \n", myMsg->src);
				}
				else if(myMsg->protocol == PROTOCOL_CMD){
					switch(getCMD((uint8_t *)&myMsg->payload,sizeof(myMsg->payload))){
				    	case CMD_NEIGHBOR_DUMP:
						dbg(NEIGHBOR_CHANNEL, "Reached Neighbor Dump Command\n");
                	            		call neighborDiscovery.printNeighborList();
                	            		break;
					}
				}
	 		}
	 	}

	 	else if(isSeenPack(myMsg)){
         		dbg(FLOODING_CHANNEL,"Seen Packet: Dropped packet seq %d from %d to %d\n", myMsg->seq, myMsg->src, myMsg->dest);
	   		if(myMsg->protocol != PROTOCOL_CMD) {
				pushPack(*myMsg);   	
	    		}
	 	}
	 
		else {
	   		makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));	
			pushPack(sendPackage);
	//		call flooding.floodPacket(sendPackage);	
			call lsRouting.routePacket(myMsg, &routingTable);
	       	}

        	 return msg;
      	}
    dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
    return msg;
   }


   bool pushPack(pack Package){
       if(call PacketList.isFull()){ 
            call PacketList.popfront();
       }
       //add Package
       if(call PacketList.pushback(Package)){
	    return TRUE;
       }
       else{
	    return FALSE;
       }
   }

  bool isSeenPack(pack *Package){
      pack packetAtIndex;
      size = call PacketList.size();

      for(i = 0; i < size; i++){
	 packetAtIndex = call PacketList.get(i);
	 if (packetAtIndex.seq == Package->seq && packetAtIndex.src == Package->src && packetAtIndex.dest == Package->dest){
		return TRUE;
	 }
      }
      return FALSE;
  }

 
			







   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      sendPackage.seq = sendPackage.seq + 1;
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, sendPackage.seq, payload, PACKET_MAX_PAYLOAD_SIZE);
	if(pushPack(sendPackage)){
		dbg(FLOODING_CHANNED, "Stores as seen by the sender\n");
}     
 call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	seqNum++;
	call LSrouting.routePing(destination, payload, seqNum, &routingTable);
   }

   event void CommandHandler.printNeighbors(){
	call neighbordiscover.printNeighborList();
}

   event void CommandHandler.printRouteTable(){
	call LSrouting.printTabl(routingTable);
}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
		dbg(NEIGHBOR_CHANNEL, "Protocol = %d\n", Package->protocol);
      memcpy(Package->payload, payload, length);
   }
}
