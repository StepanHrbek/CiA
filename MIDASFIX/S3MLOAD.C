/*      S3MLOAD.C
 *
 * Scream Tracker 3 Module loader
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by Navel:
 *  support for incorrect modules with odd length of pattern orders added
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*/


#include "lang.h"
#include "mtypes.h"
#include "errors.h"
#include "mglobals.h"
#include "mmem.h"
#include "file.h"
#include "sdevice.h"
#include "mplayer.h"
#include "s3m.h"
#ifndef NOEMS
#include "ems.h"
#endif
#include "vu.h"
#include "mutils.h"

#ifndef NULL
    #define NULL 0L
#endif





/* Size of temporary memory area used for avoiding memory fragmentation
   if EMS is used or in protected mode */
#define TEMPSIZE 8192

/* Pass error code in variable "error" on, used in s3mLoadModule(). */
#define S3MLOADPASSERROR { s3mLoadError(SD); PASSERROR(ID_s3mLoadModule) }




/****************************************************************************\
*       Module loader buffers and file pointer. These variables are static
*       instead of local so that a separate deallocation can be used which
*       will be called before exiting in error situations
\****************************************************************************/
static fileHandle f;
static int      fileOpened;
static mpModule *ms3m;
static ushort   *instPtrs;
static ushort   *pattPtrs;
static uchar    *smpBuf;
static void     *tempmem;
static uchar    *panningInfos;





/****************************************************************************\
*
* Function:     int s3mFreeModule(mpModule *module, SoundDevice *SD);
*
* Description:  Deallocates a Scream Tracker 3 module
*
* Input:        mpModule *module        module to be deallocated
*               SoundDevice *SD         Sound Device that has stored the
*                                       samples
*
* Returns:      MIDAS error code
*
\****************************************************************************/

int CALLING s3mFreeModule(mpModule *module, SoundDevice *SD)
{
    int         i, error;

    if ( module == NULL )               /* valid module? */
    {
        ERROR(errUndefined, ID_s3mFreeModule);
        return errUndefined;
    }


    /* deallocate pattern orders if allocated: */
    if ( module->orders != NULL )
        if ( (error = memFree(module->orders)) != OK )
            PASSERROR(ID_s3mFreeModule)

    /* deallocate sample used flags: */
    if ( module->instsUsed != NULL )
        if ( (error = memFree(module->instsUsed)) != OK )
            PASSERROR(ID_s3mFreeModule)


    if ( module->insts != NULL )        /* instruments? */
    {
        for ( i = 0; i < module->numInsts; i++ )
        {
            /* If the instrument has been added to Sound Device, remove
               it, otherwise just deallocate the sample if allocated */

            if ( (module->insts[i].sdInstHandle != 0) && (SD != NULL) )
            {
                if ( (error = SD->RemInstrument(
                    module->insts[i].sdInstHandle)) != OK )
                    PASSERROR(ID_s3mFreeModule)
            }
            else
                if ( module->insts[i].sample != NULL )
                    if ( (error = memFree(module->insts[i].sample)) != OK )
                        PASSERROR(ID_s3mFreeModule)
        }
        /* deallocate instrument structures: */
        if ( (error = memFree(module->insts)) != OK )
            PASSERROR(ID_s3mFreeModule)
    }

    if ( module->patterns != NULL )
    {
        for ( i = 0; i < module->numPatts; i++ )
        {
            /* if the pattern has been allocate, deallocate it - either
                from conventional memory or from EMS */
            if ( module->patterns[i] != NULL )
            {
#ifndef NOEMS
                if ( useEMS == 1 )
                {
                    if ( (error = emsFree((emsBlock*) module->patterns[i]))
                        != OK )
                        PASSERROR(ID_s3mFreeModule)
                }
                else
#endif
                    if ( (error = memFree(module->patterns[i])) != OK )
                        PASSERROR(ID_s3mFreeModule)
            }
        }
        /* deallocate pattern pointers: */
        if ( (error = memFree(module->patterns)) != OK )
            PASSERROR(ID_s3mFreeModule)
    }

    /* deallocate the module: */
    if ( (error = memFree(module)) != OK)
        PASSERROR(ID_s3mFreeModule)

    return OK;
}




/****************************************************************************\
*
* Function:     void s3mLoadError(SoundDevice *SD)
*
* Description:  Stops loading the module, deallocates all buffers and closes
*               the file.
*
* Input:        SoundDevice *SD         Sound Device that has been used for
*                                       loading.
*
\****************************************************************************/

