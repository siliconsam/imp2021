   %endoflist
%conststring(8)%array text(0:255) = %c
"Z","VDEC","OWNVDEC","EXTVSPEC","ADEC","OWNADEC",
"EXTASPEC","PROC","PROCSPEC","FORMDEC","SWDEC","LDEC",
"FORMSPEC","AFORM","OWNAFORM","LSB","RSB","PRIM",
"OPTION","COMMA","T","COLON","COMMENT","LB",
"ALIAS","RB","SUB","ARRAYD","STYPE","ARRAY",
"NAME","PROCD","FNMAP","SWITCH","OWN","EXTERNAL",
"STRING","RECORD","FORMAT","SPEC","MCODE","LABEL",
"OP1","OP2","OP3","SIGN","UOP","MOD",
"DOT","COMP","ACOMP","EQ","EQEQ","JAM",
"JUMP","RESOP","AND","OR","NOT","WHILE",
"UNTIL","FOR","CWORD","EXIT","ON","SIGNAL",
"THEN","START","ELSE","FINISH","FELSE","CYCLE",
"REPEAT","SECTION","BEGIN","END","ENDPROG","ENDPERM",
"FRESULT","MRESULT","BACK","MONITOR","STOP","LIST",
"","CONTROL","INCLUDE","MASS","RTYPE","FROM",
"IDENT","V","N","CONST","FM","",
"R","F","M","P","RP","FP",
"MP","PP","L","S","A","AN",
"NA","NAN","AF","NAF","","",
"","","","","%FROM","%INCLUDE",
"%MSTART","%CLEAR","%PRED","%STACKZ","%DUBIOUS","%DUP",
"%PIN","%POUT","%EDUP","%NOFROM","PIDENT","CIDENT",
"OIDENT","FNAME","SWID","DOTL","DOTR","ASEP",
"CSEP","OSEP","PSEP","ARB","BPLRB","ORB",
"PRB","CRB","RCRB","RECRB","RECLB","LAB",
"MLAB","SLAB","XNAME","OWNT","DBSEP","PCONST",
"CMOD","CSIGN","CUOP","COP1","COP2","COP3",
"INDEF","XELSE","CRESOP","NLAB","RUNTIL","ACONST",
"ORRB","FMANY","OSTRING","FMLB","FMRB","FMOR",
"RANGERB","FSID","LESSM","","","",
"%MINUS","%DUMMY","%DECL","%TYPE","%ZERO","%APPLY",
"%PROT","%SETPROT","%PTYPE","%GAPP","%LOCAL","%GUARD",
"%MCODE","%CDUMMY","%SETTYPE","%OPER","%PARAM","%BLOCK",
"%OTHER","%COMPILE","APP","BASEAPP","APP2","APP3",
"APP4","APP5","APP6","ADEFN","NPARM","SWDEF",
"SWIDS","CIEXP","RCONST","SCONST","ARRAYP","XIMP",
"IMP","COND","SCOND","EXP1","EXP2","SEXP",
"IEXP","IEXP1","IEXP2","ISEXP","SEQ","FDEF",
"EXP","NARRAYP","STRUCT","RESEXP","BPL","CONSTB",
"FITEM","MOREA","CLIST","FPP","FPP0","FPP1",
"FPP2","INITVAR","RECEXP","EIMP","IDENTS","RANGE",
"RCONSTB","VARP","INITDEC","SCON","REVIDENT","ESCN",
"ESCDEC","ESCPROC","ESCARRAY","ESCREC"
%constinteger gmax1=774
%owninteger gmax=774
%constinteger imp phrase =25

%ownshortintegerarray phrase(200:255) = %C
   0, 593, 594, 596, 598, 600, 602, 591,
 642, 218, 215, 628, 503, 505, 652, 308,
 221, 318, 328, 454, 447, 458, 465, 479,
 474, 482, 488, 507, 423, 660, 663, 629,
 546, 536, 511, 527, 604, 552, 553, 570,
 577, 607, 418, 297, 212, 670, 541, 649,
 183,   0, 499, 737, 674, 742, 750, 764

%constbyteintegerarray atomic(130:179) = %c
  90,  90,  90,  90,  90,  48,  48,  19,
  19,  19,  19,  25,  25,  25,  25,  25,
  25,  25,  23, 104, 104, 105,  30,  20,
  21,  93,  47,  45,  46,  42,  43,  44,
  40,  68,  55, 104,  60,  93,  25,  40,
  93,  23,  25,  57,  25,  90,  53, 177,
 178, 179

