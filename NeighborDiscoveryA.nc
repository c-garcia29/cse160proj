#include "includes/packet.h"

generic configuration NeighborDiscoveryA() {

   provides interface NeighborDiscovery;
}


implementation{
    components new NeighborDiscoveryA();
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

    components new ListA(neighbor*,64) as NeighborListA;
    NeighborDiscoveryP.NeighborList -> NeighborListA;

    components new SimpleSendA(AM_PACK);
    NeighborDiscoveryB.Sender -> SimpleSendC;

    components new PoolA(neighbor, 64) as NeighborPoolA;
    NeighborDiscoveryB.NeighborPool -> NeighborPoolA;
}



