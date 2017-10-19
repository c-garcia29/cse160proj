#include "includes/packet.h"
#include "includes/neighbor.h" 
#include "includes/routing.h"

generic configureation LSRoutingA() {
	provides interface LSRouting;
}
implementation {

	components new LSRoutingB();
	LSRouting = LSRoutingB.LSRouting;
	components new SimpleSendA(AM_PACK);
	LSRoutingB.Sender->SimpleSendA;
