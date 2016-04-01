#define TARGET Name
TARGET=template

#define TOOLCHAIN
CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar
OBJCOPY=arm-none-eabi-objcopy

DEBUGGER=arm-none-eabi-gdb
STLINK=/opt/STM/stlink


#define Toolchain and Library paths
LIB_PATH   ?=/usr/lib/gcc/arm-none-eabi/4.9.3

HAL_PATH   ?=/usr/local/workspace/stm32/fw_repo/STM32Cube_FW_F4_V1.11.0/Drivers/STM32F4xx_HAL_Driver
CMSIS_PATH ?=/usr/local/workspace/stm32/fw_repo/STM32Cube_FW_F4_V1.11.0/Drivers/CMSIS
BSP_PATH   ?=/usr/local/workspace/stm32/fw_repo/STM32Cube_FW_F4_V1.11.0/Drivers/BSP

#define INCLUDES
BASE_INCLUDES= -I$(LIB_PATH)/include-fixed -L$(LIB_PATH)/thumb,-lc

HAL_INCLUDES= -I$(HAL_PATH)/Inc -I$(CMSIS_PATH)/Include -I$(CMSIS_PATH)/Device/ST/STM32F4xx/Include

CUSTOM_INCLUDES= -IInc -I$(BSP_PATH)/STM32F4-Discovery

#define CFLAGS
DBG = -O2
ifneq (,$(DEBUG))
DBG = -g
endif

CFLAGS = $(DBG) -Wall -TSTM32F407VGTx_FLASH.ld -DUSE_STD_PERIPH_DRIVER
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += $(CUSTOM_INCLUDES) $(HAL_INCLUDES) $(BASE_INCLUDES)

CFLAGS += -DSTM32F4_DISCOVERY -DSTM32F407xx -DUSE_HAL_DRIVER

#define SRC FILES
SRCS  = startup_stm32f407xx.s
SRCS += $(BSP_PATH)/STM32F4-Discovery/stm32f4_discovery.c

SRCS += $(HAL_PATH)/Src/stm32f4xx_hal.c
SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_gpio.c
SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_rcc.c
SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_cortex.c

SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_i2c.c
SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_spi.c
SRCS += $(HAL_PATH)/Src/stm32f4xx_hal_dma.c

SRCS += Src/system_stm32f4xx.c
SRCS += Src/stm32f4xx_it.c
SRCS += Src/stm32f4xx_newlib_stubs.c

SRCS += Src/main.c

#define build targets
$(TARGET).elf:
	$(CC) $(CFLAGS) $(SRCS) -o $@
	@$(OBJCOPY) -O ihex $(TARGET).elf $(TARGET).hex
	@$(OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin

all: $(TARGET).elf
	@echo -e "\033[0;93mBuild Successful\033[0;0m"

clean:
	rm -rf *.o *.elf *.hex *.bin 2>/dev/null

burn:$(TARGET).bin
	$(STLINK)/st-flash write $(TARGET).bin 0x8000000

debug:$(TARGET).bin
	$(STLINK)/st-util -p 5000 & echo $! > /tmp/stmgdbserver.pid
	$(DEBUGGER) $(TARGET).elf -ex "target remote :5000" -ex "b main" -ex "set print pretty on" -ex "continue"