static void s3mLoadError(SoundDevice *SD)
{
    /* Close file if opened. Do not process errors. */
    if ( fileOpened )
        if ( fileClose(f) != OK )
            return;

    /* Attempt to deallocate module if allocated. Do not process errors. */
    if ( ms3m != NULL )
        if ( s3mFreeModule(ms3m, SD) != OK )
            return;

    /* Deallocate buffers if allocated. Do not process errors. */

    if ( panningInfos != NULL )
        if ( memFree(panningInfos) != OK )
            return;
    if ( smpBuf != NULL )
        if ( memFree(smpBuf) != OK )
            return;
    if ( tempmem != NULL )
        if ( memFree(tempmem) != OK )
            return;
    if ( instPtrs != NULL )
        if ( memFree(instPtrs) != OK )
            return;
    if ( pattPtrs != NULL )
        if ( memFree(pattPtrs) != OK )
            return;
}




/****************************************************************************\
*
* Function:     int s3mLoadModule(char *fileName, SoundDevice *SD,
*                   int (*SaveSampleInfo)(ushort sdInstHandle, uchar *sample,
*                   ushort slength, ushort loopStart, ushort loopEnd),
*                   mpModule **module);
*
* Description:  Loads a Scream Tracker 3 module into memory
*
* Input:        char *fileName          name of module file to be loaded
*               SoundDevice *SD         Sound Device which will store the
*                                       samples. NULL if the samples should
*                                       not be added to a Sound Device, but
*                                       should be left in conventional memory
*                                       instead.
*               int (*SaveSampleInfo)() Pointer to sample information saving
*                                       function. sdInstHandle = Sound Device
*                                       instrument handle, sample = pointer to
*                                       sample data, slength = sample length,
*                                       loopStart = sample loop start,
*                                       loopEnd = sample loop end. The
*                                       function must return a MIDAS error
*                                       code. NULL if no such function is
*                                       used.
*               mpModule **module       pointer to variable which will store
*                                       the module pointer.
*
* Returns:      MIDAS error code.
*               Pointer to module structure is stored in *module.
*
* Notes:        The only practical use at this point for SaveSampleInfo() are
*               the real VU-meters. To load a module and add the prepare the
*               VU meter information point SaveSampleInfo to vuPrepare().
*
\****************************************************************************/