!  FLAG<1> 0<1> SS<2> 0<3> T<1> LINK<8>
%constshortintegerarray initial(0:119) = %c
      24,       0,       0,       0,       0,       0,       0,       0,
       0,       0,       0,       0,       0,       0,       0,       0,
       0,       0,      23,       0,       0,       0,       0,       0,
       0,       0,       0,       0,       0,       0,       0,       0,
       0,       0,       0,       0,       0,       0,       0,       0,
      20,       0,       0,       0,       0,       0,       0,       0,
       0,       0,       0,       0,       0,       0,  -32536,       0,
       0,       0,       0,      13,       0,      14,       4,  -32542,
      16,  -32535,       0,       0,       5,       6,       3,      12,
      15,      11,       7,       8,       9,      10,  -32543,  -32539,
  -32544,  -32537,  -32538,      18,       0,      17,      21,      19,
       0,      22,       0,  -32547,  -32545,       0,       0,       0,
  -32546,       0,       0,       0,       0,       0,       0,       0,
       1,       2,       0,  -32541,       0,  -32540,       0,       0,
       0,       0,       0,       0,       0,       0,       0,       0

!  MORE<1> 0<1> ORDER<2> TYPE<4> CLASS<8>
%ownshortintegerarray gram(0:max grammar) = %c
       0,  -28523,  -28521,  -28602,  -32706,  -28509,  -28603,  -24502,
  -20405,  -20404,  -28595,  -28599,  -32697,  -32709,  -16323,  -28600,
  -32704,  -28587,  -28589,  -32681,  -16344,  -28586,  -28583,  -12270,
  -32586,     216,  -12287,  -16380,  -16371,   -8185,   -8184,  -12285,
  -12286,  -12274,  -12283,  -12282,  -12279,  -12276,  -16373,   20490,
  -32706,  -32701,     216,  -16364,  -28610,  -28613,  -28612,   16445,
     217,  -16364,      62,  -32701,   16450,  -32675,   16404,  -16364,
    5346,  -16364,     166,  -16344,    4332,     199,     130,  -16360,
  -16361,     126,     217,  -32701,     216,     119,  -16364,   16450,
  -32700,   16404,  -32701,  -32706,     216,  -32678,      93,   16405,
   16407,  -16222,    8414,     217,  -32697,   16450,    1250,    4307,
    4318,     192,     199,     170,      90,     207,  -16365,   16404,
      90,  -16360,  -16365,   16404,     241,  -16365,   16404,     132,
     132,     132,  -16360,    4329,  -16365,   16404,     133,     175,
      90,  -16365,   16404,     209,  -16365,   16404,    4313,     217,
     454,   16451,    4263,   16384,   16384,     120,     216,  -32700,
   16404,  -32706,   16404,     243,    8321,  -16365,  -32685,   16404,
     454,   16409,     118,     248,  -16365,   16404,    4263,    4329,
     194,  -16360,    4329,  -32717,   16404,    4263,   16407,     454,
     237,     127,     215,    4346,      90,     454,    4263,   16384,
  -16364,    1502,  -32629,  -16361,     153,  -32606,     222,     143,
  -32629,     153,     454,     126,   16409,   16470,     454,   16384,
     250,     234,  -16365,  -32595,     147,  -32678,     234,     193,
  -32677,  -32676,  -32661,     109,  -32717,      53,      52,      52,
      52,     194,     194,  -28581,    4188,     194,  -28566,    4203,
     194,  -28564,    4205,    4580,     183,     183,     186,     186,
  -28657,       0,    5348,   16400,      90,  -16365,       0,     134,
  -16365,       0,     210,    4329,     199,  -32677,  -32672,  -32676,
  -32688,  -32690,  -32705,  -32661,  -32659,  -32689,  -32686,  -32687,
  -16330,      65,  -32716,     186,  -32717,  -32715,  -32713,      52,
  -32664,    4201,     186,  -32717,  -32715,      55,  -16328,       0,
     197,     197,      52,      52,     197,  -28581,  -28580,     186,
  -28581,    4188,    4219,    4318,  -16365,    4219,     194,  -28581,
    4188,     194,     454,     194,  -28581,    4188,   16407,     216,
     194,  -28566,  -28565,     186,  -28566,    4203,     194,  -28564,
  -28563,     186,  -28564,    4205,     183,     183,     186,     183,
    4219,    5348,  -16365,    4219,    4580,    5095,    9444,    5348,
   16409,     217,  -32701,   16450,  -32701,     216,  -32700,       0,
  -32701,  -32706,     216,     243,     217,  -16318,       0,  -32552,
       0,  -32700,       0,  -32706,       0,     215,  -32550,     228,
  -28616,  -28615,       0,    4096,     218,     218,  -28616,       0,
  -32677,  -32676,  -16361,  -32710,  -32669,  -32662,  -32661,  -32660,
  -32659,     740,  -32719,  -32592,    4096,  -32039,     740,     194,
  -32719,  -32592,  -32718,  -32604,  -32726,  -32725,  -32724,  -32720,
    4096,     710,     180,    6116,  -32719,  -32592,       0,     710,
     180,    6116,     218,     122,      50,     710,     180,   16409,
  -32726,  -32725,  -32724,  -32719,  -32592,    4096,     454,     195,
     195,     195,     454,  -28581,    4188,     186,    4836,  -32719,
  -32592,       0,     195,     195,     195,     710,     180,    5095,
    4829,  -32726,  -32725,  -32724,  -32719,  -32592,    4096,    4827,
    4828,     454,  -32720,  -32719,  -32592,    4096,     194,  -28566,
  -28565,  -28564,    4205,     710,     180,    4829,    4827,    4828,
     194,    4836,  -16291,  -32677,      92,     184,     121,  -28581,
  -28580,  -32722,  -32723,    4317,  -32726,  -32725,  -32724,       0,
     183,  -32726,  -32725,  -32724,  -32720,       0,    4316,     195,
     195,     195,     454,  -28581,    4188,    4315,     183,    4317,
  -32726,  -32725,       0,     195,     195,    4315,    4317,  -32726,
       0,     195,  -32677,  -32676,  -16361,   16431,     228,     228,
      47,  -32610,  -32611,    5345,  -32609,  -32608,  -32607,       0,
    4320,    4319,    5345,  -32609,  -32608,       0,    4319,    5345,
  -32609,       0,  -32613,  -16361,   16431,     222,     222,     156,
  -32677,      92,     183,     186,    1222,   16435,     228,   16403,
     228,     138,    4324,      90,  -16365,       0,    4346,  -32723,
    4189,      93,     454,     148,  -32674,   16546,   16409,  -32597,
     182,  -16383,   16388,     234,  -16365,  -32595,     172,  -32678,
     234,      90,     244,     246,  -16365,       0,     235,  -32678,
     234,  -16365,     246,  -16365,       0,  -32678,     234,      90,
   16407,     222,   16405,     222,     145,   16407,     222,   16405,
     222,     146,   16407,    1252,     154,    5348,  -16365,     142,
     126,     182,  -16383,   16391,  -32678,      30,      90,  -16365,
     127,  -32678,     238,     125,      90,     239,  -16365,    8319,
    8430,     128,     126,  -16361,     127,     190,     240,     189,
   16409,     182,  -16383,   16391,  -32678,      30,      90,  -16365,
       0,  -32678,     240,   16623,      90,  -16365,       0,     244,
     232,    1252,    1252,     137,    1252,     137,    1252,     137,
    1252,     137,    1252,     137,     222,  -16365,       0,     131,
     194,  -16360,  -16333,  -16332,     124,     181,  -16292,  -16277,
   16493,  -31802,    5342,  -28581,    4188,    4263,     181,     186,
     454,   16475,     183,    5598,     222,  -32677,  -32676,   16407,
     454,     996,     186,   16409,     135,  -32632,       0,  -32677,
      92,     454,  -32677,  -32676,  -32662,  -32661,  -32660,  -32659,
     165,  -32677,      92,     188,  -32662,  -32661,     110,     188,
   16407,    5348,   16409,    1478,  -32660,  -32659,     111,  -32732,
      37,  -16344,    4318,     148,  -32674,   16424,     222,   16405,
     222,     174,  -28644,  -32734,  -32680,  -28641,  -32733,  -32730,
  -32735,  -32727,  -32751,  -32738,    4326,  -32738,  -32739,  -32741,
  -32736,     199,  -28644,  -32680,  -28641,    4326,  -32739,  -32741,
     199,  -32738,  -32739,  -32741,  -32736,  -32729,     199,  -32616,
     199,  -32739,  -32741,  -32729,     199,  -32616,  -32729,     199,
  -28644,  -32680,    4326,  -32738,  -32739,  -32741,     199,     245,
    4318,     245,   16409,     152,    4318,   16409,     152,    4318,
     245,   16409,  -24545,  -24548,  -32680,    8422,      39,      32,
     245,      92,      15,    5348,   16400,    1734,  -32672,  -32671,
  -32670,      99,   16407,     200,     144,     185,  -32677,  -32676,
  -32658,     111,   16407,  -32582,     200,   16407,     200,     187,
    5348,     141,   16409,    1478,  -32677,      92,   16410,     191,
  -32677,  -32676,  -32662,  -32661,  -32660,     109,     198,
