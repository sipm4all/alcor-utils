#pragma once

namespace definitions {

std::map<std::string, std::map<std::string, std::string>> dirname_led = {
  /*
  { "HAMA1" , {
      { "OLD"   , "test-irradiated" },
      { "NEW"   , "20220526-083350/NEW/4/led" } ,
      { "IRR1"  , "20220616-171657/IRR1/4/led" } ,
      { "ANN1"  , "20220708-094346/ANN1/4/led" } 
    } } ,
  */
  { "HAMA1" , {
      { "OLD"   , "test-hama2-irradiated" }
    } } ,
  { "HAMA2" , {
      { "OLD"   , "test-hama2-irradiated" }
    } }
};

  /*
std::vector<int> dacs_led = {
  2522, 2548, 2574, 2600, 2626,
  2652, 2678, 2705, 2731, 2757,
  2783, 2809, 2835, 2861, 2887,
  2913, 2939, 2965, 2992, 3018, 3044
};
  */

  //hama2-reference  2498,2524,2550,2576,2602,2628,2654,2680,2706,2732,2758,2784,2810,2836,2862,2888,2914,2940,2966,2992,3018 

  //hama2-target 2455,2490,2524,2558,2592,2626,2660,2694,2728,2762,2796,2831,2865,2899,2933
  
std::map<std::string, std::vector<int>> dacs_led = {
  { "HAMA1" , {
      2498,2524,2550,2576,2602,2628,2654,2680,2706,2732,2758,2784,2810,2836,2862,2888,2914,2940,2966,2992,3018
    } } ,
  { "HAMA2" , {
      2455,2490,2524,2558,2592,2626,2660,2694,2728,2762,2796,2831,2865,2899,2933
    } }
};

std::map<std::string, std::map<std::string, std::string>> dirname_dcr = {
  { "HAMA1"  , {
      { "OLD"       , "20220607-094413/OLD/1s/dcr/HAMA1-chip2"       } ,
      { "NEW"       , "20220524-170501/NEW/2/dcr/HAMA1-chip2"        } ,
      { "IRR1"      , "20220614-095618/IRR1/2/dcr/HAMA1-chip2"       } ,
      { "ANN1"      , "20220706-092039/ANN1/2/dcr/HAMA1-chip2"       } ,
      { "IRR2"      , "20220726-095315/IRR2/2/dcr/HAMA1-chip2"       } ,
      { "ANN2"      , "20220824-075943/ANN2/2/dcr/HAMA1-chip2"       } ,
      { "ANN2-bis"  , "20221027-155337/ANN2-bis/2/dcr/HAMA1-chip2"   } ,
      { "IRR3"      , "20221115-084654/IRR3/2/dcr/HAMA1-chip2"       } ,
      { "ANN3"      , "20221125-085159/ANN3/2/dcr/HAMA1-chip2"       } ,
      { "IRR4"      , "20221228-080527/IRR4/2/dcr/HAMA1-chip2"       } ,
      { "ANN4"      , "20230110-091540/ANN4/2/dcr/HAMA1-chip2"       } ,      
      { "ANN4-IBOX" , "20230216-121737/hama1/dcr/HAMA1-chip0"        } ,      
      { "ANN4-FLEX" , "20230216-141020/ANN4-FLEX/2/dcr/HAMA1-chip2"  } ,
      { "OLDFLEX"   , "20220920-142746/OLDFLEX/2/dcr/HAMA1-chip2"    } ,
      { "OLDNOFLEX" , "20220922-101650/OLDNOFLEX/2a/dcr/HAMA1-chip2" } ,
      { "DUMMY" , "" } 
    } } ,
  { "HAMA2"  , {
      { "OLD"       , "20220607-094413/OLD/1s/dcr/HAMA2-chip3"       } ,
      { "NEW"       , "20220524-170501/NEW/2/dcr/HAMA2-chip3"        } ,
      { "IRR1"      , "20220614-095618/IRR1/2/dcr/HAMA2-chip3"       } ,
      { "ANN1"      , "20220706-092039/ANN1/2/dcr/HAMA2-chip3"       } ,
      { "IRR2"      , "20220726-095315/IRR2/2/dcr/HAMA2-chip3"       } ,
      { "ANN2"      , "20220824-075943/ANN2/2/dcr/HAMA2-chip3"       } ,
      { "ANN2-bis"  , "20221027-155337/ANN2-bis/2/dcr/HAMA2-chip3"   } ,
      { "IRR3"      , "20221115-084654/IRR3/2/dcr/HAMA2-chip3"       } ,
      { "ANN3"      , "20221125-085159/ANN3/2/dcr/HAMA2-chip3"       } ,
      { "IRR4"      , "20221228-080527/IRR4/2/dcr/HAMA2-chip3"       } ,
      { "ANN4"      , "20230110-091540/ANN4/2/dcr/HAMA2-chip3"       } ,      
      { "OLDFLEX"   , "20220920-142746/OLDFLEX/2/dcr/HAMA2-chip3"    } ,
      { "OLDNOFLEX" , "20220922-101650/OLDNOFLEX/2a/dcr/HAMA2-chip3" } ,
      { "DUMMY", "" }
    } } ,
  { "FBKa"   , {
      { "OLD"      , "20220606-141829/OLD/1/dcr/FBK-chip2"      } ,
      { "NEW"      , "20220523-114027/NEW/1/dcr/FBK-chip2"      } ,
      { "IRR1"     , "20220613-125235/IRR1/1/dcr/FBK-chip2"     } ,
      { "ANN1"     , "20220704-213911/ANN1/1/dcr/FBK-chip2"     } ,
      { "IRR2"     , "20220725-112757/IRR2/1/dcr/FBK-chip2"     } ,
      { "ANN2"     , "20220823-080558/ANN2/1/dcr/FBK-chip2"     } ,
      { "ANN2-bis" , "20221028-084708/ANN2-bis/1/dcr/FBK-chip2" } ,
      { "IRR3"     , "20221114-085435/IRR3/1/dcr/FBK-chip2"     } ,
      { "ANN3"     , "20221124-111658/ANN3/1/dcr/FBK-chip2"     } ,
      { "DUMMY"    , "" }
    } } ,
  { "FBKb"   , {
      { "OLD"  , "20220606-141829/OLD/1/dcr/FBK-chip3"     } ,
      { "NEW"  , "20220523-114027/NEW/1/dcr/FBK-chip3"     } ,
      { "IRR1" , "20220613-125235/IRR1/1/dcr/FBK-chip3"    }
    } } ,
  { "FBK"   , {
      { "OLD"  , "20220606-141829/OLD/1/dcr/FBK-chip2 + 20220606-141829/OLD/1/dcr/FBK-chip3" } ,
      { "NEW"  , "20220523-114027/NEW/1/dcr/FBK-chip2 + 20220523-114027/NEW/1/dcr/FBK-chip3" } ,
      { "IRR1" , "20220613-125235/IRR1/1/dcr/FBK-chip2 + 20220613-125235/IRR1/1/dcr/FBK-chip3" }
    } } ,
  { "SENSL"  , {
      { "NEW"      , "20220525-110121/NEW/3/dcr/SENSL-chip2"      } ,
      { "IRR1"     , "20220615-093305/IRR1/3/dcr/SENSL-chip2"     } ,
      { "ANN1"     , "20220707-093050/ANN1/3/dcr/SENSL-chip2"     } ,
      { "IRR2"     , "20220728-095138/IRR2/5/dcr/SENSL-chip2"     } ,
      { "ANN2"     , "20220825-075616/ANN2/3/dcr/SENSL-chip2"     } ,
      { "ANN2-bis" , "20221102-100638/ANN2-bis/3/dcr/SENSL-chip2" } ,
      { "IRR3"     , "20221116-085844/IRR3/3/dcr/SENSL-chip2"     } ,
      { "DUMMY"    , "" }
    } } ,
  { "HAMA1L" , {
      { "NEW"      , "20220525-110121/NEW/3/dcr/HAMA1L-chip3"      } ,
      { "IRR1"     , "20220616-102548/IRR1/3/dcr/HAMA1L-chip3"     } ,
      { "ANN1La"   , "20220622-141014/ANN1La/3L/dcr/HAMA1L-chip3"  } ,
      { "ANN1Lb"   , "20220623-083051/ANN1Lb/3L/dcr/HAMA1L-chip3"  } ,
      { "ANN1"     , "20220713-133607/ANN1/3/dcr/HAMA1L-chip3"     } ,
      { "IRR2"     , "20220727-100404/IRR2/3/dcr/HAMA1L-chip3"     } ,
      { "ANN2"     , "20220825-075616/ANN2/3/dcr/HAMA1L-chip3"     } ,
      { "ANN2-bis" , "20221102-100638/ANN2-bis/3/dcr/HAMA1L-chip3" } ,
      { "IRR3"     , "20221116-085844/IRR3/3/dcr/HAMA1L-chip3"     } ,
      { "ANN3"     , "20221128-083935/ANN3/3/dcr/HAMA1L-chip3"     } ,
      { "IRR4"     , "20221229-091010/IRR4/3/dcr/HAMA1L-chip3"     } ,
      { "ANN4"     , "20230111-091431/ANN4/3/dcr/HAMA1L-chip3"     } ,
      { "DUMMY"    , "" }
    } }
};

std::map<std::string, std::map<std::string, std::string>> dirname_iv = {
  { "HAMA1" , {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama1_S1/MC0" } ,
      { "2021-IRR" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama1_S1/MC1" } ,
      { "2021-ANN" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama1_S1/MC7" } ,
      { "OLD"      , "20220606-141829/OLD/1/iv/HAMA1_sn2_mux1"      } ,
      { "NEW"      , "20220523-114027/NEW/1/iv/HAMA1_sn2_mux1"      } ,
      { "IRR1"     , "20220613-125235/IRR1/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN1"     , "20220704-213911/ANN1/1/iv/HAMA1_sn2_mux1"     } ,
      { "IRR2"     , "20220725-112757/IRR2/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN2"     , "20220823-080558/ANN2/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN2-bis" , "20221028-084708/ANN2-bis/1/iv/HAMA1_sn2_mux1" } ,
      { "IRR3"     , "20221114-085435/IRR3/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN3"     , "20221124-111658/ANN3/1/iv/HAMA1_sn2_mux1"     } ,
      { "IRR4"     , "20221227-081412/IRR4/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN4"     , "20230109-103335/ANN4/1/iv/HAMA1_sn2_mux1"     } ,
      { "ANN4-IVfix" , "20230202-113010/ANN4-IVfix/1/iv/HAMA1_sn2_mux1"     } ,
      { "DUMMY"    , "" } 
    } } ,
  { "HAMA2" , {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama2_S1/MC0" } ,
      { "2021-IRR" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama2_S1/MC1" } ,
      { "2021-ANN" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FERRARA/Hama2_S1/MC7" } ,
      { "OLD"      , "20220606-141829/OLD/1/iv/HAMA2_sn2_mux2"      } ,
      { "NEW"      , "20220523-114027/NEW/1/iv/HAMA2_sn2_mux2"      } ,
      { "IRR1"     , "20220613-125235/IRR1/1/iv/HAMA2_sn2_mux2"     } ,
      { "ANN1"     , "20220704-213911/ANN1/1/iv/HAMA2_sn2_mux2"     } ,
      { "IRR2"     , "20220725-112757/IRR2/1/iv/HAMA2_sn2_mux2"     } ,
      { "ANN2"     , "20220823-080558/ANN2/1/iv/HAMA2_sn2_mux2"     } ,
      { "ANN2-bis" , "20221028-084708/ANN2-bis/1/iv/HAMA2_sn2_mux2" } ,
      { "IRR3"     , "20221114-085435/IRR3/1/iv/HAMA2_sn2_mux2"     } ,
      { "ANN3"     , "20221124-111658/ANN3/1/iv/HAMA2_sn2_mux2"     } ,
      { "IRR4"     , "20221227-081412/IRR4/1/iv/HAMA2_sn2_mux2"     } ,
      { "ANN4"     , "20230109-103335/ANN4/1/iv/HAMA2_sn2_mux2"     } ,
      { "DUMMY"    , "" }
    } } ,
  { "FBKa" ,  {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/sn3/243K" } ,
      { "2021-IRR" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postIrrad/sn3/243K" } ,
      { "2021-ANN" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postAnneal/sn3/243K" } ,
      { "OLD"      , "20220607-094413/OLD/1s/iv/FBK_sn1_mux1"     } ,
      { "NEW"      , "20220525-110121/NEW/3/iv/FBK_sn1_mux1"      } ,
      { "IRR1"     , "20220615-093305/IRR1/3/iv/FBK_sn1_mux1"     } ,
      { "ANN1"     , "20220707-093050/ANN1/3/iv/FBK_sn1_mux1"     } ,
      { "IRR2"     , "20220727-100404/IRR2/3/iv/FBK_sn1_mux1"     } ,
      { "ANN2"     , "20220825-075616/ANN2/3/iv/FBK_sn1_mux1"     } ,
      { "ANN2-bis" , "20221102-100638/ANN2-bis/3/iv/FBK_sn1_mux1" } ,
      { "IRR3"     , "20221116-085844/IRR3/3/iv/FBK_sn1_mux1"     } ,
      { "DUMMY"    , "" }
    } } ,
  { "FBKb" ,  {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/sn4/243K" } ,
      { "2021-IRR" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postIrrad/sn4/243K" } ,
      { "2021-ANN" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postAnneal/sn4/243K" } ,
      { "OLD"  , "20220607-094413/OLD/1s/iv/FBK_sn2_mux2"   } ,
      { "NEW"  , "20220525-110121/NEW/3/iv/FBK_sn2_mux2"    } ,
      { "IRR1" , "20220615-093305/IRR1/3/iv/FBK_sn2_mux2"   }
    } } ,
  { "FBK" ,  {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/sn3/243K + /home/preghenella/EIC/sipm4eic/characterisation/data/FBK/sn4/243K" } ,
      { "2021-IRR" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postIrrad/sn3/243K + /home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postIrrad/sn4/243K" } ,
      { "2021-ANN" , "/home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postAnneal/sn3/243K + /home/preghenella/EIC/sipm4eic/characterisation/data/FBK/postAnneal/sn4/243K" } ,
      { "OLD"  , "20220607-094413/OLD/1s/iv/FBK_sn1_mux1 + 20220607-094413/OLD/1s/iv/FBK_sn2_mux2"   } ,
      { "NEW"  , "20220525-110121/NEW/3/iv/FBK_sn1_mux1 + 20220525-110121/NEW/3/iv/FBK_sn2_mux2"    } ,
      { "IRR1" , "20220615-093305/IRR1/3/iv/FBK_sn1_mux1 + 20220615-093305/IRR1/3/iv/FBK_sn2_mux2"   }
    } } ,
  { "SENSL" , {
      { "NEW"      , "20220524-170501/NEW/2/iv/SENSL_sn1_mux1"      } ,
      { "IRR1"     , "20220614-095618/IRR1/2/iv/SENSL_sn1_mux1"     } ,
      { "ANN1"     , "20220706-092039/ANN1/2/iv/SENSL_sn1_mux1"     } ,
      { "IRR2"     , "20220726-095315/IRR2/2/iv/SENSL_sn1_mux1"     } ,
      { "ANN2"     , "20220824-075943/ANN2/2/iv/SENSL_sn1_mux1"     } ,
      { "ANN2-bis" , "20221027-155337/ANN2-bis/2/iv/SENSL_sn1_mux1" } ,
      { "IRR3"     , "20221115-084654/IRR3/2/iv/SENSL_sn1_mux1"     } ,
      { "ANN3"     , "20221125-085159/ANN3/2/iv/SENSL_sn1_mux1"     } ,
      { "DUMMY"    , "" }
    } } ,
  { "HAMA1L", {
      { "2021-NEW" , "/home/preghenella/EIC/sipm4eic/characterisation/data/HAMA1/sn4/243K" } ,
      { "NEW"      , "20220524-170501/NEW/2/iv/HAMA1_sn4_mux2"      } ,
      { "IRR1"     , "20220614-095618/IRR1/2/iv/HAMA1_sn4_mux2"     } ,
      { "ANN1La"   , "20220622-114429/ANN1La/2L/iv/HAMA1_sn4_mux1"  } ,
      { "ANN1Lb"   , "20220622-195438/ANN1Lb/2L/iv/HAMA1_sn4_mux2"  } ,
      { "ANN1"     , "20220706-092039/ANN1/2/iv/HAMA1_sn4_mux2"     } ,
      { "IRR2"     , "20220726-095315/IRR2/2/iv/HAMA1_sn4_mux2"     } ,
      { "ANN2"     , "20220824-075943/ANN2/2/iv/HAMA1_sn4_mux2"     } ,
      { "ANN2-bis" , "20221027-155337/ANN2-bis/2/iv/HAMA1_sn4_mux2" } ,
      { "IRR3"     , "20221115-084654/IRR3/2/iv/HAMA1_sn4_mux2"     } ,
      { "ANN3"     , "20221125-085159/ANN3/2/iv/HAMA1_sn4_mux2"     } ,
      { "IRR4"     , "20221228-080527/IRR4/2/iv/HAMA1_sn4_mux2"     } ,
      { "ANN4"     , "20230110-091540/ANN4/2/iv/HAMA1_sn4_mux2"     } ,
      { "DUMMY"    , "" }
    } }
};

std::map<std::string, std::string> chip_dcr = {
  { "HAMA1"  , "2" } ,
  { "HAMA2"  , "3" } ,
  { "FBKa"   , "2" } ,
  { "FBKb"   , "3" } ,
  { "FBK"   , "2 + 3" } ,
  { "SENSL"  , "2" } ,
  { "HAMA1L" , "3" }
};

std::map<std::string, std::map<std::string, std::string>> tagname_iv = {
  { "HAMA1"  , {
      { "2021-NEW" , "Hama1_S1" } ,
      { "2021-IRR" , "Hama1_S1" } ,
      { "2021-ANN" , "Hama1_S1" } ,
      { "OLD"      , "HAMA1_sn2" } ,
      { "NEW"      , "HAMA1_sn2" } ,
      { "IRR1"     , "HAMA1_sn2" } ,
      { "ANN1"     , "HAMA1_sn2" } ,
      { "IRR2"     , "HAMA1_sn2" } ,
      { "ANN2"     , "HAMA1_sn2" } ,
      { "ANN2-bis" , "HAMA1_sn2" } ,
      { "IRR3"     , "HAMA1_sn2" } ,
      { "ANN3"     , "HAMA1_sn2" } ,
      { "IRR4"     , "HAMA1_sn2" } ,
      { "ANN4"     , "HAMA1_sn2" } ,
      { "ANN4-IVfix"     , "HAMA1_sn2" } 
    } } ,
  { "HAMA2"  , {
      { "2021-NEW" , "Hama2_S1" } ,
      { "2021-IRR" , "Hama2_S1" } ,
      { "2021-ANN" , "Hama2_S1" } ,
      { "OLD"  , "HAMA2_sn2" } ,
      { "NEW"  , "HAMA2_sn2" } ,
      { "IRR1" , "HAMA2_sn2" } ,
      { "ANN1" , "HAMA2_sn2" } ,
      { "IRR2" , "HAMA2_sn2" } ,
      { "ANN2" , "HAMA2_sn2" } ,
      { "IRR3" , "HAMA2_sn2" } ,
      { "ANN3" , "HAMA2_sn2" } ,
      { "IRR4" , "HAMA2_sn2" } ,
      { "ANN4" , "HAMA2_sn2" }
    } } ,
  { "FBKa"   , {
      { "2021-NEW" , "FBK_sn3" } ,
      { "2021-IRR" , "FBK_sn3" } ,
      { "2021-ANN" , "FBK_sn3" } ,
      { "OLD"      , "FBK_sn1" } ,
      { "NEW"      , "FBK_sn1" } ,
      { "IRR1"     , "FBK_sn1" } ,
      { "ANN1"     , "FBK_sn1" } ,
      { "IRR2"     , "FBK_sn1" } ,      
      { "ANN2"     , "FBK_sn1" } ,
    } } ,
  { "FBKb"   , {
      { "2021-NEW" , "FBK_sn4" } ,
      { "2021-IRR" , "FBK_sn4" } ,
      { "2021-ANN" , "FBK_sn4" } ,
      { "OLD"      , "FBK_sn2" } ,
      { "NEW"      , "FBK_sn2" } ,
      { "IRR1"     , "FBK_sn2" }
    } } ,
  { "FBK"   , {
      { "2021-NEW" , "FBK_sn3 + FBK_sn4" } ,
      { "2021-IRR" , "FBK_sn3 + FBK_sn4" } ,
      { "2021-ANN" , "FBK_sn3 + FBK_sn4" } ,
      { "OLD"      , "FBK_sn1 + FBK_sn2" } ,
      { "NEW"      , "FBK_sn1 + FBK_sn2" } ,
      { "IRR1"     , "FBK_sn1 + FBK_sn2" }
    } } ,
  { "SENSL"  , {
      { "NEW"  , "SENSL_sn1" } ,
      { "IRR1" , "SENSL_sn1" } ,
      { "ANN1" , "SENSL_sn1" } ,
      { "IRR2" , "SENSL_sn1" } ,
      { "ANN2" , "SENSL_sn1" } ,
    } } ,
  { "HAMA1L" , {
      { "2021-NEW" , "HAMA1_sn4" } ,
      { "NEW"      , "HAMA1_sn4" } ,
      { "IRR1"     , "HAMA1_sn4" } ,
      { "ANN1La"   , "HAMA1_sn4" } ,
      { "ANN1Lb"   , "HAMA1_sn4" } ,
      { "ANN1"     , "HAMA1_sn4" } ,
      { "IRR2"     , "HAMA1_sn4" } ,
      { "ANN2"     , "HAMA1_sn4" } ,
      { "ANN2-bis" , "HAMA1_sn4" } ,
      { "IRR3"     , "HAMA1_sn4" } ,
      { "ANN3"     , "HAMA1_sn4" } ,
      { "IRR4"     , "HAMA1_sn4" } ,
      { "ANN4"     , "HAMA1_sn4" } ,
    } }
};

std::map<std::string, std::vector<std::string>> rows = {
  { "ALL"        , {"A", "B", "C", "D", "E", "F", "G", "H"} } ,
  { "13360_3050" , {"A", "C", "E", "G"} },
  { "13360_3025" , {"B", "D", "F", "H"} },
  { "14160_3050" , {"A", "C", "E", "G"} },
  { "14160_3015" , {"B", "D", "F", "H"} },
  { "NUVHD_CHK"  , {"A", "C", "E"}      },
  { "NUVHD_RH"   , {"B", "D", "F"}      },
  { "30020"      , {"A", "C", "E", "G"} },
  { "30035"      , {"B", "D", "F", "H"} }
};

std::map<std::string, std::vector<std::string>> cols = {
  { "ALL"    , {"1", "2", "3", "4"} },
  { "NIEL08" , {"1"}                },
  { "NIEL09" , {"2"}                },
  { "NIEL10" , {"3"}                },
  { "NIEL11" , {"4"}                }
};

std::map<std::string, std::map<std::string, std::vector<std::string>>> outliers_dcr = {
  { "HAMA1" , {
      { "NEW"  , { "B2" } } ,
      { "IRR1" , { "B2" } } ,
      { "ANN1" , { "B2" } } ,
      { "IRR2" , { "B2" } } ,
      { "OLD"  , { } }
    } } ,
  { "HAMA2" , {
      { "NEW"  , { "G4", "F2" } } ,
      { "IRR1" , { "G4", "F2" } } ,
      { "ANN1" , { "G4", "F2" } } ,
      { "IRR2" , { "G4", "F2" } } ,
      { "OLD"  , {} }
    } } ,
  { "FBKa" , {
      { "NEW"  , { "C2", "B1", "B2" } } ,
      { "IRR1" , { "C2", "B1", "B2" } } ,
      { "ANN1" , { "C2", "B1", "B2" } } ,
      { "IRR2" , { "C2", "B1", "B2" } } ,
      { "OLD"  , {} }
    } } ,
  { "FBKb" , {
      { "NEW"  , { "C2", "F3" } } ,
      { "IRR1" , { "C2", "F3" } } ,
      { "OLD"  , {} }
    } } ,
  { "FBK" , {
      { "NEW"  , { "C2", "B1", "B2" , "C2+" , "F3+" } } ,
      { "IRR1" , { "C2", "B1", "B2" , "C2+" , "F3+" } } ,
      { "OLD"  , {} }
    } } ,
  { "SENSL" , {
      { "NEW"  , { /*"A1", "A2",*/ "F1", "F2" } } ,
      { "IRR1" , { /*"A1", "A2",*/ "F1", "F2" } } ,
      { "ANN1" , { /*"A1", "A2",*/ "F1", "F2" } } ,
      { "IRR2" , { /*"A1", "A2",*/ "F1", "F2" } } ,
      { "ANN2" , { /*"A1", "A2",*/ "F1", "F2" } } ,
    } }
};

std::map<std::string, std::map<std::string, std::vector<std::string>>> outliers_iv = {
  { "HAMA1" , {
      { "NEW"  , {} } ,
      { "IRR1"  , {} } ,
      { "ANN1"  , {} } ,
      { "IRR2"  , {} } ,
      { "OLD"  , { "E1" } }
    } } ,
  { "HAMA2" , {
      { "NEW"  , { "F2" } } ,
      { "IRR1" , { "F2" } } ,
      { "ANN1" , { "F2" } } ,
      { "IRR2" , { "F2" } } ,
      { "OLD"  , { "H2", "B4" } }
    } } ,
  { "FBKa" , {
      { "2021-NEW" , { "C2" } } ,
      { "NEW"  , { "B2" } } ,
      { "IRR1" , { "B2" } } ,
      { "ANN1" , { "B2" } } ,
      { "IRR2" , { "B2" } } ,
      { "OLD"  , {} }
    } } ,
  { "FBKb" , {
      { "2021-NEW" , {} } ,
      { "NEW"  , { "F3" } } ,
      { "IRR1" , { "F3" } } ,
      { "ANN1" , { "F3" } } ,
      { "IRR2" , { "F3" } } ,
      { "OLD"  , { "A1", "A2", "A3", "A4" } }
    } } ,
  { "FBK" , {
      { "2021-NEW" , { "C2" } } ,
      { "NEW"  , { "B2" , "F3+" } } ,
      { "IRR1" , { "B2" , "F3+" } } ,
      { "OLD"  , { "A1+", "A2+", "A3+", "A4+" } }
    } } ,
  { "SENSL" , {
      { "NEW"  , { "A1", "F1" } } ,
      { "IRR1" , { "A1", "F1" } } ,
      { "ANN1" , { "A1", "F1" } } ,
      { "IRR2" , { "A1", "F1" } }
    } }
};

std::map<std::string, std::map<std::string, std::vector<std::string>>> outliers_led = {
  { "HAMA1" , {
      { "NEW"  , {} } ,
      { "OLD"  , {} }
    } }
};

std::map<std::string, std::string> producer_label = {
  { "HAMA1"  , "HPK" } ,
  { "HAMA2"  , "HPK" } ,
  { "FBKa"   , "FBK" } ,
  { "FBKb"   , "FBK" } ,
  { "FBK"    , "FBK" } ,
  { "SENSL"  , "SENSL" } ,
  { "HAMA1L" , "HPK" }
};

std::map<std::string, std::string> model_label = {
  { "13360_3050" , "S13360-3050VS" },
  { "13360_3025" , "S13360-3025VS" },
  { "14160_3050" , "S14160-3050HS" },
  { "14160_3015" , "S14160-3015PS" },
  { "NUVHD_CHK"  , "NUV-HD-CHK"    },
  { "NUVHD_RH"   , "NUV-HD-RH"     },
  { "30020"      , "MICROFJ-30020" },
  { "30035"      , "MICROFJ-30035" }
};

 
std::map<std::string, std::pair<float, float>> vrange_dcr = {
  { "HAMA1"  , {46., 62.} } ,
  { "HAMA2"  , {36., 46.} } ,
  { "FBKa"   , {29., 41.} } ,
  { "FBKb"   , {29., 41.} } ,
  { "FBK"    , {29., 41.} } ,
  { "SENSL"  , {22., 34.} } ,
  { "HAMA1L" , {46., 62.} }
};

std::map<std::string, std::pair<float, float>> vrange_led = {
  { "HAMA1"  , {46., 62.} }
};

std::map<std::string, std::pair<float, float>> vrange_iv = {
  { "HAMA1"  , {45., 65.} } ,
  { "HAMA2"  , {33., 47.} } ,
  { "FBKa"   , {27., 46.} } ,
  { "FBKb"   , {27., 46.} } ,
  { "FBK"    , {27., 46.} } ,
  { "SENSL"  , {20., 35.} } ,
  { "HAMA1L" , {45., 65.} }
};

std::map<std::string, std::map<std::string, float>> vcut_iv = {
  { "HAMA1"  , {
      { "13360_3050" , 58.  } ,
      { "13360_3025" , 100. }
    } } ,
  { "HAMA2"  , {
      { "14160_3050" , 45.  } ,
      { "14160_3015" , 46.  }
    } } ,
  { "FBKa"  , {
      { "NUVHD_CHK"  , 38.  } ,
      { "NUVHD_RH"   , 100. }
    } } ,
  { "FBKb"  , {
      { "NUVHD_CHK"  , 38.  } ,
      { "NUVHD_RH"   , 100. }
    } } ,
  { "FBK"   , {
      { "NUVHD_CHK"  , 38.  } ,
      { "NUVHD_RH"   , 100. }
    } } ,
  { "SENSL"  , {
      { "30020"      , 33.  } ,
      { "30035"      , 33.  }
    } } ,
  { "HAMA1L" , {
      { "13360_3050" , 58.  } ,
      { "13360_3025" , 100. }
    } }  
};
    
std::map<std::string, std::map<std::string, float>> vbreak = {
  { "HAMA1"  , {
      { "13360_3050" , 48.3  } ,
      { "13360_3025" , 49.0  }
    } } ,
  { "HAMA2"  , {
      { "14160_3050" , 36.5  } ,
      { "14160_3015" , 36.5  }
    } } ,
  { "FBKa"   , {
      { "NUVHD_CHK"  , 30.5  } ,
      { "NUVHD_RH"   , 30.5  }
    } } ,
  { "FBKb"   , {
      { "NUVHD_CHK"  , 30.5  } ,
      { "NUVHD_RH"   , 30.5  }
    } } ,
  { "FBK"    , {
      { "NUVHD_CHK"  , 30.5  } ,
      { "NUVHD_RH"   , 30.5  }
    } } ,
  { "SENSL"  , {
      { "30020"      , 23.4  } ,
      { "30035"      , 23.4  }
    } } ,
  { "HAMA1L"  , {
      { "13360_3050" , 48.3  } ,
      { "13360_3025" , 49.0  }
    } }
};

  
std::map<std::string, float> vbreak_ini = {
  { "HAMA1"  , 48.3 } ,
  { "HAMA2"  , 36.5 } ,
  { "FBK"    , 30.5 } ,
  { "SENSL"  , 23.4 } ,
  { "HAMA1L" , 48.3 }
};

  
} // namespace definitions