int CALLING s3mLoadModule(char *fileName, SoundDevice *SD,
    int CALLING (*SaveSampleInfo)(ushort sdInstHandle, uchar *sample,
    ushort slength, ushort loopStart, ushort loopEnd), mpModule **module)
{
    s3mHeader   s3mh;
    s3mInstHdr  s3mi;
    int         i;
    mpInstrument   *inst;
    ushort      pattSize;
    mpPattern   *pattData;
    ushort      lend;
    ulong       maxSmpLength;
    int         error;
    unsigned    ordersize;
    void        *p;

    /* point buffers to NULL and set fileOpened to 0 so that s3mLoadError()
       can be called at any point: */
    fileOpened = 0;
    ms3m = NULL;
    instPtrs = NULL;
    pattPtrs = NULL;
    smpBuf = NULL;
    tempmem = NULL;
    panningInfos = NULL;


    /* Open module file: */
    if ( (error = fileOpen(fileName, fileOpenRead, &f)) != OK )
        S3MLOADPASSERROR

    /* Allocate memory for the module structure: */
    if ( (error = memAlloc(sizeof(mpModule), (void**) &ms3m)) != OK )
        S3MLOADPASSERROR

    ms3m->orders = NULL;                 /* clear module structure so that */
    ms3m->insts = NULL;                  /* it can be deallocated with */
    ms3m->patterns = NULL;               /* s3mFree() at any point */
    ms3m->instsUsed = NULL;

    ms3m->MP = &mpS3M;                  /* point MP field to module player */

    /* Read .S3M file header: */
    if ( (error = fileRead(f, &s3mh, sizeof(s3mHeader))) != OK )
        S3MLOADPASSERROR

    /* Check the "SCRM" signature in header: */
    if ( !mMemEqual(&s3mh.SCRM[0], "SCRM", 4) )
    {
        ERROR(errInvalidModule, ID_s3mLoadModule);
        s3mLoadError(SD);
        return errInvalidModule;
    }

    mMemCopy(&ms3m->ID[0], &s3mh.SCRM[0], 4);    /* copy ID */
    ms3m->IDnum = idS3M;                 /* S3M module ID */

    mMemCopy(&ms3m->songName[0], &s3mh.name[0], 28); /* copy song name */
    ms3m->songLength = s3mh.songLength;         /* copy song length */
    ms3m->numInsts = s3mh.numInsts;      /* copy number of instruments */
    ms3m->numPatts = s3mh.numPatts;      /* copy number of patterns */
    mMemCopy(&ms3m->flags, &s3mh.flags, sizeof s3mh.flags);/* copy S3M flags */
    ms3m->masterVol = s3mh.masterVol;    /* copy master volume */
    ms3m->speed = s3mh.speed;            /* copy initial speed */
    ms3m->tempo = s3mh.tempo;            /* copy initial BPM tempo */
    ms3m->masterMult = s3mh.masterMult & 15;     /* copy master multiplier */
    ms3m->stereo = (s3mh.masterMult >> 4) & 1;   /* copy stereo flag */

    /* Use fast volume slides for Scream Tracker versions below 3.20: */
    if ( s3mh.trackerVer < 0x1320 )
        ms3m->flags.fastVolSlide = 1;

    /* Allocate memory for pattern orders: (length of pattern orders must be
       even) */
//  ordersize = 2 * ((ms3m->songLength+1) / 2);
//  bugfix?:
    ordersize = ms3m->songLength;
    if ( (error = memAlloc(ordersize, (void**) &ms3m->orders)) != OK )
        S3MLOADPASSERROR

    /* Read pattern orders from file: */
    if ( (error = fileRead(f, ms3m->orders, ordersize)) != OK )
        S3MLOADPASSERROR

    /* Calculate real song length: (exclude 0xFF bytes from end) */
    for ( i = (ms3m->songLength - 1); ms3m->orders[i] == 0xFF; i-- );
    ms3m->songLength = i + 1;

    /* check that song length is nonzero: */
    if ( ms3m->songLength == 0 )
    {
        ERROR(errInvalidModule, ID_s3mLoadModule);
        s3mLoadError(SD);
        return errInvalidModule;
    }

    /* Allocate memory for instrument structures: */
    if ( (error = memAlloc(ms3m->numInsts * sizeof(mpInstrument),
        (void**) &ms3m->insts)) != OK )
        S3MLOADPASSERROR

    /* Clear all instruments: */
    for ( i = 0; i < ms3m->numInsts; i++ )
    {
        ms3m->insts[i].sample = NULL;
        ms3m->insts[i].sdInstHandle = 0;
    }


    /* Allocate memory for instrument paragraph pointers: */
    if ( (error = memAlloc(2 * ms3m->numInsts, (void**) &instPtrs)) != OK )
        S3MLOADPASSERROR

    /* Read instrument pointers: */
    if ( (error = fileRead(f, instPtrs, 2 * ms3m->numInsts)) != OK )
        S3MLOADPASSERROR

    /* Allocate memory for S3M file pattern pointers: */
    if ( (error = memAlloc(2 * ms3m->numPatts, (void**) &pattPtrs)) != OK )
        S3MLOADPASSERROR

    /* Read pattern pointers: */
    if ( (error = fileRead(f, pattPtrs, 2 * ms3m->numPatts)) != OK )
        S3MLOADPASSERROR

    /* Allocate memory for pattern pointers: */
    if ( (error = memAlloc(ms3m->numPatts * sizeof(mpPattern*), (void**)
        &ms3m->patterns)) != OK )
        S3MLOADPASSERROR

    if ( s3mh.panningMagic == 0xFC )
    {
        /* Allocate memory for panning infos: */
        if ( (error = memAlloc(32 * sizeof(uchar),
            (void**) &panningInfos)) != OK )
            S3MLOADPASSERROR

        /* Read panning infos: */
        if ( ( error = fileRead(f, panningInfos, 32 * sizeof(uchar)) ) != OK )
            S3MLOADPASSERROR

        /* Convert panning values: */
        for (i = 0; i < 32; i++)
        {
            if ( s3mh.chanSettings[i] > 15 )
            {
                ms3m->chanSettings[i] = 0;
            }
            else
            {
                if ( panningInfos[i] & 0x20 )
                {
                    ms3m->chanSettings[i] = ((panningInfos[i] & 0xf) - 8) * 8;
                    if ( ms3m->chanSettings[i] >= 0 )
                        ms3m->chanSettings[i] += 8;
                }
                else
                {
                    if (s3mh.chanSettings[i] < 8)
                        ms3m->chanSettings[i] = panLeft;
                    else
                        ms3m->chanSettings[i] = panRight;
                }
            }
        }

        /* Free panning infos: */
        if ( (error = memFree(panningInfos)) != OK )
            S3MLOADPASSERROR
        panningInfos = NULL;
    }
    else
    {
        /* copy default channel panning settings: */
        for (i = 0; i < 32; i++)
        {
            if (s3mh.chanSettings[i] > 15)
                ms3m->chanSettings[i] = 0;
            else
            {
                if (s3mh.chanSettings[i] < 8)
                    ms3m->chanSettings[i] = panLeft;
                else
                    ms3m->chanSettings[i] = panRight;
            }
        }
    }

    /* Point all unallocated patterns to NULL for safety: */
    for ( i = 0; i < ms3m->numPatts; i++ )
        ms3m->patterns[i] = NULL;

    /* Read all patterns to memory: */
    for ( i = 0; i < ms3m->numPatts; i++ )
    {
        if ( pattPtrs[i] != NULL )
        {
            /* Seek to pattern beginning in file: */
            if ( (error = fileSeek(f, 16L * pattPtrs[i], fileSeekAbsolute))
                != OK )
                S3MLOADPASSERROR

            /* Read pattern length from file: */
            if ( (error = fileRead(f, &pattSize, 2)) != OK )
                S3MLOADPASSERROR

#ifndef NOEMS
            if ( useEMS == 1 )
            {
                /* Allocate EMS memory for pattern: */
                if ( (error = emsAlloc(pattSize+2, (emsBlock**) &p)) != OK )
                    S3MLOADPASSERROR

                /* Map EMS block to conventional memory and point pattData to
                   the memory area: */
                if ( (error = emsMap((emsBlock*) p, (void**) &pattData))
                    != OK )
                    S3MLOADPASSERROR
            }
            else
            {
#endif
                /* No EMS memory used - allocate conventional memory for
                    pattern: */
                if ( (error = memAlloc(pattSize+2, (void**) &p)) != OK )
                    S3MLOADPASSERROR

                pattData = p;
#ifndef NOEMS
            }
#endif


            ms3m->patterns[i] = p;

            pattData->length = pattSize;    /* save pattern length */

            /* Read pattern data from file: */
            if ( (error = fileRead(f, &pattData->data[0], pattSize)) != OK )
                S3MLOADPASSERROR
        }
    }

    /* deallocate pattern file pointers: */
    if ( (error = memFree(pattPtrs)) != OK )
        S3MLOADPASSERROR
    pattPtrs = NULL;

    /* detect number of channels: */
    if ( (error = s3mDetectChannels(ms3m, &ms3m->numChans)) != OK )
        S3MLOADPASSERROR

    /* allocate memory for instrument used flags: */
    if ( (error = memAlloc(ms3m->numInsts, (void **) &ms3m->instsUsed))
        != OK )
        S3MLOADPASSERROR

    /* find which instruments are used: */
    if ( (error = s3mFindUsedInsts(ms3m, ms3m->instsUsed)) != OK )
        S3MLOADPASSERROR

    /* Find maximum sample length: */
    maxSmpLength = 0;
    for ( i = 0; i < ms3m->numInsts; i++ )
    {
        /* Seek to instrument header in file: */
        if ( (error = fileSeek(f, 16L * instPtrs[i], fileSeekAbsolute))
            != OK )
            S3MLOADPASSERROR

        /* Read instrument header from file: */
        if ( (error = fileRead(f, &s3mi, sizeof(s3mInstHdr))) != OK )
            S3MLOADPASSERROR

        if ( maxSmpLength < s3mi.length )
            maxSmpLength = s3mi.length;
    }

    /* Check that no instrument is too long: */
    if ( maxSmpLength > SMPMAX )
    {
        ERROR(errInvalidInst, ID_s3mLoadModule);
        s3mLoadError(SD);
        return errInvalidInst;
    }

    /* If EMS is used, allocate TEMPSIZE bytes of memory before the sample
       buffer and deallocate it after allocating the sample buffer to
       minimize memory fragmentation. This is not necessary if the samples
       will not be added to a Sound Device. */
#ifndef NOEMS
    if ( useEMS )
    {
#endif
        if ( SD != NULL )
        {
            if ( (error = memAlloc(TEMPSIZE, &tempmem)) != OK )
            {
                S3MLOADPASSERROR
            }
        }
#ifndef NOEMS
    }
#endif

    /* allocate memory for sample loading buffer if needed: */
    if ( SD != NULL )
    {
        if ( (error = memAlloc(maxSmpLength, (void**) &smpBuf)) != OK )
        {
            S3MLOADPASSERROR
        }
    }

#ifndef NOEMS
    if ( useEMS )
    {
#endif
        if ( SD != NULL )
        {
            if ( (error = memFree(tempmem)) != OK )
            {
                S3MLOADPASSERROR
            }
        }
        tempmem = NULL;
#ifndef NOEMS
    }
#endif


    /* Process all instruments: */

    for ( i = 0; i < ms3m->numInsts; i++ )
    {
        /* point inst to current instrument structure */
        inst = &ms3m->insts[i];

        /* Seek to instrument header in file: */
        if ( (error = fileSeek(f, 16 * instPtrs[i], fileSeekAbsolute))
            != OK )
            S3MLOADPASSERROR

        /* Read instrument header from file: */
        if ( (error = fileRead(f, &s3mi, sizeof(s3mInstHdr))) != OK )
            S3MLOADPASSERROR

        /* Check if the instrument is valid - not too long, not stereo,
           16-bit or packed */
        if ( (s3mi.type > 1) || (s3mi.length > SMPMAX) ||
            ((s3mi.flags & 6) != 0) || (s3mi.pack != 0) )
        {
            ERROR(errInvalidInst, ID_s3mLoadModule);
            s3mLoadError(SD);
            return errFileRead;
        }

        mMemCopy(&inst->fileName[0], &s3mi.dosName[0], 13);/* copy filename */
        mMemCopy(&inst->iname[0], &s3mi.iname[0], 28);  /* copy inst name */
        inst->length = s3mi.length;         /* copy sample length */
        inst->loopStart = s3mi.loopStart;   /* copy sample loop start */
        inst->loopEnd = s3mi.loopEnd;       /* copy sample loop end */
        inst->looping = s3mi.flags & 1;     /* copy looping status */
        inst->volume = s3mi.volume;         /* copy default volume */
        inst->c2Rate = s3mi.c2Rate;         /* copy C2 playing rate */

        /* If instrument is looped, set length to loop end */
        if ( inst->looping == 1 )
            inst->length = inst->loopEnd;

        /* Make sure that instrument volume is < 63 */
        if ( inst->volume > 63 )
            inst->volume = 63;

        /* Check if instrument is used: */
        if ( ms3m->instsUsed[i] == 1 )
        {
            /* Instrument is used - check if there is a sample for this
               instrument - type = 1, signature "SCRS" and length != 0 */
            if ( (s3mi.type == 1) && mMemEqual(&s3mi.SCRS[0], "SCRS", 4)
                && (inst->length != 0) )
            {
                if ( SD == NULL )
                {
                    /* No Sound Device used - allocate memory for the sample
                       and point inst->sample to the memory area: */
                    if ( (error = memAlloc(inst->length, (void**) &smpBuf))
                        != OK )
                        S3MLOADPASSERROR
                    inst->sample = smpBuf;
                }
                else
                {
                    /* The instruments will be added to a Sound Device - load
                       the sample to a buffer (allocated before) and point
                       inst->sample to NULL: */
                    inst->sample = NULL;
                }

                /* Seek to sample position in file: */
                if ( (error = fileSeek(f, 16L * s3mi.samplePtr,
                    fileSeekAbsolute)) != OK )
                    S3MLOADPASSERROR

                /* Read sample to loading buffer: */
                if ( (error = fileRead(f, smpBuf, inst->length)) != OK )
                    S3MLOADPASSERROR
            }
            else
                inst->sample = NULL;

            /* Add instrument to Sound Device: */
            if ( SD != NULL )
            {
                error = SD->AddInstrument(smpBuf, smp8bit, inst->length,
                    inst->loopStart, inst->loopEnd, inst->volume, inst->looping,
                    1, &inst->sdInstHandle);
                if ( error != OK )
                    S3MLOADPASSERROR
            }

            /* Call SaveSampleInfo() if not NULL: */
            if ( SaveSampleInfo != NULL )
            {
                if ( inst->looping )
                    lend = inst->loopEnd;
                else
                    lend = 0;           /* no looping - set loop end to
                                           zero */

                if ( (error = (*SaveSampleInfo)(inst->sdInstHandle, smpBuf,
                    inst->length, inst->loopStart, lend)) != OK )
                    S3MLOADPASSERROR
            }
        }
    }

    /* deallocate instrument pointers: */
    if ( (error = memFree(instPtrs)) != OK )
        S3MLOADPASSERROR
    instPtrs = NULL;

    /* deallocate sample loading buffer: */
    if ( SD != NULL )
    {
        if ( (error = memFree(smpBuf)) != OK )
        {
            S3MLOADPASSERROR
        }
    }
    smpBuf = NULL;

    if ( (error = fileClose(f)) != OK )
        S3MLOADPASSERROR
    fileOpened = 0;

    *module = ms3m;                     /* return module pointer in *module */

    return OK;
}
