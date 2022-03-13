--p - population
--o - own
--a - army
local game_data = {
  id = "anarchy",
  lands = {
     Undeveloped_land = {
      color = { 200, 200, 200 },
      name = "undeveloped_land",
    },
    civ_1 = {
      color = { 125, 228, 53 },
      name = "Region 1"
    },
    civ_10 = {
      color = { 136, 165, 160 },
      name = "Region 10"
    },
    civ_102 = {
      color = { 226, 144, 238 },
      name = "Region 102"
    },
    civ_103 = {
      color = { 7, 105, 238 },
      name = "Region 103"
    },
    civ_104 = {
      color = { 215, 183, 184 },
      name = "Region 104"
    },
    civ_109 = {
      color = { 94, 212, 11 },
      name = "Region 109"
    },
    civ_11 = {
      color = { 43, 68, 206 },
      name = "Region 11"
    },
    civ_112 = {
      color = { 63, 70, 242 },
      name = "Region 112"
    },
    civ_117 = {
      color = { 131, 147, 239 },
      name = "Region 117"
    },
    civ_118 = {
      --capital = "goteborg",
      color = { 60, 155, 3 },
      name = "Region 118"
    },
    civ_12 = {
      --capital = "malmo",
      color = { 29, 157, 199 },
      name = "Region 12"
    },
    civ_120 = {
      --capital = "wroclaw",
      color = { 172, 135, 99 },
      name = "Region 120"
    },
    civ_121 = {
      --capital = "nancy",
      color = { 168, 109, 143 },
      name = "Region 121"
    },
    civ_122 = {
      --capital = "helsinki",
      color = { 212, 140, 159 },
      name = "Region 122"
    },
    civ_125 = {
      --capital = "firenze",
      color = { 77, 194, 140 },
      name = "Region 125"
    },
    civ_127 = {
      --capital = "valencia",
      color = { 25, 241, 30 },
      name = "Region 127"
    },
    civ_128 = {
      --capital = "sundsvall",
      color = { 222, 17, 214 },
      name = "Region 128"
    },
    civ_129 = {
      --capital = "albania",
      color = { 199, 174, 203 },
      name = "Region 129"
    },
    civ_131 = {
      --capital = "vratsa",
      color = { 64, 97, 175 },
      name = "Region 131"
    },
    civ_139 = {
      --capital = "cluj_napoca",
      color = { 34, 62, 182 },
      name = "Region 139"
    },
    civ_14 = {
      --capital = "izmir",
      color = { 224, 189, 27 },
      name = "Region 14"
    },
    civ_140 = {
      --capital = "bucuresti",
      color = { 146, 158, 200 },
      name = "Region 140"
    },
    civ_141 = {
      --capital = "zagreb",
      color = { 83, 63, 106 },
      name = "Region 141"
    },
    civ_145 = {
      --capital = "oslo",
      color = { 187, 83, 130 },
      name = "Region 145"
    },
    civ_146 = {
      --capital = "berlin",
      color = { 21, 98, 172 },
      name = "Region 146"
    },
    civ_149 = {
      --capital = "vilnius",
      color = { 77, 82, 94 },
      name = "Region 149"
    },
    civ_151 = {
      --capital = "venezia",
      color = { 92, 25, 254 },
      name = "Region 151"
    },
    civ_153 = {
      --capital = "thessaloniki",
      color = { 84, 133, 52 },
      name = "Region 153"
    },
    civ_154 = {
      --capital = "southern_ireland",
      color = { 108, 82, 87 },
      name = "Region 154"
    },
    civ_155 = {
      --capital = "kielce",
      color = { 127, 205, 190 },
      name = "Region 155"
    },
    civ_157 = {
      --capital = "zaragoza",
      color = { 99, 105, 93 },
      name = "Region 157"
    },
    civ_158 = {
      --capital = "chernigov",
      color = { 81, 236, 120 },
      name = "Region 158"
    },
    civ_16 = {
      --capital = "kaluga",
      color = { 183, 57, 218 },
      name = "Region 16"
    },
    civ_160 = {
      --capital = "ostersund",
      color = { 80, 139, 10 },
      name = "Region 160"
    },
    civ_163 = {
      --capital = "vladimir",
      color = { 150, 93, 28 },
      name = "Region 163"
    },
    civ_164 = {
      --capital = "katrineholm",
      color = { 130, 84, 141 },
      name = "Region 164"
    },
    civ_169 = {
      --capital = "kozan",
      color = { 57, 135, 246 },
      name = "169"
    },
    civ_17 = {
      --capital = "graz",
      color = { 133, 99, 23 },
      name = "Region 17"
    },
    civ_171 = {
      --capital = "szeged",
      color = { 245, 187, 48 },
      name = "Region 171"
    },
    civ_173 = {
      --capital = "tula",
      color = { 156, 219, 172 },
      name = "Region 173"
    },
    civ_175 = {
      --capital = "north_africa_1",
      color = { 131, 20, 5 },
      name = "Region 175"
    },
    civ_176 = {
      --capital = "krasnodar",
      color = { 7, 184, 82 },
      name = "Region 176"
    },
    civ_179 = {
      --capital = "bilbo",
      color = { 143, 187, 146 },
      name = "Region 179"
    },
    civ_18 = {
      --capital = "sumy",
      color = { 213, 55, 61 },
      name = "Region 18"
    },
    civ_180 = {
      --capital = "murmansk",
      color = { 32, 83, 106 },
      name = "Region 180"
    },
    civ_181 = {
      --capital = "moscow",
      color = { 201, 19, 112 },
      name = "Region 181"
    },
    civ_182 = {
      --capital = "london",
      color = { 215, 46, 248 },
      name = "Region 182"
    },
    civ_183 = {
      --capital = "praha",
      color = { 95, 197, 119 },
      name = "Region 183"
    },
    civ_186 = {
      --capital = "odessa",
      color = { 83, 64, 82 },
      name = "Region 186"
    },
    civ_187 = {
      --capital = "marmaris",
      color = { 62, 148, 67 },
      name = "Region 187"
    },
    civ_19 = {
      --capital = "sivas",
      color = { 48, 51, 79 },
      name = "Region 19"
    },
    civ_190 = {
      --capital = "crimea",
      color = { 231, 102, 58 },
      name = "Region 190"
    },
    civ_193 = {
      --capital = "denmark",
      color = { 215, 236, 58 },
      name = "Region 193"
    },
    civ_195 = {
      --capital = "pskov",
      color = { 137, 146, 170 },
      name = "Region 195"
    },
    civ_196 = {
      --capital = "cherkassy",
      color = { 53, 85, 133 },
      name = "Region 196"
    },
    civ_197 = {
      --capital = "dijon",
      color = { 101, 149, 177 },
      name = "Region 197"
    },
    civ_2 = {
      --capital = "brest",
      color = { 240, 118, 244 },
      name = "Region 2"
    },
    civ_20 = {
      --capital = "lugansk",
      color = { 224, 1, 18 },
      name = "Region 20"
    },
    civ_200 = {
      --capital = "rouen",
      color = { 144, 47, 14 },
      name = "Region 200"
    },
    civ_201 = {
      --capital = "samsun",
      color = { 233, 118, 98 },
      name = "Region 201"
    },
    civ_203 = {
      --capital = "schweiz",
      color = { 146, 95, 182 },
      name = "Region 203"
    },
    civ_204 = {
      --capital = "faro",
      color = { 71, 226, 117 },
      name = "Region 204"
    },
    civ_206 = {
      --capital = "trier",
      color = { 78, 80, 93 },
      name = "Region 206"
    },
    civ_207 = {
      --capital = "vaxjo",
      color = { 174, 203, 79 },
      name = "Region 207"
    },
    civ_209 = {
      --capital = "nederland",
      color = { 3, 30, 172 },
      name = "Region 209"
    },
    civ_21 = {
      --capital = "tampere",
      color = { 49, 99, 4 },
      name = "Region 21"
    },
    civ_212 = {
      --capital = "athens",
      color = { 33, 212, 164 },
      name = "Region 212"
    },
    civ_214 = {
      --capital = "north_africa_3",
      color = { 89, 23, 91 },
      name = "Region 214"
    },
    civ_215 = {
      --capital = "lyon",
      color = { 156, 170, 140 },
      name = "Region 215"
    },
    civ_216 = {
      --capital = "rennes",
      color = { 181, 110, 76 },
      name = "Region 216"
    },
    civ_217 = {
      --capital = "cyprus",
      color = { 42, 245, 131 },
      name = "Region 217"
    },
    civ_22 = {
      --capital = "hamar",
      color = { 90, 158, 151 },
      name = "Region 22"
    },
    civ_224 = {
      --capital = "macedonia",
      color = { 203, 52, 217 },
      name = "Region 224"
    },
    civ_228 = {
      --capital = "kirov",
      color = { 68, 69, 167 },
      name = "Region 228"
    },
    civ_232 = {
      --capital = "bourges",
      color = { 26, 127, 232 },
      name = "Region 232"
    },
    civ_234 = {
      --capital = "kursk",
      color = { 247, 21, 206 },
      name = " Region 234"
    },
    civ_24 = {
      --capital = "vologda",
      color = { 165, 105, 182 },
      name = "Region 24"
    },
    civ_27 = {
      --capital = "stuttgart",
      color = { 107, 202, 20 },
      name = "Region 27"
    },
    civ_29 = {
      --capital = "torino",
      color = { 204, 87, 39 },
      name = "Region 29"
    },
    civ_3 = {
      --capital = "poznan",
      color = { 48, 58, 181 },
      name = "Region 3"
    },
    civ_32 = {
      --capital = "ancona",
      color = { 137, 169, 39 },
      name = "Region 32"
    },
    civ_33 = {
      --capital = "volgograd",
      color = { 245, 126, 26 },
      name = "Region 33"
    },
    civ_35 = {
      --capital = "lisboa",
      color = { 234, 71, 52 },
      name = "Region 35"
    },
    civ_37 = {
      --capital = "dnipro",
      color = { 71, 102, 238 },
      name = "Region 37"
    },
    civ_39 = {
      --capital = "tromso",
      color = { 108, 211, 171 },
      name = "Region 39"
    },
    civ_4 = {
      --capital = "gavle",
      color = { 135, 163, 6 },
      name = "Region 4"
    },
    civ_42 = {
      --capital = "isparta",
      color = { 77, 188, 216 },
      name = "Region 42"
    },
    civ_44 = {
      --capital = "lasi",
      color = { 165, 176, 82 },
      name = "Region 44"
    },
    civ_45 = {
      --capital = "khmelnitsky",
      color = { 169, 226, 22 },
      name = "Region 45"
    },
    civ_49 = {
      --capital = "porto",
      color = { 193, 217, 230 },
      name = "Region 49"
    },
    civ_5 = {
      --capital = "bratislava",
      color = { 248, 144, 176 },
      name = "Region 5"
    },
    civ_50 = {
      --capital = "nizhny_novgorod",
      color = { 154, 231, 84 },
      name = "Region 50"
    },
    civ_51 = {
      --capital = "leeds",
      color = { 234, 145, 234 },
      name = "Region 51"
    },
    civ_52 = {
      --capital = "zhitomir",
      color = { 217, 236, 18 },
      name = "Region 52"
    },
    civ_55 = {
      --capital = "tambov",
      color = { 146, 78, 11 },
      name = "Region 55"
    },
    civ_58 = {
      --capital = "antalya",
      color = { 252, 63, 172 },
      name = "Region 58"
    },
    civ_59 = {
      --capital = "bryansk",
      color = { 53, 107, 16 },
      name = "Region 59"
    },
    civ_60 = {
      --capital = "gyor",
      color = { 150, 85, 170 },
      name = "Region 60"
    },
    civ_61 = {
      --capital = "nantes",
      color = { 220, 105, 163 },
      name = "Region 61"
    },
    civ_66 = {
      --capital = "cosenza",
      color = { 175, 236, 209 },
      name = "Region 66"
    },
    civ_69 = {
      --capital = "lutsk",
      color = { 26, 167, 240 },
      name = "Region 69"
    },
    civ_7 = {
      --capital = "amiens",
      color = { 177, 190, 31 },
      name = "Region 7"
    },
    civ_70 = {
      --capital = "daugavpils",
      color = { 51, 194, 130 },
      name = "Region 70"
    },
    civ_71 = {
      --capital = "saransk",
      color = { 16, 55, 47 },
      name = "Region 71"
    },
    civ_72 = {
      --capital = "novgorod",
      color = { 239, 109, 17 },
      name = "Region 72"
    },
    civ_74 = {
      --capital = "gdynia",
      color = { 233, 194, 221 },
      name = "Region 74"
    },
    civ_75 = {
      --capital = "minsk",
      color = { 171, 50, 116 },
      name = "Region 75"
    },
    civ_81 = {
      --capital = "bremen",
      color = { 102, 63, 122 },
      name = "Region 81"
    },
    civ_82 = {
      --capital = "kalmar",
      color = { 92, 201, 101 },
      name = "Region 82"
    },
    civ_84 = {
      --capital = "umea",
      color = { 217, 104, 128 },
      name = "Region 84"
    },
    civ_85 = {
      --capital = "valladolid",
      color = { 56, 182, 200 },
      name = "Region 85"
    },
    civ_87 = {
      --capital = "belgium",
      color = { 113, 43, 159 },
      name = "Region 87"
    },
    civ_88 = {
      --capital = "tekirdag",
      color = { 22, 148, 212 },
      name = "Region 88"
    },
    civ_89 = {
      --capital = "montpellier",
      color = { 50, 74, 78 },
      name = "Region 89"
    },
    civ_93 = {
      --capital = "slovenija",
      color = { 223, 110, 224 },
      name = "Region 93"
    },
    civ_97 = {
      --capital = "northern_ireland",
      color = { 246, 15, 33 },
      name = "Region 97"
    },
    civ_99 = {
      --capital = "iceland",
      color = { 28, 30, 39 },
      name = "Region 99"
    }
  },
  map = "europe",
  name = "Анархия",
  player_land = "England",
  provinces = {
    akhisar = {
      o = "civ_187"
    },
    albania = {
      o = "civ_129"
    },
    alesund = {
      o = "civ_1"
    },
    alta = {
      o = "civ_39"
    },
    ambrakia = {
      o = "civ_212"
    },
    amiens = {
      o = "civ_7"
    },
    ancona = {
      o = "civ_32"
    },
    ankara = {
      o = "civ_42"
    },
    antalya = {
      o = "civ_58"
    },
    arkhangelsk = {
      o = "civ_24"
    },
    athens = {
      o = "civ_212"
    },
    badajoz = {
      o = "civ_35"
    },
    barcelona = {
      o = "civ_157"
    },
    belgium = {
      o = "civ_87"
    },
    beograd = {
      o = "civ_171"
    },
    bergen = {
      o = "civ_1"
    },
    berlin = {
      o = "civ_146"
    },
    besancon = {
      o = "civ_197"
    },
    bialystok = {
      o = "civ_117"
    },
    bilbo = {
      o = "civ_179"
    },
    bologna = {
      o = "civ_151"
    },
    bolu = {
      o = "civ_11"
    },
    bordeaux = {
      o = "civ_104"
    },
    borlange = {
      o = "civ_4"
    },
    bosna_i_hercegovina = {
      o = "civ_141"
    },
    bourges = {
      o = "civ_232"
    },
    bratislava = {
      o = "civ_5"
    },
    bremen = {
      o = "civ_81"
    },
    brest = {
      o = "civ_69"
    },
    brno = {
      o = "civ_183"
    },
    bryansk = {
      o = "civ_59"
    },
    bucuresti = {
      o = "civ_131"
    },
    budapest = {
      o = "civ_60"
    },
    burgas = {
      o = "civ_88"
    },
    bursa = {
      o = "civ_14"
    },
    bydgoszcz = {
      o = "civ_3"
    },
    caen = {
      o = "civ_216"
    },
    calais = {
      o = "civ_182"
    },
    cheboksary = {
      o = "civ_50"
    },
    cherkassy = {
      o = "civ_196"
    },
    chernigov = {
      o = "civ_158"
    },
    clermont_ferrand = {
      o = "civ_215"
    },
    cluj_napoca = {
      o = "civ_139"
    },
    coimbra = {
      o = "civ_49"
    },
    constanta = {
      o = "civ_44"
    },
    corum = {
      o = "civ_201"
    },
    coruna = {
      o = "civ_179"
    },
    cosenza = {
      o = "civ_66"
    },
    crete = {
      o = "civ_103"
    },
    crimea = {
      o = "civ_190"
    },
    crna_gora = {
      o = "civ_129"
    },
    cyprus = {
      o = "civ_217"
    },
    daugavpils = {
      o = "civ_70"
    },
    denizli = {
      o = "civ_58"
    },
    denmark = {
      o = "civ_193"
    },
    dijon = {
      o = "civ_197"
    },
    dnipro = {
      o = "civ_37"
    },
    donetsk = {
      o = "civ_20"
    },
    dortmund = {
      o = "civ_209"
    },
    eesti = {
      o = "civ_195"
    },
    faro = {
      o = "civ_204"
    },
    firenze = {
      o = "civ_125"
    },
    frankfurt_am_main = {
      o = "civ_206"
    },
    gabrovo = {
      o = "civ_112"
    },
    gavle = {
      o = "civ_4"
    },
    gdynia = {
      o = "civ_74"
    },
    gomel = {
      o = "civ_158"
    },
    goteborg = {
      o = "civ_118"
    },
    graz = {
      o = "civ_17"
    },
    grodno = {
      o = "civ_2"
    },
    gyor = {
      o = "civ_60"
    },
    halmstad = {
      o = "civ_12"
    },
    hamar = {
      o = "civ_22"
    },
    hamburg = {
      o = "civ_193"
    },
    haskovo = {
      o = "civ_153"
    },
    helsinki = {
      o = "civ_122"
    },
    iceland = {
      o = "civ_99"
    },
    innsbruck = {
      o = "civ_203"
    },
    isparta = {
      o = "civ_42"
    },
    izmir = {
      o = "civ_14"
    },
    jonkoping = {
      o = "civ_207"
    },
    kalamata = {
      o = "civ_103"
    },
    kaliningrad = {
      o = "civ_149"
    },
    kalmar = {
      o = "civ_82"
    },
    kaluga = {
      o = "civ_16"
    },
    karabuk = {
      o = "civ_11"
    },
    karaman = {
      o = "civ_217"
    },
    karelia = {
      o = "civ_180"
    },
    karlstad = {
      o = "civ_118"
    },
    katrineholm = {
      o = "civ_164"
    },
    kharkiv = {
      o = "civ_234"
    },
    kherson = {
      o = "civ_190"
    },
    khmelnitsky = {
      o = "civ_45"
    },
    kielce = {
      o = "civ_155"
    },
    kiev = {
      o = "civ_52"
    },
    kirov = {
      o = "civ_228"
    },
    klaipeda = {
      o = "civ_149"
    },
    komi = {
      o = "civ_228"
    },
    konya = {
      o = "civ_19"
    },
    kosice = {
      o = "civ_5"
    },
    kostroma = {
      o = "civ_10"
    },
    kozan = {
      o = "civ_169"
    },
    krakow = {
      o = "civ_120"
    },
    krasnodar = {
      o = "civ_176"
    },
    kristiansand = {
      o = "civ_145"
    },
    kuopio = {
      o = "civ_21"
    },
    kursk = {
      o = "civ_234"
    },
    la_rochelle = {
      o = "civ_61"
    },
    lasi = {
      o = "civ_44"
    },
    leeds = {
      o = "civ_51"
    },
    limoges = {
      o = "civ_232"
    },
    linkoping = {
      o = "civ_82"
    },
    lipetsk = {
      o = "civ_55"
    },
    lisboa = {
      o = "civ_35"
    },
    london = {
      o = "civ_182"
    },
    lublin = {
      o = "civ_155"
    },
    lugansk = {
      o = "civ_20"
    },
    lulea = {
      o = "civ_84"
    },
    lutsk = {
      o = "civ_69"
    },
    luxembourg = {
      o = "civ_87"
    },
    lviv = {
      o = "civ_139"
    },
    lyon = {
      o = "civ_215"
    },
    macedonia = {
      o = "civ_224"
    },
    madrid = {
      o = "civ_85"
    },
    magdeburg = {
      o = "civ_81"
    },
    malmo = {
      o = "civ_12"
    },
    marmaris = {
      o = "civ_187"
    },
    middle_ireland = {
      o = "civ_97"
    },
    milano = {
      o = "civ_29"
    },
    minsk = {
      o = "civ_75"
    },
    mogilev = {
      o = "civ_59"
    },
    moldova = {
      o = "civ_186"
    },
    montpellier = {
      o = "civ_89"
    },
    moscow = {
      o = "civ_181"
    },
    munchen = {
      o = "civ_27"
    },
    murcia = {
      o = "civ_127"
    },
    murmansk = {
      o = "civ_180"
    },
    nancy = {
      o = "civ_121"
    },
    nantes = {
      o = "civ_61"
    },
    napoli = {
      o = "civ_32"
    },
    nederland = {
      o = "civ_209"
    },
    nenets = {
      o = "civ_24"
    },
    nice = {
      o = "civ_89"
    },
    nigde = {
      o = "civ_19"
    },
    nikolaev = {
      o = "civ_196"
    },
    nis = {
      o = "civ_109"
    },
    nizhny_novgorod = {
      o = "civ_50"
    },
    north_africa_1 = {
      o = "civ_175"
    },
    north_africa_2 = {
      o = "civ_175"
    },
    north_africa_3 = {
      o = "civ_214"
    },
    northern_ireland = {
      o = "civ_97"
    },
    nottingham = {
      o = "civ_51"
    },
    novgorod = {
      o = "civ_72"
    },
    odessa = {
      o = "civ_186"
    },
    olsztyn = {
      o = "civ_74"
    },
    orel = {
      o = "civ_173"
    },
    oslo = {
      o = "civ_145"
    },
    ostersund = {
      o = "civ_128"
    },
    otta = {
      o = "civ_22"
    },
    oulu = {
      o = "civ_102"
    },
    paris = {
      o = "civ_200"
    },
    penza = {
      o = "civ_71"
    },
    piter = {
      o = "civ_122"
    },
    poltava = {
      o = "civ_18"
    },
    porto = {
      o = "civ_49"
    },
    poznan = {
      o = "civ_3"
    },
    praha = {
      o = "civ_183"
    },
    pskov = {
      o = "civ_195"
    },
    reims = {
      o = "civ_7"
    },
    rennes = {
      o = "civ_216"
    },
    riga = {
      o = "civ_70"
    },
    roma = {
      o = "civ_125"
    },
    rostov_on_don = {
      o = "civ_176"
    },
    rouen = {
      o = "civ_200"
    },
    rovaniemi = {
      o = "civ_102"
    },
    ryazan = {
      o = "civ_181"
    },
    samsun = {
      o = "civ_201"
    },
    saransk = {
      o = "civ_71"
    },
    sardegna = {
      o = "civ_214"
    },
    schweiz = {
      o = "civ_203"
    },
    scotland = {
      o = "civ_99"
    },
    sevilla = {
      o = "civ_204"
    },
    sibiu = {
      o = "civ_140"
    },
    sicilia = {
      o = "civ_66"
    },
    sivas = {
      o = "civ_169"
    },
    slovenija = {
      o = "civ_93"
    },
    smolensk = {
      o = "civ_16"
    },
    sofia = {
      o = "civ_224"
    },
    southern_ireland = {
      o = "civ_154"
    },
    stockholm = {
      o = "civ_164"
    },
    strasbourg = {
      o = "civ_121"
    },
    stuttgart = {
      o = "civ_27"
    },
    sumy = {
      o = "civ_18"
    },
    sundsvall = {
      o = "civ_128"
    },
    szczecin = {
      o = "civ_146"
    },
    szeged = {
      o = "civ_171"
    },
    tambov = {
      o = "civ_55"
    },
    tampere = {
      o = "civ_21"
    },
    tekirdag = {
      o = "civ_88"
    },
    ternopol = {
      o = "civ_45"
    },
    thessaloniki = {
      o = "civ_153"
    },
    timisoara = {
      o = "civ_140"
    },
    torino = {
      o = "civ_29"
    },
    toulouse = {
      o = "civ_104"
    },
    trier = {
      o = "civ_206"
    },
    trofors = {
      o = "civ_160"
    },
    tromso = {
      o = "civ_39"
    },
    trondheim = {
      o = "civ_160"
    },
    tula = {
      o = "civ_173"
    },
    tver = {
      o = "civ_72"
    },
    umea = {
      o = "civ_84"
    },
    uzice = {
      o = "civ_109"
    },
    valencia = {
      o = "civ_127"
    },
    valladolid = {
      o = "civ_85"
    },
    varna = {
      o = "civ_112"
    },
    vaxjo = {
      o = "civ_207"
    },
    venezia = {
      o = "civ_151"
    },
    vilnius = {
      o = "civ_2"
    },
    vitebsk = {
      o = "civ_75"
    },
    vladimir = {
      o = "civ_163"
    },
    volgograd = {
      o = "civ_33"
    },
    vologda = {
      o = "civ_10"
    },
    voronezh = {
      o = "civ_33"
    },
    vratsa = {
      o = "civ_131"
    },
    wales = {
      o = "civ_154"
    },
    warszawa = {
      o = "civ_117"
    },
    wien = {
      o = "civ_17"
    },
    wroclaw = {
      o = "civ_120"
    },
    yaroslavl = {
      o = "civ_163"
    },
    zadar = {
      o = "civ_93"
    },
    zagreb = {
      o = "civ_141"
    },
    zaporozhye = {
      o = "civ_37"
    },
    zaragoza = {
      o = "civ_157"
    },
    zhitomir = {
      o = "civ_52"
    }
  },
  technology_lvl = 16,
  year = 0
}
return game_data