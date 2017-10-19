/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"
#include "include/neighbor.h"
#include "include/routing.h"
configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components new ListC(pack, 32) as PacketListC;
    Node.PacketList -> PacketListC;

    components new TimerMilliC() as NeighborTimerC;
    Node.NeighborTimer -> NeighborTimerC;

    components RandomC as RandomC;
    Node.Random -> RandomC;

    components new FloodingC() as floodingC;
    Node.flooding -> floodingC;

    components new NeighborDiscoveryC() as neighborDiscoveryC;
    Node.neighborDiscovery -> neighborDiscoveryC;

    components new LSRoutingC() as lsRoutingC;
    Node.lsRouting -> lsRoutingC;
}

