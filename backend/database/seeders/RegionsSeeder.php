<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Region;
use App\Models\Presbytery;
use App\Models\Parish;

class RegionsSeeder extends Seeder
{
    public function run(): void
    {
        $regions = [
            [
                "region_name" => "CENTRAL REGION",
                "presbyteries" => [
                    ["presbytery_name" => "GATUNDU PRESBYTERY","parishes" => ["PCEA Icaciri Parish","PCEA Gatundu Parish","PCEA Mang'u Parish","PCEA Gitwe Parish","PCEA Ndarugu Parish","PCEA Githaruru Parish","PCEA Chania Parish"]],
                    ["presbytery_name" => "GITHUNGURI PRESBYTERY","parishes" => ["PCEA Githunguri Parish","PCEA Gathangari Parish","PCEA Kahunira Parish","PCEA Githiga Parish","PCEA Karuthi Parish","PCEA Gathaithi Parish","PCEA Kagaa Parish","PCEA Kamburu Parish","PCEA Gathanji Parish","PCEA Riara Ridge Parish"]],
                    ["presbytery_name" => "KAMBUI PRESBYTERY","parishes" => ["PCEA Kambui Parish","PCEA Kanjai Parish","PCEA Kiambururu Parish","PCEA Nyaga Parish"]],
                    ["presbytery_name" => "RUIRU PRESBYTERY","parishes" => ["PCEA Murera Parish","PCEA Magumano Parish","PCEA Ebenezer Parish","PCEA Ruiru East Parish","PCEA Kamiti Ridge Parish","PCEA Ruiru Town Parish","PCEA Ruiru Northlands Parish","PCEA Membley Parish","PCEA Ridges Parish","PCEA Theta parish"]],
                    ["presbytery_name" => "KIAMATHARE PRESBYTERY","parishes" => ["PCEA Kiamathare Parish","PCEA Ngemwa Parish","PCEA Gachoire Parish","PCEA Karatina Parish-Kiamathare","PCEA Kamuchege Parish","PCEA Ting'ang'a Parish","PCEA Karia Parish"]],
                    ["presbytery_name" => "KIAMBU PRESBYTERY","parishes" => ["PCEA Kiambu Parish","PCEA Thindigua Parish","PCEA Banana Parish","PCEA kirigiti parish","PCEA Kitui Parish"]],
                    ["presbytery_name" => "KIHUMBUINI PRESBYTERY","parishes" => ["PCEA Kihumbuini Parish","PCEA Ruchu East Parish","PCEA Kandara Parish","PCEA Nguthuru Parish","PCEA Ruchu West Parish","PCEA Kiunyu Parish"]],
                    ["presbytery_name" => "KIKUYU PRESBYTERY","parishes" => ["PCEA Njumbi Parish","PCEA Mai-a-ihii Parish","PCEA Musa Gitau Parish","PCEA Thogoto Parish","PCEA Kamangu parish","PCEA Gikambura parish"]],
                    ["presbytery_name" => "KOMOTHAI PRESBYTERY","parishes" => ["PCEA Komothai Parish","PCEA Kiratina Parish","PCEA Gathugu Parish","PCEA Kibichoi Parish"]],
                    ["presbytery_name" => "LIMURU PRESBYTERY","parishes" => ["PCEA Limuru Parish","PCEA Narok Parish","PCEA Mirithu Parish","PCEA THIGIO Parish","PCEA Githunguchu Parish","PCEA Rironi Parish","PCEA Joshua Matenjwa Parish"]],
                    ["presbytery_name" => "LARI PRESBYTERY","parishes" => ["PCEA Ngarariga Parish","PCEA Lari Parish","PCEA Uplands Parish"]],
                    ["presbytery_name" => "NGECHA PRESBYTERY","parishes" => ["PCEA Ngecha Parish","PCEA Kahuho Parish","PCEA Nyathuna Parish","PCEA Kabuku Parish","PCEA RedHill Parish"]],
                    ["presbytery_name" => "MUGUGA PRESBYTERY","parishes" => ["PCEA Muguga Parish","PCEA Sigona Parish","PCEA Nderi Parish","PCEA Kerwa Parish","PCEA Thamanda Parish","PCEA Mai Mahiu outreach"]],
                    ["presbytery_name" => "MURANG'A PRESBYTERY","parishes" => ["PCEA Kamahuha Parish","PCEA Kandani Parish","PCEA Murang'a Parish","PCEA Muthithi Parish","PCEA Nginda Parish","PCEA Kaharati Parish","PCEA Makuyu Parish","PCEA Kangema Parish","PCEA Ithanga Nendeni Area"]]
                ]
            ],
            [
                "region_name" => "EASTERN REGION",
                "presbyteries" => [
                    ["presbytery_name" => "CHOGORIA CENTRAL PRESBYTERY","parishes" => ["PCEA Mugumango East Parish","PCEA Mugumango Central Parish","PCEA Igwanjau parish","PCEA Mwangaza parish","PCEA Mugumango West Parish","PCEA Tharaka Nendeni Area"]],
                    ["presbytery_name" => "CHOGORIA WEST PRESBYTERY","parishes" => ["PCEA Murugi West Parish","PCEA Murugi Central Parish","PCEA Murugi East Parish","PCEA Kiriaini Parish"]],
                    ["presbytery_name" => "CHOGORIA NORTH PRESBYTERY","parishes" => ["PCEA Chogoria Central Parish","PCEA St. John Kimuchia Parish","PCEA Chogoria Hills Parish","PCEA Ebenezer Parish -Chogoria","PCEA Chogoria East Parish","PCEA Kiera Hill Parish","PCEA Mugero Parish","PCEA Kiroo Parish"]],
                    ["presbytery_name" => "CHOGORIA SOUTH PRESBYTERY","parishes" => ["PCEA Gatua Parish","PCEA Igamurathi Parish","PCEA Iriga Parish","PCEA Itara Parish","PCEA Kamwangu Nendeni Area"]],
                    ["presbytery_name" => "CHUKA PRESBYTERY","parishes" => ["PCEA Chuka Town Parish","PCEA Ndagani Parish","PCEA Kirege Parish","PCEA Kiereni Parish","PCEA Kambandi Parish","PCEA Kiang'ondu Parish","PCEA Kanwa Nendeni Area","PCEA Kithangani Nendeni Area"]],
                    ["presbytery_name" => "IMENTI CENTRAL PRESBYTERY","parishes" => ["PCEA Ngirine Parish","PCEA Kanyakine Parish","PCEA Yururu Parish","PCEA Kirendene Parish"]],
                    ["presbytery_name" => "IMENTI NORTH PRESBYTERY","parishes" => ["PCEA Meru Township Parish","PCEA Kithino Parish","PCEA Igoki South Parish","PCEA Igoki North Parish","PCEA Maua Parish","PCEA Meru West Parish","PCEA Nkubu Parish","PCEA Kithurine N/A","PCEA Giaki Outreach","PCEA Gaitu N/A"]],
                    ["presbytery_name" => "IMENTI SOUTH PRESBYTERY","parishes" => ["PCEA Kinoro Parish","PCEA Kianjogu Parish","PCEA Gikurune Parish","PCEA Gatuntune Parish","PCEA Kiangua Parish","PCEA Mikinduri N/A"]],
                    ["presbytery_name" => "MAGUMONI PRESBYTERY","parishes" => ["PCEA Magumoni Parish","PCEA Thuita Parish","PCEA Mukuuni Parish","PCEA Ibiriga Parish","PCEA Rubate Parish","PCEA Ikuu Parish","PCEA Kamwimbi Parish"]]
                ]
            ],
            [
                "region_name" => "MT.KENYA REGION",
                "presbyteries" => [
                    ["presbytery_name" => "KIENI WEST PRESBYTERY","parishes" => ["PCEA Muiga Parish","PCEA Endarasha Parish","PCEA Charity Parish","PCEA Mwiyogo Parish","PCEA Gataragwa Parish","PCEA Kariminu Parish","PCEA Mugunda Parish","PCEA Wiyumiririe Parish","PCEA Ngarengiro Outreach"]],
                    ["presbytery_name" => "KIGANJO PRESBYTERY","parishes" => ["PCEA Kiganjo Parish","PCEA Munyu Parish","PCEA Ngorano Parish","PCEA Kimahuri Parish","PCEA Ebenezer Parish","PCEA Kimanjo N/A"]],
                    ["presbytery_name" => "KIRIMARA EAST PRESBYTERY","parishes" => ["PCEA Kerugoya Parish","PCEA Embu east parish","PCEA Embu west parish","PCEA Kiangai Parish","PCEA Kibirigwi Parish","PCEA Mwea Parish","PCEA Kagio Parish","PCEA Kagumo Parish-Krm East","PCEA Mukangu Parish","PCEA Kiriari Nendeni Area","PCEA Runyenjes Nendeni Area","PCEA Siakago Nendeni Area"]],
                    ["presbytery_name" => "KIRIMARA WEST PRESBYTERY","parishes" => ["PCEA Karatina Parish- Krm West","PCEA Kiamwangi Parish","PCEA Ruguru Parish","PCEA Gikororo Parish","PCEA Giakagina Parish","PCEA Gathaithi Parish-Kirimara West","PCEA Gatondo Parish","PCEA Magutu Parish","PCEA Karindundu Parish","PCEA Muthea Parish","PCEA Nyangeni Nendeni Area"]],
                    ["presbytery_name" => "MUKURWE-INI PRESBYTERY","parishes" => ["PCEA Muhito Parish","PCEA Ndia-ini Parish","PCEA Tambaya Parish","PCEA Muyu Parish","PCEA Mihuti Parish","PCEA Giathugu PARISH","PCEA Kaharo Parish","PCEA Ngamwa Parish","PCEA Karundu Parish"]],
                    ["presbytery_name" => "NANYUKI PRESBYTERY","parishes" => ["PCEA Nanyuki Parish","PCEA Ragati Parish","PCEA Naro-moru Parish","PCEA Timau Parish","PCEA Waguthiru Parish","PCEA Kiamathaga Parish","PCEA Githima Parish-Nanyuki","PCEA Isiolo Nendeni Area"]],
                    ["presbytery_name" => "NYERI PRESBYTERY","parishes" => ["PCEA King'ong'o Parish","PCEA Muringato Parish","PCEA Nyamachaki Parish","PCEA St. Cuthbert Parish","PCEA Nyeri Joy Parish","PCEA Riamukurwe Parish","PCEA Gura Parish","PCEA Kagumo Parish","PCEA Gaaki Parish","PCEA Wandumbi Parish","PCEA Giakanja Parish","PCEA Ihithe Parish","PCEA Thegenge Parish","PCEA Ruring'u Parish","PCEA Nkondi Nendeni Area"]],
                    ["presbytery_name" => "NYERI HILL PRESBYTERY","parishes" => ["PCEA Kimathi Parish","PCEA Ihururu Parish","PCEA Tetu Parish","PCEA Huho-ini Parish","PCEA Thatha Parish"]],
                    ["presbytery_name" => "OTHAYA PRESBYTERY","parishes" => ["PCEA Othaya Town Parish","PCEA Mahiga Parish","PCEA Munyange Parish","PCEA Karima Parish","PCEA Iriaini Parish-Othaya","PCEA Kiaguthu Parish","PCEA Chinga Parish","PCEA Mathioya Parish","PCEA KANGEMA NENDENI AREA"]],
                    ["presbytery_name" => "TUMUTUMU PRESBYTERY","parishes" => ["PCEA Mathaithi Parish","PCEA Tumutumu Parish","PCEA Rititi Parish","PCEA Ngaini Parish","PCEA Icuga Parish","PCEA Tumutumu West Parish","PCEA Marsabit Nendeni Area"]]
                ]
            ],
            [
                "region_name" => "NAIROBI REGION",
                "presbyteries" => [
                    ["presbytery_name" => "KAJIADO PRESBYTERY","parishes" => ["PCEA Eserian Parish","PCEA Kitengela Parish","PCEA Mbagathi Parish","PCEA Baraka Parish","PCEA Kajiado Parish","PCEA Ololoitikosh Parish","PCEA Olooseos Parish","PCEA OLoitoktok Parish","PCEA Magadi Nendeni Area","PCEA Ol-Lodokilani N/A"]],
                    ["presbytery_name" => "MILIMANI NORTH PRESBYTERY","parishes" => ["PCEA St. Andrews Parish","PCEA Loresho Parish","PCEA Evergreen Parish","PCEA Kangemi Parish","PCEA Kibera Parish","PCEA Kawangware Parish","PCEA NYARI PARISH","PCEA Mashuru Nendeni Area"]],
                    ["presbytery_name" => "MILIMANI SOUTH PRESBYTERY","parishes" => ["PCEA Nairobi West Parish","PCEA Lang'ata Parish","PCEA Karen Central Parish","PCEA Karen West Parish","PCEA Riruta Parish","PCEA Waithaka Parish","PCEA Dagoretti Parish","PCEA Mutuini Parish","PCEA Namanga Nendeni Area"]],
                    ["presbytery_name" => "NAIROBI CENTRAL PRESBYTERY","parishes" => ["PCEA Bahati Matyrs Parish","PCEA Makadara Parish","PCEA Eastleigh Parish","PCEA Pangani parish","PCEA Buruburu Parish","PCEA Neema Parish","PCEA Athi River Parish","PCEA Kibwezi Parish","PCEA Machakos Outreach"]],
                    ["presbytery_name" => "NEW NAIROBI EAST PRESBYTERY","parishes" => ["PCEA Ruai Central Parish","PCEA Embakasi Parish","PCEA Tumaini Parish","PCEA Ruai South Parish","Pcea Njiru Parish","PCEA Ruai East Parish","New Nairobi East presbytery Instituions"]],
                    ["presbytery_name" => "NAIROBI SOUTH PRESBYTERY","parishes" => ["PCEA Kariobangi South Parish","PCEA Kayole Parish","PCEA Umoja Parish","PCEA Sosian Parish","PCEA Unity Parish","PCEA Tena Parish","PCEA Dandora Parish","PCEA Kangundo Parish"]],
                    ["presbytery_name" => "NAIROBI NORTH PRESBYTERY","parishes" => ["PCEA Kahawa Farmers Parish","PCEA Sukari Parish","PCEA Kasarani east parish","PCEA Kasarani west Parish","PCEA Kasarani central Parish","PCEA Gateway Parish","PCEA Zimmerman Parish","PCEA Thome Parish","PCEA Ruaraka Parish","PCEA Kimbo Parish","PCEA Mwihoko Parish","PCEA WendaniParish","PCEA Mukinyi Parish","PCEA Githurai Parish","PCEA Kahawa West Parish","PCEA Kahawa Station Parish","PCEA Berea Parish","PCEA Mbooni Nendeni Area"]],
                    ["presbytery_name" => "NGONG HILLS PRESBYTERY","parishes" => ["PCEA Oloolaiser Parish","PCEA Kiserian Parish","PCEA Kibiko Parish","PCEA Kerarapon Parish","PCEA Intashat Parish","PCEA Ngong Parish","PCEA Ewuaso Kedong N/A"]],
                    ["presbytery_name" => "PWANI KATI PRESBYTERY","parishes" => ["PCEA South Coast Parish","PCEA St. Margaret Parish","PCEA Kisauni Parish","PCEA BAMBURI PARISH","Sagalla Outreach"]],
                    ["presbytery_name" => "PWANI MAGHARIBI PRESBYTERY","parishes" => ["PCEA West Coast Parish","PCEA Voi Parish","PCEA Makupa Parish","PCEA Jomvu Parish","Taveta Outreach"]],
                    ["presbytery_name" => "PWANI KASKAZINI PRESBYTERY","parishes" => ["PCEA Mtwapa Parish","PCEA Malindi Parish","PCEA Kilifi PARISH","PCEA Mpeketoni Parish","PCEA Milele Parish","PCEA Lamu Parish"]]
                ]
            ],
            [
                "region_name" => "RIFT VALLEY REGION",
                "presbyteries" => [
                    ["presbytery_name" => "ABERDARE PRESBYTERY","parishes" => ["PCEA Gilgil Parish","PCEA Karunga Parish","Pcea Miharati Parish","Pcea Mawingu Parish","Pcea Satima Parish","Pcea Kamande Parish","Pcea Kirima Parish","Pcea olkalou Parish","Pcea Geta Mission Area"]],
                    ["presbytery_name" => "ELBURGON PRESBYTERY","parishes" => ["PCEA Molo Parish","PCEA Elburgon Parish","PCEA Kericho Parish","PCEA Turi Parish","PCEA Mau Summit Outreach","PCEA Keringet Outreach","PCEA Londiani Outreach","PCEA KISII NENDENI"]],
                    ["presbytery_name" => "ELDORET PRESBYTERY","parishes" => ["PCEA Ayub Kinyua Parish","PCEA Soy Parish","PCEA Marula Parish","PCEA Pioneer Parish","PCEA Huruma Parish","PCEA Burnt Forest Parish","PCEA Moiben Nendeni Area","PCEA Kaptagat Nendeni Area","PCEA Turkana Nendeni Area"]],
                    ["presbytery_name" => "IRIA-INI PRESBYTERY","parishes" => ["PCEA Gathanje Parish","PCEA Kichaka Parish","PCEA Ol-joro-orok Parish","PCEA Mirangine Parish","PCEA Kanjuiri Parish","PCEA Rurii Parish","PCEA Tumaini Parish","PCEA Kasuku Parish","PCEA Dol Dol Nendeni Area"]],
                    ["presbytery_name" => "KITALE PRESBYTERY","parishes" => ["PCEA Kitale East Parish","PCEA Kitale West Parish","PCEA Kiungani Parish","PCEA Matunda Parish","PCEA Cherangani Parish"]],
                    ["presbytery_name" => "NAKURU EAST PRESBYTERY","parishes" => ["PCEA Jerusalem Parish","PCEA Wema Parish","PCEA Crater Parish","PCEA Umoja Parish","PCEA Tabuga Parish","PCEA St. Mary's Parish","PCEA Bahati Parish","PCEA Kirathimo Parish","PCEA Wendo Parish","PCEA Ngorika Parish","Pcea Lanet East Parish","PCEA Lanet West Parish","Pcea Nakuru Pipeline Parish","PCEA Kiptagwanyi Outreach"]],
                    ["presbytery_name" => "NAKURU WEST PRESBYTERY","parishes" => ["PCEA Dr. Arthur Parish","PCEA Bethsaida Parish","PCEA Nakuru West Parish","PCEA Millimani Parish","PCEA Beracah Parish","PCEA Amani Parish","PCEA Rongai Parish","PCEA Shalom Kiamunyi","PCEA Kuria Nendeni Area"]],
                    ["presbytery_name" => "NDARAGWA PRESBYTERY","parishes" => ["PCEA Githima Parish-Ndaragwa","PCEA Manguo Parish","PCEA Murichu Parish","PCEA Shamata Parish","PCEA Kanyagia Parish","PCEA Gituamba Parish"]],
                    ["presbytery_name" => "NJORO PRESBYTERY","parishes" => ["PCEA Njoro Parish","PCEA Emmanuel Parish-Njoro","PCEA Wendo Parish-Njoro","PCEA Mau Narok Outreach","PCEA Lare Nendeni Area","PCEA Olenguruone Nendeni Area"]],
                    ["presbytery_name" => "NYAHURURU PRESBYTERY","parishes" => ["PCEA Nyahururu Parish","PCEA Subukia Parish","PCEA Equator Parish","PCEA Emmanuel Parish -Laikipia","PCEA Kabazi Parish","PCEA Mbogoini Parish","PCEA Wamba Nendeni Area"]],
                    ["presbytery_name" => "NYANDARUA PRESBYTERY","parishes" => ["PCEA Naivasha town Parish","PCEA Kinangop North Parish","PCEA New Njabini Parish","PCEA Naivasha East Parish","PCEA Flyover Parish","PCEA Maela Outreach","PCEA Kinangop Central Parish","PCEA mukeu parish"]],
                    ["presbytery_name" => "RUMURUTI PRESBYTERY","parishes" => ["PCEA Muhotetu Parish","PCEA Ng'arua Parish","PCEA Marmanet Parish","PCEA Maraalal Parish","PCEA Kirima Parish"]],
                    ["presbytery_name" => "SUGARBELT PRESBYTERY","parishes" => ["PCEA Mt.Olive Bungoma parish","PCEA Ebenezer Busia parish","PCEA Webuye Parish","PCEA Kakamega Parish","PCEA Kisumu Parish","UGANDA MISSION AREA"]]
                ]
            ]
        ];

        foreach ($regions as $regionData) {
            $region = Region::firstOrCreate(['name' => $regionData['region_name']]);
            foreach ($regionData['presbyteries'] as $presData) {
                $presbytery = Presbytery::firstOrCreate([
                    'region_id' => $region->id,
                    'name' => $presData['presbytery_name'],
                ]);
                foreach ($presData['parishes'] as $parishName) {
                    Parish::firstOrCreate([
                        'presbytery_id' => $presbytery->id,
                        'name' => $parishName,
                    ]);
                }
            }
        }
    }
}
