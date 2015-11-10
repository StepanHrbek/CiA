{*      RAWFILE.PAS
 *
 * Raw file I/O for MIDAS Sound System
 *
 * Copyright 1995 Petteri Kangaslampi and Jarno Paananen
 *
 * by D.Ment:
 *  rfSuperStart and rfSuperSize added to allow work with virtual files inside
 *   WAD-like files (set them before midasLoadModule and clear after)
 *
 * This file is part of the MIDAS Sound System, and may only be
 * used, modified and distributed under the terms of the MIDAS
 * Sound System license, LICENSE.TXT. By continuing to use,
 * modify or distribute this file you indicate that you have
 * read the license and understand and accept it fully.
*}


unit rawFile;


interface

var
    rfSuperStart:longint; {start of your file in WAD-like file}
    rfSuperSize:longint;  {size of your file}



{****************************************************************************\
*       struct rfFile
*       -------------
* Description:  File state structure
\****************************************************************************}

type
    rfFile = Record
        f : file;
    end;



{****************************************************************************\
*       typedef rfHandle;
*       -----------------
* Description: Raw file I/O file handle
\****************************************************************************}

type
    rfHandle = ^rfFile;
    PrfHandle = ^rfHandle;



{****************************************************************************\
*       enum rfOpenMode
*       ---------------
* Description:  File opening mode. Used by rfOpen()
\****************************************************************************}

const
    rfOpenRead = 1;                     { open file for reading }
    rfOpenWrite = 2;                    { open file for writing }
    rfOpenReadWrite = 3;                { open file for both reading and
                                          writing }



{****************************************************************************\
*       enum rfSeekMode
*       ---------------
* Description:  File seeking mode. Used by rfSeek()
\****************************************************************************}

const
    rfSeekAbsolute = 1;                 { seek to an absolute position from
                                          the beginning of the file }
    rfSeekRelative = 2;                 { seek to a position relative to
                                          current position }
    rfSeekEnd = 3;                      { seek relative to the end of file }


type
    Plongint = ^longint;
    Pinteger = ^integer;



{****************************************************************************\
*
* Function:     rfOpen(fileName : Pchar; openMode : integer;
*                   fileh : PrfHandle) : integer;
*
* Description:  Opens a file for reading or writing
*
* Input:        fileName : Pchar        pointer to name of file name, ASCIIZ!
*               openMode : integer      file opening mode, see enum rfOpenMode
*               fileh : PrfHandle       pointer to file handle
*
* Returns:      MIDAS error code.
*               File handle is stored in fileh^.
*
\****************************************************************************}

function rfOpen(fileName : Pchar; openMode : integer; fileh : PrfHandle)
    : integer;



