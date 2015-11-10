{tento soubor je vygenerovan z lang.eng programem lang2inc}
const lang2str='eng';
{$ifdef lang_in_DS}
const hlasky2DS:array[erOk..__] of pchar=(
'',
'Undefined error.',
'Out of memory.',
'Conventional memory heap corrupted.',
'Invalid conventional memory block.',
'Out of EMS memory.',
'EMS memory heap corrupted.',
'Invalid EMS memory block.',
'Expanded Memory Manager failure.',
'Out of soundcard memory.',
'Soundcard memory heap corrupted.',
'Invalid soundcard memory block.',
'Out of instrument handles.',
'Unable to open file.',
'Unable to read file.',
'Invalid module file.',
'Invalid instrument in module.',
'Invalid pattern data in module.',
'Invalid channel number.',
'Invalid instrument handle.',
'Sound Device channels not open.',
'Sound Device hardware failure.',
'Invalid function arguments.',
'File does not exist.',
'Invalid file handle.',
'Access denied.',
'File exists.',
'Too many open files.',
'Disk full.',
'Unexpected end of file.',
'Invalid path.',
'Unable to write file.',
'Unable to lock Virtual DMA buffer.',
'Unable to use Virtual DMA Services.',
'Invalid Virtual DMA Service version.',
'DPMI failure.',
'Invalid segment descriptor.',
'Out of system resources.',
'',
'Not enough conventional memory.',
'I need DOS version at least',
'Invalid disc',
'Unable to select fantom disc',
'Failed to test fantom disc',
'You killed a cat, lives had she',
'Unable to create file.',
'Unable to close file.',
'Too big file.',
'Unable to write to disk in ReadOnly mode.',
'Event Wait busy.',
'Dialog window is bigger than screen, try higher resolution.',
'Not enough memory for shell command "$".',
'Unsuccessful shell call "$".',
'FileLoad failed.',
'FileSave failed.',
'Calling shell failed.',
'Address',
'Unable to set video mode.',
'Bad VESA BIOS. Get a better one or use VGA resolution.',
'Screen=nil. You should set a video mode first.',
'Bitmaps has different models. You should convert one first.',
'Incorrect font.',
'It''s not possible to set/convert so big font.',
'Error in INI file, line:',
'Bad hexadecimal number on following line of INI file:',
'INI reader internal error.',
'Number out of range $..$ on following line of INI file:',
'Variable should be number on following line of INI file:',
'ReadOnly mode, skipping job with',
'You alloc too many conv.mem.blocks. For author: increase maxDosBlocks.',
'conv.mem.blocks not freed.',
'Your graphics card gets mad, straight jacket and call doctor d.ment@email.cz!',
'Nobody sets ret, internal error.',
'Bios sux, service ''load user font'' changes doublescanning.',
'last mode forgot to free timer',
'no bitmap on input.',
'too big bottom map.',
'',
'- GRAPHICS CARD TEST -',
'Proceed according to instructions on screen.',
'If you are in window, go to fullscreen!',
'...ENTER - continue...',
'If text moves, press ENTER.',
'Otherwise ESC.',
'ENTER if text flicks, otherwise ESC.',
'Press ENTER.',
'Press ESC.',
'If you see only halfcircle, press ESC.',
'Press ENTER if you see whole circle.',
'Press SPACE if you see whole circle.',
'If this column is in the middle of screen, press ENTER. If it is aside, press ESC.',
'If cursor moves vertically (in one column), press ENTER. Otherwise ESC.',
'If text moves smoothly, press ENTER. Otherwise ESC.',
'If text moves',
'smoothly,',
'press ENTER.',
'Otherwise ESC.',
'',
'Missing file',
'File $ already exists.',
'Directory $ doesn''t exist.',
'Unable to open file',
'Unable to read file',
'Unable to read whole file',
'Unable to create file',
'Unable to write file',
'perhaps low diskspace.',
'Unable to close file',
'Unable to rename file',
'Unable to delete file',
'to',
'Unable to get size of file',
'Unable to get attributes of file',
'Unable to set attributes of file',
'Unable to create directory',
'Unable to enter directory',
'Unable to delete directory',
'Error occured during action.',
'Continue;Always C;Stop;Always S',
'Bad numeral base.',
'Bad digit on input.',
'Stream access error',
'Cannot initialize stream',
'Read beyond end of stream',
'Cannot expand stream',
'Get of unregistered object type',
'Put of unregistered object type',
'Write protected disc.',
'Drive',
'Drives',
'NOT READY',
'No files',
'2 MANY FILES',
'TOO MANY',
'FILES!',
'Wait,',
'please',
'Sorting..',
'Enter wildcard.',
'DIRECTORY',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'Division by zero',
'Range check error',
'Stack overflow error',
'Out of memory',
'Invalid pointer operation',
'Floating point overflow',
'Floating point underflow',
'Invalid floating point operation',
'Overlay manager not installed',
'Overlay file read error',
'Object not initialized',
'Call to abstract method',
'Stream registration error',
'Collection index out of range',
'Collection overflow error',
'Arithmetic overflow error',
'General Protection fault, hehe :)',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'',
'Break, you rule.',
'',
'Usage: FN [options] [source [destination]]',
'  -i show informations about source fonts, nothing more',
'  -f show formats description, nothing more',
'  -p convert font to proportional',
'  -nnumber convert font to no-proportional, number is width, none=autodetect',
'  -r rename font (name in header, not a filename)',
'  -first-last tells that font contains only chars first..last (eg. -32-255)',
'  -wnumber sets char width in FNT in pixels, 8 by default',
'  -snumber shifts all chars up (to create superscript)',
'  -k some conversion meaningful only for Czechs',
'  -v work out all fonts from a multifont file (.fon)',
'  -cword word found in each font header in multifont file, (c) by default',
'   (I have no .FON description, I detect subfonts by searching this word)',
'  :lang language selection (:eng or :cz)',
'  If you enter only source, font is set up on screen.',
'  If you enter also destination, program tries to convert.',
'  Both source and destination may contain * and ? (eg. FN *.fnt *.fn).',
'',
'Formats (sorted by complexity):',
'  FNT - unpacked bitmaps, width 8 pixels, height autodetected',
'  FNP - as FNT but with byte width(1-24) before each bitmap',
'  RIF - magic "af"; pchar copyright; word height(0-24),lastchar (firstchar=32);',
'        table[word ofs_from_bitmaps_start,width(0-16)]; bitmaps heap',
'  FN  - magic "ëmÕonç "; pchar name; char firstchar,lastchar; short sizeover,',
'        sizeunder; short addspace; byte future; table[short relx,rely;',
'        byte width,height,shift; word ofs_from_file_start]; bitmaps heap',
'  FON - copyright, copyright, copyright, chaos, copyright...',
'',
'Too many parameters.',
'Unknown parameter',
'FON chaos 1, I can''t code more without format description.',
'FON chaos 2, I can''t code more without format description.',
'Fonts:',
'Use font number',
'Font',
'Height',
'Width of $ doesn''t match parameters - it''s not multiple of $ (chars*width).',
'Too big font.',
'Internal error, bad size of generated fn.',
'Expand failed.',
'Shrink failed.',
'Write to format .',
'is not supported.',
'Load $.',
'Rename (enter unlimited-length fontname, will be stored in font header):',
'Proporc.',
'Noprop.',
'Superscript.',
'Show.',
'Save',
'Unknown file format.',
'',
'There is no loader for such format.',
'There is no writer for such format.',
'Unsupported monochromatic image!',
'Unsupported compression type!',
'Unsupported bitdepth!',
'Palette was not found!',
'Unexpected palette!',
'Error in data!',
'Too many Huffman tables!',
'Too many quantisation tables!',
'Too many color components!',
'Noninterlaced images are not yet supported!',
'Incorrect number of color components',
'Bogus DRI size!',
'Incorrect file header size!',
'DHL not yet supported!',
'Unknown mark found in data!',
'CMYK color model not yet supported!',
'YIQ color model not yet suported!',
'Unknown color model!',
'Arithmetic compression is not yet supported!',
'HSI JPEGs are not yet supported!',
'Unexpected end-of-file marker found!',
'No Huffman decompression table was defined!',
'Unsupported type of interlacing!',
'Unexpected marker found in data!',
'Interlaced images are not yer supported!',
'Image too wide!',
'Only 256color images are supported!',
'Bad CRC of the file header',
'Unexpected end of the file found!',
'Progressive mode images are not yet supported!',
'Unknown compression type!',
'Too big decompression buffer required, not supported!',
'Unknown filter type!',
'Incorrect size of uncompressed block!',
'Alpha channel is not yet supported!',
'Too big animation for indirect player.',
'Only $% of picture fits to memory.',
'');