0(max grammar-774)

%ownshortintegerarray glink(0:max grammar) = %c
      -1,      79,      80,      40,      48,      49,      54,      54,
      54,      54,      54,      53,      55,      83,      86,      57,
      59,      87,      54,      88,      89,      61,      90,      91,
      26,      43,      92,      93,      93,      62,      62,      96,
     100,     103,     104,     105,     110,     111,     112,     115,
      48,      54,      54,       0,     118,     118,     119,      56,
      51,       0,      66,      54,      67,     120,       0,       0,
      54,       0,     119,     121,     121,      69,      63,     122,
     123,     124,      70,      54,      72,      77,     125,     126,
      74,       0,      54,     131,      54,     132,     136,       0,
      81,     137,     137,      84,      54,      42,      84,      54,
      54,       0,     138,     120,     139,      94,      93,       0,
      97,     142,      96,       0,     101,     100,       0,     143,
     144,     106,     149,     108,     105,       0,     150,      54,
     113,     112,       0,     116,     115,       0,      54,      54,
      54,      54,     151,     152,     153,       0,     127,     129,
     125,     154,     125,      54,     133,     155,      54,       0,
     134,      79,     156,     140,      92,       0,     157,      54,
     145,     158,     147,     159,       0,     170,     171,      64,
     172,      54,     128,     134,     173,      98,     174,     160,
     159,     162,     160,     165,       0,     167,     167,     168,
     160,       0,     107,     175,      54,     176,     146,     177,
     134,     178,     181,     177,     153,     178,     178,     184,
     188,     190,     191,     192,     193,     193,     194,     197,
     200,     203,     195,     204,     205,     198,     204,     204,
     201,     204,     204,       0,     206,     207,       0,     208,
     210,       0,     211,       0,     213,     212,       0,     216,
     215,       0,     219,     220,       0,     242,     246,     234,
     248,     249,       0,     250,     251,     252,     258,     246,
     240,     259,     262,     236,     265,     265,     266,     267,
       0,     270,     243,     265,     265,     266,     271,       0,
       0,     203,     272,     278,     253,     287,     287,     256,
     204,     204,     288,     260,     289,     288,     263,     284,
     284,     292,     293,     268,     285,     285,     294,       0,
     273,     284,     284,     276,     285,     285,     279,     284,
     284,     282,     285,     285,     246,     286,     246,       0,
       0,     290,     295,       0,     246,     246,     296,       0,
       0,     298,       0,     300,       0,     302,     304,       0,
       0,     307,       0,       0,     309,     311,       0,     313,
       0,     315,       0,     317,       0,       0,     320,     323,
     324,     325,       0,       0,     326,     321,     324,       0,
     343,     343,     341,     362,     363,     364,     364,     364,
     364,     338,     365,     366,       0,     296,     367,     344,
     353,     354,     255,     374,     375,     376,     377,     378,
       0,     355,     353,     356,     359,     360,       0,     361,
     359,       0,       0,       0,     381,     382,     365,     368,
     386,     387,     388,     389,     390,       0,     391,     392,
     399,     400,     379,     401,     401,     406,     383,     411,
     412,       0,     413,     414,     415,     416,     389,       0,
     393,     375,     376,     377,     353,     354,       0,     394,
     395,     402,     378,     353,     354,       0,     407,     204,
     204,     204,     204,     417,     411,     368,     369,     370,
     382,       0,     421,     287,     287,     422,       0,     432,
     432,     427,     438,     428,     439,     440,     441,       0,
     433,     439,     440,     441,     442,       0,     430,     427,
     445,     438,     443,     446,     446,     429,     436,     448,
     451,     452,       0,     447,     453,     449,     455,     457,
       0,     454,     287,     287,     462,     463,     296,     464,
       0,     467,     472,     468,     467,     473,     472,       0,
     470,     469,     475,     474,     478,       0,     476,     480,
     479,       0,     287,     485,     486,     296,     487,       0,
     490,     490,     491,     492,     493,     494,     495,     496,
     497,     498,       0,     500,     502,       0,     500,     504,
     287,     506,       0,     508,     510,     510,     220,     515,
     513,     521,     522,     516,     519,     515,       0,     516,
     516,       0,     523,     524,     526,       0,       0,     529,
     531,     535,     524,     533,       0,     531,     531,     529,
     537,     538,     539,     540,       0,     542,     543,     544,
     545,       0,     547,     548,     549,     550,     547,       0,
     553,     554,     558,     556,     563,     564,     559,     561,
       0,     559,       0,     565,     563,     566,     568,     569,
     569,       0,     571,     573,       0,     574,     575,     576,
     560,     578,     582,     580,     587,     588,     583,     585,
       0,     583,       0,     589,     587,     586,       0,     592,
     220,       0,     595,     593,     597,     594,     599,     596,
     601,     598,     603,     600,     605,     604,       0,     608,
     609,     621,     622,     613,     220,     614,     617,     617,
     617,     619,     220,     623,     623,     624,     625,     626,
     610,     627,     220,     220,     220,     632,     632,     633,
     634,     635,     636,     637,     631,     639,       0,     641,
     641,     206,     206,     206,     206,     206,     206,     206,
       0,     651,     651,     206,     655,     655,     656,       0,
     657,     658,     659,     655,     655,     655,     656,     665,
     667,     296,     296,     668,     296,     296,     671,     672,
     673,       0,     685,     712,     719,     701,     690,     220,
     220,     220,     727,     220,     685,     694,     703,     720,
     701,       0,     697,     721,     701,     697,     703,     720,
       0,     705,     709,     724,     701,     220,       0,     220,
       0,     709,     724,     220,       0,     701,     220,       0,
     715,     728,     715,     694,     703,     720,       0,     685,
     722,     697,     723,     220,     725,     726,     701,     729,
     715,     730,     734,     735,     736,     735,     220,     734,
     735,     738,     739,     740,     741,       0,     746,     746,
     746,     746,     747,     748,     749,       0,     754,     754,
     757,     757,     755,     758,     759,     760,     761,     761,
     762,     749,     763,       0,     766,     766,     767,     768,
     774,     774,     774,     774,     774,     774,       0,
