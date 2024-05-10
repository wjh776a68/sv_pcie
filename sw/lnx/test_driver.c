#include <linux/pci.h>
#include <linux/mod_devicetable.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/dma-mapping.h>
#include <asm/cacheflush.h>
// #include <unistd.h>
#include <linux/delay.h> 


#define DRIVER_NAME "test_driver"
#define VENDOR_ID_FUNC_1 0x10ee
#define DEVICE_ID_FUNC_1 0x9034
#define VENDOR_ID_FUNC_2 0x10ee
#define DEVICE_ID_FUNC_2 0x9234
#define VENDOR_ID_FUNC_3 0x10ee
#define DEVICE_ID_FUNC_3 0x9434
#define VENDOR_ID_FUNC_4 0x10ee
#define DEVICE_ID_FUNC_4 0x9634

static struct pci_device_id pci_ids[] = {
    {PCI_DEVICE(VENDOR_ID_FUNC_1, DEVICE_ID_FUNC_1)},
//     {PCI_DEVICE(VENDOR_ID_FUNC_2, DEVICE_ID_FUNC_2)},
//     {PCI_DEVICE(VENDOR_ID_FUNC_3, DEVICE_ID_FUNC_3)},
//     {PCI_DEVICE(VENDOR_ID_FUNC_4, DEVICE_ID_FUNC_4)},
    {0}
};
// MODULE_DEVICE_TABLE()

// #define TEST_SINGLE_TRANSFER
#define TEST_DMAINTR_TRANSFER
#define INTERRUPT_TYPE INTERRUPT_MSIX

#define INTERRUPT_NONE      0
#define INTERRUPT_LEGACY    1
#define INTERRUPT_MSI       2
#define INTERRUPT_MSIX      3

#define MIN_VEC_NUM 1
#define MAX_VEC_NUM 1

#ifdef TEST_DMAINTR_TRANSFER
#define HAS_INTERRUPT
#endif

u8 interrupt_type = 0; // 0: "none" 1: "legacy" 2: "msi" 3: "msix"
u32 u32_buf;
void* bar32;
u32 bar_baseaddress;
u32 bar_length;
u8* dma_cpuregion_addr;
dma_addr_t dma_rcregion_addr;
int ret;
u8 pcieirq;
u32 dma_session;

static u8 irq_on = 0;
static irqreturn_t legacy_irq_handler(int irq, void* dev) {
    // disable_irq_nosync(irq);
    irq_on = 1;
    printk("test_driver recv interrupt");
    return IRQ_HANDLED;
}


