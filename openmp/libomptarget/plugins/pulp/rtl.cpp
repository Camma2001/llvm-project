//===----RTLs/cuda/src/rtl.cpp - Target RTLs Implementation ------- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is dual licensed under the MIT and the University of Illinois Open
// Source Licenses. See LICENSE.txt for details.
//
//===----------------------------------------------------------------------===//
//
// RTL for CUDA machine
//
//===----------------------------------------------------------------------===//

#include <cassert>
#include <cstddef>
#include <list>
#include <map>
#include <stdio.h>
#include <string>
#include <vector>

#ifdef PREM_MODE
#include <prem/cmuxif.h>
#include <prem/vote.h>
#endif

#ifndef TARGET_NAME
#define TARGET_NAME PULP
#endif

#ifdef OMPTARGET_DEBUG
static int DebugLevel = 10;

#define GETNAME2(name) #name
#define GETNAME(name) GETNAME2(name)
#define DP(...)                                                                \
  do {                                                                         \
    if (DebugLevel > 0) {                                                      \
      DEBUGP("Target " GETNAME(TARGET_NAME) " RTL", __VA_ARGS__);              \
    }                                                                          \
  } while (false)
#else // OMPTARGET_DEBUG
#define DP(...)                                                                \
  {}
#endif // OMPTARGET_DEBUG

#include "omptarget.h"
#include "Debug.h"
#include "omptargetplugin.h"
#include "plugin-pulp-hero.cpp"

#include "../common/elf_common/elf_common.h"
#include <gelf.h>

// size of the argument buffer in words
#define ARG_BUF_SIZE 16
std::vector<uint64_t> host_arg_buf;
void *dev_arg_buf;

#ifdef PREM_MODE
voteopts_t voteopts;
// address of channel in our address space; can be written to in this process
volatile channel_t *channel_virt;
// address of the pointer in the physical address space, can be written to by PULP
void *channel_phys;
#endif


