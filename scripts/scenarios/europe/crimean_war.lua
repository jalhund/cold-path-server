local t = {
  fog_of_war = "standard",
  id = "crimean_war",
  lands = {
    Arles = {
      allies = {},
      capital = "torino",
      color = { 102, 204, 0 },
      enemies = { "Russia", "civ_6", "civ_4" },
      name = "kingdom_of_sardinia",
      pacts = {}
    },
    Bulgars = {
      allies = {},
      capital = "belgium",
      color = { 153, 52, 102 },
      enemies = {},
      name = "belgium",
      pacts = {}
    },
    Byzantium = {
      allies = { "France", "England" },
      capital = "bursa",
      color = { 0, 102, 205 },
      enemies = { "Russia", "civ_6", "civ_4", "civ_7" },
      name = "ottoman",
      pacts = {}
    },
    Cordoba = {
      allies = {},
      capital = "lisboa",
      color = { 114, 159, 37 },
      enemies = {},
      name = "portugal",
      pacts = {}
    },
    Croatia = {
      allies = {},
      capital = "nederland",
      color = { 59, 120, 41 },
      enemies = {},
      name = "netherlands",
      pacts = {}
    },
    Denmark = {
      allies = {},
      capital = "denmark",
      color = { 201, 179, 51, 1 },
      enemies = {},
      name = "danish_realm",
      pacts = {}
    },
    England = {
      allies = { "France", "Byzantium", "civ_5" },
      capital = "london",
      color = { 102, 153, 204 },
      enemies = { "Russia", "civ_6", "civ_4", "civ_7" },
      name = "british_empire",
      pacts = {}
    },
    France = {
      allies = { "England", "Byzantium", "civ_5" },
      capital = "paris",
      color = { 106, 125, 160 },
      enemies = { "Russia", "civ_6", "civ_4", "civ_7" },
      name = "french_empire",
      pacts = {}
    },
    Hungary = {
      allies = {},
      capital = "wien",
      color = { 52, 52, 102 },
      enemies = {},
      name = "austrian_empire",
      pacts = {}
    },
    Leon = {
      allies = {},
      capital = "valladolid",
      color = { 255, 174, 117 },
      enemies = {},
      name = "spanish_empire",
      pacts = {}
    },
    Navarre = {
      allies = {},
      capital = "north_africa_1",
      color = { 41, 7, 120, 1 },
      enemies = {},
      name = "morocco",
      pacts = {}
    },
    Normandy = {
      allies = {},
      capital = "firenze",
      color = { 250, 10, 10 },
      enemies = {},
      name = "tuscany",
      pacts = {}
    },
    Norway = {
      allies = {},
      capital = "luxembourg",
      color = { 12, 0, 230 },
      enemies = {},
      name = "luxembourg",
      pacts = {}
    },
    Pechenegs = {
      allies = {},
      capital = "schweiz",
      color = { 255, 191, 51 },
      enemies = {},
      name = "switzerland",
      pacts = {}
    },
    Poland = {
      allies = {},
      capital = "roma",
      color = { 255, 210, 153 },
      enemies = {},
      name = "papal_states",
      pacts = {}
    },
    Roman = {
      allies = {},
      capital = "kaliningrad",
      color = { 128, 128, 230 },
      enemies = {},
      name = "prussia",
      pacts = {}-- "Russia", "civ_4", "civ_6" }
    },
    Russia = {
      allies = {},
      capital = "piter",
      color = { 230, 76, 0 },
      enemies = { "England", "France", "Byzantium", "Arles", "civ_5" },
      name = "russian_empire",
      pacts = {}-- "Sweden", "Roman" }
    },
    Scotland = {
      allies = {},
      capital = "napoli",
      color = { 40, 75, 160 },
      enemies = {},
      name = "kingdom_of_the_two_sicilies",
      pacts = {}
    },
    Sweden = {
      allies = {},
      capital = "stockholm",
      color = { 51, 82, 128 },
      enemies = {},
      name = "kingdom_of_sweden",
      pacts = {}-- "Russia", "civ_4", "civ_6" }
    },
    Undeveloped_land = {
      allies = {},
      color = { 200, 200, 200 },
      enemies = {},
      name = "undeveloped_land",
      pacts = {}
    },
    Wales = {
      allies = {},
      capital = "munchen",
      color = { 100, 100, 0 },
      enemies = {},
      name = "kingdom_of_bavaria",
      pacts = {}
    },
    civ_0 = {
      allies = {},
      capital = "stuttgart",
      color = { 246, 100, 4 },
      enemies = {},
      name = "wurttemberg",
      pacts = {}
    },
    civ_1 = {
      allies = {},
      color = { 110, 202, 248 },
      enemies = {},
      name = "mecklenburg",
      pacts = {}
    },
    civ_2 = {
      allies = {},
      capital = "frankfurt_am_main",
      color = { 212, 250, 33 },
      enemies = {},
      name = "german_confederation",
      pacts = {}
    },
    civ_3 = {
      allies = {},
      capital = "bremen",
      color = { 19, 254, 164 },
      enemies = {},
      name = "hanover",
      pacts = {}
    },
    civ_4 = {
      allies = {},
      capital = "constanta",
      color = { 166, 195, 25 },
      enemies = { "England", "France", "Byzantium", "Arles", "civ_5" },
      name = "wallachia",
      pacts = {},-- "Sweden", "Roman" },
      vassal = "Russia"
    },
    civ_5 = {
      allies = { "France", "England" },
      capital = "north_africa_3",
      color = { 229, 42, 223 },
      enemies = { "Russia", "civ_6", "civ_4", "civ_7" },
      name = "ottoman_tunisia",
      pacts = {},
      vassal = "Byzantium"
    },
    civ_6 = {
      allies = {},
      capital = "moldova",
      color = { 144, 201, 172 },
      enemies = { "England", "France", "Byzantium", "Arles", "civ_5" },
      name = "moldavia",
      pacts = {},-- "Sweden", "Roman" },
      vassal = "Russia"
    },
    civ_7 = {
      allies = {},
      capital = "kalamata",
      color = { 148, 176, 119 },
      enemies = { "Byzantium", "France", "England", "civ_5" },
      name = "kingdom_of_greece",
      pacts = {}
    }
  },
  map = "europe",
  name = "crimean_war",
  pacts_data = {},
  player_land = "Russia",
  provinces = {
    akhisar = {
      o = "Byzantium"
    },
    albania = {
      o = "Byzantium"
    },
    alesund = {
      o = "Sweden"
    },
    alta = {
      o = "Sweden"
    },
    ambrakia = {
      o = "civ_7"
    },
    amiens = {
      o = "France"
    },
    ancona = {
      o = "Poland"
    },
    ankara = {
      o = "Byzantium"
    },
    antalya = {
      o = "Byzantium"
    },
    arkhangelsk = {
      o = "Russia"
    },
    athens = {
      o = "civ_7"
    },
    badajoz = {
      o = "Leon"
    },
    barcelona = {
      o = "Leon"
    },
    belgium = {
      o = "Bulgars"
    },
    beograd = {
      o = "Hungary"
    },
    bergen = {
      o = "Sweden"
    },
    berlin = {
      o = "Roman"
    },
    besancon = {
      o = "France"
    },
    bialystok = {
      o = "Russia"
    },
    bilbo = {
      o = "Leon"
    },
    bologna = {
      o = "Poland"
    },
    bolu = {
      o = "Byzantium"
    },
    bordeaux = {
      o = "France"
    },
    borlange = {
      o = "Sweden"
    },
    bosna_i_hercegovina = {
      o = "Byzantium"
    },
    bourges = {
      o = "France"
    },
    bratislava = {
      o = "Hungary"
    },
    bremen = {
      o = "civ_3"
    },
    brest = {
      o = "Russia"
    },
    brno = {
      o = "Hungary"
    },
    bryansk = {
      o = "Russia"
    },
    bucuresti = {
      o = "civ_4"
    },
    budapest = {
      o = "Hungary"
    },
    burgas = {
      o = "Byzantium"
    },
    bursa = {
      o = "Byzantium"
    },
    bydgoszcz = {
      o = "Roman"
    },
    caen = {
      o = "France"
    },
    calais = {
      o = "France"
    },
    cheboksary = {
      o = "Russia"
    },
    cherkassy = {
      o = "Russia"
    },
    chernigov = {
      o = "Russia"
    },
    clermont_ferrand = {
      o = "France"
    },
    cluj_napoca = {
      o = "Hungary"
    },
    coimbra = {
      o = "Cordoba"
    },
    constanta = {
      o = "civ_4"
    },
    corum = {
      o = "Byzantium"
    },
    coruna = {
      o = "Leon"
    },
    cosenza = {
      o = "Scotland"
    },
    crete = {
      o = "Byzantium"
    },
    crimea = {
      o = "Russia"
    },
    crna_gora = {
      o = "Byzantium"
    },
    cyprus = {
      o = "Byzantium"
    },
    daugavpils = {
      o = "Russia"
    },
    denizli = {
      o = "Byzantium"
    },
    denmark = {
      o = "Denmark"
    },
    dijon = {
      o = "France"
    },
    dnipro = {
      o = "Russia"
    },
    donetsk = {
      o = "Russia"
    },
    dortmund = {
      o = "Roman"
    },
    eesti = {
      o = "Russia"
    },
    faro = {
      o = "Cordoba"
    },
    firenze = {
      o = "Normandy"
    },
    frankfurt_am_main = {
      o = "civ_2"
    },
    gabrovo = {
      o = "Byzantium"
    },
    gavle = {
      o = "Sweden"
    },
    gdynia = {
      o = "Roman"
    },
    gomel = {
      o = "Russia"
    },
    goteborg = {
      o = "Sweden"
    },
    graz = {
      o = "Hungary"
    },
    grodno = {
      o = "Russia"
    },
    gyor = {
      o = "Hungary"
    },
    halmstad = {
      o = "Sweden"
    },
    hamar = {
      o = "Sweden"
    },
    hamburg = {
      o = "civ_1"
    },
    haskovo = {
      o = "Byzantium"
    },
    helsinki = {
      o = "Russia"
    },
    iceland = {
      o = "Denmark"
    },
    innsbruck = {
      o = "Hungary"
    },
    isparta = {
      o = "Byzantium"
    },
    izmir = {
      o = "Byzantium"
    },
    jonkoping = {
      o = "Sweden"
    },
    kalamata = {
      o = "civ_7"
    },
    kaliningrad = {
      o = "Roman"
    },
    kalmar = {
      o = "Sweden"
    },
    kaluga = {
      o = "Russia"
    },
    karabuk = {
      o = "Byzantium"
    },
    karaman = {
      o = "Byzantium"
    },
    karelia = {
      o = "Russia"
    },
    karlstad = {
      o = "Sweden"
    },
    katrineholm = {
      o = "Sweden"
    },
    kharkiv = {
      o = "Russia"
    },
    kherson = {
      o = "Russia"
    },
    khmelnitsky = {
      o = "Russia"
    },
    kielce = {
      o = "Russia"
    },
    kiev = {
      o = "Russia"
    },
    kirov = {
      o = "Russia"
    },
    klaipeda = {
      o = "Russia"
    },
    komi = {
      o = "Russia"
    },
    konya = {
      o = "Byzantium"
    },
    kosice = {
      o = "Hungary"
    },
    kostroma = {
      o = "Russia"
    },
    kozan = {
      o = "Byzantium"
    },
    krakow = {
      o = "Hungary"
    },
    krasnodar = {
      o = "Russia"
    },
    kristiansand = {
      o = "Sweden"
    },
    kuopio = {
      o = "Russia"
    },
    kursk = {
      o = "Russia"
    },
    la_rochelle = {
      o = "France"
    },
    lasi = {
      o = "civ_6"
    },
    leeds = {
      o = "England"
    },
    limoges = {
      o = "France"
    },
    linkoping = {
      o = "Sweden"
    },
    lipetsk = {
      o = "Russia"
    },
    lisboa = {
      o = "Cordoba"
    },
    london = {
      o = "England"
    },
    lublin = {
      o = "Russia"
    },
    lugansk = {
      o = "Russia"
    },
    lulea = {
      o = "Sweden"
    },
    lutsk = {
      o = "Russia"
    },
    luxembourg = {
      o = "Norway"
    },
    lviv = {
      o = "Hungary"
    },
    lyon = {
      o = "France"
    },
    macedonia = {
      o = "Byzantium"
    },
    madrid = {
      o = "Leon"
    },
    magdeburg = {
      o = "civ_2"
    },
    malmo = {
      o = "Sweden"
    },
    marmaris = {
      o = "Byzantium"
    },
    middle_ireland = {
      o = "England"
    },
    milano = {
      o = "Hungary"
    },
    minsk = {
      o = "Russia"
    },
    mogilev = {
      o = "Russia"
    },
    moldova = {
      o = "civ_6"
    },
    montpellier = {
      o = "France"
    },
    moscow = {
      o = "Russia"
    },
    munchen = {
      o = "Wales"
    },
    murcia = {
      o = "Leon"
    },
    murmansk = {
      o = "Russia"
    },
    nancy = {
      o = "France"
    },
    nantes = {
      o = "France"
    },
    napoli = {
      o = "Scotland"
    },
    nederland = {
      o = "Croatia"
    },
    nenets = {
      o = "Russia"
    },
    nice = {
      o = "France"
    },
    nigde = {
      o = "Byzantium"
    },
    nikolaev = {
      o = "Russia"
    },
    nis = {
      o = "Byzantium"
    },
    nizhny_novgorod = {
      o = "Russia"
    },
    north_africa_1 = {
      o = "Navarre"
    },
    north_africa_2 = {
      o = "France"
    },
    north_africa_3 = {
      o = "civ_5"
    },
    northern_ireland = {
      o = "England"
    },
    nottingham = {
      o = "England"
    },
    novgorod = {
      o = "Russia"
    },
    odessa = {
      o = "Russia"
    },
    olsztyn = {
      o = "Roman"
    },
    orel = {
      o = "Russia"
    },
    oslo = {
      o = "Sweden"
    },
    ostersund = {
      o = "Sweden"
    },
    otta = {
      o = "Sweden"
    },
    oulu = {
      o = "Russia"
    },
    paris = {
      o = "France"
    },
    penza = {
      o = "Russia"
    },
    piter = {
      o = "Russia"
    },
    poltava = {
      o = "Russia"
    },
    porto = {
      o = "Cordoba"
    },
    poznan = {
      o = "Roman"
    },
    praha = {
      o = "Hungary"
    },
    pskov = {
      o = "Russia"
    },
    reims = {
      o = "France"
    },
    rennes = {
      o = "France"
    },
    riga = {
      o = "Russia"
    },
    roma = {
      o = "Poland"
    },
    rostov_on_don = {
      o = "Russia"
    },
    rouen = {
      o = "France"
    },
    rovaniemi = {
      o = "Russia"
    },
    ryazan = {
      o = "Russia"
    },
    samsun = {
      o = "Byzantium"
    },
    saransk = {
      o = "Russia"
    },
    sardegna = {
      o = "Arles"
    },
    schweiz = {
      o = "Pechenegs"
    },
    scotland = {
      o = "England"
    },
    sevilla = {
      o = "Leon"
    },
    sibiu = {
      o = "Hungary"
    },
    sicilia = {
      o = "Scotland"
    },
    sivas = {
      o = "Byzantium"
    },
    slovenija = {
      o = "Hungary"
    },
    smolensk = {
      o = "Russia"
    },
    sofia = {
      o = "Byzantium"
    },
    southern_ireland = {
      o = "England"
    },
    stockholm = {
      o = "Sweden"
    },
    strasbourg = {
      o = "France"
    },
    stuttgart = {
      o = "civ_0"
    },
    sumy = {
      o = "Russia"
    },
    sundsvall = {
      o = "Sweden"
    },
    szczecin = {
      o = "Roman"
    },
    szeged = {
      o = "Hungary"
    },
    tambov = {
      o = "Russia"
    },
    tampere = {
      o = "Russia"
    },
    tekirdag = {
      o = "Byzantium"
    },
    ternopol = {
      o = "Russia"
    },
    thessaloniki = {
      o = "Byzantium"
    },
    timisoara = {
      o = "Hungary"
    },
    torino = {
      o = "Arles"
    },
    toulouse = {
      o = "France"
    },
    trier = {
      o = "Roman"
    },
    trofors = {
      o = "Sweden"
    },
    tromso = {
      o = "Sweden"
    },
    trondheim = {
      o = "Sweden"
    },
    tula = {
      o = "Russia"
    },
    tver = {
      o = "Russia"
    },
    umea = {
      o = "Sweden"
    },
    uzice = {
      o = "Byzantium"
    },
    valencia = {
      o = "Leon"
    },
    valladolid = {
      o = "Leon"
    },
    varna = {
      o = "Byzantium"
    },
    vaxjo = {
      o = "Sweden"
    },
    venezia = {
      o = "Hungary"
    },
    vilnius = {
      o = "Russia"
    },
    vitebsk = {
      o = "Russia"
    },
    vladimir = {
      o = "Russia"
    },
    volgograd = {
      o = "Russia"
    },
    vologda = {
      o = "Russia"
    },
    voronezh = {
      o = "Russia"
    },
    vratsa = {
      o = "Byzantium"
    },
    wales = {
      o = "England"
    },
    warszawa = {
      o = "Russia"
    },
    wien = {
      o = "Hungary"
    },
    wroclaw = {
      o = "Roman"
    },
    yaroslavl = {
      o = "Russia"
    },
    zadar = {
      o = "Hungary"
    },
    zagreb = {
      o = "Hungary"
    },
    zaporozhye = {
      o = "Russia"
    },
    zaragoza = {
      o = "Leon"
    },
    zhitomir = {
      o = "Russia"
    }
  },
  technology_lvl = 12,
  year = 1853
}
return t