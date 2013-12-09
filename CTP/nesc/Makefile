TOSMAKE_PATH=../support/make/

COMPONENT=GlobalTestAppC

CFLAGS += -DCC2420_DEF_RFPOWER=27
CFLAGS += -DCC2420_DEF_CHANNEL=17
CFLAGS += -DACK_LOW_POWER_LISTENING
MSG_SIZE = 94


PFLAGS += -DCTP_CLEAR
PFLAGS += -DLPL_COEXISTENCE
PFLAGS += -DCTP_REPORT
PFLAGS += -DRADIO_ACTIVATIONS

CFLAGS += -IroutingTest/common \
	  -IroutingTest/common/routingInfo \
	  -IPLR
# PFLAGS += -DCTP_RADIO_SETTINGS

ifdef LSLEEP
CFLAGS += -DLOCAL_SLEEP=$(LSLEEP)
endif

ifeq ($(OBJECTIVE),SINK)
CFLAGS += -IroutingTest/sink_node 
CFLAGS += -DSERIAL_FW
endif

ifeq ($(OBJECTIVE),WINE_SINK)
CFLAGS += -IroutingTest/sink_node
#CFLAGS += -DALTERNATE_RADIO_FLASH
CFLAGS += -DMSG_LOGGER
endif

ifeq ($(OBJECTIVE),NET)
CFLAGS += -IroutingTest/net_node
endif

ifeq ($(OBJECTIVE),BRIDGE_SINK)
CFLAGS += -DROUTING_NODE
CFLAGS += -DSERIAL_FW
CFLAGS += -IroutingTest/bridge_node 
endif

ifeq ($(OBJECTIVE),BRIDGE)
CFLAGS += -DROUTING_NODE
CFLAGS += -IroutingTest/bridge_node 
endif

# CFLAGS += -DPRINTF_SUPPORT
# CFLAGS += -I$(TOSDIR)/lib/printf
# BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class
# %.class: %.java 
# 	javac $<

include $(MAKERULES)

