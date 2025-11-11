<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CountiesAndConstituenciesSeeder extends Seeder
{
    public function run(): void
    {
        // Insert counties first
        $counties = [
            ["Mombasa", 1], ["Kwale", 2], ["Kilifi", 3], ["Tana River", 4], ["Lamu", 5],
            ["Taita–Taveta", 6], ["Garissa", 7], ["Wajir", 8], ["Mandera", 9], ["Marsabit", 10],
            ["Isiolo", 11], ["Meru", 12], ["Tharaka-Nithi", 13], ["Embu", 14], ["Kitui", 15],
            ["Machakos", 16], ["Makueni", 17], ["Nyandarua", 18], ["Nyeri", 19], ["Kirinyaga", 20],
            ["Murang'a", 21], ["Kiambu", 22], ["Turkana", 23], ["West Pokot", 24], ["Samburu", 25],
            ["Trans Nzoia", 26], ["Uasin Gishu", 27], ["Elgeyo-Marakwet", 28], ["Nandi", 29], ["Baringo", 30],
            ["Laikipia", 31], ["Nakuru", 32], ["Narok", 33], ["Kajiado", 34], ["Kericho", 35],
            ["Bomet", 36], ["Kakamega", 37], ["Vihiga", 38], ["Bungoma", 39], ["Busia", 40],
            ["Siaya", 41], ["Kisumu", 42], ["Homa Bay", 43], ["Migori", 44], ["Kisii", 45],
            ["Nyamira", 46], ["Nairobi", 47]
        ];

        foreach ($counties as [$name, $code]) {
            DB::table('counties')->insert([
                'county_name' => $name,
                'county_code' => $code,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Insert constituencies
        $this->insertConstituencies();
    }

    private function insertConstituencies(): void
    {
        $constituencies = [
            // Mombasa
            ["Mombasa", "Changamwe"], ["Mombasa", "Jomvu"], ["Mombasa", "Kisauni"], 
            ["Mombasa", "Nyali"], ["Mombasa", "Likoni"], ["Mombasa", "Mvita"],
            
            // Kwale
            ["Kwale", "Msambweni"], ["Kwale", "Lunga Lunga"], ["Kwale", "Matuga"], ["Kwale", "Kinango"],
            
            // Kilifi
            ["Kilifi", "Kilifi North"], ["Kilifi", "Kilifi South"], ["Kilifi", "Kaloleni"],
            ["Kilifi", "Rabai"], ["Kilifi", "Ganze"], ["Kilifi", "Malindi"], ["Kilifi", "Magarini"],
            
            // Tana River
            ["Tana River", "Garsen"], ["Tana River", "Galole"], ["Tana River", "Bura"],
            
            // Lamu
            ["Lamu", "Lamu East"], ["Lamu", "Lamu West"],
            
            // Taita-Taveta
            ["Taita–Taveta", "Taveta"], ["Taita–Taveta", "Wundanyi"], ["Taita–Taveta", "Mwatate"], ["Taita–Taveta", "Voi"],
            
            // Garissa
            ["Garissa", "Garissa Township"], ["Garissa", "Balambala"], ["Garissa", "Lagdera"],
            ["Garissa", "Dadaab"], ["Garissa", "Fafi"], ["Garissa", "Ijara"],
            
            // Wajir
            ["Wajir", "Wajir East"], ["Wajir", "Tarbaj"], ["Wajir", "Wajir West"],
            ["Wajir", "Eldas"], ["Wajir", "Wajir South"], ["Wajir", "Wajir North"],
            
            // Mandera
            ["Mandera", "Mandera West"], ["Mandera", "Banissa"], ["Mandera", "Mandera North"],
            ["Mandera", "Mandera East"], ["Mandera", "Lafey"], ["Mandera", "Mandera South"],
            
            // Marsabit
            ["Marsabit", "Moyale"], ["Marsabit", "North Horr"], ["Marsabit", "Saku"], ["Marsabit", "Laisamis"],
            
            // Isiolo
            ["Isiolo", "Isiolo North"], ["Isiolo", "Isiolo South"],
            
            // Meru
            ["Meru", "Igembe South"], ["Meru", "Igembe Central"], ["Meru", "Igembe North"],
            ["Meru", "Tigania West"], ["Meru", "Tigania East"], ["Meru", "North Imenti"],
            ["Meru", "Buuri"], ["Meru", "Central Imenti"], ["Meru", "South Imenti"],
            
            // Tharaka-Nithi
            ["Tharaka-Nithi", "Maara"], ["Tharaka-Nithi", "Chuka/Igambang'omb'e"], ["Tharaka-Nithi", "Tharaka"],
            
            // Embu
            ["Embu", "Manyatta"], ["Embu", "Runyenjes"], ["Embu", "Mbeere South"], ["Embu", "Mbeere North"],
            
            // Kitui
            ["Kitui", "Mwingi North"], ["Kitui", "Mwingi West"], ["Kitui", "Mwingi Central"],
            ["Kitui", "Kitui West"], ["Kitui", "Kitui Rural"], ["Kitui", "Kitui Central"],
            ["Kitui", "Kitui East"], ["Kitui", "Kitui South"],
            
            // Machakos
            ["Machakos", "Masinga"], ["Machakos", "Yatta"], ["Machakos", "Kangundo"],
            ["Machakos", "Matungulu"], ["Machakos", "Kathiani"], ["Machakos", "Mavoko"],
            ["Machakos", "Machakos Town"], ["Machakos", "Mwala"],
            
            // Makueni
            ["Makueni", "Mbooni"], ["Makueni", "Kilome"], ["Makueni", "Kaiti"],
            ["Makueni", "Makueni"], ["Makueni", "Kibwezi West"], ["Makueni", "Kibwezi East"],
            
            // Nyandarua
            ["Nyandarua", "Kinangop"], ["Nyandarua", "Kipipiri"], ["Nyandarua", "Ol Kalou"],
            ["Nyandarua", "Ol Jorok"], ["Nyandarua", "Ndaragwa"],
            
            // Nyeri
            ["Nyeri", "Tetu"], ["Nyeri", "Kieni"], ["Nyeri", "Mathira"],
            ["Nyeri", "Othaya"], ["Nyeri", "Mukurweini"], ["Nyeri", "Nyeri Town"],
            
            // Kirinyaga
            ["Kirinyaga", "Mwea"], ["Kirinyaga", "Gichugu"], ["Kirinyaga", "Ndia"], ["Kirinyaga", "Kirinyaga Central"],
            
            // Murang'a
            ["Murang'a", "Kangema"], ["Murang'a", "Mathioya"], ["Murang'a", "Kiharu"],
            ["Murang'a", "Kigumo"], ["Murang'a", "Maragua"], ["Murang'a", "Kandara"], ["Murang'a", "Gatanga"],
            
            // Kiambu
            ["Kiambu", "Gatundu South"], ["Kiambu", "Gatundu North"], ["Kiambu", "Juja"],
            ["Kiambu", "Thika Town"], ["Kiambu", "Ruiru"], ["Kiambu", "Githunguri"],
            ["Kiambu", "Kiambu Town"], ["Kiambu", "Kiambaa"], ["Kiambu", "Kabete"],
            ["Kiambu", "Kikuyu"], ["Kiambu", "Limuru"], ["Kiambu", "Lari"],
            
            // Turkana
            ["Turkana", "Turkana North"], ["Turkana", "Turkana West"], ["Turkana", "Turkana Central"],
            ["Turkana", "Loima"], ["Turkana", "Turkana South"], ["Turkana", "Turkana East"],
            
            // West Pokot
            ["West Pokot", "Kapenguria"], ["West Pokot", "Sigor"], ["West Pokot", "Kacheliba"], ["West Pokot", "Pokot South"],
            
            // Samburu
            ["Samburu", "Samburu West"], ["Samburu", "Samburu North"], ["Samburu", "Samburu East"],
            
            // Trans Nzoia
            ["Trans Nzoia", "Kwanza"], ["Trans Nzoia", "Endebess"], ["Trans Nzoia", "Saboti"],
            ["Trans Nzoia", "Kiminini"], ["Trans Nzoia", "Cherangany"],
            
            // Uasin Gishu
            ["Uasin Gishu", "Soy"], ["Uasin Gishu", "Turbo"], ["Uasin Gishu", "Moiben"],
            ["Uasin Gishu", "Ainabkoi"], ["Uasin Gishu", "Kapseret"], ["Uasin Gishu", "Kesses"],
            
            // Elgeyo-Marakwet
            ["Elgeyo-Marakwet", "Marakwet East"], ["Elgeyo-Marakwet", "Marakwet West"],
            ["Elgeyo-Marakwet", "Keiyo North"], ["Elgeyo-Marakwet", "Keiyo South"],
            
            // Nandi
            ["Nandi", "Tinderet"], ["Nandi", "Aldai"], ["Nandi", "Nandi Hills"],
            ["Nandi", "Chesumei"], ["Nandi", "Emgwen"], ["Nandi", "Mosop"],
            
            // Baringo
            ["Baringo", "Tiaty"], ["Baringo", "Baringo North"], ["Baringo", "Baringo Central"],
            ["Baringo", "Baringo South"], ["Baringo", "Mogotio"], ["Baringo", "Eldama Ravine"],
            
            // Laikipia
            ["Laikipia", "Laikipia West"], ["Laikipia", "Laikipia East"], ["Laikipia", "Laikipia North"],
            
            // Nakuru
            ["Nakuru", "Molo"], ["Nakuru", "Njoro"], ["Nakuru", "Naivasha"], ["Nakuru", "Gilgil"],
            ["Nakuru", "Kuresoi South"], ["Nakuru", "Kuresoi North"], ["Nakuru", "Subukia"],
            ["Nakuru", "Rongai"], ["Nakuru", "Bahati"], ["Nakuru", "Nakuru Town West"], ["Nakuru", "Nakuru Town East"],
            
            // Narok
            ["Narok", "Kilgoris"], ["Narok", "Emurua Dikirr"], ["Narok", "Narok North"],
            ["Narok", "Narok East"], ["Narok", "Narok South"], ["Narok", "Narok West"],
            
            // Kajiado
            ["Kajiado", "Kajiado North"], ["Kajiado", "Kajiado Central"], ["Kajiado", "Kajiado East"],
            ["Kajiado", "Kajiado West"], ["Kajiado", "Kajiado South"],
            
            // Kericho
            ["Kericho", "Ainamoi"], ["Kericho", "Belgut"], ["Kericho", "Kipkelion East"],
            ["Kericho", "Kipkelion West"], ["Kericho", "Bureti"], ["Kericho", "Soin/Sigowet"],
            
            // Bomet
            ["Bomet", "Sotik"], ["Bomet", "Chepalungu"], ["Bomet", "Bomet East"],
            ["Bomet", "Bomet Central"], ["Bomet", "Konoin"],
            
            // Kakamega
            ["Kakamega", "Lugari"], ["Kakamega", "Lurambi"], ["Kakamega", "Likuyani"],
            ["Kakamega", "Malava"], ["Kakamega", "Navakholo"], ["Kakamega", "Mumias West"],
            ["Kakamega", "Mumias East"], ["Kakamega", "Matungu"], ["Kakamega", "Butere"],
            ["Kakamega", "Khwisero"], ["Kakamega", "Shinyalu"], ["Kakamega", "Ikolomani"],
            
            // Vihiga
            ["Vihiga", "Vihiga"], ["Vihiga", "Sabatia"], ["Vihiga", "Hamisi"],
            ["Vihiga", "Luanda"], ["Vihiga", "Emuhaya"],
            
            // Bungoma
            ["Bungoma", "Mt. Elgon"], ["Bungoma", "Sirisia"], ["Bungoma", "Kabuchai"],
            ["Bungoma", "Bumula"], ["Bungoma", "Kanduyi"], ["Bungoma", "Webuye East"],
            ["Bungoma", "Webuye West"], ["Bungoma", "Kimilili"], ["Bungoma", "Tongaren"],
            
            // Busia
            ["Busia", "Teso North"], ["Busia", "Teso South"], ["Busia", "Nambale"],
            ["Busia", "Matayos"], ["Busia", "Butula"], ["Busia", "Funyula"], ["Busia", "Budalangi"],
            
            // Siaya
            ["Siaya", "Ugenya"], ["Siaya", "Ugunja"], ["Siaya", "Alego Usonga"],
            ["Siaya", "Gem"], ["Siaya", "Bondo"], ["Siaya", "Rarieda"],
            
            // Kisumu
            ["Kisumu", "Kisumu East"], ["Kisumu", "Kisumu West"], ["Kisumu", "Kisumu Central"],
            ["Kisumu", "Seme"], ["Kisumu", "Nyando"], ["Kisumu", "Muhoroni"], ["Kisumu", "Nyakach"],
            
            // Homa Bay
            ["Homa Bay", "Kasipul"], ["Homa Bay", "Kabondo Kasipul"], ["Homa Bay", "Karachuonyo"],
            ["Homa Bay", "Rangwe"], ["Homa Bay", "Homa Bay Town"], ["Homa Bay", "Ndhiwa"],
            ["Homa Bay", "Mbita"], ["Homa Bay", "Suba South"],
            
            // Migori
            ["Migori", "Rongo"], ["Migori", "Awendo"], ["Migori", "Suna East"],
            ["Migori", "Suna West"], ["Migori", "Uriri"], ["Migori", "Nyatike"],
            ["Migori", "Kuria West"], ["Migori", "Kuria East"],
            
            // Kisii
            ["Kisii", "Bonchari"], ["Kisii", "South Mugirango"], ["Kisii", "Bomachoge Borabu"],
            ["Kisii", "Bobasi"], ["Kisii", "Bomachoge Chache"], ["Kisii", "Nyaribari Masaba"],
            ["Kisii", "Nyaribari Chache"], ["Kisii", "Kitutu Chache North"], ["Kisii", "Kitutu Chache South"],
            
            // Nyamira
            ["Nyamira", "Kitutu Masaba"], ["Nyamira", "West Mugirango"], ["Nyamira", "North Mugirango"], ["Nyamira", "Borabu"],
            
            // Nairobi
            ["Nairobi", "Westlands"], ["Nairobi", "Dagoretti North"], ["Nairobi", "Dagoretti South"],
            ["Nairobi", "Lang'ata"], ["Nairobi", "Kibra"], ["Nairobi", "Roysambu"],
            ["Nairobi", "Kasarani"], ["Nairobi", "Ruaraka"], ["Nairobi", "Embakasi South"],
            ["Nairobi", "Embakasi North"], ["Nairobi", "Embakasi Central"], ["Nairobi", "Embakasi East"],
            ["Nairobi", "Embakasi West"], ["Nairobi", "Makadara"], ["Nairobi", "Kamukunji"],
            ["Nairobi", "Starehe"], ["Nairobi", "Mathare"]
        ];

        foreach ($constituencies as [$countyName, $constituencyName]) {
            $county = DB::table('counties')->where('county_name', $countyName)->first();
            if ($county) {
                DB::table('constituencies')->insert([
                    'county_id' => $county->id,
                    'constituency_name' => $constituencyName,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }
}