#ifdef __cplusplus
extern "C" {
#endif

static int initialized = 0;
// Fixed device ids to initialize
#define BIGPULP_SVM 0
#define BIGPULP_MEMCPY 1

int32_t __tgt_rtl_is_valid_binary(__tgt_device_image *image) {
  DP("__tgt_rtl_is_valid_binary(" DPxMOD ") = 1\n", DPxPTR(image));
  elf_check_machine(image, 243);
  return 1;
}

int32_t __tgt_rtl_number_of_devices() {
  DP("__tgt_rtl_number_of_devices() = 2\n");
  return 2;
}

void __tgt_register_requires(int64_t flags) {
  DP("__tgt_register_requires(%x)", flags);
}

int32_t __tgt_rtl_init_device(int32_t device_id) {
  DP("__tgt_rtl_init_device(%d)\n", device_id);
  if (device_id != BIGPULP_SVM && device_id != BIGPULP_MEMCPY) {
    DP("PULP plugin should have device id %d (memcpy) or %d (svm)\n",
       BIGPULP_MEMCPY, BIGPULP_SVM);
    return OFFLOAD_FAIL;
  }
  if (!initialized) {
    init_hero_device();
    initialized = true;
  }
  // init hero does not return failure
  return OFFLOAD_SUCCESS;
}

bool satisfy_requested_symbols(
    __tgt_device_image *image,
    std::map<std::string, __tgt_offload_entry> &syms) {
  size_t NumEntries = (size_t)(image->EntriesEnd - image->EntriesBegin);
  DP("Expecting to have %zd entries defined.\n", NumEntries);

  __tgt_offload_entry *HostBegin = image->EntriesBegin;
  __tgt_offload_entry *HostEnd = image->EntriesEnd;

  // 1. Find all host entries that need to be found on device
  for (__tgt_offload_entry *e = HostBegin; e != HostEnd; ++e) {
    if (!e->addr) {
      DP("Invalid binary: host entry '<null>' (size = %zd)...\n", e->size);
      return false;
    }

    DP("entry to resolve: %s\n", e->name);
    syms[e->name] = *e;
  }

  // 2. Search symbols in device elf for entries

  // Is the library version incompatible with the header file?
  if (elf_version(EV_CURRENT) == EV_NONE) {
    DP("Incompatible ELF library!\n");
    return false;
  }

  // Obtain elf handler
  size_t ImageSize = (size_t)image->ImageEnd - (size_t)image->ImageStart;
  Elf *e = elf_memory((char *)image->ImageStart, ImageSize);
  if (!e) {
    DP("Unable to get ELF handle: %s!\n", elf_errmsg(-1));
    return false;
  }

  if (elf_kind(e) != ELF_K_ELF) {
    DP("Invalid ELF kind!\n");
    elf_end(e);
    return false;
  }

  // Find the section containing the OMP symbols
  size_t shstrndx;
  if (elf_getshdrstrndx(e, &shstrndx)) {
    DP("Unable to get ELF strings index!\n");
    elf_end(e);
    return false;
  }

  Elf_Scn *section = 0;
  GElf_Shdr shdr;
  bool sec_found = false;
  while ((section = elf_nextscn(e, section))) {
    gelf_getshdr(section, &shdr);

    if (shdr.sh_type == SHT_SYMTAB) {
      sec_found = true;
      break;
    }
  }

  if (!sec_found) {
    DP("Symbols section not found\n");
    elf_end(e);
    return false;
  }

  // 3. Satisfy symbols, read function address
  Elf_Data *data = elf_getdata(section, NULL);
  int count = shdr.sh_size / shdr.sh_entsize;

  for (int i = 0; i < count; i++) {
    GElf_Sym sym;
    gelf_getsym(data, i, &sym);

    char *name = elf_strptr(e, shdr.sh_link, sym.st_name);
    // printf("Symbol \"%s\" at " DPxMOD "\n", name, DPxPTR(sym.st_value),
    // shdr.sh_offset);
    if (syms.find(name) != syms.end()) {
      DP("found %s at " DPxMOD " 0x%016x, 0x%016x\n", name,
         DPxPTR((void *)sym.st_value), shdr.sh_offset, shdr.sh_addr);
      // symbol value is the function address
      syms[name].addr = (void *)sym.st_value;
    }
  }

  elf_end(e);

  for (std::map<std::string, __tgt_offload_entry>::iterator it = syms.begin();
       it != syms.end(); ++it) {
    if (it->second.addr == NULL) {
      DP("failed to resolve symbol: %s", it->first.c_str());
      return false;
    }
  }

  return true;
}

bool map_to_mem(__tgt_device_image *image, void **target, size_t *size) {
  size_t ImageSize = (size_t)image->ImageEnd - (size_t)image->ImageStart;
  Elf *e = elf_memory((char *)image->ImageStart, ImageSize);
  if (!e) {
    DP("Unable to get ELF handle: %s!\n", elf_errmsg(-1));
    elf_end(e);
    return false;
  }

  size_t phdrnum;
  int err = elf_getphdrnum(e, &phdrnum);
  if (err) {
    DP("Failed to read number of physical section headers\n");
    elf_end(e);
    return false;
  }

  struct MemTarget {
    PulpSubDev *dev;
    size_t vaddr;
    const char *name;
  };

  MemTarget devs[] = {
      {&pulp->clusters, 0x10000000, "L1"},
      {&pulp->clusters, 0x1b000000, "alias"},
      {&pulp->l2_mem, 0x1c000000, "L2"},
  };
  size_t dev_count = 3;

  for (size_t j = 0; j < dev_count; j++) {
    size_t dev_lo = devs[j].vaddr;
    size_t dev_hi = dev_lo + devs[j].dev->size;

    DP("Device %s: [" DPxMOD ", " DPxMOD "]\n", devs[j].name, DPxPTR(dev_lo),
       DPxPTR(dev_hi));
  }

  bool wrote_segment = false;

  Elf32_Phdr *hdr = elf32_getphdr(e);
  for (size_t i = 0; i < phdrnum; i++, hdr++) {
    size_t sc_lo = hdr->p_vaddr;
    size_t sc_hi = hdr->p_vaddr + hdr->p_memsz;

    // section does not reside in memory during runtime
    if (hdr->p_type != PT_LOAD) {
      DP("skipping ELF segment [" DPxMOD ", " DPxMOD "]\n", DPxPTR(sc_lo),
         DPxPTR(sc_hi));
      continue;
    }

    if (sc_lo == 0x80000000) {
      DP("skipping ELF segment [" DPxMOD ", " DPxMOD "] because it is L3", DPxPTR(sc_lo),
         DPxPTR(sc_hi));
      continue;
    }

    DP("writing ELF segment [" DPxMOD ", " DPxMOD "]\n", DPxPTR(sc_lo),
       DPxPTR(sc_hi));

    bool found = false;
    for (size_t j = 0; j < dev_count; j++) {
      MemTarget &tgt = devs[j];

      size_t dev_lo = tgt.vaddr;
      size_t dev_hi = dev_lo + tgt.dev->size;

      if (sc_lo >= dev_lo && sc_hi <= dev_hi) {
        DP("to device %s\n", tgt.name);
        size_t dev_offset = sc_lo - dev_lo;
        uint32_t *dev_mapping =
            (uint32_t *)((uint64_t)tgt.dev->v_addr + dev_offset);

        // FIXME: use of memset/memcpy lead to unaligned accesses
        for (int i = 0; i < hdr->p_memsz / 4; ++i) {
          *(dev_mapping + i) = (int64_t)dev_mapping + i; // 0xcafebabe;
        }
        assert((hdr->p_filesz % 4) == 0);
        for (int i = 0; i < hdr->p_filesz / 4; ++i) {
          *(dev_mapping + i) =
              *(((uint32_t *)(image->ImageStart + hdr->p_offset)) + i);
        }
        // memset(dev_mapping, 0, 0x100);
        // memcpy(dev_mapping,
        //      image->ImageStart + hdr->p_offset, hdr->p_filesz);
        DP("*** wrote %d bytes, zeroed %d bytes\n", hdr->p_filesz,
           hdr->p_memsz - hdr->p_filesz);
        found = true;
        wrote_segment = true;
      }
    }

    if (!found) {
      DP("can't find out where to put section\n");
      elf_end(e);
      return false;
    }
  }

  if (!wrote_segment) {
    DP("did not find a writable ELF segment\n");
  }

  elf_end(e);
  return wrote_segment;
}

bool load_and_execute_image(__tgt_device_image *image) {
  void *image_start;
  size_t image_size;
  bool success = map_to_mem(image, &image_start, &image_size);
  if (!success) {
    return false;
  }

  pulp_exe_start(pulp);
  return true;
}

__tgt_target_table *__tgt_rtl_load_binary(int32_t device_id,
                                          __tgt_device_image *image) {
  DP("__tgt_rtl_load_binary(%d, " DPxMOD ")\n", device_id, DPxPTR(image));

  DP("Dev %d: load binary from " DPxMOD " image\n", device_id,
     DPxPTR(image->ImageStart));

  std::map<std::string, __tgt_offload_entry> syms;
  bool success = satisfy_requested_symbols(image, syms);
  if (!success) {
    DP("failed to satisfy requested OpenMP symbols\n");
    return NULL;
  }

  success = load_and_execute_image(image);
  if (!success) {
    return NULL;
  }

  // init argument buffers
  host_arg_buf.reserve(ARG_BUF_SIZE); // memory leak
  if (device_id == BIGPULP_MEMCPY) {
    dev_arg_buf = __tgt_rtl_data_alloc(
        device_id, ARG_BUF_SIZE * sizeof(uint64_t), host_arg_buf.data());
  }

#ifdef PREM_MODE
  // init channel
  channel_virt = (void *)pulp_l3_malloc(pulp, sizeof(channel_t), (uintptr_t *)&channel_phys);
  voteopts = init_channel(channel_virt);
#endif


  // create target table
  __tgt_target_table *table = new __tgt_target_table(); // memory leak
  std::vector<__tgt_offload_entry> *sym_vec =
      new std::vector<__tgt_offload_entry>(); // memory leak
  sym_vec->reserve(syms.size());

  // for (std::map<std::string, __tgt_offload_entry>::iterator it =
  // syms.begin();
  //     it != syms.end(); ++it)
  //    sym_vec->push_back(it->second);

  __tgt_offload_entry *HostBegin = image->EntriesBegin;
  __tgt_offload_entry *HostEnd = image->EntriesEnd;
  for (__tgt_offload_entry *e = HostBegin; e != HostEnd; ++e) {
    sym_vec->push_back(syms[e->name]);
  }

  table->EntriesBegin = &*sym_vec->begin();
  table->EntriesEnd = &*sym_vec->end();

  return table;
}

void *__tgt_rtl_data_alloc(int32_t device_id, int64_t size, void *hst_ptr) {
  DP("__tgt_rtl_data_alloc(device_id=%d, size=%lld, hst_ptr=" DPxMOD ")\n",
     device_id, size, DPxPTR(hst_ptr));
  void *ptr = nullptr;
  if (device_id == BIGPULP_SVM) {
    ptr = hst_ptr;
  } else {
    ptr = GOMP_OFFLOAD_alloc(device_id, size);
  }
  return ptr;
}

int32_t __tgt_rtl_data_submit(int32_t device_id, void *tgt_ptr, void *hst_ptr,
                              int64_t size) {
  DP("__tgt_rtl_data_submit(device_id=%d, tgt_ptr=" DPxMOD ", hst_ptr=" DPxMOD
     ", size=%lld\n",
     device_id, DPxPTR(tgt_ptr), DPxPTR(hst_ptr), size);
  if (device_id == BIGPULP_SVM) {
    assert(hst_ptr == tgt_ptr);
    return OFFLOAD_SUCCESS;
  }
  return GOMP_OFFLOAD_host2dev(device_id, tgt_ptr, hst_ptr, size)
             ? OFFLOAD_SUCCESS
             : OFFLOAD_FAIL;
}

int32_t __tgt_rtl_data_retrieve(int32_t device_id, void *hst_ptr, void *tgt_ptr,
                                int64_t size) {
  DP("__tgt_rtl_data_retrieve(device_id=%d, hst_ptr=" DPxMOD ", tgt_ptr=" DPxMOD
     ", size=%lld\n",
     device_id, DPxPTR(hst_ptr), DPxPTR(tgt_ptr), size);
  if (device_id == BIGPULP_SVM) {
    assert(hst_ptr == tgt_ptr);
    return OFFLOAD_SUCCESS;
  }
  return GOMP_OFFLOAD_dev2host(device_id, hst_ptr, tgt_ptr, size)
             ? OFFLOAD_SUCCESS
             : OFFLOAD_FAIL;
}

int32_t __tgt_rtl_data_delete(int32_t device_id, void *tgt_ptr) {
  DP("__tgt_rtl_data_delete(device_id=%d, tgt_ptr=" DPxMOD ")\n", device_id,
     DPxPTR(tgt_ptr));
  if (device_id == BIGPULP_SVM) {
    return OFFLOAD_SUCCESS;
  }
  return GOMP_OFFLOAD_free(device_id, tgt_ptr) ? OFFLOAD_SUCCESS : OFFLOAD_FAIL;
}

int32_t __tgt_rtl_run_target_team_region(int32_t device_id, void *tgt_entry_ptr,
                                         void **tgt_args,
                                         ptrdiff_t *tgt_offsets,
                                         int32_t arg_num, int32_t team_num,
                                         int32_t thread_limit,
                                         uint64_t loop_tripcount) {
  DP("__tgt_rtl_run_target_team_region(..)\n");

#ifdef PREM_MODE
  // disallow realloc
  if (arg_num + 1 > ARG_BUF_SIZE) {
    DP("argument buffer too large, max. number of args: %d\n",
           ARG_BUF_SIZE - 1);
    return OFFLOAD_FAIL;
    }
#endif

  for (int32_t i = 0; i < arg_num; i++) {
    if (tgt_offsets[i] != 0) {
      fprintf(stderr, "Unimplemented: non-zero offset");
      return OFFLOAD_FAIL;
    }
  }

  host_arg_buf.clear();
  DP("Offload Args (%p): ", host_arg_buf.data());
  for (int32_t i = 0; i < arg_num; i++) {
    host_arg_buf.push_back((uint64_t)tgt_args[i]);
    DP(DPxMOD ", ", DPxPTR((void *)tgt_args[i]));
  }
  DP("\n");

#ifdef PREM_MODE
  host_arg_buf.push_back(((uint32_t)channel_phys));
  DP(DPxMOD ", ", DPxPTR((void*) channel_phys));
#endif

  void *host_buf = host_arg_buf.data();
  if (device_id == BIGPULP_SVM) {
    // FIXME: assumes the host buf is in 32-bit range for now
    dev_arg_buf = host_buf;
  } else {
    size_t size = sizeof(uint64_t) * host_arg_buf.size();

    DP("copying argbuf from host buffer " DPxMOD " to device buffer: " DPxMOD
       "\n",
       DPxPTR(host_buf), DPxPTR(dev_arg_buf));
    __tgt_rtl_data_submit(device_id, dev_arg_buf, host_buf, size);
  }

  // instruct PULP to run the offload function
  DP("Start offloading...\n");
  pulp_mbox_write(pulp, PULP_START);
  pulp_mbox_write(pulp, (uint32_t)tgt_entry_ptr);
  pulp_mbox_write(pulp, (uint32_t)dev_arg_buf);
  const uint32_t num_miss_handler_threads = (device_id == BIGPULP_SVM) ? 1 : 0;
  pulp_mbox_write(pulp, num_miss_handler_threads);

#ifdef PREM_MODE
  // synchronize with CMUX
  DP("starting PREM sync on channel (virt/phys): " DPxMOD ", "
        DPxMOD "\n", DPxPTR(channel_virt), DPxPTR(channel_phys));
  host_sync(&voteopts);
  DP("Done PREM sync\n");
#endif

  uint32_t ret[2];
  while (pulp_mbox_read(pulp, (unsigned int *)&ret[0], 1));
  assert(ret[0] == 4 /* PULP_DONE */ &&
         "Software mailbox protocol failure: Expected PULP_DONE.");
  while (pulp_mbox_read(pulp, (unsigned int *)&ret[1], 1));

  for (unsigned i = 0; i < ARCHI_CLUSTER_NB_PE; ++i) {
    const size_t stdout_buf_size = 1024*1024; // FIXME: this should be defined in the same place as
                                              // for PULP
    const size_t stdout_offset_per_core = stdout_buf_size / ARCHI_CLUSTER_NB_PE;
    const volatile char* ptr = (char*)pulp->l3_mem.v_addr + stdout_offset_per_core * i;
    const volatile char* const end = ptr + stdout_offset_per_core;
    if (!*ptr)
      continue;
    printf(">>> PRINTING BUFFER OF CORE %d:\n", i);
    while (*ptr && ptr < end) {
      printf("%c", *ptr);
      ++ptr;
    }
    printf("<<< END OF BUFFER\n");
  }

  printf("Done offloading, cycles to execute kernel: %d!\n", (int)ret[1]);

  return OFFLOAD_SUCCESS;
}

int32_t __tgt_rtl_run_target_region(int32_t device_id, void *tgt_entry_ptr,
                                    void **tgt_args, ptrdiff_t *tgt_offsets,
                                    int32_t arg_num) {
  DP("__tgt_rtl_run_target_region(..)\n");
  // use one team and the default number of threads.
  const int32_t team_num = 1;
  const int32_t thread_limit = 0;
  return __tgt_rtl_run_target_team_region(device_id, tgt_entry_ptr, tgt_args,
                                          tgt_offsets, arg_num, team_num,
                                          thread_limit, 0);
}

#ifdef __cplusplus
}
#endif
