main(argc, argv)
int argc;
int *argv;
{
	int m;
    	mode(1);
	asm("di\n");
poke(0x7050,40);
poke(0x706D,2);poke(0x706E,168);poke(0x706F,2);poke(0x7070,170);poke(0x7071,128);
poke(0x708D,10);poke(0x708E,170);poke(0x708F,10);poke(0x7090,170);poke(0x7091,160);
poke(0x70AD,42);poke(0x70AE,170);poke(0x70AF,170);poke(0x70B0,170);poke(0x70B1,160);
poke(0x70CD,10);poke(0x70CE,170);poke(0x70CF,170);poke(0x70D0,170);poke(0x70D1,128);
poke(0x70DE,15);poke(0x70DF,128);poke(0x70ED,2);poke(0x70EE,106);poke(0x70EF,170);
poke(0x70F0,8);poke(0x70FC,3);poke(0x70FD,255);poke(0x70FE,85);poke(0x70FF,126);
poke(0x7109,136);poke(0x710D,2);poke(0x710E,169);poke(0x710F,170);
poke(0x711C,255);poke(0x711D,255);poke(0x711E,255);poke(0x711F,248);
poke(0x7128,10);poke(0x7129,9);poke(0x712D,234);poke(0x712E,170);poke(0x712F,170);
poke(0x713B,15);poke(0x713C,255);poke(0x713D,255);poke(0x713E,255);poke(0x713F,160);
poke(0x7147,2);poke(0x7148,165);poke(0x7149,90);
poke(0x714A,106);poke(0x714C,3);poke(0x714D,234);poke(0x714E,162);poke(0x714F,160);
poke(0x715B,15);poke(0x715C,255);poke(0x715D,255);poke(0x715E,234);poke(0x7167,41);
poke(0x7168,85);poke(0x7169,169);poke(0x716A,90);poke(0x716D,170);poke(0x716F,128);
poke(0x717B,15);poke(0x717C,255);poke(0x717D,255);poke(0x717E,128);
poke(0x7186,2);poke(0x7187,85);poke(0x7188,90);poke(0x7189,10);poke(0x718A,86);poke(0x718B,136);
poke(0x718E,2);poke(0x718F,128);poke(0x719B,3);poke(0x719C,255);poke(0x719D,254);
poke(0x71A6,37);poke(0x71A7,85);poke(0x71A8,128);poke(0x71A9,40);
poke(0x71AA,149);poke(0x71AB,170);poke(0x71AE,2);poke(0x71AF,160);
poke(0x71BC,63);poke(0x71BD,255);poke(0x71BE,224);
poke(0x71C5,10);poke(0x71C6,85);poke(0x71C7,106);
poke(0x71C9,2);poke(0x71CA,9);poke(0x71CB,90);poke(0x71CC,170);poke(0x71CD,170);
poke(0x71CE,170);poke(0x71CF,170);poke(0x71D0,128);poke(0x71D1,32);
poke(0x71DC,15);poke(0x71DD,255);poke(0x71DE,248);poke(0x71E5,2);
poke(0x71E6,166);poke(0x71E7,128);poke(0x71EA,33);poke(0x71EB,104);
poke(0x71EE,170);poke(0x71EF,170);poke(0x71F0,160);poke(0x71F1,32);
poke(0x71FC,3);poke(0x71FD,245);poke(0x71FE,88);poke(0x7206,40);poke(0x7209,42);
poke(0x720D,10);poke(0x720E,170);poke(0x720F,162);
poke(0x7210,128);poke(0x7211,40);poke(0x7214,255);poke(0x7215,255);poke(0x7216,168);
poke(0x721D,255);poke(0x721E,94);poke(0x7220,2);poke(0x7221,170);poke(0x7222,170);poke(0x7223,128);
poke(0x7228,15);poke(0x7229,254);poke(0x722A,128);poke(0x722D,170);
poke(0x722E,170);poke(0x722F,130);poke(0x7231,10);poke(0x7232,255);poke(0x7233,255);
poke(0x7234,213);poke(0x7235,95);poke(0x7236,255);poke(0x7237,160);
poke(0x723D,63);poke(0x723E,87);poke(0x723F,128);
poke(0x7240,2);poke(0x7241,255);poke(0x7242,254);poke(0x7243,240);poke(0x7244,255);poke(0x7245,255);
poke(0x7246,255);poke(0x7247,143);poke(0x7248,255);poke(0x7249,86);
poke(0x724C,2);poke(0x724D,170);poke(0x724E,154);poke(0x724F,170);poke(0x7250,32);poke(0x7251,10);
poke(0x7252,255);poke(0x7253,255);poke(0x7254,255);poke(0x7255,85);poke(0x7256,85);poke(0x7257,250);
poke(0x725D,15);poke(0x725E,247);poke(0x725F,128);poke(0x7261,190);poke(0x7262,171);poke(0x7263,255);
poke(0x7264,255);poke(0x7265,255);poke(0x7266,255);poke(0x7267,250);poke(0x7268,171);poke(0x7269,248);
poke(0x726C,2);poke(0x726D,170);poke(0x726E,86);poke(0x726F,170);
poke(0x7270,170);poke(0x7271,171);poke(0x7272,255);poke(0x7273,255);poke(0x7274,255);poke(0x7275,255);
poke(0x7276,245);poke(0x7277,95);poke(0x7278,160);
poke(0x727D,15);poke(0x727E,255);poke(0x727F,224);poke(0x7281,47);
poke(0x7282,191);poke(0x7283,255);poke(0x7284,255);poke(0x7285,255);poke(0x7286,255);poke(0x7287,255);
poke(0x7288,175);poke(0x7289,234);poke(0x728A,160);poke(0x728B,2);poke(0x728C,170);poke(0x728D,169);
poke(0x728E,170);poke(0x728F,160);poke(0x7290,15);poke(0x7291,255);poke(0x7292,255);poke(0x7293,255);
poke(0x7294,255);poke(0x7295,255);poke(0x7296,255);poke(0x7297,213);poke(0x7298,248);
poke(0x729D,3);poke(0x729E,255);poke(0x729F,224);
poke(0x72A1,10);poke(0x72A2,255);poke(0x72A3,255);poke(0x72A4,255);poke(0x72A5,255);
poke(0x72A6,255);poke(0x72A7,255);poke(0x72A8,255);poke(0x72A9,191);poke(0x72AA,255);
poke(0x72AC,252);poke(0x72AD,255);poke(0x72AE,106);poke(0x72AF,163);poke(0x72B0,255);poke(0x72B1,255);
poke(0x72B2,85);poke(0x72B3,255);poke(0x72B4,255);poke(0x72B5,255);poke(0x72B6,255);poke(0x72B7,245);
poke(0x72B8,254);poke(0x72BD,15);
poke(0x72BE,255);poke(0x72BF,224);poke(0x72C1,11);poke(0x72C2,255);poke(0x72C3,255);
poke(0x72C4,255);poke(0x72C5,255);poke(0x72C6,255);poke(0x72C7,255);poke(0x72C8,254);poke(0x72C9,191);
poke(0x72CA,255);poke(0x72CB,252);poke(0x72CC,255);poke(0x72CD,255);poke(0x72CE,214);poke(0x72CF,163);
poke(0x72D0,85);poke(0x72D1,127);poke(0x72D2,255);poke(0x72D3,255);poke(0x72D4,255);poke(0x72D5,255);
poke(0x72D6,255);poke(0x72D7,255);poke(0x72D8,254);poke(0x72D9,255);
poke(0x72DC,3);poke(0x72DD,255);poke(0x72DE,255);poke(0x72DF,128);poke(0x72E1,47);
poke(0x72E2,255);poke(0x72E3,175);poke(0x72E4,255);poke(0x72E5,250);poke(0x72E6,255);poke(0x72E7,255);
poke(0x72E8,213);poke(0x72E9,191);poke(0x72EA,253);poke(0x72EB,95);poke(0x72EC,255);poke(0x72ED,250);
poke(0x72EE,170);poke(0x72EF,104);poke(0x72F0,255);poke(0x72F1,215);poke(0x72F2,255);poke(0x72F3,255);
poke(0x72F4,255);poke(0x72F5,255);poke(0x72F6,255);poke(0x72F7,255);poke(0x72F8,255);poke(0x72F9,191);
poke(0x72FA,252);poke(0x72FB,243);poke(0x72FC,255);poke(0x72FD,253);poke(0x72FE,95);poke(0x72FF,128);
poke(0x7301,47);poke(0x7302,254);poke(0x7303,91);poke(0x7304,255);poke(0x7305,229);
poke(0x7306,191);poke(0x7307,255);poke(0x7308,245);poke(0x7309,239);poke(0x730A,255);poke(0x730B,215);
poke(0x730C,255);poke(0x730D,255);poke(0x730E,170);poke(0x730F,170);poke(0x7310,255);poke(0x7311,255);
poke(0x7312,255);poke(0x7313,255);poke(0x7314,255);poke(0x7315,255);poke(0x7316,255);poke(0x7317,255);
poke(0x7318,255);poke(0x7319,191);poke(0x731A,95);poke(0x731B,255);poke(0x731C,255);poke(0x731D,85);
poke(0x731E,126);poke(0x7321,47);poke(0x7322,254);poke(0x7323,91);
poke(0x7324,255);poke(0x7325,229);poke(0x7326,191);poke(0x7327,255);poke(0x7328,253);poke(0x7329,239);
poke(0x732A,255);poke(0x732B,255);poke(0x732C,255);poke(0x732D,255);poke(0x732E,250);poke(0x732F,170);
poke(0x7330,255);poke(0x7331,255);poke(0x7332,255);poke(0x7333,255);poke(0x7334,255);poke(0x7335,255);
poke(0x7336,255);poke(0x7337,255);poke(0x7338,255);poke(0x7339,239);poke(0x733A,223);poke(0x733B,255);
poke(0x733C,213);poke(0x733D,87);poke(0x733E,128);poke(0x7341,191);
poke(0x7342,255);poke(0x7343,175);poke(0x7344,255);poke(0x7345,250);poke(0x7346,255);poke(0x7347,255);
poke(0x7348,253);poke(0x7349,239);poke(0x734A,255);poke(0x734B,255);poke(0x734C,255);poke(0x734D,255);
poke(0x734E,255);poke(0x734F,175);poke(0x7350,255);poke(0x7351,255);poke(0x7352,255);poke(0x7353,255);
poke(0x7354,255);poke(0x7355,255);poke(0x7356,255);poke(0x7357,255);poke(0x7358,255);poke(0x7359,239);
poke(0x735A,255);poke(0x735B,255);poke(0x735C,255);poke(0x735D,224);
poke(0x7361,191);poke(0x7362,255);poke(0x7363,213);poke(0x7364,95);poke(0x7365,255);
poke(0x7366,255);poke(0x7367,255);poke(0x7368,253);poke(0x7369,239);poke(0x736A,255);poke(0x736B,255);
poke(0x736C,255);poke(0x736D,255);poke(0x736E,255);poke(0x736F,255);poke(0x7370,255);poke(0x7371,255);
poke(0x7372,255);poke(0x7373,255);poke(0x7374,255);poke(0x7375,255);poke(0x7376,255);poke(0x7377,255);
poke(0x7378,255);poke(0x7379,248);poke(0x737A,63);poke(0x737B,255);poke(0x737C,128);
poke(0x7381,191);poke(0x7382,255);poke(0x7383,85);
poke(0x7384,87);poke(0x7385,255);poke(0x7386,255);poke(0x7387,255);poke(0x7388,255);poke(0x7389,239);
poke(0x738A,255);poke(0x738B,255);poke(0x738C,255);poke(0x738D,255);poke(0x738E,255);poke(0x738F,255);
poke(0x7390,255);poke(0x7391,255);poke(0x7392,255);poke(0x7393,255);poke(0x7394,255);poke(0x7395,255);
poke(0x7396,255);poke(0x7397,255);poke(0x7398,255);poke(0x7399,248);poke(0x73A1,191);
poke(0x73A2,255);poke(0x73A3,213);poke(0x73A4,95);poke(0x73A5,255);poke(0x73A6,255);poke(0x73A7,255);
poke(0x73A8,255);poke(0x73A9,239);poke(0x73AA,255);poke(0x73AB,255);poke(0x73AC,255);poke(0x73AD,255);
poke(0x73AE,255);poke(0x73AF,255);poke(0x73B0,255);poke(0x73B1,255);poke(0x73B2,255);poke(0x73B3,255);
poke(0x73B4,255);poke(0x73B5,255);poke(0x73B6,255);poke(0x73B7,255);poke(0x73B8,255);poke(0x73B9,248);
poke(0x73C1,47);poke(0x73C2,255);poke(0x73C3,245);poke(0x73C4,127);poke(0x73C5,255);
poke(0x73C6,255);poke(0x73C7,255);poke(0x73C8,255);poke(0x73C9,111);poke(0x73CA,255);poke(0x73CB,255);
poke(0x73CC,255);poke(0x73CD,255);poke(0x73CE,255);poke(0x73CF,255);poke(0x73D0,255);poke(0x73D1,255);
poke(0x73D2,255);poke(0x73D3,255);poke(0x73D4,255);poke(0x73D5,255);poke(0x73D6,255);poke(0x73D7,255);
poke(0x73D8,255);poke(0x73D9,248);poke(0x73E1,11);poke(0x73E2,255);poke(0x73E3,253);
poke(0x73E4,255);poke(0x73E5,255);poke(0x73E6,255);poke(0x73E7,255);poke(0x73E8,253);poke(0x73E9,191);
poke(0x73EA,255);poke(0x73EB,255);poke(0x73EC,255);poke(0x73ED,255);poke(0x73EE,255);poke(0x73EF,255);
poke(0x73F0,255);poke(0x73F1,255);poke(0x73F2,255);poke(0x73F3,255);poke(0x73F4,255);poke(0x73F5,255);
poke(0x73F6,255);poke(0x73F7,255);poke(0x73F8,255);poke(0x73F9,248);poke(0x7401,2);
poke(0x7402,255);poke(0x7403,255);poke(0x7404,255);poke(0x7405,255);poke(0x7406,255);poke(0x7407,255);
poke(0x7408,117);poke(0x7409,191);poke(0x740A,255);poke(0x740B,255);poke(0x740C,255);poke(0x740D,255);
poke(0x740E,255);poke(0x740F,255);poke(0x7410,255);poke(0x7411,255);poke(0x7412,255);poke(0x7413,255);
poke(0x7414,255);poke(0x7415,255);poke(0x7416,255);poke(0x7417,255);poke(0x7418,255);poke(0x7419,248);
poke(0x7422,171);poke(0x7423,255);poke(0x7424,255);poke(0x7425,255);
poke(0x7426,255);poke(0x7427,253);poke(0x7428,246);poke(0x7429,255);poke(0x742A,255);poke(0x742B,255);
poke(0x742C,255);poke(0x742D,255);poke(0x742E,255);poke(0x742F,255);poke(0x7430,255);poke(0x7431,255);
poke(0x7432,255);poke(0x7433,255);poke(0x7434,255);poke(0x7435,255);poke(0x7436,255);poke(0x7437,255);
poke(0x7438,255);poke(0x7439,248);poke(0x7442,2);poke(0x7443,175);
poke(0x7444,235);poke(0x7445,255);poke(0x7446,254);poke(0x7447,91);poke(0x7448,191);poke(0x7449,255);
poke(0x744A,255);poke(0x744B,255);poke(0x744C,255);poke(0x744D,255);poke(0x744E,255);poke(0x744F,255);
poke(0x7450,255);poke(0x7451,255);poke(0x7452,255);poke(0x7453,255);poke(0x7454,255);poke(0x7455,255);
poke(0x7456,255);poke(0x7457,255);poke(0x7458,255);poke(0x7459,248);
poke(0x7463,10);poke(0x7464,130);poke(0x7465,170);poke(0x7466,255);poke(0x7467,175);
poke(0x7468,255);poke(0x7469,255);poke(0x746A,255);poke(0x746B,255);poke(0x746C,255);poke(0x746D,255);
poke(0x746E,255);poke(0x746F,255);poke(0x7470,255);poke(0x7471,255);poke(0x7472,255);poke(0x7473,255);
poke(0x7474,255);poke(0x7475,255);poke(0x7476,255);poke(0x7477,255);poke(0x7478,255);poke(0x7479,248);
poke(0x7486,190);poke(0x7487,255);poke(0x7488,255);poke(0x7489,255);poke(0x748A,255);poke(0x748B,255);
poke(0x748C,255);poke(0x748D,255);poke(0x748E,255);poke(0x748F,255);poke(0x7490,255);poke(0x7491,255);
poke(0x7492,255);poke(0x7493,255);poke(0x7494,255);poke(0x7495,255);poke(0x7496,255);poke(0x7497,255);
poke(0x7498,255);poke(0x7499,248);poke(0x74A6,47);poke(0x74A7,255);poke(0x74A8,255);poke(0x74A9,255);
poke(0x74AA,255);poke(0x74AB,255);poke(0x74AC,255);poke(0x74AD,255);poke(0x74AE,255);poke(0x74AF,255);
poke(0x74B0,255);poke(0x74B1,255);poke(0x74B2,255);poke(0x74B3,255);poke(0x74B4,255);poke(0x74B5,255);
poke(0x74B6,255);poke(0x74B7,255);poke(0x74B8,255);poke(0x74B9,248);poke(0x74C6,15);poke(0x74C7,255);
poke(0x74C8,255);poke(0x74C9,255);poke(0x74CA,255);poke(0x74CB,255);poke(0x74CC,255);poke(0x74CD,255);
poke(0x74CE,255);poke(0x74CF,255);poke(0x74D0,255);poke(0x74D1,255);poke(0x74D2,255);poke(0x74D3,255);
poke(0x74D4,255);poke(0x74D5,255);poke(0x74D6,255);poke(0x74D7,255);poke(0x74D8,255);poke(0x74D9,248);
poke(0x74E6,3);poke(0x74E7,255);poke(0x74E8,255);poke(0x74E9,255);poke(0x74EA,255);poke(0x74EB,255);
poke(0x74EC,255);poke(0x74ED,255);poke(0x74EE,255);poke(0x74EF,255);poke(0x74F0,255);poke(0x74F1,255);
poke(0x74F2,255);poke(0x74F3,255);poke(0x74F4,95);poke(0x74F5,255);poke(0x74F6,255);poke(0x74F7,255);
poke(0x74F8,255);poke(0x74F9,248);poke(0x7507,63);poke(0x7508,255);poke(0x7509,255);
poke(0x750A,255);poke(0x750B,255);poke(0x750C,255);poke(0x750D,255);poke(0x750E,255);poke(0x750F,255);
poke(0x7510,255);poke(0x7511,255);poke(0x7512,255);poke(0x7513,253);poke(0x7514,87);poke(0x7515,254);
poke(0x7516,255);poke(0x7517,255);poke(0x7518,255);poke(0x7519,248);poke(0x7527,3);
poke(0x7528,255);poke(0x7529,255);poke(0x752A,255);poke(0x752B,255);poke(0x752C,255);poke(0x752D,255);
poke(0x752E,255);poke(0x752F,255);poke(0x7530,255);poke(0x7531,255);poke(0x7532,255);poke(0x7533,213);
poke(0x7534,127);poke(0x7535,255);poke(0x7536,191);poke(0x7537,255);poke(0x7538,255);poke(0x7539,248);
poke(0x7548,63);poke(0x7549,255);poke(0x754A,255);poke(0x754B,255);
poke(0x754C,255);poke(0x754D,191);poke(0x754E,255);poke(0x754F,191);poke(0x7550,255);poke(0x7551,255);
poke(0x7552,213);poke(0x7553,95);poke(0x7554,255);poke(0x7555,255);poke(0x7556,191);poke(0x7557,255);
poke(0x7558,255);poke(0x7559,248);poke(0x7569,255);
poke(0x756A,239);poke(0x756B,255);poke(0x756C,239);poke(0x756D,191);poke(0x756E,255);poke(0x756F,239);
poke(0x7570,255);poke(0x7571,255);poke(0x7572,255);poke(0x7573,255);poke(0x7574,254);
poke(0x7576,63);poke(0x7577,255);poke(0x7578,223);poke(0x7579,128);
poke(0x7588,3);poke(0x7589,255);poke(0x758A,224);poke(0x758B,15);poke(0x758C,251);poke(0x758D,191);
poke(0x758E,255);poke(0x758F,239);poke(0x7590,255);poke(0x7591,255);poke(0x7592,255);poke(0x7593,234);
poke(0x7594,128);poke(0x7596,63);poke(0x7597,255);poke(0x7598,215);poke(0x7599,128);
poke(0x75A8,3);poke(0x75A9,255);poke(0x75AA,248);poke(0x75AD,63);poke(0x75AE,255);poke(0x75AF,248);
poke(0x75B2,63);poke(0x75B3,255);poke(0x75B4,128);poke(0x75B6,15);poke(0x75B7,255);
poke(0x75B8,215);poke(0x75B9,128);poke(0x75C8,3);poke(0x75C9,255);
poke(0x75CA,248);poke(0x75CD,63);poke(0x75CE,255);poke(0x75CF,248);
poke(0x75D2,255);poke(0x75D3,255);poke(0x75D4,128);
poke(0x75D6,63);poke(0x75D7,255);poke(0x75D8,215);poke(0x75D9,128);
poke(0x75E9,255);poke(0x75EA,254);poke(0x75ED,63);
poke(0x75EE,255);poke(0x75EF,248);poke(0x75F2,255);poke(0x75F3,255);
poke(0x75F4,128);poke(0x75F6,63);poke(0x75F7,255);poke(0x75F8,222);
poke(0x7609,255);poke(0x760A,254);poke(0x760D,63);poke(0x760E,253);poke(0x760F,120);
poke(0x7612,255);poke(0x7613,255);poke(0x7614,128);poke(0x7616,63);poke(0x7617,255);
poke(0x7618,94);poke(0x7629,255);
poke(0x762A,255);poke(0x762B,128);poke(0x762D,63);poke(0x762E,253);poke(0x762F,120);
poke(0x7632,255);poke(0x7633,255);poke(0x7634,128);poke(0x7636,255);poke(0x7637,255);poke(0x7638,88);
poke(0x7649,255);poke(0x764A,255);poke(0x764B,128);poke(0x764D,63);
poke(0x764E,253);poke(0x764F,88);poke(0x7651,3);poke(0x7652,255);poke(0x7653,255);
poke(0x7654,128);poke(0x7656,255);poke(0x7657,253);poke(0x7658,88);
poke(0x7669,255);poke(0x766A,254);poke(0x766D,63);poke(0x766E,253);poke(0x766F,94);poke(0x7671,3);
poke(0x7672,255);poke(0x7673,255);poke(0x7674,128);poke(0x7676,255);poke(0x7677,253);
poke(0x7678,248);poke(0x7688,3);poke(0x7689,255);
poke(0x768A,254);poke(0x768D,63);poke(0x768E,253);poke(0x768F,94);
poke(0x7691,63);poke(0x7692,255);poke(0x7693,255);poke(0x7694,128);poke(0x7695,3);
poke(0x7696,255);poke(0x7697,255);poke(0x7698,224);
poke(0x76A8,3);poke(0x76A9,255);poke(0x76AA,254);poke(0x76AD,63);
poke(0x76AE,255);poke(0x76AF,126);poke(0x76B0,3);poke(0x76B1,255);poke(0x76B2,255);poke(0x76B3,255);
poke(0x76B4,160);poke(0x76B5,15);poke(0x76B6,255);poke(0x76B7,255);poke(0x76B8,128);
poke(0x76C7,15);poke(0x76C8,255);poke(0x76C9,255);poke(0x76CA,255);poke(0x76CB,128);
poke(0x76CD,63);poke(0x76CE,255);poke(0x76CF,254);poke(0x76D0,255);poke(0x76D1,255);
poke(0x76D2,255);poke(0x76D3,255);poke(0x76D4,235);poke(0x76D5,255);poke(0x76D6,255);poke(0x76D7,255);
poke(0x76D8,128);poke(0x76E6,255);poke(0x76E7,239);poke(0x76E8,255);poke(0x76E9,255);
poke(0x76EA,255);poke(0x76EB,248);poke(0x76ED,255);poke(0x76EE,255);poke(0x76EF,255);
poke(0x76F0,143);poke(0x76F1,255);poke(0x76F2,255);poke(0x76F3,255);poke(0x76F4,255);poke(0x76F5,255);
poke(0x76F6,255);poke(0x76F7,245);poke(0x76F8,248);poke(0x7705,3);poke(0x7706,255);poke(0x7707,254);
poke(0x7708,63);poke(0x7709,255);poke(0x770A,255);poke(0x770B,254);poke(0x770C,255);poke(0x770D,255);
poke(0x770E,255);poke(0x770F,253);poke(0x7710,126);poke(0x7711,191);poke(0x7712,171);poke(0x7713,255);
poke(0x7714,255);poke(0x7715,255);poke(0x7716,255);poke(0x7717,213);poke(0x7718,86);poke(0x7725,4);
poke(0x7726,63);poke(0x7727,251);poke(0x7728,255);poke(0x7729,255);poke(0x772A,131);poke(0x772B,255);
poke(0x772C,255);poke(0x772D,255);poke(0x772E,255);poke(0x772F,85);poke(0x7730,95);poke(0x7731,191);
poke(0x7732,191);poke(0x7733,255);poke(0x7734,248);poke(0x7735,255);poke(0x7736,255);poke(0x7737,255);
poke(0x7738,254);poke(0x7746,63);poke(0x7747,251);poke(0x7748,227);poke(0x7749,254);
poke(0x774A,255);poke(0x774B,255);poke(0x774C,143);poke(0x774D,255);poke(0x774E,255);poke(0x774F,255);
poke(0x7750,255);poke(0x7751,191);poke(0x7752,131);poke(0x7753,255);poke(0x7754,207);poke(0x7755,245);
poke(0x7756,126);poke(0x7757,15);poke(0x7758,245);poke(0x7759,120);
poke(0x7766,64);poke(0x7769,254);poke(0x776A,255);poke(0x776B,255);poke(0x776C,191);poke(0x776D,245);
poke(0x776E,248);poke(0x776F,63);poke(0x7770,247);poke(0x7771,248);poke(0x7773,255);
poke(0x7774,175);poke(0x7775,255);poke(0x7776,254);poke(0x7777,255);poke(0x7778,255);poke(0x7779,126);
poke(0x7788,4);poke(0x7789,16);poke(0x778A,3);poke(0x778B,254);
poke(0x778C,255);poke(0x778D,255);poke(0x778E,254);poke(0x778F,255);poke(0x7790,253);poke(0x7791,126);
poke(0x7792,1);poke(0x7793,4);poke(0x7796,248);poke(0x7797,63);
poke(0x7798,192);poke(0x77AC,248);poke(0x77AD,15);poke(0x77AE,254);poke(0x77AF,255);
poke(0x77B1,192);poke(0x77B4,1);poke(0x77B6,64);poke(0x77B7,64);
poke(0x77CC,64);poke(0x77CD,4);poke(0x77CE,16);poke(0x77CF,16);

	draw_string(68,0, 1, "'BARK LIKE");
	draw_string(74,7, 1, "A DOG'");
	m=1;
	while(m==1){;}
}


draw_string(x,y,color,src)
int x,y,color;
char *src;
{	
	while (*src){
		char_draw(x,y,color,*src);
	   	x = x + 6;
           	src++;	
	}
}