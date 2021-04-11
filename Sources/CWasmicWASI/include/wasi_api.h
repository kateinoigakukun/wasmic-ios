//
//  wasi_api.h
//  Wasmic
//
//  Created by kateinoigakukun on 2021/04/11.
//

#ifndef wasi_api_h
#define wasi_api_h

#include "m3_api_wasi.h"

typedef struct {
    m3_wasi_context_t parent;
    void *user_context;
    ssize_t (*writev)(void *user_context, int, const struct iovec *, int);
} wasmic_wasi_context_t;

wasmic_wasi_context_t* wasmic_GetWasiContext(void);

#endif /* wasi_api_h */
