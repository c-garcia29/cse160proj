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

typedef nx_struct Neighbor { 
	nx_uint16_t Node; 
	nx_uint16_t pingNumber; 
}

typedef nx_struct LinkState { 
	nx_unit16_t Dest; 
	nx_unit16_t Cost; 
	nx_unit16_t Next; 
	nx_unit16_t Seq; 
	nx_unit16_t NEIGHBOR[64]; 
	nx_unit16_t NeighborsLenght; 
}
module Node{
   uses interface Boot;
   uses interface List<pack> as PacketList;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
}

implementation{
   pack sendPackage;
	uint16_t seqCounter = 0;
   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	void pushPack(pack Package);
	bool findPack(pack *Package);
   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
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

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
	dbg(GENERAL_CHANNEL, "Packet Received\n");
	if(len==sizeof(pack)){
			pack* myMsg=(pack*) payload;
		if((myMsg->TTL == 0) || findPack(myMsg)){
	
		} else if ((myMsg->dest == TOS_NODE_ID) && (myMsg->protocol == PROTOCOL_PING)){ 	
      		  	dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
			makePack(&sendPackage, TOS_NODE_ID, myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY,seqCounter, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
			seqCounter++; 
			pushPack(sendPackage);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		}else if((myMsg->dest == TOS_NODE_ID) && (myMsg->protocol == PROTOCOL_PINGREPLY)){ 
			dbg(GENERAL_CHANNEL, "A reply was recieved and it was delivered from %d\n", myMsg->src);
		} else{ 
			makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t*)myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
			pushPack(sendPackage); 
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		}
        	return msg;
	}
		dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
		return msg;
}


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

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
      memcpy(Package->payload, payload, length);
   }
void accessNeighbors() { 
	pack Pack; 
	char* message; 
	accessCOunter++; 
	if (!(call Neighbors.isEmpty())) { 
		unit16_t lenght = call Neighbors.size(); 
		unit16_t pings = 0 
		Neighbor NeighborNode; 
		unit16_t i = 0; 
		Neighbor temp;
	for (i = 0; i < lenght; i++){ 
		temp = call Neighbors.get(i); 
		temp.pingNumber = temp.pingNumber + 1;
 		pings = temp.pingNumber;
	if (pings > 3){
		NeighborNode = call Neighbors.removeFromList(i);
		dbg(NEIGHBOR_CHANNEL, "Node %d was dropped due to the fact that their was more than 3 pings\n", NeighborNode.Node);
		call NeighborsDropped.pushFront(NeighborNode);
		i--;
		lenght--;
					}
				}
}
	message = "Pinged Neighbors\n";
	makePack(&Pack, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 1, (unit8_t*) message, (unit8_t) sizeof)message);
	pushPack(Pack);
	call Sender.send(Pack, AM_BROADCASTE_ADDR);
}
		void pushPack(pack Package) {
			call PacketList.popfront();
			call PacketList.pushfront(Package);
		}

		bool findPack(pack *Package) {
			uint16_t size = call PacketList.size();
			uint16_t i = 0;
			pack match;
			for (i = 0; i < size; i++) {
				match = call PacketList.get(i);
				if((match.src == Package->src) && (match.dest == Package->dest) && (match.seq == Package->seq)) {
					return TRUE;
				}
			}
			return FALSE;
		}
}