{****************************************************************************\
*
* Function:     rfClose(fileh : rfHandle) : integer;
*
* Description:  Closes a file opened with rfOpen().
*
* Input:        fileh : rfHandle        handle of an open file
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfClose(fileh : rfHandle) : integer;




{****************************************************************************\
*
* Function:     rfGetSize(fileh : rfHandle; fileSize : Plongint) : integer;
*
* Description:  Get the size of a file
*
* Input:        fileh : rfHandle        handle of an open file
*               fileSize : Plongint     pointer to file size
*
* Returns:      MIDAS error code.
*               File size is stored in fileSize^.
*
\****************************************************************************}

function rfGetSize(fileh : rfHandle; fileSize : Plongint) : integer;




{****************************************************************************\
*
* Function:     rfRead(fileh : rfHandle; buffer : pointer;
*                   numBytes : longint) : integer;
*
* Description:  Reads binary data from a file
*
* Input:        fileh : rfHandle        file handle
*               buffer : pointer        reading buffer
*               numBytes : longint      number of bytes to read
*
* Returns:      MIDAS error code.
*               Read data is stored in buffer^, which must be large enough
*               for it.
*
\****************************************************************************}

function rfRead(fileh : rfHandle; buffer : pointer; numBytes : longint)
    : integer;




{****************************************************************************\
*
* Function:     rfWrite(fileh : rfHandle; buffer : pointer;
*               numBytes : longint) : integer;
*
* Description:  Writes binary data to a file
*
* Input:        fileh : rfHandle        file handle
*               buffer : pointer        pointer to data to be written
*               numBytes : longint      number of bytes to write
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfWrite(fileh : rfHandle; buffer : pointer; numBytes : longint)
    : integer;




{****************************************************************************\
*
* Function:     rfSeek(fileh : rfHandle; newPosition : longint;
*               seekMode : integer) : integer;
*
* Description:  Seeks to a new position in file. Subsequent reads and writes
*               go to the new position.
*
* Input:        fileh : rfHandle        file handle
*               newPosition : longint   new file position
*               seekMode : integer      file seek mode, see enum rfSeekMode
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfSeek(fileh : rfHandle; newPosition : longint; seekMode : integer)
    : integer;




{****************************************************************************\
*
* Function:     int rfGetPosition(fileh : rfHandle; position : Plongint)
*                   : integer;
*
* Description:  Reads the current position in a file
*
* Input:        fileh : rfHandle        file handle
*               position : Plongint     pointer to file position
*
* Returns:      MIDAS error code.
*               Current file position is stored in position^.
*
\****************************************************************************}

function rfGetPosition(fileh : rfHandle; position : Plongint) : integer;




{****************************************************************************\
*
* Function:     rfFileExists(fileName : Pchar; exists : Pinteger);
*
* Description:  Checks if a file exists or not
*
* Input:        fileName : Pchar        file name, ASCIIZ
*               exists : Pinteger       pointer to file exists status
*
* Returns:      MIDAS error code.
*               exists^ contains 1 if file exists, 0 if not.
*
\****************************************************************************}

function rfFileExists(fileName : Pchar; exists : Pinteger) : integer;





implementation


uses    Errors, mMem;

{$I-}
{$R-}



{****************************************************************************\
*       enum rfFunctIDs
*       ---------------
* Description:  ID numbers for raw file I/O functions
\****************************************************************************}

const
    ID_rfOpen = ID_rf + 0;
    ID_rfClose = ID_rf + 1;
    ID_rfGetSize = ID_rf + 2;
    ID_rfRead = ID_rf + 3;
    ID_rfWrite = ID_rf + 4;
    ID_rfSeek = ID_rf + 5;
    ID_rfGetPosition = ID_rf + 6;
    ID_rfFileExists = ID_rf + 7;





{****************************************************************************\
*
* Function:     rfOpen(fileName : Pchar; openMode : integer;
*                   fileh : PrfHandle) : integer;
*
* Description:  Opens a file for reading or writing
*
* Input:        fileName : Pchar        pointer to name of file name, ASCIIZ!
*               openMode : integer      file opening mode, see enum rfOpenMode
*               fileh : PrfHandle       pointer to file handle
*
* Returns:      MIDAS error code.
*               File handle is stored in fileh^.
*
\****************************************************************************}

function rfOpen(fileName : Pchar; openMode : integer; fileh : PrfHandle)
    : integer;
var
    error : integer;
    hdl : rfHandle;
begin
asm
        push    si
        push    di
end;
    { Allocate file structure: }
    error := memAlloc(SizeOf(rfFile), @pointer(hdl));
    if error <> OK then
    begin
        mError(error, ID_rfOpen);
        rfOpen := error;
        exit;
    end;

    { Assign file handle to file name: }
    Assign(hdl^.f, fileName);

    { Set file access mode: }
    case openMode of
        rfOpenRead: FileMode := 0;              { open file for reading }
        rfOpenWrite: FileMode := 1;             { open file for writing }
        rfOpenReadWrite: FileMode := 2;         { reading and writing }
    end;

    { Open file: }
    Reset(hdl^.f, 1);
    if IOResult <> 0 then
    begin
        { File could not be opened. If writing, try to create file: }
        if openMode <> rfOpenRead then
        begin
            Rewrite(hdl^.f, 1);
            if IOResult <> 0 then
            begin
                { Could not open file for writing - return unable to write: }
                mError(errFileWrite, ID_rfOpen);
                rfOpen := errFileWrite;
                exit;
            end;
        end
        else
        begin
            { Could not open file for reading - file not found: }
            mError(errFileNotFound, ID_rfOpen);
            rfOpen := errFileNotFound;
            exit;
        end;
    end
    else Seek(hdl^.f,rfSuperStart);

    { Store file handle in *fileh: }
    fileh^ := hdl;

    rfOpen := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfClose(fileh : rfHandle) : integer;
*
* Description:  Closes a file opened with rfOpen().
*
* Input:        fileh : rfHandle        handle of an open file
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfClose(fileh : rfHandle) : integer;
var
    error : integer;
begin
asm
        push    si
        push    di
end;
    { Close file: }
    close(fileh^.f);
    if IOResult <> 0 then
    begin
        mError(errInvalidFileHandle, ID_rfClose);
        rfClose := errInvalidFileHandle;
        exit;
    end;

    { deallocate file structure: }
    error := memFree(fileh);
    if error <> OK then
    begin
        mError(error, ID_rfClose);
        rfClose := error;
        exit;
    end;

    rfClose := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfGetSize(fileh : rfHandle; fileSize : Plongint) : integer;
*
* Description:  Get the size of a file
*
* Input:        fileh : rfHandle        handle of an open file
*               fileSize : Plongint     pointer to file size
*
* Returns:      MIDAS error code.
*               File size is stored in fileSize^.
*
\****************************************************************************}

function rfGetSize(fileh : rfHandle; fileSize : Plongint) : integer;
begin
asm
        push    si
        push    di
end;

    if rfSuperSize<>0
      then fileSize^:=rfSuperSize
      else fileSize^:=system.FileSize(fileh^.f);

    rfGetSize := OK;

asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfRead(fileh : rfHandle; buffer : pointer;
*                   numBytes : longint) : integer;
*
* Description:  Reads binary data from a file
*
* Input:        fileh : rfHandle        file handle
*               buffer : pointer        reading buffer
*               numBytes : longint      number of bytes to read
*
* Returns:      MIDAS error code.
*               Read data is stored in buffer^, which must be large enough
*               for it.
*
\****************************************************************************}

function rfRead(fileh : rfHandle; buffer : pointer; numBytes : longint)
    : integer;
var
    numRead : word;
begin
asm
        push    si
        push    di
end;
    { As Borland Pascal does not support memory blocks larger than 64Kb,
      there is no need to support file reads or writes longer than that. }

    if numBytes > 65535 then
    begin
        mError(errInvalidArguments, ID_rfRead);
        rfRead := errInvalidArguments;
        exit;
    end;

    { Read data from file to buffer: }
    BlockRead(fileh^.f, buffer^, numBytes, numRead);
    if IOResult <> 0 then
    begin
        mError(errInvalidFileHandle, ID_rfRead);
        rfRead := errInvalidFileHandle;
        exit;
    end;

    { Check if past end of file: }
    if numRead <> numBytes then
    begin
        mError(errEndOfFile, ID_rfRead);
        rfRead := errEndOfFile;
        exit;
    end;

    rfRead := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfWrite(fileh : rfHandle; buffer : pointer;
*               numBytes : longint) : integer;
*
* Description:  Writes binary data to a file
*
* Input:        fileh : rfHandle        file handle
*               buffer : pointer        pointer to data to be written
*               numBytes : longint      number of bytes to write
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfWrite(fileh : rfHandle; buffer : pointer; numBytes : longint)
    : integer;
var
    numWritten : word;
begin
asm
        push    si
        push    di
end;
    { As Borland Pascal does not support memory blocks larger than 64Kb,
      there is no need to support file reads or writes longer than that. }

    if numBytes > 65535 then
    begin
        mError(errInvalidArguments, ID_rfWrite);
        rfWrite := errInvalidArguments;
        exit;
    end;

    { Write data in buffer to file: }
    BlockWrite(fileh^.f, buffer^, numBytes, numWritten);
    if IOResult <> 0 then
    begin
        mError(errInvalidFileHandle, ID_rfWrite);
        rfWrite := errInvalidFileHandle;
        exit;
    end;

    rfWrite := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfSeek(fileh : rfHandle; newPosition : longint;
*               seekMode : integer) : integer;
*
* Description:  Seeks to a new position in file. Subsequent reads and writes
*               go to the new position.
*
* Input:        fileh : rfHandle        file handle
*               newPosition : longint   new file position
*               seekMode : integer      file seek mode, see enum rfSeekMode
*
* Returns:      MIDAS error code
*
\****************************************************************************}