0(max grammar-774)

%ownshortintegerarray kdict(32:674) = %c
       0,     511,     131,     531,     131,     551,     559,     131,
     567,     599,     607,     655,     663,     671,     703,     723,
     129,     129,     129,     129,     129,     129,     129,     129,
     129,     129,     743,     762,     771,     827,     847,     131,
     131,     876,     952,    1084,    1212,    1256,    1432,     128,
    1560,    1600,     128,     128,    1668,    1752,    1804,    1896,
    1984,     128,    2044,    2216,    2436,    2468,     128,    2508,
     128,     128,     128,    2527,    2535,    2579,    2587,    2607,
     131,     131,     131,     131,     131,     131,     131,     131,
     131,     131,     131,     131,     131,     131,     131,     131,
     131,     131,     131,     131,     131,     131,     131,     131,
     131,     131,     131,    2615,    2675,     131,    2587,  -32351,
   16428,      25,   16428,      29,  -32349,   16433,       1,   16434,
       1,  -16127,       0,   16427,      21,  -31990,  -32326,   16407,
       0,   16399,     117,   16407,       0,   16409,       0,  -31958,
  -32323,  -10840,      40,   16471,       0,  -32342,   16426,      51,
      42,   16426,      13,  -10580,      32,   16384,      19,  -31990,
  -32322,  -10580,      36,   -9290,       0,   16384,       0,  -32374,
   16432,      13,   16432,      13,  -32337,   16427,      46,   16427,
      17,  -32343,   16405,       0,   16400,       0,   16404,       0,
  -31187,  -31556,  -31939,  -32322,   16433,       2,   16433,       1,
   16433,       5,   16426,       5,   16437,       2,  -32323,   -9807,
       0,   -9678,       0,  -31939,  -32322,   16433,       4,   16426,
       9,   16433,       3,  -30772,  -31666,   10578,   11457,  -32344,
   16413,       2,   16411,       2,      68,  -32374,   16440,       0,
   16440,       0,    8393,      83,   16408,       0,  -28987,  -31287,
   10841,      69,  -32311,   16412,      18,   10830,    9157,   10565,
   16412,      18,      84,  -31039,  -31538,  -32049,   10200,      82,
   16428,      29,      82,   16428,      25,   10831,   16430,      51,
    8782,   16427,      21,    9415,      78,   16458,       0,  -28918,
  -32049,    8665,    8908,   16455,       0,  -30131,      78,  -31277,
      84,  -32055,   10194,      76,   16469,       0,   10958,      69,
   16447,      32,      84,  -32319,   16418,       2,   10830,   16418,
       2,    8909,   10830,   16406,       0,   16384,       0,  -31927,
   10073,    9921,    8649,   16419,       5,    9153,   10190,    8915,
   16469,       1,  -27444,  -31282,      88,  -31927,    8916,   10066,
    9793,   16419,       3,      84,   16447,       4,      68,  -32305,
   16459,       2,      70,  -30138,  -30772,      80,  -31419,   10194,
   10567,    9921,  -32307,   16460,       1,      69,   16460,       1,
    9938,   16461,       0,   10697,      84,   16467,       3,    9801,
      69,   16460,       0,    8915,   16452,       0,  -29119,  -30391,
  -30770,  -31281,  -31790,   10069,   10819,   10185,      78,   16416,
       9,    9935,   16473,       0,      82,   16445,       0,   16416,
       9,    9422,    9299,  -32315,   16453,       0,   10700,      69,
   16454,       0,   10700,      69,   16464,    1210,    9793,      70,
  -32311,   16412,      19,   10830,    9157,   10565,   16412,      19,
  -30778,      78,  -31549,    8916,    8903,      82,  -32344,   16412,
      17,   16472,      17,   10956,    8900,   16470,       0,   16446,
      44,  -30527,  -31031,   10063,      71,  -32055,    8914,    9793,
   16412,      36,   10830,    9157,   10565,   16412,      20,   10835,
   16467,       1,    8898,      76,   16425,       6,  -31423,      79,
  -31932,    9422,   10196,      82,   16465,     109,   16431,      14,
      80,   16416,      10,  -31423,      79,  -32180,      84,   16442,
       0,   10697,      84,   16467,       3,    8909,  -32314,   16414,
       1,  -31794,   10069,   10819,   10185,      78,   16416,      10,
   16416,      10,  -30770,  -31408,  -32174,   10071,   16418,       1,
  -32374,   16441,       2,   16441,       2,    9428,   10063,   16402,
       0,  -32315,   16448,       0,    8918,   10830,   16448,       0,
  -31163,      82,  -32059,    9929,      40,   16401,       6,    9412,
    8387,    8916,   16415,     123,    9938,   16419,       7,  -31931,
   10959,    9428,    8910,   16415,     104,  -28351,  -30397,  -31024,
  -32045,   10964,   10066,   16464,    1319,    9813,    7892,  -32323,
   16462,    1384,   16463,    1241,    8389,      84,   16456,       0,
   10575,      68,  -32314,   16421,      64,   10575,    8397,      84,
  -32301,   16422,       9,    8912,      67,   16422,      12,      76,
   16412,      33,  -26299,  -27704,  -28983,  -29488,  -31276,  -31913,
   10713,    8916,      77,   16419,       4,   10825,    9283,   16417,
      12,  -31423,  -31921,    9426,    9166,      40,   16420,      48,
      80,   16466,       0,   10834,   16451,       0,    8645,   16423,
       0,   10055,    9793,  -32315,   16449,       0,    8918,   10830,
   16449,       0,   10575,      84,  -32311,   16412,      19,   10830,
    9157,   10565,   16412,      19,   10819,   10185,      78,   16457,
       0,  -32056,   10962,      69,   16464,    1354,   10053,   16450,
       0,      78,  -32052,    9428,      76,   16444,     182,   10693,
      83,   16446,      46,    9416,    8908,   16443,     180,   16399,
     117,  -31939,  -32292,  -10454,      51,   16426,      13,  -32323,
   16433,       1,   16434,       1,   16400,       0,  -32290,  -10454,
      51,   16426,      13,   16410,       0,   14694,   14063,   13472,
   13028,   14958,   13161,   13033,    4210,   14310,   13932,   15343,
   14185,   12007,   16502,       0,   16431,      14,  -32323,   16430,
      51,   16433,       1
   %list
%endoffile