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
'',
'Forbidden sample name: $',
'',
'Some error in background description:',
'Syntax error in background description:',
'Unknown color:',
'',
'Bad project name, *?[|] have special meaning.',
'Compile first - use parameter 1.',
'is listed more than once.',
'$. DM filename.',
'Name of $. DM file contents.',
'If it isn''t Root, it''s AddOn for',
'(you can use *,?,[variant1|variant2|..] in expression)',
'2-3 letter long acronyme.',
'',
'(linked from $).',
'No link to page: $.',
'Page $ is not fit! (I accept only versions 200..$)',
'Picture $ used on page $ doesn''t exist.',
'Excluding',
'Ignoring size of',
'Chcecking dependencies inside project...',
'I didn''t found any pages to compile into .DM file.',
'Project size',
'',
'Not enough memory for Parlan script.',
'',
'Too many modules on page.',
'',
'Too many columns on page.',
'',
'Shortening text.',
'',
'Too small buffer for dmtext.',
'File created by Machina of too high version.',
'Missing page template.',
'Page has incomplete header, maybe you changed template.',
'Loop in templates.',
'',
'Too many DM files.',
'Too many projects.',
'Too many DM files in one project.',
'Not compiled',
'must be root',
'rulez',
'sux',
'none',
'Looking for DMs in',
'version',
'Missing',
'but you can select other language.',
'',
'Sorry, too many pages in history.',
'Unable to refresh old page (low memory or internal error).',
'Palette editor (controls: mouse, space, z,x)',
'ESC=abort',
'ENTER=confirm',
'set',
'Setup',
'help',
'MiniHelp',
'rip',
'Ripper',
'shell',
'DOS shell',
'bye',
'Exit',
'trying size',
'Ministack overflow.',
'Ministack underflow.',
'Export to:',
'screenshot',
'picture of whole page',
'plain text',
'Vyhen: plain page',
'HTML: plain page',
'HTML: page and pictures',
'HTML: whole site with subpages',
'Machina: plain page',
'Machina: fully equipped page',
'Machina: whole site with subpages',
'Page doesn''t contain any text data.',
'Where to go for modules',
'$ has no music.',
'File $ doesn''t exist.',
'Select module/mp3 to play.',
'Select directory to play.',
'There are no modules/mp3 in directory.',
'Modules/mp3 loaded: $',
' Play module/mp3 from project.',
' Play module/mp3 from disk.',
' Play directory from disku.',
'Play rather in alphabetic order.',
'Play rather in random order.',
'When to switch music...',
'Never.',
'After its end.',
'After 1 minute.',
'After $ minutes.',
' Play previous.',
' Play next.',
' Play random.',
'Turn off music.',
'Stop $.',
'Back to $.',
'Back to music from $.',
'You started Machina without audiosystem.',
'This menu.',
'Setup.',
'Go to page.',
'Articles by authors.',
'Project selector.',
'Resolution selector.',
'Language selector.',
'Page export.',
' Music.',
'Sudden death.',
'Main menu.',
'Palette editor.',
'Space',
'Link points to',
'This format is not supported.',
'points to',
'which wasn''t found.',
'Unable to create button (bad parameters or low memory).',
'Directory for exported files.',
'Ripping unfinished.',
'This project has no title page yet.',
'Create page "title" first.',
'Note that viewing pages from historical',
'versions 0.xx is not absolutely safe.',
'',
'Trying',
'Installing',
'to',
'Entering readonly mode.',
'Command "SET DM=path" tells Machina where to store its files.',
'INI file $ was created by higher version of Machina.',
'If you really want to use this older version, you must delete INI file.',
'Installing Machina to',
'Updating Machina in',
'Parameters:           /usage: "dm [parameters]", eg. "dm 4" viewing in textmode',
' ?,H      - help',
' R        - readonly mode (doesn''t write to disk)',
' S        - safe mode (no hw scrolling etc)',
' O        - oldies but goldies (read also 0.xx version .DM files, no warranty)',
' D,DP,DM,DW,DC,DA,DS - different debug modes',
'            (debug general,pal,mem,writer,cache,atoms,scripts)',
' I        - automatic installation/update (to $ or %DM%)',
' E        - editor (create your diskmag..)',
' 1        - compile project (generate filelist $)',
' 2        - link project (merge files from $ to .DM)',
' VGA,VESA,NOVGA,NOVESA - forces or disables VGA or VESA modes',
' AxisRelationLimit - limits resolutions in axis x or y by given # of pixels',
'            (examples: y=480, xlt800, "x<800", x!=360, "y<100"...)',
' +bits    - use only modes with this number of bits per pixel (4,8,15,16,24,32)',
' -bits    - ignore modes with this number of bits per pixel   (4=textmode)',
' :lang    - select language (:eng or :cz)',
' directory- search .DM files also there',
' file     - open this file (.DM or editor page)',
' file.swp [megabytes]-enlarge memory by opening swapfile (default 16MB), unsafe',
'Program is already running, run another copy? [Yes/No/you Lie]',
'YyNnLl',
'Linked ini file version doesn''t match program version.',
'Linked ini file language doesn''t match its name.',
'',
'Yes;Cancel',
'Internal error, bad estimation of? page size.',
'column',
'bytes',
'Page',
'can''t be saved. Rename it.',
'Select page or type new name.',
'Layer has no space for text, make it in source or go to a different one.',
'Select picture...',
'Select script...',
'Select font...',
'Which font to replace?',
'You mix 4 fonts on one page and want more?',
'Your link points to...',
'Merge this column with previous one?',
'You are going to erase background textures. Continue?',
'Define textures on background. F1=help.',
'Page size (WIDTHxHEIGHT) (widthò$).',
'Recommended resolution (WIDTHxHEIGHT).',
'Page name.',
'Page author.',
'Flags',
'Killing bad demons...',
'Note: You don''t have a VESA BIOS.',
'Note: You don''t have a mouse.',
'Check Event Wait...',
'Your operating system currently doesn''t support standard Event Wait service.',
'I can continue, but anything could happen then.',
'Check OS...',
'Note: Scrolling is smoother without Windows.',
'Check memory...',
'Note: More memory won''t be amiss.',
'You don''t have enough memory. I can continue, but expect troubles.',
'Select one set of script parameters.',
'Setting has effect from next session.',
'Script',
'parameter',
'is of unknown type',
'has not documented parameters.',
'doesn''t support parameters',
'parameter of type script/link/... must be last.',
'',
'Text cathegory',
'Normal text',
'Different text (cowriter, cite, code...)',
'Emphasized text, links',
'Strongly emphasized text',
'',
'Select theme',
'News',
'!ednews.eng',
'The most important in first minute',
'!1stmin.eng',
'What to read next - main part',
'!editor.eng',
'Keyboard+mouse overview',
'!keys.eng',
'Editor menu',
'!edmenu.eng',
'Pictures and animations',
'!picture.eng',
'Backgrounds and textures',
'!texture.eng',
'Sound and music',
'!sound.eng',
'Projects',
'!project.eng',
'Atoms, scripts, ParLan',
'!parlan.cz',
'Bugs and collapses',
'!bugz.eng',
'Format description',
'!format.eng',
'',
'How to align text in paragraph',
'default, as in previous paragraph',
'align to left here',
'align to both sides here',
'center here',
'align to right here',
'',
'Other functions',
'Page size',
'Template page',
' Page name',
' Page author',
' Recommended resolution',
' Background picture',
' Background description',
' List of fonts',
' Sample >þ  (welcome)',
' Sample  þ (wel.again)',
' Sample  þ> (yessir)',
' Sample þ  (goback)',
' Sample þ (boom)',
' Music',
' Flags',
'Align paragraph...',
'Center column',
'Resolution in editor',
'Switch Y and Z',
'');