{$else}

procedure hlasky2CS;assembler;asm
 dw 698,698,714,728,763,797,815,841,866,898,922,954
 dw 985,1011,1031,1051,1071,1100,1131,1154,1180,1211,1241,1268
 dw 1288,1308,1322,1334,1354,1364,1387,1400,1421,1455,1490,1526
 dw 1539,1566,1590,1590,1621,1648,1660,1688,1714,1745,1767,1788
 dw 1801,1842,1858,1917,1957,1985,2001,2017,2038,2045,2070,2124
 dw 2170,2229,2244,2289,2313,2366,2392,2447,2503,2535,2605,2631
 dw 2708,2740,2798,2828,2847,2866,2866,2888,2932,2971,2993,3020
 dw 3034,3070,3082,3092,3130,3166,3202,3284,3355,3406,3419,3428
 dw 3440,3454,3454,3466,3488,3514,3533,3552,3577,3598,3618,3640
 dw 3660,3681,3702,3704,3730,3762,3794,3820,3845,3871,3899,3930
 dw 3947,3966,3985,4009,4034,4054,4085,4116,4137,4142,4148,4157
 dw 4165,4177,4185,4191,4196,4202,4211,4226,4235,4235,4235,4235
 dw 4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235
 dw 4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235
 dw 4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235
 dw 4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235,4235
 dw 4235,4235,4235,4235,4235,4235,4235,4235,4235,4251,4268,4288
 dw 4301,4326,4349,4373,4405,4434,4457,4479,4502,4527,4556,4581
 dw 4606,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639
 dw 4639,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639
 dw 4639,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639,4639
 dw 4639,4639,4639,4639,4655,4655,4697,4752,4795,4828,4904,4953
 dw 5028,5085,5139,5186,5238,5311,5384,5424,5477,5535,5605,5605
 dw 5636,5697,5756,5835,5903,5980,6050,6122,6182,6182,6202,6219
 dw 6277,6335,6341,6356,6360,6366,6441,6454,6495,6509,6523,6540
 dw 6557,6564,6636,6644,6651,6663,6668,6672,6692,6692,6727,6762
 dw 6794,6823,6844,6866,6885,6899,6923,6952,6978,7021,7057,7072
 dw 7099,7121,7148,7183,7216,7236,7280,7312,7348,7391,7423,7455
 dw 7495,7510,7545,7571,7604,7650,7675,7728,7748,7785,7820,7858
 dw 7892
 db 'Undefined error.'
 db 'Out of memory.'
 db 'Conventional memory heap corrupted.'
 db 'Invalid conventional memory block.'
 db 'Out of EMS memory.'
 db 'EMS memory heap corrupted.'
 db 'Invalid EMS memory block.'
 db 'Expanded Memory Manager failure.'
 db 'Out of soundcard memory.'
 db 'Soundcard memory heap corrupted.'
 db 'Invalid soundcard memory block.'
 db 'Out of instrument handles.'
 db 'Unable to open file.'
 db 'Unable to read file.'
 db 'Invalid module file.'
 db 'Invalid instrument in module.'
 db 'Invalid pattern data in module.'
 db 'Invalid channel number.'
 db 'Invalid instrument handle.'
 db 'Sound Device channels not open.'
 db 'Sound Device hardware failure.'
 db 'Invalid function arguments.'
 db 'File does not exist.'
 db 'Invalid file handle.'
 db 'Access denied.'
 db 'File exists.'
 db 'Too many open files.'
 db 'Disk full.'
 db 'Unexpected end of file.'
 db 'Invalid path.'
 db 'Unable to write file.'
 db 'Unable to lock Virtual DMA buffer.'
 db 'Unable to use Virtual DMA Services.'
 db 'Invalid Virtual DMA Service version.'
 db 'DPMI failure.'
 db 'Invalid segment descriptor.'
 db 'Out of system resources.'
 db 'Not enough conventional memory.'
 db 'I need DOS version at least'
 db 'Invalid disc'
 db 'Unable to select fantom disc'
 db 'Failed to test fantom disc'
 db 'You killed a cat, lives had she'
 db 'Unable to create file.'
 db 'Unable to close file.'
 db 'Too big file.'
 db 'Unable to write to disk in ReadOnly mode.'
 db 'Event Wait busy.'
 db 'Dialog window is bigger than screen, try higher resolution.'
 db 'Not enough memory for shell command "$".'
 db 'Unsuccessful shell call "$".'
 db 'FileLoad failed.'
 db 'FileSave failed.'
 db 'Calling shell failed.'
 db 'Address'
 db 'Unable to set video mode.'
 db 'Bad VESA BIOS. Get a better one or use VGA resolution.'
 db 'Screen=nil. You should set a video mode first.'
 db 'Bitmaps has different models. You should convert one first.'
 db 'Incorrect font.'
 db 'It''s not possible to set/convert so big font.'
 db 'Error in INI file, line:'
 db 'Bad hexadecimal number on following line of INI file:'
 db 'INI reader internal error.'
 db 'Number out of range $..$ on following line of INI file:'
 db 'Variable should be number on following line of INI file:'
 db 'ReadOnly mode, skipping job with'
 db 'You alloc too many conv.mem.blocks. For author: increase maxDosBlocks.'
 db 'conv.mem.blocks not freed.'
 db 'Your graphics card gets mad, straight jacket and call doctor d.ment@email.cz!'
 db 'Nobody sets ret, internal error.'
 db 'Bios sux, service ''load user font'' changes doublescanning.'
 db 'last mode forgot to free timer'
 db 'no bitmap on input.'
 db 'too big bottom map.'
 db '- GRAPHICS CARD TEST -'
 db 'Proceed according to instructions on screen.'
 db 'If you are in window, go to fullscreen!'
 db '...ENTER - continue...'
 db 'If text moves, press ENTER.'
 db 'Otherwise ESC.'
 db 'ENTER if text flicks, otherwise ESC.'
 db 'Press ENTER.'
 db 'Press ESC.'
 db 'If you see only halfcircle, press ESC.'
 db 'Press ENTER if you see whole circle.'
 db 'Press SPACE if you see whole circle.'
 db 'If this column is in the middle of screen, press ENTER. If it is aside, press ESC.'
 db 'If cursor moves vertically (in one column), press ENTER. Otherwise ESC.'
 db 'If text moves smoothly, press ENTER. Otherwise ESC.'
 db 'If text moves'
 db 'smoothly,'
 db 'press ENTER.'
 db 'Otherwise ESC.'
 db 'Missing file'
 db 'File $ already exists.'
 db 'Directory $ doesn''t exist.'
 db 'Unable to open file'
 db 'Unable to read file'
 db 'Unable to read whole file'
 db 'Unable to create file'
 db 'Unable to write file'
 db 'perhaps low diskspace.'
 db 'Unable to close file'
 db 'Unable to rename file'
 db 'Unable to delete file'
 db 'to'
 db 'Unable to get size of file'
 db 'Unable to get attributes of file'
 db 'Unable to set attributes of file'
 db 'Unable to create directory'
 db 'Unable to enter directory'
 db 'Unable to delete directory'
 db 'Error occured during action.'
 db 'Continue;Always C;Stop;Always S'
 db 'Bad numeral base.'
 db 'Bad digit on input.'
 db 'Stream access error'
 db 'Cannot initialize stream'
 db 'Read beyond end of stream'
 db 'Cannot expand stream'
 db 'Get of unregistered object type'
 db 'Put of unregistered object type'
 db 'Write protected disc.'
 db 'Drive'
 db 'Drives'
 db 'NOT READY'
 db 'No files'
 db '2 MANY FILES'
 db 'TOO MANY'
 db 'FILES!'
 db 'Wait,'
 db 'please'
 db 'Sorting..'
 db 'Enter wildcard.'
 db 'DIRECTORY'
 db 'Division by zero'
 db 'Range check error'
 db 'Stack overflow error'
 db 'Out of memory'
 db 'Invalid pointer operation'
 db 'Floating point overflow'
 db 'Floating point underflow'
 db 'Invalid floating point operation'
 db 'Overlay manager not installed'
 db 'Overlay file read error'
 db 'Object not initialized'
 db 'Call to abstract method'
 db 'Stream registration error'
 db 'Collection index out of range'
 db 'Collection overflow error'
 db 'Arithmetic overflow error'
 db 'General Protection fault, hehe :)'
 db 'Break, you rule.'
 db 'Usage: FN [options] [source [destination]]'
 db '  -i show informations about source fonts, nothing more'
 db '  -f show formats description, nothing more'
 db '  -p convert font to proportional'
 db '  -nnumber convert font to no-proportional, number is width, none=autodetect'
 db '  -r rename font (name in header, not a filename)'
 db '  -first-last tells that font contains only chars first..last (eg. -32-255)'
 db '  -wnumber sets char width in FNT in pixels, 8 by default'
 db '  -snumber shifts all chars up (to create superscript)'
 db '  -k some conversion meaningful only for Czechs'
 db '  -v work out all fonts from a multifont file (.fon)'
 db '  -cword word found in each font header in multifont file, (c) by default'
 db '   (I have no .FON description, I detect subfonts by searching this word)'
 db '  :lang language selection (:eng or :cz)'
 db '  If you enter only source, font is set up on screen.'
 db '  If you enter also destination, program tries to convert.'
 db '  Both source and destination may contain * and ? (eg. FN *.fnt *.fn).'
 db 'Formats (sorted by complexity):'
 db '  FNT - unpacked bitmaps, width 8 pixels, height autodetected'
 db '  FNP - as FNT but with byte width(1-24) before each bitmap'
 db '  RIF - magic "af"; pchar copyright; word height(0-24),lastchar (firstchar=32);'
 db '        table[word ofs_from_bitmaps_start,width(0-16)]; bitmaps heap'
 db '  FN  - magic "ëmÕonç "; pchar name; char firstchar,lastchar; short sizeover,'
 db '        sizeunder; short addspace; byte future; table[short relx,rely;'
 db '        byte width,height,shift; word ofs_from_file_start]; bitmaps heap'
 db '  FON - copyright, copyright, copyright, chaos, copyright...'
 db 'Too many parameters.'
 db 'Unknown parameter'
 db 'FON chaos 1, I can''t code more without format description.'
 db 'FON chaos 2, I can''t code more without format description.'
 db 'Fonts:'
 db 'Use font number'
 db 'Font'
 db 'Height'
 db 'Width of $ doesn''t match parameters - it''s not multiple of $ (chars*width).'
 db 'Too big font.'
 db 'Internal error, bad size of generated fn.'
 db 'Expand failed.'
 db 'Shrink failed.'
 db 'Write to format .'
 db 'is not supported.'
 db 'Load $.'
 db 'Rename (enter unlimited-length fontname, will be stored in font header):'
 db 'Proporc.'
 db 'Noprop.'
 db 'Superscript.'
 db 'Show.'
 db 'Save'
 db 'Unknown file format.'
 db 'There is no loader for such format.'
 db 'There is no writer for such format.'
 db 'Unsupported monochromatic image!'
 db 'Unsupported compression type!'
 db 'Unsupported bitdepth!'
 db 'Palette was not found!'
 db 'Unexpected palette!'
 db 'Error in data!'
 db 'Too many Huffman tables!'
 db 'Too many quantisation tables!'
 db 'Too many color components!'
 db 'Noninterlaced images are not yet supported!'
 db 'Incorrect number of color components'
 db 'Bogus DRI size!'
 db 'Incorrect file header size!'
 db 'DHL not yet supported!'
 db 'Unknown mark found in data!'
 db 'CMYK color model not yet supported!'
 db 'YIQ color model not yet suported!'
 db 'Unknown color model!'
 db 'Arithmetic compression is not yet supported!'
 db 'HSI JPEGs are not yet supported!'
 db 'Unexpected end-of-file marker found!'
 db 'No Huffman decompression table was defined!'
 db 'Unsupported type of interlacing!'
 db 'Unexpected marker found in data!'
 db 'Interlaced images are not yer supported!'
 db 'Image too wide!'
 db 'Only 256color images are supported!'
 db 'Bad CRC of the file header'
 db 'Unexpected end of the file found!'
 db 'Progressive mode images are not yet supported!'
 db 'Unknown compression type!'
 db 'Too big decompression buffer required, not supported!'
 db 'Unknown filter type!'
 db 'Incorrect size of uncompressed block!'
 db 'Alpha channel is not yet supported!'
 db 'Too big animation for indirect player.'
 db 'Only $% of picture fits to memory.'
end;

{$endif}
