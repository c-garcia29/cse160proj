#include "includes/packet.h"
#include "includes/neighbor.h"

interface NeighborDiscovery{

	command uint8_t checkNeighbors();
	command void receivedReply(pack *myMsg);
//	command neighbor* getNeighbors();
	command void printNeighborList();
	command bool isFoundNeighbor(uint16_t neighborID);
}
â