static int configure_device(struct pci_dev *dev) {
    int rc;
    // int addr;
    int i;

#ifdef TEST_SINGLE_TRANSFER
    // unsigned int bar32_rc = 0x11223344;
    // unsigned long bar64_rc = 0x1122334455667788;
#endif

    int dma_mismatch;

    rc = pci_enable_device(dev);

    if (rc) {
        goto pci_enable_device_err;
    } 
    pci_set_master(dev);

    // if (rc) {
    //     goto pci_set_master_err;
    // }

    rc = pci_try_set_mwi(dev);

    if (rc) {
        goto pci_try_set_mwi_err;
    }

    rc = pci_request_regions(dev, DRIVER_NAME);

    if (rc) {
        goto pci_request_regions_err;
    }

    rc = dma_set_mask(&dev->dev, DMA_BIT_MASK(64));

    if (rc) {
        goto dma_set_mask_err;
    }


    #ifdef TEST_SINGLE_TRANSFER

        printk("try write to mmio");
        bar32 = pci_ioremap_bar(dev, 2);

        if (bar32 != NULL) {
            // bar_baseaddress = pci_resource_start(dev, 0);
            // bar_length = pci_resource_len(dev, 0);
            // bar32 = ioremap_nocache(bar_baseaddress, bar_length);
            
            printk("bar status: %d %d", bar_baseaddress, bar_length);
            printk("write %x to %p", bar32_rc, bar32);
            // iowrite32(0x11223344, bar32);
            // *((u32*)bar32) = 0x11223344;
            for (i = 0; i < 8; i+=4) {
                iowrite32(bar32_rc, (u32*)bar32 + i);
                // iowrite32be(0x11223344, (u32*)bar32 + i);
            }
            // clflush_cache_range(bar32, 4);
            
            printk("try read from mmio");
            // bar32_rc = ioread32(bar32);
            for (i = 0; i < 8; i++) {
                bar32_rc = ioread32((u32*)bar32 + i);
                printk("read %p value: %08x ", (u32*)bar32 + i, bar32_rc);
            }
            printk("\n");

            printk("test 32 wrrd pass, then test 64 wrrd\n");

            printk("write %lx to %p", bar64_rc, bar32);
            // iowrite32(0x11223344, bar32);
            // *((u32*)bar32) = 0x11223344;
            for (i = 0; i < 1; i++) {
                // iowrite64(0x1122334455667788, (u32*)bar32 + i);
                iowrite32_rep((u32*)bar32 + i, &bar64_rc, 2);
            }
            // clflush_cache_range(bar32, 4);
            
            printk("try read from mmio");
            // bar32_rc = ioread32(bar32);
            for (i = 0; i < 1; i++) {
                ioread32_rep((u32*)bar32 + i, &bar64_rc, 2);
                // bar64_rc = ioread64((u32*)bar32 + i);
                printk("read %p value: %lx ", (u32*)bar32 + i, bar64_rc);
            }
            printk("\n");

            printk("test 64 wrrd pass, then test dma\n"); 

            // bar32_rc = *((u32*)bar32);

            // bar32_rc = *((u32*)bar32 + 1);

            // printk("read %p value: %08x ", (u32*)bar32 + 1, bar32_rc);
            //pci_iounmap

        }
        else {
            printk("cannot map bar");
        }
    #endif

/****************  dma test  ********************/
    #ifdef TEST_DMA_TRANSFER

            printk("test dma\n");

        bar32 = pci_ioremap_bar(dev, 0);
        if (bar32 != NULL) {
            dma_mismatch = 0;
            dma_cpuregion_addr = dma_alloc_coherent(&dev->dev, 0x400, &dma_rcregion_addr, GFP_KERNEL | __GFP_ZERO);

            if (dma_cpuregion_addr == NULL) {
                goto dma_alloc_err;
            }

            for (i = 0; i < 400; i++) { // set initial value
                *((u8*)dma_cpuregion_addr + i) = i;
            }

            printk("rc base addr %llx\n", dma_rcregion_addr);

            iowrite32((dma_rcregion_addr + 0x0000) & 0xffffffff, (u8*)bar32 + 0x000100);
            iowrite32(((dma_rcregion_addr + 0x0000) >> 32) & 0xffffffff, (u8*)bar32 + 0x000104);
            iowrite32(0x00, (u8*)bar32 + 0x000108);
            iowrite32(0, (u8*)bar32 + 0x00010C);
            iowrite32(0x50, (u8*)bar32 + 0x000110);
            iowrite32(0xA2, (u8*)bar32 + 0x000114);

            usleep_range(1000000, 2000001);

            printk("Read status of writing data");
            printk("%08x\n", ioread32((u8*)bar32 + 0x000114));
            printk("%08x\n", ioread32((u8*)bar32 + 0x000118));

            usleep_range(1000, 2001);

        printk("start copy to host");
            iowrite32((dma_rcregion_addr + 0x0100) & 0xffffffff, (u8*)bar32 + 0x000200);        // cpu region lo addr       
            iowrite32(((dma_rcregion_addr + 0x0100) >> 32) & 0xffffffff, (u8*)bar32 + 0x000204);    // cpu region hi addr
            iowrite32(0x00, (u8*)bar32 + 0x000208);                             // fpga region lo addr
            iowrite32(0, (u8*)bar32 + 0x00020C);                                // fpga region hi addr
            iowrite32(0x50, (u8*)bar32 + 0x000210);                         // len
            iowrite32(0x52, (u8*)bar32 + 0x000214);                         // id

            usleep_range(1000000, 2000001);

            printk("Read status of reading data");
            printk("%08x\n", ioread32((u8*)bar32 + 0x000214));
            printk("%08x\n", ioread32((u8*)bar32 + 0x000218));

            printk("Read data from original DMA region %p\n", ((u8*)dma_cpuregion_addr + 0x0000));
            for (i = 0; i < 0x50; i++) { // get initial value
                printk("%u ", *((u8*)dma_cpuregion_addr + 0x0000 + i));
            }
            printk("\n");

            printk("Read data from new DMA region %p\n", ((u8*)dma_cpuregion_addr + 0x0400));
            for (i = 0; i < 0x50; i++) { // get initial value
                printk("%u ", *((u8*)dma_cpuregion_addr + 0x0100 + i));
            }
            printk("\n");

            for (i = 0; i < 0x50; i++) { // get initial value
                if (*((u8*)dma_cpuregion_addr + 0x0100 + i) != *((u8*)dma_cpuregion_addr + 0x0000 + i)) {
                    printk("reading mismatch starting at address %d\n", i);
                    dma_mismatch = 1;
                    break;
                }
            }

            if (!dma_mismatch) {
            printk("dma all matched\n");
            printk("\n");
            }
        } else {
            printk("cannot map bar");
        }
    #endif

/****************  dma with interrupt test  ********************/
    #ifdef TEST_DMAINTR_TRANSFER

        printk("test dma with interrupt\n");

        bar32 = pci_ioremap_bar(dev, 0);
        if (bar32 != NULL) {
            dma_mismatch = 0;
            dma_cpuregion_addr = dma_alloc_coherent(&dev->dev, 0x400, &dma_rcregion_addr, GFP_KERNEL | __GFP_ZERO);

            if (dma_cpuregion_addr == NULL) {
                goto dma_alloc_err;
            }

#if INTERRUPT_TYPE == INTERRUPT_LEGACY
            printk("start create legacy interrupt");
            interrupt_type = INTERRUPT_LEGACY;
            pcieirq = dev->irq; 
            free_irq(pcieirq, (void*)legacy_irq_handler);                                                   // clear exist pending interrupt (if any)
            ret = request_irq(pcieirq, legacy_irq_handler, 0, "test_driver", (void*)legacy_irq_handler);    // associate handler and enable irq
            if (ret != 0) { 
                printk("cannot register irq %d", ret);
                goto irq_alloc_err; 
            }

            printk("finish create legacy interrupt");

#elif INTERRUPT_TYPE == INTERRUPT_MSI // exclusive and avoids race conditions 

            printk("start create msi interrupt");

            interrupt_type = INTERRUPT_MSI;
            ret = pci_alloc_irq_vectors(dev, MIN_VEC_NUM, MAX_VEC_NUM, PCI_IRQ_MSI); // allocate specific amount of interrupts
            if (ret < MIN_VEC_NUM) { // real allocated interrupts amount
                printk("cannot register enough irq %d", ret);
                goto irq_alloc_err; 
            }

            pcieirq = pci_irq_vector(dev, 0); // get IRQ number

            free_irq(pcieirq, (void*)legacy_irq_handler);                                                   // clear exist pending interrupt (if any)
            ret = request_irq(pcieirq, legacy_irq_handler, 0, "test_driver", (void*)legacy_irq_handler);    // associate handler and enable irq
            if (ret != 0) { 
                printk("cannot register irq %d", ret);
                goto irq_alloc_err; 
            }

            printk("finish create msi interrupt");

#elif INTERRUPT_TYPE == INTERRUPT_MSIX

            printk("start create msix interrupt");

            interrupt_type = INTERRUPT_MSIX;
            ret = pci_alloc_irq_vectors(dev, MIN_VEC_NUM, MAX_VEC_NUM, PCI_IRQ_MSIX); // allocate specific amount of interrupts
            if (ret < MIN_VEC_NUM) { // real allocated interrupts amount
                printk("cannot register enough irq %d", ret);
                goto irq_alloc_err; 
            }

            pcieirq = pci_irq_vector(dev, 0); // get IRQ number

            free_irq(pcieirq, (void*)legacy_irq_handler);                                                   // clear exist pending interrupt (if any)
            ret = request_irq(pcieirq, legacy_irq_handler, 0, "test_driver", (void*)legacy_irq_handler);    // associate handler and enable irq
            if (ret != 0) { 
                printk("cannot register irq %d", ret);
                goto irq_alloc_err; 
            }

            printk("finish create msix interrupt");

            printk("print msix interrupt table");
            for (i = 0; i < 16; i++) { // get initial value
                printk("%x ", *((u8*)bar32 + 0x0040 + i));
            }
            printk("print msix pending table");
            for (i = 0; i < 16; i++) { // get initial value
                printk("%x ", *((u8*)bar32 + 0x0050 + i));
            }

#endif


            for (i = 0; i < 400; i++) { // set initial value
                *((u8*)dma_cpuregion_addr + i) = i;
            }

            irq_on = 0;
            printk("rc base addr %llx\n", dma_rcregion_addr);

            dma_session = ioread32((u8*)bar32 + 0x000114) + 1;

            iowrite32((dma_rcregion_addr + 0x0000) & 0xffffffff, (u8*)bar32 + 0x000100);
            iowrite32(((dma_rcregion_addr + 0x0000) >> 32) & 0xffffffff, (u8*)bar32 + 0x000104);
            iowrite32(0x00, (u8*)bar32 + 0x000108);
            iowrite32(0, (u8*)bar32 + 0x00010C);
            iowrite32(0x50, (u8*)bar32 + 0x000110);
            iowrite32(dma_session, (u8*)bar32 + 0x000114);

            usleep_range(1000000, 2000001);
            printk("irq value: %x\n", irq_on);
            // while (irq_on == 0) {
            //     usleep(1);
            // }

            printk("Read status of writing data");
            printk("%08x\n", ioread32((u8*)bar32 + 0x000114));
            printk("%08x\n", ioread32((u8*)bar32 + 0x000118));

            usleep_range(1000, 2001);

            irq_on = 0;
            printk("start copy to host");
            iowrite32((dma_rcregion_addr + 0x0100) & 0xffffffff, (u8*)bar32 + 0x000200);        // cpu region lo addr       
            iowrite32(((dma_rcregion_addr + 0x0100) >> 32) & 0xffffffff, (u8*)bar32 + 0x000204);    // cpu region hi addr
            iowrite32(0x00, (u8*)bar32 + 0x000208);                             // fpga region lo addr
            iowrite32(0, (u8*)bar32 + 0x00020C);                                // fpga region hi addr
            iowrite32(0x50, (u8*)bar32 + 0x000210);                         // len
            iowrite32(dma_session, (u8*)bar32 + 0x000214);                         // id

            usleep_range(1000000, 2000001);
            printk("irq value: %x\n", irq_on);
            // while (irq_on == 0) {
            //     usleep(1);
            // }

            printk("Read status of reading data");
            printk("%08x\n", ioread32((u8*)bar32 + 0x000214));
            printk("%08x\n", ioread32((u8*)bar32 + 0x000218));

            printk("Read data from original DMA region %p\n", ((u8*)dma_cpuregion_addr + 0x0000));
            for (i = 0; i < 0x50; i++) { // get initial value
                printk("%u ", *((u8*)dma_cpuregion_addr + 0x0000 + i));
            }
            printk("\n");

            printk("Read data from new DMA region %p\n", ((u8*)dma_cpuregion_addr + 0x0400));
            for (i = 0; i < 0x50; i++) { // get initial value
                printk("%u ", *((u8*)dma_cpuregion_addr + 0x0100 + i));
            }
            printk("\n");

            for (i = 0; i < 0x50; i++) { // get initial value
                if (*((u8*)dma_cpuregion_addr + 0x0100 + i) != *((u8*)dma_cpuregion_addr + 0x0000 + i)) {
                    printk("reading mismatch starting at address %d\n", i);
                    dma_mismatch = 1;
                    break;
                }
            }

            if (!dma_mismatch) {
            printk("dma all matched\n");
            printk("\n");
            }
        } else {
            printk("cannot map bar");
        }
    #endif

    goto pci_configure_done;

irq_alloc_err:
    // disable_irq(pcieirq);
    free_irq(pcieirq, (void*)legacy_irq_handler);
    if (interrupt_type == INTERRUPT_MSI || interrupt_type == INTERRUPT_MSIX) {
        pci_free_irq_vectors(dev);
    }
dma_alloc_err:
    ;
dma_set_mask_err:
    ; 
pci_request_regions_err:
    pci_release_regions(dev);
pci_try_set_mwi_err:
    pci_clear_mwi(dev);
// pci_set_master_err:
    pci_clear_master(dev);
pci_enable_device_err:
    pci_disable_device(dev);
pci_configure_done:
    return rc;
    // pci_(read|write)_config_(byte|word|dword)
}

