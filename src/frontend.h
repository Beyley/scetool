/*
 * Copyright (c) 2011-2013 by naehrwert
 * This file is released under the GPLv2.
 */

#ifndef _FRONTEND_H_
#define _FRONTEND_H_

#if __cplusplus
#define export extern "C"
#else
#define export
#endif

// if windows, we have to use __desclspec(dllexport)
#ifdef _WIN32
#define export extern "C" __declspec(dllexport)
#endif

export void frontend_print_infos(s8 const *file);
export void frontend_decrypt(s8 *file_in, s8 *file_out);
export void frontend_encrypt(s8 *file_in, s8 *file_out);

#endif
