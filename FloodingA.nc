#include "includes/packet.h"

generic configuration FloodingA() {
	provides interface Flooding;
}
implementation {
	components new FloodingA();
	Flooding = FloodingB.Flooding;

	components new SimpleSendA(AM_PACK);
	FloodingB.Sender -> SimpleSendA;
}

