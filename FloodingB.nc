#include "includes/packet.h"

generic module FloodinBP() {
	provides interface Flooding;
	uses interface SimpleSend as Sender;
}

implementation{
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);

	command void Flooding.floodPacket(pack sendPackage){
		dbg(FLOODING_CHANNEL, "FLOOD: Packet meant for: %d, Rebroadcasting...\n", sendPackage.dest);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	}



	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
   	}
}

