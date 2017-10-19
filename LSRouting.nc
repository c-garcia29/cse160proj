#include "includes/packet.h"
#include "includes/neighbor.h"
#include "includes/routing.h"

interface LSRouting{
	command void initialize(routing *routingTable);
	command bool add(routing *routingTable, uint8_t num, uint8_t distance, uint8_t next)'
	command void printTable(routing rTable); 
	command void buildPacket(pack* sendPackage, routing *routingTable, uint16_t num, uint16_t seq);
	command void routePacket(pack* sendPackage, routing *routingTable);
	command void routePing( uint16_t destincation, uint8_t *payload, uint16_t seqNum, routing *routingTable);
	command void routePingReply (pack* myMsg, routing *routingTable);
	command void removeRoute(uint8_t node, routing *routingTable); 