static int  probe(struct pci_dev *dev, const struct pci_device_id *id) {
    return configure_device(dev);
}

static void remove(struct pci_dev *dev) {
// #ifdef HAS_INTERRUPT
    if (interrupt_type != INTERRUPT_NONE) {
        disable_irq(pcieirq);

        free_irq(pcieirq, (void*)legacy_irq_handler);

        if (interrupt_type == INTERRUPT_MSI || interrupt_type == INTERRUPT_MSIX) {
            pci_free_irq_vectors(dev);
        }
    }
// #endif

    // pci_iounmap(dev, bar32);
    pci_disable_device(dev);
    pci_release_regions(dev);
    pci_clear_mwi(dev);
    pci_clear_master(dev);
}

static void shutdown(struct pci_dev *dev) {
    remove(dev);
}

static struct pci_driver test_pci_driver = {
    // .node,
    .name = DRIVER_NAME,
    .id_table = pci_ids,
    .probe = probe,
    .remove = remove,
    // .suspend,
    // .resume,
    .shutdown = shutdown,
    // .sriov_configure,
    // .sriov_set_msix_vec_count,
    // .sriov_get_vf_total_msix,
    // .err_handler,
    
};

static int __init test_driver_construct(void) {
    
#if 1
    int rc = 0;
    rc = pci_register_driver(&test_pci_driver);
    return rc;
#else 
    struct pci_dev *dev = NULL;
    while ((dev = pci_get_device(0x10ee, 0x903F, dev)) != NULL) {
        configure_device(dev);
    }
    return 0;

#endif

    
}


static void __exit test_driver_destruct(void) {
    pci_unregister_driver(&test_pci_driver);
}

module_init(test_driver_construct);
module_exit(test_driver_destruct);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("wjh776a68");
MODULE_DESCRIPTION("A driver used for learning PCIe");