function rfSeek(fileh : rfHandle; newPosition : longint; seekMode : integer)
    : integer;
var
    error : integer;
begin
asm
        push    si
        push    di
end;
    { Seek to correct file position using correct seeking mode: }
    case seekMode of
        rfSeekAbsolute: Seek(fileh^.f, rfSuperStart + newPosition);
        rfSeekEnd: if rfSuperSize=0
                     then Seek(fileh^.f, FileSize(fileh^.f) + newPosition)
                     else Seek(fileh^.f, rfSuperStart + rfSuperSize + newPosition);
        rfSeekRelative: Seek(fileh^.f, FilePos(fileh^.f) + newPosition);
    end;

    if IOResult <> 0 then
    begin
        mError(errInvalidArguments, ID_rfSeek);
        rfSeek := errInvalidArguments;
        exit;
    end;

    rfSeek := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     int rfGetPosition(fileh : rfHandle; position : Plongint)
*                   : integer;
*
* Description:  Reads the current position in a file
*
* Input:        fileh : rfHandle        file handle
*               position : Plongint     pointer to file position
*
* Returns:      MIDAS error code.
*               Current file position is stored in position^.
*
\****************************************************************************}

function rfGetPosition(fileh : rfHandle; position : Plongint) : integer;
begin
asm
        push    si
        push    di
end;
    { Get file position and store it to position^: }
    position^ := FilePos(fileh^.f) - rfSuperStart;
    if IOResult <> 0 then
    begin
        mError(errInvalidFileHandle, ID_rfGetPosition);
        rfGetPosition := errInvalidFileHandle;
        exit;
    end;

    rfGetPosition := OK;
asm
        pop     di
        pop     si
end;
end;




{****************************************************************************\
*
* Function:     rfFileExists(fileName : Pchar; exists : Pinteger);
*
* Description:  Checks if a file exists or not
*
* Input:        fileName : Pchar        file name, ASCIIZ
*               exists : Pinteger       pointer to file exists status
*
* Returns:      MIDAS error code.
*               exists^ contains 1 if file exists, 0 if not.
*
\****************************************************************************}

function rfFileExists(fileName : Pchar; exists : Pinteger) : integer;
var
    f : file;
begin
asm
        push    si
        push    di
end;
    { Attempt to open file. If IOResult = 0, the file exists: }
    Assign(f, fileName);
    FileMode := 0;
    Reset(f, 1);
    if IOResult = 0 then
    begin
        Close(f);
        exists^ := 1;
    end
    else
    begin
        exists^ := 0;
    end;

    rfFileExists := OK;
asm
        pop     di
        pop     si
end;
end;


{$I+}


BEGIN
 rfSuperStart:=0;
 rfSuperSize:=0;
END.