{$else}

procedure hlasky2CS;assembler;asm
 dw 1234,1234,1250,1264,1299,1333,1351,1377,1402,1434,1458,1490
 dw 1521,1547,1567,1587,1607,1636,1667,1690,1716,1747,1777,1804
 dw 1824,1844,1858,1870,1890,1900,1923,1936,1957,1991,2026,2062
 dw 2075,2102,2126,2126,2157,2184,2196,2224,2250,2281,2303,2324
 dw 2337,2378,2394,2453,2493,2521,2537,2553,2574,2581,2606,2660
 dw 2706,2765,2780,2825,2849,2902,2928,2983,3039,3071,3141,3167
 dw 3244,3276,3334,3364,3383,3402,3402,3424,3468,3507,3529,3556
 dw 3570,3606,3618,3628,3666,3702,3738,3820,3891,3942,3955,3964
 dw 3976,3990,3990,4002,4024,4050,4069,4088,4113,4134,4154,4176
 dw 4196,4217,4238,4240,4266,4298,4330,4356,4381,4407,4435,4466
 dw 4483,4502,4521,4545,4570,4590,4621,4652,4673,4678,4684,4693
 dw 4701,4713,4721,4727,4732,4738,4747,4762,4771,4771,4771,4771
 dw 4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771
 dw 4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771
 dw 4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771
 dw 4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771,4771
 dw 4771,4771,4771,4771,4771,4771,4771,4771,4771,4787,4804,4824
 dw 4837,4862,4885,4909,4941,4970,4993,5015,5038,5063,5092,5117
 dw 5142,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175
 dw 5175,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175
 dw 5175,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175,5175
 dw 5175,5175,5175,5175,5191,5191,5233,5288,5331,5364,5440,5489
 dw 5564,5621,5675,5722,5774,5847,5920,5960,6013,6071,6141,6141
 dw 6172,6233,6292,6371,6439,6516,6586,6658,6718,6718,6738,6755
 dw 6813,6871,6877,6892,6896,6902,6977,6990,7031,7045,7059,7076
 dw 7093,7100,7172,7180,7187,7199,7204,7208,7228,7228,7263,7298
 dw 7330,7359,7380,7402,7421,7435,7459,7488,7514,7557,7593,7608
 dw 7635,7657,7684,7719,7752,7772,7816,7848,7884,7927,7959,7991
 dw 8031,8046,8081,8107,8140,8186,8211,8264,8284,8321,8356,8394
 dw 8428,8428,8452,8452,8489,8528,8542,8542,8587,8619,8644,8659
 dw 8687,8719,8773,8798,8798,8814,8833,8883,8922,8931,8947,8987
 dw 9037,9049,9049,9085,9085,9110,9110,9135,9135,9151,9151,9179
 dw 9223,9245,9300,9318,9318,9336,9354,9387,9399,9411,9416,9419
 dw 9423,9441,9448,9455,9489,9489,9522,9580,9624,9633,9646,9649
 dw 9654,9658,9666,9669,9675,9680,9689,9692,9696,9707,9726,9746
 dw 9756,9766,9787,9797,9814,9830,9853,9883,9902,9930,9963,9998
 dw 10021,10036,10057,10083,10108,10146,10167,10198,10226,10254,10286,10314
 dw 10337,10343,10357,10372,10388,10404,10416,10430,10445,10452,10462,10483
 dw 10523,10533,10539,10550,10570,10587,10607,10625,10637,10645,10658,10668
 dw 10683,10688,10702,10731,10740,10759,10814,10843,10862,10897,10923,10962
 dw 10999,10999,11005,11015,11017,11040,11101,11153,11224,11245,11264,11343
 dw 11359,11408,11451,11529,11573,11635,11691,11733,11782,11834,11895,11970
 dw 12036,12115,12189,12230,12269,12316,12395,12457,12463,12517,12565,12565
 dw 12575,12620,12626,12631,12635,12661,12690,12762,12779,12795,12809,12831
 dw 12873,12895,12931,12984,13023,13058,13096,13106,13118,13123,13144,13177
 dw 13206,13225,13301,13348,13359,13403,13418,13451,13517,13553,13590,13596
 dw 13605,13623,13653,13679,13726,13726,13740,13751,13791,13813,13837,13837
 dw 13849,13853,13864,13898,13909,13938,13949,13972,13981,13992,14003,14026
 dw 14038,14062,14074,14089,14099,14107,14119,14141,14151,14169,14178,14196
 dw 14207,14207,14237,14270,14288,14312,14323,14342,14342,14357,14366,14379
 dw 14389,14401,14424,14443,14466,14480,14501,14524,14544,14564,14582,14588
 dw 14594,14612,14625,14645,14659
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
 db 'Forbidden sample name: $'
 db 'Some error in background description:'
 db 'Syntax error in background description:'
 db 'Unknown color:'
 db 'Bad project name, *?[|] have special meaning.'
 db 'Compile first - use parameter 1.'
 db 'is listed more than once.'
 db '$. DM filename.'
 db 'Name of $. DM file contents.'
 db 'If it isn''t Root, it''s AddOn for'
 db '(you can use *,?,[variant1|variant2|..] in expression)'
 db '2-3 letter long acronyme.'
 db '(linked from $).'
 db 'No link to page: $.'
 db 'Page $ is not fit! (I accept only versions 200..$)'
 db 'Picture $ used on page $ doesn''t exist.'
 db 'Excluding'
 db 'Ignoring size of'
 db 'Chcecking dependencies inside project...'
 db 'I didn''t found any pages to compile into .DM file.'
 db 'Project size'
 db 'Not enough memory for Parlan script.'
 db 'Too many modules on page.'
 db 'Too many columns on page.'
 db 'Shortening text.'
 db 'Too small buffer for dmtext.'
 db 'File created by Machina of too high version.'
 db 'Missing page template.'
 db 'Page has incomplete header, maybe you changed template.'
 db 'Loop in templates.'
 db 'Too many DM files.'
 db 'Too many projects.'
 db 'Too many DM files in one project.'
 db 'Not compiled'
 db 'must be root'
 db 'rulez'
 db 'sux'
 db 'none'
 db 'Looking for DMs in'
 db 'version'
 db 'Missing'
 db 'but you can select other language.'
 db 'Sorry, too many pages in history.'
 db 'Unable to refresh old page (low memory or internal error).'
 db 'Palette editor (controls: mouse, space, z,x)'
 db 'ESC=abort'
 db 'ENTER=confirm'
 db 'set'
 db 'Setup'
 db 'help'
 db 'MiniHelp'
 db 'rip'
 db 'Ripper'
 db 'shell'
 db 'DOS shell'
 db 'bye'
 db 'Exit'
 db 'trying size'
 db 'Ministack overflow.'
 db 'Ministack underflow.'
 db 'Export to:'
 db 'screenshot'
 db 'picture of whole page'
 db 'plain text'
 db 'Vyhen: plain page'
 db 'HTML: plain page'
 db 'HTML: page and pictures'
 db 'HTML: whole site with subpages'
 db 'Machina: plain page'
 db 'Machina: fully equipped page'
 db 'Machina: whole site with subpages'
 db 'Page doesn''t contain any text data.'
 db 'Where to go for modules'
 db '$ has no music.'
 db 'File $ doesn''t exist.'
 db 'Select module/mp3 to play.'
 db 'Select directory to play.'
 db 'There are no modules/mp3 in directory.'
 db 'Modules/mp3 loaded: $'
 db ' Play module/mp3 from project.'
 db ' Play module/mp3 from disk.'
 db ' Play directory from disku.'
 db 'Play rather in alphabetic order.'
 db 'Play rather in random order.'
 db 'When to switch music...'
 db 'Never.'
 db 'After its end.'
 db 'After 1 minute.'
 db 'After $ minutes.'
 db ' Play previous.'
 db ' Play next.'
 db ' Play random.'
 db 'Turn off music.'
 db 'Stop $.'
 db 'Back to $.'
 db 'Back to music from $.'
 db 'You started Machina without audiosystem.'
 db 'This menu.'
 db 'Setup.'
 db 'Go to page.'
 db 'Articles by authors.'
 db 'Project selector.'
 db 'Resolution selector.'
 db 'Language selector.'
 db 'Page export.'
 db ' Music.'
 db 'Sudden death.'
 db 'Main menu.'
 db 'Palette editor.'
 db 'Space'
 db 'Link points to'
 db 'This format is not supported.'
 db 'points to'
 db 'which wasn''t found.'
 db 'Unable to create button (bad parameters or low memory).'
 db 'Directory for exported files.'
 db 'Ripping unfinished.'
 db 'This project has no title page yet.'
 db 'Create page "title" first.'
 db 'Note that viewing pages from historical'
 db 'versions 0.xx is not absolutely safe.'
 db 'Trying'
 db 'Installing'
 db 'to'
 db 'Entering readonly mode.'
 db 'Command "SET DM=path" tells Machina where to store its files.'
 db 'INI file $ was created by higher version of Machina.'
 db 'If you really want to use this older version, you must delete INI file.'
 db 'Installing Machina to'
 db 'Updating Machina in'
 db 'Parameters:           /usage: "dm [parameters]", eg. "dm 4" viewing in textmode'
 db ' ?,H      - help'
 db ' R        - readonly mode (doesn''t write to disk)'
 db ' S        - safe mode (no hw scrolling etc)'
 db ' O        - oldies but goldies (read also 0.xx version .DM files, no warranty)'
 db ' D,DP,DM,DW,DC,DA,DS - different debug modes'
 db '            (debug general,pal,mem,writer,cache,atoms,scripts)'
 db ' I        - automatic installation/update (to $ or %DM%)'
 db ' E        - editor (create your diskmag..)'
 db ' 1        - compile project (generate filelist $)'
 db ' 2        - link project (merge files from $ to .DM)'
 db ' VGA,VESA,NOVGA,NOVESA - forces or disables VGA or VESA modes'
 db ' AxisRelationLimit - limits resolutions in axis x or y by given # of pixels'
 db '            (examples: y=480, xlt800, "x<800", x!=360, "y<100"...)'
 db ' +bits    - use only modes with this number of bits per pixel (4,8,15,16,24,32)'
 db ' -bits    - ignore modes with this number of bits per pixel   (4=textmode)'
 db ' :lang    - select language (:eng or :cz)'
 db ' directory- search .DM files also there'
 db ' file     - open this file (.DM or editor page)'
 db ' file.swp [megabytes]-enlarge memory by opening swapfile (default 16MB), unsafe'
 db 'Program is already running, run another copy? [Yes/No/you Lie]'
 db 'YyNnLl'
 db 'Linked ini file version doesn''t match program version.'
 db 'Linked ini file language doesn''t match its name.'
 db 'Yes;Cancel'
 db 'Internal error, bad estimation of? page size.'
 db 'column'
 db 'bytes'
 db 'Page'
 db 'can''t be saved. Rename it.'
 db 'Select page or type new name.'
 db 'Layer has no space for text, make it in source or go to a different one.'
 db 'Select picture...'
 db 'Select script...'
 db 'Select font...'
 db 'Which font to replace?'
 db 'You mix 4 fonts on one page and want more?'
 db 'Your link points to...'
 db 'Merge this column with previous one?'
 db 'You are going to erase background textures. Continue?'
 db 'Define textures on background. F1=help.'
 db 'Page size (WIDTHxHEIGHT) (widthò$).'
 db 'Recommended resolution (WIDTHxHEIGHT).'
 db 'Page name.'
 db 'Page author.'
 db 'Flags'
 db 'Killing bad demons...'
 db 'Note: You don''t have a VESA BIOS.'
 db 'Note: You don''t have a mouse.'
 db 'Check Event Wait...'
 db 'Your operating system currently doesn''t support standard Event Wait service.'
 db 'I can continue, but anything could happen then.'
 db 'Check OS...'
 db 'Note: Scrolling is smoother without Windows.'
 db 'Check memory...'
 db 'Note: More memory won''t be amiss.'
 db 'You don''t have enough memory. I can continue, but expect troubles.'
 db 'Select one set of script parameters.'
 db 'Setting has effect from next session.'
 db 'Script'
 db 'parameter'
 db 'is of unknown type'
 db 'has not documented parameters.'
 db 'doesn''t support parameters'
 db 'parameter of type script/link/... must be last.'
 db 'Text cathegory'
 db 'Normal text'
 db 'Different text (cowriter, cite, code...)'
 db 'Emphasized text, links'
 db 'Strongly emphasized text'
 db 'Select theme'
 db 'News'
 db '!ednews.eng'
 db 'The most important in first minute'
 db '!1stmin.eng'
 db 'What to read next - main part'
 db '!editor.eng'
 db 'Keyboard+mouse overview'
 db '!keys.eng'
 db 'Editor menu'
 db '!edmenu.eng'
 db 'Pictures and animations'
 db '!picture.eng'
 db 'Backgrounds and textures'
 db '!texture.eng'
 db 'Sound and music'
 db '!sound.eng'
 db 'Projects'
 db '!project.eng'
 db 'Atoms, scripts, ParLan'
 db '!parlan.cz'
 db 'Bugs and collapses'
 db '!bugz.eng'
 db 'Format description'
 db '!format.eng'
 db 'How to align text in paragraph'
 db 'default, as in previous paragraph'
 db 'align to left here'
 db 'align to both sides here'
 db 'center here'
 db 'align to right here'
 db 'Other functions'
 db 'Page size'
 db 'Template page'
 db ' Page name'
 db ' Page author'
 db ' Recommended resolution'
 db ' Background picture'
 db ' Background description'
 db ' List of fonts'
 db ' Sample >þ  (welcome)'
 db ' Sample  þ (wel.again)'
 db ' Sample  þ> (yessir)'
 db ' Sample þ  (goback)'
 db ' Sample þ (boom)'
 db ' Music'
 db ' Flags'
 db 'Align paragraph...'
 db 'Center column'
 db 'Resolution in editor'
 db 'Switch Y and Z'
end;

{$endif}
