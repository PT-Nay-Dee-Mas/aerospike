#ifndef AEROSPIKE_ZIG_H
#define AEROSPIKE_ZIG_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_version                                                   ║
 * ║ Brief   : Returns a static null-terminated version string                ║
 * ║ Params  : N/A                                                            ║
 * ║ Usage   : const char* v = aero_version();                                ║
 * ║ Returns : version C string                                               ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
const char* aero_version(void);

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_detect_edition                                            ║
 * ║ Brief   : Detects edition via env key; returns code                      ║
 * ║ Params  : env_key (e.g., "AEROSPIKE_EDITION")                            ║
 * ║ Usage   : int code = aero_detect_edition("AEROSPIKE_EDITION");           ║
 * ║ Returns : 0=community, 1=enterprise, -1=invalid                          ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
int32_t aero_detect_edition(const char* env_key);

typedef void* aero_client_t;

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_client_init_default                                       ║
 * ║ Brief   : Initializes client from environment configuration              ║
 * ║ Params  : N/A                                                            ║
 * ║ Usage   : aero_client_t h = aero_client_init_default();                  ║
 * ║ Returns : non-null handle on success; NULL on failure                    ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
aero_client_t aero_client_init_default(void);

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_client_deinit                                             ║
 * ║ Brief   : Deinitializes and frees client handle                          ║
 * ║ Params  : handle                                                         ║
 * ║ Usage   : aero_client_deinit(h);                                         ║
 * ║ Returns : void                                                           ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
void aero_client_deinit(aero_client_t handle);

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_client_connect                                            ║
 * ║ Brief   : Connects to cluster (active then passive failover)             ║
 * ║ Params  : handle                                                         ║
 * ║ Usage   : int rc = aero_client_connect(h);                               ║
 * ║ Returns : 0 on success; -1 on failure                                    ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
int32_t aero_client_connect(aero_client_t handle);

/*
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║ Function: aero_client_ping                                               ║
 * ║ Brief   : Pings cluster via Info `statistics`                            ║
 * ║ Params  : handle                                                         ║
 * ║ Usage   : int ok = aero_client_ping(h);                                  ║
 * ║ Returns : 1 on success; 0 on failure                                     ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */
int32_t aero_client_ping(aero_client_t handle);

void aero_free(void* ptr);

#ifdef __cplusplus
}
#endif

#endif /* AEROSPIKE_ZIG_H */