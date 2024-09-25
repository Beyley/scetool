/*
 * Copyright (c) 2011-2013 by naehrwert
 * This file is released under the GPLv2.
 */

#define CLI_APP 1

#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <io.h>
// #include "getopt.h"
#else
#include <unistd.h>
// #include <getopt.h>
#endif

#include "types.h"
#include "config.h"
#include "aes.h"
#include "util.h"
#include "keys.h"
#include "sce.h"
#include "np.h"
#include "self.h"
#include "rvk.h"

#include "frontend.h"

/*! Shorter Versions of arg options. */
#define ARG_NULL no_argument
#define ARG_NONE no_argument
#define ARG_REQ required_argument
#define ARG_OPT optional_argument

/*! Verbose mode. */
BOOL _verbose = FALSE;
/*! Raw mode. */
BOOL _raw = FALSE;

/*! We got work. */
// static BOOL _got_work = FALSE;
// /*! List keys. */
static BOOL _list_keys = FALSE;
// /*! Print infos on file. */
// static BOOL _print_info = FALSE;
// /*! Decrypt file. */
// static BOOL _decrypt_file = FALSE;
// /*! Encrypt file. */
// static BOOL _encrypt_file = FALSE;

/*! Parameters. */
s8 *_template = NULL;
s8 *_file_type = NULL;
s8 *_compress_data = NULL;
s8 *_skip_sections = NULL;
s8 *_key_rev = NULL;
s8 *_meta_info = NULL;
s8 *_keyset = NULL;
s8 *_auth_id = NULL;
s8 *_vendor_id = NULL;
s8 *_self_type = NULL;
s8 *_app_version = NULL;
s8 *_fw_version = NULL;
s8 *_add_shdrs = NULL;
s8 *_ctrl_flags = NULL;
s8 *_cap_flags = NULL;
#ifdef CONFIG_CUSTOM_INDIV_SEED
s8 *_indiv_seed = NULL;
#endif
s8 *_license_type = NULL;
s8 *_app_type = NULL;
s8 *_content_id = NULL;
s8 *_klicensee = NULL;
s8 *_real_fname = NULL;
s8 *_add_sig = NULL;

/*! Input file. */
// static s8 *_file_in = NULL;
/*! Ouput file. */
// static s8 *_file_out = NULL;

/*! Long option values. */
#define VAL_TEMPLATE 't'
#define VAL_FILE_TYPE '0'
#define VAL_COMPRESS_DATA '1'
#define VAL_SKIP_SECTIONS 's'
#define VAL_KEY_REV '2'
#define VAL_META_INFO 'm'
#define VAL_KEYSET 'K'
#define VAL_AUTH_ID '3'
#define VAL_VENDOR_ID '4'
#define VAL_SELF_TYPE '5'
#define VAL_APP_VERSION 'A'
#define VAL_FW_VERSION '6'
#define VAL_ADD_SHDRS '7'
#define VAL_CTRL_FLAGS '8'
#define VAL_CAP_FLAGS '9'
#ifdef CONFIG_CUSTOM_INDIV_SEED
#define VAL_INDIV_SEED 'a'
#endif
#define VAL_LICENSE_TYPE 'b'
#define VAL_APP_TYPE 'c'
#define VAL_CONTENT_ID 'f'
#define VAL_KLICENSEE 'l'
#define VAL_REAL_FNAME 'g'
#define VAL_ADD_SIG 'j'

static void print_version()
{
	printf("scetool " SCETOOL_VERSION " (C) 2011-2013 by naehrwert\n");
	printf("NP local license handling (C) 2012 by flatz\n");
	printf("Library conversion + patches (C) 2023-2024 by Lyris\n");
#if PACKAGE
	printf("[Build Date/Time: %s/%s]\n", __DATE__, __TIME__);
#endif
}

export int libscetool_init()
{
	_verbose = TRUE;

	print_version();
	printf("\n");

	// Load keysets.
	if (keys_load() == TRUE)
		_LOG_VERBOSE("Loaded keysets.\n");
	else
	{
		if (_list_keys == TRUE)
		{
			printf("[*] Error: Could not load keys.\n");
			return 0;
		}
		else
			printf("[*] Warning: Could not load keys.\n");
	}

	// Load curves.
	if (curves_load() == TRUE)
		_LOG_VERBOSE("Loaded loader curves.\n");
	else
		printf("[*] Warning: Could not load loader curves.\n");

	// Load vsh curves.
	if (vsh_curves_load() == TRUE)
		_LOG_VERBOSE("Loaded vsh curves.\n");
	else
		printf("[*] Warning: Could not load vsh curves.\n");

	// Set klicensee.
	if (_klicensee != NULL)
	{
		if (strlen(_klicensee) != 0x10 * 2)
		{
			printf("[*] Error: klicensee needs to be 16 bytes.\n");
			return 1;
		}
		np_set_klicensee(_x_to_u8_buffer(_klicensee));
	}

	return 0;
}