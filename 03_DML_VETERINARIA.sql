/* =====================================================================
   VETERINARIA - DML / LLENADO (SQL Server 2025)
   Migrado desde PostgreSQL.
   Ejecutar DESPUES de 01_DDL y 02_TRIGGERS: los triggers participan en la carga
   (recalculan montos, descuentan stock, cancelan citas vencidas, etc.).
   Cambios principales:
     - Fechas/horas de Cita normalizadas a 'YYYY-MM-DD' y 'HH:MM:SS'
     - Textos con acentos con prefijo N'...' (Unicode)
     - Bloque de PAGO: random()/array[] -> NEWID()/CHOOSE() con tabla temporal
   ===================================================================== */

USE Veterinaria;
GO
SET NOCOUNT ON;
GO

-- PROPIETARIO
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Cyndi Beggini', '40523095-9', 'cbeggini0@gmail.com', '+503 7358-8689');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rebeca Schimpke', '11594342-9', 'rschimpke1@yahoo.com', '+503 2949-0347');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Fergus Brockman', '54134545-6', 'fbrockman2@yahoo.com', '+503 6811-0815');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Chane Fance', '01662461-1', 'cfance3@theguardian.com', '+503 6214-8974');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Adel Spencley', '00539425-4', 'aspencley4@gmail.com', '+503 2043-3140');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Eve Brace', '20247864-2', 'ebrace5@outlook.com', '+503 2713-8656');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Joellen O'' Scallan', '35944599-4', 'jo6@gmail.com', '+503 6102-4353');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Chrisy Quarry', '67296481-0', 'cquarry7@gmail.com', '+503 7302-9198');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hazel Gregorace', '44264335-1', 'hgregorace8@gmail.com', '+503 6450-1376');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Marylynne Skellion', '61288195-8', 'mskellion9@gmail.com', '+503 2366-9561');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Jamil Gundry', '78124078-3', 'jgundrya@yahoo.com', '+503 2002-3804');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Randi Vassel', '78702475-6', 'rvasselb@outlook.com', '+503 7012-1328');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rodi Guerrero', '37553552-8', 'rguerreroc@outlook.com', '+503 6750-3958');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Kristina Czyz', '41002486-8', 'kczyzd@meetup.com', '+503 7835-8427');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Mendie Imesen', '01629395-5', 'mimesene@hotmail.com', '+503 2679-3128');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Arie Blodget', '30483529-0', 'ablodgetf@yahoo.com', '+503 2738-0036');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Alvan Worg', '36828714-8', 'aworgg@yahoo.com', '+503 7114-8801');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Filberto Pendreigh', '16689100-7', 'fpendreighh@yahoo.com', '+503 7628-7624');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Isa Penelli', '61429660-7', 'ipenellii@gmail.com', '+503 2533-3407');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Constantine Houselee', '82189602-0', 'chouseleej@hotmail.com', '+503 2266-8421');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Clementina Stanistrete', '81419463-5', 'cstanistretek@gmail.com', '+503 2084-8968');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Kathie McGurn', '37691431-7', 'kmcgurnl@apple.com', '+503 6346-6029');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Lana Pelman', '24766055-4', 'lpelmanm@hotmail.com', '+503 2870-6142');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Gabriel Veljes', '13818023-5', '00671234@uca.edu.sv', '+503 7402-0943');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Eward Houtbie', '30377563-1', 'ehoutbieo@gmail.com', '+503 2026-1432');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ailis Heine', '10488632-9', 'aheinep@yahoo.com', '+503 7524-8432');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Darelle Dewberry', '58551291-1', 'ddewberryq@gmail.com', '+503 7312-5655');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Tatiana Lathe', '08778416-2', 'tlather@gmail.com', '+503 6465-0067');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rubi Benedikt', '52340336-8', 'rbenedikts@yahoo.com', '+503 6744-1436');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Alexa Ellaway', '76130750-2', 'aellawayt@gmail.com', '+503 2006-4321');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ailsun Tomasello', '21990837-7', 'atomasello0@goo.gl', '+503 2264-3202');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Jerrilee Snoxall', '79553314-5', 'jsnoxall1@marketwatch.com', '+503 7319-0609');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Stearn Widmore', '09018785-2', 'swidmore2@kickstarter.com', '+503 2318-6478');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Milzie Burfitt', '82404424-2', 'mburfitt3@nbcnews.com', '+503 2180-7809');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Gayel Priscott', '65956875-4', 'gpriscott4@ning.com', '+503 2235-1321');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Sibyl Oglethorpe', '49265100-4', 'soglethorpe5@ebay.com', '+503 7724-2810');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hiram Slade', '17365418-0', 'hslade6@jiathis.com', '+503 2591-2871');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Stephi Tummond', '80035131-0', 'stummond7@columbia.edu', '+503 2656-7707');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Dana Purdy', '43210839-6', 'dpurdy8@craigslist.org', '+503 7494-0706');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rutter MacRury', '77927941-8', 'rmacrury9@cdc.gov', '+503 7229-6529');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Husain Ramirez', '01296929-7', 'hramireza@qq.com', '+503 2328-4140');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Peyton McQueen', '79161333-8', 'pmcqueenb@sfgate.com', '+503 7974-1071');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Pennie Murrie', '26610907-9', 'pmurriec@elpais.com', '+503 7253-3377');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Pearl Conen', '71903937-4', 'pconend@instagram.com', '+503 2288-5083');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Kerry Dahler', '83507779-0', 'kdahlere@cpanel.net', '+503 7993-3409');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Aviva Lauga', '47967503-6', 'alaugaf@forbes.com', '+503 2712-8235');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Emiline Rossey', '61434810-3', 'erosseyg@skype.com', '+503 2801-0565');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Eleni Blakes', '20279983-6', 'eblakesh@yellowbook.com', '+503 7229-3029');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Wendye Juden', '02966359-7', 'wjudeni@pcworld.com', '+503 2315-6211');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hershel Tuddall', '48838731-4', 'htuddallj@ocn.ne.jp', '+503 7454-6784');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Baldwin Giacopelo', '18418773-9', 'bgiacopelok@abc.net.au', '+503 6189-7209');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Liesa Western', '24739210-7', 'lwesternl@economist.com', '+503 6879-2636');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Terri-jo Bowring', '67482466-0', 'tbowringm@senate.gov', '+503 6808-2401');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nichol Kupisz', '96895523-9', 'nkupiszn@jalbum.net', '+503 6087-2709');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Vonni Northern', '41013089-1', 'vnortherno@domainmarket.com', '+503 2600-2755');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Carmelita Goudie', '80529642-8', 'cgoudiep@blogger.com', '+503 2160-7124');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Burgess Sudell', '08621801-0', 'bsudellq@google.com.hk', '+503 7850-1415');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Laird Pottie', '47262440-3', 'lpottier@mysql.com', '+503 2557-3497');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Deonne Hallums', '62073448-3', 'dhallumss@dion.ne.jp', '+503 7765-5171');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Delmer Gabrieli', '67170314-3', 'dgabrielit@youtu.be', '+503 7795-2883');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Vic Bedford', '12833769-4', 'vbedfordu@symantec.com', '+503 7148-4911');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Garnet Cansdill', '87095192-6', 'gcansdillv@lycos.com', '+503 6293-9199');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ursuline Bischoff', '13455604-5', 'ubischoffw@wsj.com', '+503 7411-9715');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Alvy Forsdike', '75781173-6', 'aforsdikex@globo.com', '+503 6339-9958');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Catlee Hundy', '52730073-6', 'chundyy@uol.com.br', '+503 7180-8566');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Sallee Weldrick', '33909365-1', 'sweldrickz@sciencedirect.com', '+503 6359-6392');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Eliza Mahedy', '30944593-2', 'emahedy10@edublogs.org', '+503 2938-3812');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rollins Blowing', '82088389-2', 'rblowing11@weather.com', '+503 2669-3498');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Verna Dollman', '71166878-3', 'vdollman12@wikipedia.org', '+503 2805-1880');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Mandi Stokes', '52250388-3', 'mstokes13@goodreads.com', '+503 2868-8946');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rutherford Ascroft', '97904302-9', 'rascroft14@techcrunch.com', '+503 6150-7907');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Dorena Nickless', '00644466-1', 'dnickless15@ezinearticles.com', '+503 6303-2992');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Jeddy Jovicevic', '51388032-5', 'jjovicevic16@sakura.ne.jp', '+503 7063-3165');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Edita Meas', '16673191-5', 'emeas17@wsj.com', '+503 2293-5624');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Wenona Le Provest', '95701243-2', 'wle18@prlog.org', '+503 2079-7228');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Janessa Scud', '23127158-8', 'jscud19@moonfruit.com', '+503 7866-5678');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Neddie Goadby', '35749210-6', 'ngoadby1a@dmoz.org', '+503 6077-3637');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Kandy Tye', '42681184-6', 'ktye1b@trellian.com', '+503 6384-6211');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hazel Mothersole', '50282348-0', 'hmothersole1c@japanpost.jp', '+503 6163-7210');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Elane Thickpenny', '14184490-4', 'ethickpenny1d@apache.org', '+503 6550-9553');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hans Stuchbury', '42386089-3', 'hstuchbury1e@icio.us', '+503 2543-7649');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Simone De Benedictis', '46494111-3', 'sde1f@howstuffworks.com', '+503 7145-8957');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Massimiliano Sach', '43224751-9', 'msach1g@freewebs.com', '+503 2249-1357');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Maude Quemby', '58588711-5', 'mquemby1h@biblegateway.com', '+503 2042-9310');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Upton O''Scollain', '60444311-8', 'uoscollain1i@tripod.com', '+503 6513-4463');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Cally Rowth', '90392735-3', 'crowth1j@alibaba.com', '+503 2848-8416');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Rozanna Wyndham', '68125290-0', 'rwyndham1k@about.com', '+503 6249-2977');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Martyn O''Hdirscoll', '98194689-0', 'mohdirscoll1l@youtube.com', '+503 6656-0494');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Muhammad Foxley', '06824653-4', 'mfoxley1m@t.co', '+503 7700-7520');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Julita Fidele', '77227387-6', 'jfidele1n@altervista.org', '+503 6621-5542');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nikki Papps', '95960612-8', 'npapps1o@yelp.com', '+503 7627-2480');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ulrich Bontine', '36976553-1', 'ubontine1p@salon.com', '+503 7170-9399');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Harmonie Swiffan', '50286794-0', 'hswiffan1q@wufoo.com', '+503 2716-9195');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Derril Towers', '45330590-1', 'dtowers1r@list-manage.com', '+503 6225-3156');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nico Paler', '94173418-0', 'npaler1s@ovh.net', '+503 2766-6731');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Biddy Agget', '17470945-1', 'bagget1t@walmart.com', '+503 6479-0709');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Joane Lackemann', '80398654-0', 'jlackemann1u@typepad.com', '+503 2891-2101');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Bianka Chatwin', '08516118-8', 'bchatwin1v@hibu.com', '+503 7564-9615');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Wilt Prendergrast', '51382401-1', 'wprendergrast1w@linkedin.com', '+503 7431-0486');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Xylia Blacker', '30459969-7', 'xblacker1x@aol.com', '+503 2650-4171');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Reynard Astle', '84297258-2', 'rastle1y@narod.ru', '+503 2877-2939');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Corrie Fehely', '56669714-3', 'cfehely1z@house.gov', '+503 2424-4791');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Lloyd Beels', '46889492-0', 'lbeels20@constantcontact.com', '+503 6847-6512');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Gaston Rother', '94126002-5', 'grother21@sciencedirect.com', '+503 2282-6921');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Karena Oury', '21123206-3', 'koury22@parallels.com', '+503 7950-8736');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Allister Turland', '21683122-7', 'aturland23@barnesandnoble.com', '+503 2850-1915');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Robinson Hail', '13702995-2', 'rhail24@patch.com', '+503 6036-6934');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Tybie Yurlov', '05122960-6', 'tyurlov25@paginegialle.it', '+503 2648-7464');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Mac Filipson', '21710591-5', 'mfilipson26@bluehost.com', '+503 6371-2664');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Stillmann Berick', '89671053-4', 'sberick27@upenn.edu', '+503 7751-1942');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Carol-jean Rawls', '31926029-9', 'crawls28@51.la', '+503 2270-7961');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Wilhelmine Novotne', '43319743-6', 'wnovotne29@sun.com', '+503 2479-4658');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Heinrick Milland', '25176157-7', 'hmilland2a@slideshare.net', '+503 2942-2098');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Britney Cork', '12555955-6', 'bcork2b@addthis.com', '+503 2970-4579');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Gilligan Otteridge', '33339215-8', 'gotteridge2c@utexas.edu', '+503 7895-4783');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Perren Soonhouse', '18070230-2', 'psoonhouse2d@ovh.net', '+503 6533-0855');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Britt Jacobowits', '42449573-7', 'bjacobowits2e@artisteer.com', '+503 6616-7726');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Neron Crayke', '05499557-2', 'ncrayke2f@instagram.com', '+503 2484-5029');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Simonette Pearle', '63555595-3', 'spearle2g@woothemes.com', '+503 6583-0923');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Maurise Morin', '36535452-9', 'mmorin2h@scientificamerican.com', '+503 2552-5622');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Bancroft Jeannon', '79202465-9', 'bjeannon2i@tuttocitta.it', '+503 6557-3270');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Herby McIlmorie', '31586690-4', 'hmcilmorie2j@redcross.org', '+503 6638-4429');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Roda Gayforth', '96403847-7', 'rgayforth2k@army.mil', '+503 2253-8506');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Brandice Dufaur', '88408649-7', 'bdufaur2l@goo.ne.jp', '+503 2128-6571');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ingeberg Jump', '52415598-2', 'ijump2m@sfgate.com', '+503 2303-3237');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Harmon Strippling', '45186982-8', 'hstrippling2n@canalblog.com', '+503 6426-4510');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Dolley Skeemor', '37313336-3', 'dskeemor2o@upenn.edu', '+503 7141-1680');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Merralee Whorlton', '77303413-2', 'mwhorlton2p@joomla.org', '+503 2873-1963');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Minnnie Beany', '26461137-9', 'mbeany2q@usnews.com', '+503 6604-8767');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Benyamin Savary', '82616017-3', 'bsavary2r@wired.com', '+503 7808-2682');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Lloyd Bedlington', '64422331-4', 'lbedlington2s@abc.net.au', '+503 7368-1306');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Odille Trenholme', '42495581-6', 'otrenholme2t@symantec.com', '+503 6128-4124');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Victoria Semarke', '26766750-1', 'vsemarke2u@yolasite.com', '+503 2543-6008');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hinze Fuxman', '16157792-1', 'hfuxman2v@whitehouse.gov', '+503 6253-0252');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Philippine Caslane', '25732503-5', 'pcaslane2w@columbia.edu', '+503 6322-2947');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Lyda Henzley', '17424773-2', 'lhenzley2x@springer.com', '+503 2996-2174');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Adriana Stading', '92277698-5', 'astading2y@twitter.com', '+503 6635-0182');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Moyra Demead', '02676855-5', 'mdemead2z@cam.ac.uk', '+503 6424-7413');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Dannel Masserel', '08545784-9', 'dmasserel30@usa.gov', '+503 6124-0032');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Kirsten Tellenbach', '08834692-8', 'ktellenbach31@diigo.com', '+503 7777-5639');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Natasha Fuchs', '21271380-1', 'nfuchs32@github.io', '+503 2257-7846');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Hamil Catherick', '43915677-7', 'hcatherick33@usda.gov', '+503 7029-4869');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nicolette Cobelli', '11142321-9', 'ncobelli34@yahoo.com', '+503 2453-5163');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nessy Titman', '09378404-8', 'ntitman35@free.fr', '+503 2932-4549');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Bowie Karsh', '89480793-9', 'bkarsh36@people.com.cn', '+503 7746-0665');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Ingelbert Alebrooke', '00394912-7', 'ialebrooke37@usgs.gov', '+503 7460-5593');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Trev Brame', '78439931-4', 'tbrame38@gnu.org', '+503 6817-4845');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Abbe MacSorley', '49392035-7', 'amacsorley39@microsoft.com', '+503 6621-8011');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Otha De Bellis', '80554136-4', 'ode3a@themeforest.net', '+503 2470-3063');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Siegfried Corhard', '81345891-6', 'scorhard3b@hubpages.com', '+503 7389-8375');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Fenelia Langlais', '38564628-5', 'flanglais3c@bandcamp.com', '+503 2822-3375');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Sande Gallahue', '40744848-6', 'sgallahue3d@odnoklassniki.ru', '+503 7736-8588');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Marys St. Hill', '94001742-9', 'mst3e@wikia.com', '+503 6355-9211');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Nealson Harback', '27166337-4', 'nharback3f@loc.gov', '+503 6998-4331');
insert into Propietario (Nombre, DUI, Correo, Telefono) values ('Saidee Swiffin', '47156179-2', 'sswiffin3g@businessinsider.com', '+503 6828-1283');
--select * from Propietario;


GO

-- VETERINARIO
insert into Veterinario (nombre, correo) values ('Guillermo Scandrite', 'guillermosewjz@gmail.com');
insert into Veterinario (nombre, correo) values ('Britte Shynn', 'britteshyngjiw@gmail.com');
insert into Veterinario (nombre, correo) values ('Ardys Birchill', 'ardysbirchevhv@gmail.com');
insert into Veterinario (nombre, correo) values ('Kevin Manuely', 'kevinmanuenzwq@gmail.com');
insert into Veterinario (nombre, correo) values ('Jemima Sheaf', 'jemimasheavvhe@gmail.com');
insert into Veterinario (nombre, correo) values ('Orelle Scargill', 'orellescarujsf@gmail.com');
insert into Veterinario (nombre, correo) values ('Aili Sute', 'ailisuteadkg@gmail.com');
insert into Veterinario (nombre, correo) values ('Augustin Demeter', 'augustindelsfg@gmail.com');
insert into Veterinario (nombre, correo) values ('Aimee Catchpole', 'aimeecatchzybn@gmail.com');
insert into Veterinario (nombre, correo) values ('Amil Knock', 'amilknocknmnu@gmail.com');
--select * from Veterinario;
--select count(*) from veterinario;


GO

--ESPECIALIDAD
insert into Especialidad (Nombre, Estado) values (N'Cardiología', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Dermatología', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Oncología', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Neurología', 'Inactivo');
insert into Especialidad (Nombre, Estado) values ('Medicina Interna', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Cirugía de Tejidos Blandos', 'Activo');
insert into Especialidad (Nombre, Estado) values ('Ortopedia', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Traumatología', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Anestesiología', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Oftalmología', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Odontología', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Diagnóstico por imagen', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Medicina de pequeñas especies', 'Activo');
insert into Especialidad (Nombre, Estado) values ('Medicina equina', 'Inactivo');
insert into Especialidad (Nombre, Estado) values ('Medicina de Grandes Especies', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Animales exóticos y salvajes', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Patología clínica', 'Inactivo');
insert into Especialidad (Nombre, Estado) values (N'Fisioterapia y Rehabilitación', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Nutrición veterinaria', 'Activo');
insert into Especialidad (Nombre, Estado) values ('Urgencias y Cuidados Intensivos', 'Activo');
insert into Especialidad (Nombre, Estado) values (N'Reproducción Animal', 'Activo');
-- select * from especialidad;



GO

-- VETERINARIO-ESPECIALIDAD
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (7, 3);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 19);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (10, 21);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 17);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 14);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (2, 14);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (1, 1);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (4, 1);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (10, 5);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (1, 15);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 3);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (7, 20);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (1, 5);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (5, 19);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (10, 4);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (10, 13);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (10, 19);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 5);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (3, 1);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (7, 9);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (1, 8);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (5, 14);
insert into Veterinario_Especialidad (ID_Veterinario, ID_Especialidad) values (5, 16);
-- select * from Veterinario_Especialidad;



GO

--MASCOTA
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Max', 'Labrador Retriever', '2019-05-14', 1);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Luna', 'Golden Retriever', '2021-08-02', 2);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Rocky', N'Pastor Alemán', '2018-11-20', 3);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Toby', 'Beagle', '2022-01-15', 4);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Loki', N'Bulldog Francés', '2021-07-25', 5);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Michi', N'Siamés', '2021-03-12', 23);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Simba', 'Persa', '2019-12-25', 6);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Pelusa', 'Mestizo', '2023-02-18', 7);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Kiara', 'Maine Coon', '2020-06-30', 8);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Tom', 'British Shorthair', '2018-04-11', 9);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Conejo', 'Copito', N'Cabeza de León', '2022-05-08', 10);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Conejo', 'Canela', 'Mini Lop', '2021-10-17', 11);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Conejo', 'Nube', N'Holandés', '2023-01-05', 2);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', N'Piolín', 'Canario', '2020-07-19', 12);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', 'Kiwi', 'Periquito Australiano', '2022-09-21', 13);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', 'Lolo', N'Cacatúa Ninfa', '2021-12-14', 14);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', 'Paco', 'Agapornis', '2019-08-03', 15);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Tortuga', 'Shelly', 'Tortuga de Orejas Rojas', '2017-05-30', 16);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Tortuga', 'Flash', N'Tortuga Mediterránea', '2016-10-12', 3);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values (N'Hámster', 'Bolita', 'Sirio', '2024-01-09', 17);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values (N'Hámster', 'Chispa', 'Ruso', '2023-06-27', 18);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Cobaya', 'Manchitas', 'Americana', '2022-11-11', 19);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Cobaya', 'Coco', 'Peruana', '2021-04-28', 20);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Pez', 'Nemo', 'Pez Payaso', '2023-07-15', 5);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Pez', 'Burbuja', 'Goldfish', '2022-08-01', 6);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Bruno', 'Pug', '2020-02-22', 7);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Zeus', 'Rottweiler', '2019-09-18', 8);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Milo', 'Chihuahua', '2023-05-06', 9);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Loki', 'Mestizo', '2022-04-20', 10);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Olivia', N'Bengalí', '2021-01-13', 25);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Conejo', N'Saltín', 'Rex', '2020-12-07', 12);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', 'Azul', 'Periquito Australiano', '2023-03-29', 13);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values (N'Hámster', 'Pipo', 'Sirio', '2024-02-11', 24);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Cobaya', 'Trufa', 'Abisinia', '2021-07-24', 15);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Kira', 'Border Collie', '2018-06-14', 16);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Gato', 'Mora', 'Angora', '2019-11-05', 17);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Perro', 'Thor', 'Doberman', '2021-09-09', 22);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Ave', 'Sunny', 'Canario', '2022-10-30', 19);
insert into mascota (especie, nombre, raza, fecha_nacimiento, id_propietario) values ('Tortuga', 'Verde', 'Tortuga de Orejas Rojas', '2015-03-17', 20);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Karlen', 'Angora', '2023-01-23', 44);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Chinchilla', 'Anitra', N'Estándar', '2017-01-13', 82);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Mathilde', 'Husky', '2020-03-06', 106);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Jeni', 'Canela', '2015-11-08', 40);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Dede', 'Blanco', '2024-10-30', 96);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Betteanne', 'Gigante de Madagascar', '2014-11-19', 57);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Korie', 'Tokay', '2026-06-07', 59);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Gratiana', 'Fancy', '2021-08-30', 94);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Melba', 'Beagle', '2017-02-07', 38);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Tacuazin', 'Lucho', 'Lanudo', '2014-04-10', 113);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Cammi', 'Crestado', '2026-02-26', 132);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Tacuazin', 'Fifi', 'Pigmeo', '2025-09-25', 132);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Vincents', 'Abisinio', '2019-05-26', 62);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Tana', 'Canela', '2015-12-29', 50);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Ambrosi', 'Angora', '2022-08-09', 102);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Bradford', 'Pinto', '2019-03-31', 56);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Tacuazin', 'Dwayne', N'Común', '2017-01-13', 107);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Hewett', N'Doméstico', '2025-07-10', 77);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Roze', 'Rottweiler', '2016-04-22', 87);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Chinchilla', 'Jemmy', 'Violeta', '2019-01-25', 71);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Arlina', 'Golden Retriever', '2015-06-12', 129);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Constantine', 'Husky', '2017-02-22', 95);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Emmey', 'Labrador', '2016-10-08', 28);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Shelly', N'Doméstico', '2024-10-05', 49);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Lawton', 'Bulldog', '2015-03-18', 108);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Benedick', 'Goldfish', '2023-10-22', 99);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Lalo', 'Canela', '2014-01-05', 96);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Chinchilla', 'Worth', N'Estándar', '2022-04-13', 97);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Darrin', 'Periquito Australiano', '2022-02-08', 43);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Rana', 'Jayme', 'Toro', '2017-11-25', 28);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Chinchilla', 'Gilles', 'Blanca', '2014-05-16', 79);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Carlotta', 'Crestado', '2024-02-28', 31);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Elli', N'Pastor Alemán', '2024-07-28', 106);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Lilas', 'Angora', '2025-10-05', 51);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Reg', 'British Shorthair', '2017-01-16', 88);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Teirtza', 'Pinto', '2023-07-15', 67);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Cobaya', 'Imelda', 'Peruana', '2023-09-24', 135);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Peder', 'Sphynx', '2014-01-06', 105);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Bevvy', 'Goldfish', '2014-07-09', 47);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Linnet', 'Gigante de Madagascar', '2014-11-11', 79);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Illa', 'Tetra', '2022-05-19', 86);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Demetre', 'Tetra', '2018-09-29', 30);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Rana', 'Dorian', 'Toro', '2023-10-02', 105);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Cobaya', 'Gavrielle', 'Abisinia', '2018-12-04', 114);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Olive', 'Yaco', '2019-06-20', 32);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Burk', 'Ninfa', '2020-05-24', 92);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Iguana', 'Arnuad', 'Roja', '2022-10-12', 105);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Goldie', 'Belier', '2019-05-02', 115);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Jaclyn', 'Labrador', '2020-03-22', 102);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Britteny', 'Loro Amazona', '2017-02-15', 132);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Basilius', 'Leopardo', '2022-05-11', 53);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Rana', 'Bradford', 'Toro', '2020-09-15', 115);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Etta', 'Husky', '2019-07-03', 88);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Noah', 'Guppy', '2025-08-21', 74);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Hollis', 'Gigante de Madagascar', '2022-03-04', 83);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Ailee', 'Argelino', '2022-12-04', 68);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Tacuazin', 'Clarinda', 'Pigmeo', '2024-06-28', 28);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Ange', 'Satinado', '2018-11-03', 60);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Kattie', 'Gigante de Madagascar', '2025-08-06', 45);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Iguana', 'Howey', 'Verde', '2019-04-23', 133);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Elset', 'Chino', '2023-09-09', 81);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Rochell', 'Ruso', '2019-01-28', 104);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Rana', 'Shannon', 'Toro', '2018-06-25', 90);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Gunner', N'Holandés', '2016-08-02', 71);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Christophorus', N'Siamés', '2015-10-01', 114);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Sibilla', 'Champagne', '2020-07-04', 134);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Tacuazin', 'Brinna', 'Pigmeo', '2019-02-10', 68);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Desiree', 'Beagle', '2014-05-13', 122);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Anthea', 'Periquito Australiano', '2018-01-02', 60);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Randa', N'Cacatúa', '2015-07-10', 46);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Crin', 'Champagne', '2017-01-21', 87);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Eudora', 'Angora', '2016-03-06', 127);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Debbie', 'Campbell', '2017-10-01', 114);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Eleanore', 'Canela', '2015-08-07', 131);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Chinchilla', 'Langsdon', N'Estándar', '2025-11-02', 84);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Iguana', 'Dottie', 'Verde', '2025-03-01', 88);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Cobaya', 'Melva', 'Americana', '2025-06-14', 93);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Jennilee', 'Belier', '2017-07-05', 83);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Perro', 'Corey', 'Bulldog', '2019-02-24', 137);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Iguana', 'Marline', 'Verde', '2014-12-09', 58);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Hadlee', 'Sphynx', '2025-04-15', 60);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Giorgio', 'Loro Amazona', '2018-09-03', 103);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Regen', 'Africano', '2016-05-21', 57);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Diann', 'Sirio', '2025-07-30', 33);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Valaree', N'Doméstico', '2019-12-21', 127);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Louella', 'Plateado', '2021-06-16', 69);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Geko', 'Torrey', 'Crestado', '2016-08-09', 54);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Remus', 'Mini Lop', '2020-01-08', 138);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Stewart', 'Plateado', '2026-01-11', 73);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Angelle', 'Chino', '2022-04-08', 113);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Brandie', 'Argelino', '2017-10-12', 77);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Isa', 'Chocolate', '2025-11-16', 85);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hurón', 'Saudra', 'Sable', '2017-12-08', 136);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Conejo', 'Darice', 'Angora', '2022-06-01', 140);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Hámster', 'Adaline', 'Campbell', '2023-11-08', 80);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Erizo', 'Sadie', 'Africano', '2018-11-15', 66);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Ave', 'Millicent', 'Agapornis', '2020-03-08', 36);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values (N'Ratón', 'Ivar', 'Dumbo', '2020-10-21', 70);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Pez', 'Aristotle', 'Disco', '2025-08-29', 115);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Gato', 'Pet', N'Bengalí', '2024-08-18', 44);
insert into Mascota (Especie, Nombre, Raza, Fecha_Nacimiento, ID_Propietario) values ('Iguana', 'Colleen', 'Rinoceronte', '2018-04-20', 38);
--select * from mascota;




GO

--ITEM_FACTURABLE
insert into item_facturable (descripcion, costo) values ('Consulta general', 12);
insert into item_facturable (descripcion, costo) values ('Consulta de emergencia', 20);
insert into item_facturable (descripcion, costo) values ('Vacuna antirrabica', 18);
insert into item_facturable (descripcion, costo) values ('Vacuna triple felina', 27);
insert into item_facturable (descripcion, costo) values (N'Desparasitación', 8);
insert into item_facturable (descripcion, costo) values ('Radiografia', 45);
insert into item_facturable (descripcion, costo) values ('Examen de sangre', 30);
insert into item_facturable (descripcion, costo) values ('Hospitalizacion diaria', 80);
insert into item_facturable (descripcion, costo) values ('Certificado medico', 25);
insert into item_facturable (descripcion, costo) values ('Limpieza de oidos', 15);
insert into item_facturable (descripcion, costo) values ('Curacion de heridas', 22);
insert into item_facturable (descripcion, costo) values ('Amoxicilina 250mg', 12);
insert into item_facturable (descripcion, costo) values ('Meloxicam', 18);
insert into item_facturable (descripcion, costo) values ('Prednisolona', 15);
insert into item_facturable (descripcion, costo) values ('Enrofloxacina', 20);
insert into item_facturable (descripcion, costo) values ('Ivermectina', 10);
insert into item_facturable (descripcion, costo) values ('Doxiciclina', 19);
insert into item_facturable (descripcion, costo) values ('Omeprazol', 9);
insert into item_facturable (descripcion, costo) values ('Metronidazol', 14);
insert into item_facturable (descripcion, costo) values ('Tramadol', 16);
insert into item_facturable (descripcion, costo) values ('Vitamina b complejo', 8);
insert into item_facturable (descripcion, costo) values ('Limpieza dental', 15);
insert into item_facturable (descripcion, costo) values ('Extraccion dental', 20);
insert into item_facturable (descripcion, costo) values ('Esterilizacion felina', 160);
insert into item_facturable (descripcion, costo) values ('Esterilizacion canina', 190);
insert into item_facturable (descripcion, costo) values ('Castracion felina', 145);
insert into item_facturable (descripcion, costo) values ('Castracion canina', 170);
insert into item_facturable (descripcion, costo) values ('Cirugia menor', 250);
insert into item_facturable (descripcion, costo) values ('Cirugia ortopedica', 350);
insert into item_facturable (descripcion, costo) values ('Extraccion de tumor', 400);
insert into item_facturable (descripcion, costo) values ('Biopsia', 100);
insert into item_facturable (descripcion, costo) values ('Sutura compleja', 120);
insert into item_facturable (descripcion, costo) values ('Colocacion de yeso', 30);
insert into item_facturable (descripcion, costo) values ('Endoscopia', 220);
insert into item_facturable (descripcion, costo) values ('Oxigenoterapia', 45);
insert into item_facturable (descripcion, costo) values ('Transfusion sanguinea', 80);
--select * from item_facturable;




GO

--PROCEDIMIENTO
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (1, 'Bajo - Sin riesgo aparente', 20);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (2, 'Medio - Depende de la gravedad del paciente', 30);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (3, N'Bajo - Reacción alérgica leve posible', 10);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (4, N'Bajo - Reacción alérgica leve posible', 10);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (5, 'Bajo - Molestia estomacal leve', 5);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (6, N'Bajo - Exposición mínima a radiación', 15);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (7, N'Bajo - Hematoma leve en zona de punción', 15);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (8, 'Medio - Monitoreo constante requerido', 1440);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (9, 'Ninguno', 15);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (10, N'Bajo - Irritación leve del canal auditivo', 15);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (11, N'Bajo - Dolor local o infección secundaria', 20);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (22, 'Bajo - Sensibilidad dental temporal', 45);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (23, N'Medio - Sangrado o infección post-extracción', 30);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (24, N'Medio - Riesgo anestésico estándar', 45);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (25, N'Medio - Riesgo anestésico estándar', 60);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (26, N'Medio - Riesgo anestésico estándar', 30);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (27, N'Medio - Riesgo anestésico estándar', 40);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (28, N'Medio - Riesgo quirúrgico y anestésico modera', 60);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (29, N'Alto - Hemorragia, daño tisular o postoperatorio complejo', 180);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (30, N'Alto - Hemorragia o compromiso de órganos adyacentes', 120);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (31, N'Bajo - Infección localizada', 20);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (32, 'Bajo - Apertura de puntos por movimiento', 30);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (33, N'Bajo - Lesión por presión si queda muy ajustado', 40);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (34, N'Medio - Requiere sedación profunda', 45);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (35, N'Bajo - Resequedad en vías respiratorias', 60);
insert into Procedimiento (ID_Procedimiento, Riesgo, Tiempo_Estimado) values (36, N'Alto - Reacción hemolítica o shock anafiláctico', 120);
-- select * from procedimiento;





GO

--MEDICAMENTO
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (12, 'Oral', '15 mg/kg cada 12 horas', 'No administrar a animales con historial de alergia a la penicilina.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (13, N'Oral / Subcutánea', N'0.2 mg/kg el primer día, luego 0.1 mg/kg', N'Contraindicado en pacientes con úlceras gastrointestinales o deshidratación.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (14, 'Oral', '1 a 2 mg/kg cada 24 horas', 'No interrumpir el tratamiento abruptamente si ha sido prolongado.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (15, 'Oral / Inyectable', '5 mg/kg cada 24 horas', N'Evitar en animales jóvenes en fase de crecimiento por riesgo de daño en cartílagos.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (16, N'Oral / Subcutánea', N'0.2 a 0.4 mg/kg dosis única', N'Altamente tóxico en razas tipo Collie, Pastor Australiano y sus cruzas.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (17, 'Oral', '10 mg/kg cada 24 horas con comida', N'Puede causar esofagitis, administrar siempre acompañada de agua o alimento.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (18, 'Oral', '0.7 a 1 mg/kg cada 24 horas en ayunas', N'El uso prolongado puede afectar la absorción de ciertos nutrientes.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (19, 'Oral / Intravenosa', '15 a 25 mg/kg cada 12 horas', N'Puede generar trastornos neurológicos temporales si se exceden las dosis.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (20, 'Oral / Intramuscular', '2 a 4 mg/kg cada 8 horas', N'Puede provocar sedación profunda, estreñimiento o cambios de conducta leves.', 100);
insert into Medicamento (ID_Medicamento, Via, Dosis_Recomendada, Precauciones, stock) values (21, N'Intramuscular / Subcutánea', '0.5 a 1 ml por cada 10 kg', 'Mantener refrigerado y proteger de la luz solar directa.', 100);
-- select * from Medicamento;




GO

--CITA
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-10', '08:00:00', 'Consultorio A', 'Completada', 1, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-10', '09:00:00', 'Consultorio B', 'Completada', 2, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-11', '10:30:00', 'Consultorio A', 'Completada', 3, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-11', '11:30:00', 'Consultorio C', 'Completada', 4, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-12', '08:30:00', 'Consultorio A', 'Completada', 5, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-12', '14:00:00', 'Consultorio B', 'Completada', 6, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-13', '09:15:00', 'Consultorio C', 'Completada', 7, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-13', '15:00:00', 'Consultorio A', 'Completada', 8, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-14', '10:00:00', 'Consultorio B', 'Completada', 9, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-14', '16:00:00', 'Consultorio C', 'Completada', 10, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-15', '08:00:00', 'Consultorio A', 'Cancelada', 11, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-15', '09:30:00', 'Consultorio B', 'Cancelada', 12, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-16', '11:00:00', 'Consultorio C', 'Completada', 13, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-16', '13:00:00', 'Consultorio A', 'Completada', 14, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-17', '15:30:00', 'Consultorio B', 'Completada', 15, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-18', '08:30:00', 'Consultorio A', 'Programada', 16, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-18', '10:00:00', 'Consultorio C', 'Programada', 17, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-19', '09:00:00', 'Consultorio B', 'Programada', 18, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-19', '11:30:00', 'Consultorio A', 'Programada', 19, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-20', '14:00:00', 'Consultorio C', 'Programada', 20, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-20', '15:30:00', 'Consultorio A', 'Programada', 21, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-21', '08:00:00', 'Consultorio B', 'Programada', 22, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-21', '09:45:00', 'Consultorio C', 'Programada', 23, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-22', '11:00:00', 'Consultorio A', 'Programada', 24, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-22', '13:30:00', 'Consultorio B', 'Programada', 25, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-23', '08:30:00', 'Consultorio C', 'Programada', 26, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-23', '10:30:00', 'Consultorio A', 'Programada', 27, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-24', '14:30:00', 'Consultorio B', 'Programada', 28, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-24', '16:00:00', 'Consultorio C', 'Programada', 29, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-25', '09:00:00', 'Consultorio A', 'Programada', 30, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-25', '11:00:00', 'Consultorio B', 'Programada', 31, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-26', '13:00:00', 'Consultorio C', 'Programada', 32, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-26', '15:00:00', 'Consultorio A', 'Programada', 33, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-27', '08:00:00', 'Consultorio B', 'Programada', 34, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-27', '10:00:00', 'Consultorio C', 'Programada', 35, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-28', '11:30:00', 'Consultorio A', 'Programada', 36, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-28', '14:00:00', 'Consultorio B', 'Programada', 37, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-29', '15:30:00', 'Consultorio C', 'Programada', 38, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-30', '09:00:00', 'Consultorio A', 'Programada', 39, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-01', '13:13:13', 'Consultorio C', 'Programada', 57, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-07', '15:06:30', 'Consultorio A', 'Programada', 42, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-23', '16:16:47', 'Consultorio C', 'Programada', 45, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-26', '09:06:44', 'Consultorio A', 'Programada', 63, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-04', '11:39:45', 'Consultorio A', 'Programada', 65, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-28', '11:05:10', 'Consultorio C', 'Programada', 67, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-06', '17:29:21', 'Consultorio A', 'Programada', 89, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-24', '08:01:31', 'Consultorio B', 'Programada', 67, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-18', '06:49:17', 'Consultorio A', 'Programada', 83, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-17', '12:24:55', 'Consultorio C', 'Programada', 53, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-12', '16:33:00', 'Consultorio A', 'Programada', 78, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-26', '16:13:45', 'Consultorio A', 'Programada', 45, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-05', '05:13:26', 'Consultorio C', 'Programada', 65, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-08', '17:50:32', 'Consultorio A', 'Programada', 56, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-31', '12:12:10', 'Consultorio C', 'Programada', 51, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-23', '09:24:03', 'Consultorio A', 'Programada', 43, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-22', '16:01:24', 'Consultorio B', 'Programada', 94, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-07', '09:45:48', 'Consultorio C', 'Programada', 61, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-17', '17:46:18', 'Consultorio B', 'Programada', 50, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-23', '11:47:44', 'Consultorio A', 'Programada', 46, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-16', '06:35:09', 'Consultorio B', 'Programada', 49, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-21', '13:53:40', 'Consultorio C', 'Programada', 43, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-21', '06:27:09', 'Consultorio A', 'Programada', 94, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-28', '12:01:56', 'Consultorio A', 'Programada', 67, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-22', '15:49:57', 'Consultorio B', 'Programada', 49, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-21', '05:59:19', 'Consultorio B', 'Programada', 95, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-30', '05:27:50', 'Consultorio C', 'Programada', 85, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-27', '10:18:03', 'Consultorio C', 'Programada', 59, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-15', '12:53:36', 'Consultorio C', 'Programada', 55, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-08', '10:07:27', 'Consultorio B', 'Programada', 55, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-25', '05:47:57', 'Consultorio B', 'Programada', 62, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-26', '05:29:12', 'Consultorio C', 'Programada', 65, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-02', '15:43:27', 'Consultorio B', 'Programada', 85, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-27', '09:09:57', 'Consultorio A', 'Programada', 90, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-11', '09:10:48', 'Consultorio A', 'Programada', 57, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-14', '12:46:36', 'Consultorio A', 'Programada', 62, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-04', '09:12:53', 'Consultorio C', 'Programada', 42, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-08', '05:16:56', 'Consultorio B', 'Programada', 75, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-11', '17:11:14', 'Consultorio C', 'Programada', 81, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-06', '15:20:31', 'Consultorio C', 'Programada', 73, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-08', '11:20:43', 'Consultorio C', 'Programada', 91, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-22', '08:19:15', 'Consultorio C', 'Programada', 60, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-20', '13:08:18', 'Consultorio B', 'Programada', 89, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-17', '17:09:23', 'Consultorio C', 'Programada', 72, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-19', '09:33:24', 'Consultorio A', 'Programada', 74, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-14', '10:25:37', 'Consultorio C', 'Programada', 92, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-29', '16:33:38', 'Consultorio C', 'Programada', 69, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-06', '16:52:06', 'Consultorio A', 'Programada', 46, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-19', '17:25:43', 'Consultorio C', 'Programada', 66, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-10', '11:04:02', 'Consultorio B', 'Programada', 66, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-01', '15:22:19', 'Consultorio B', 'Programada', 59, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-04', '14:04:23', 'Consultorio C', 'Programada', 46, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-15', '15:59:49', 'Consultorio B', 'Programada', 57, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-10', '10:31:26', 'Consultorio A', 'Programada', 90, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-05', '05:08:13', 'Consultorio A', 'Programada', 78, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-16', '05:05:29', 'Consultorio B', 'Programada', 40, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-03', '09:15:59', 'Consultorio C', 'Programada', 66, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-15', '05:41:53', 'Consultorio C', 'Programada', 72, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-22', '16:05:56', 'Consultorio C', 'Programada', 90, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-14', '17:22:36', 'Consultorio B', 'Programada', 70, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-10', '15:21:12', 'Consultorio B', 'Programada', 60, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-18', '05:32:50', 'Consultorio A', 'Programada', 52, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-26', '17:40:28', 'Consultorio C', 'Programada', 65, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-13', '10:58:45', 'Consultorio C', 'Programada', 87, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-28', '10:09:20', 'Consultorio B', 'Programada', 67, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-03', '09:25:01', 'Consultorio A', 'Programada', 88, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-01', '05:51:12', 'Consultorio B', 'Programada', 85, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-11', '13:06:31', 'Consultorio A', 'Programada', 57, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-12', '09:54:21', 'Consultorio B', 'Programada', 58, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-19', '07:16:03', 'Consultorio B', 'Programada', 68, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-07', '16:39:14', 'Consultorio B', 'Programada', 72, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-25', '08:35:05', 'Consultorio A', 'Programada', 48, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-05', '10:18:29', 'Consultorio A', 'Programada', 87, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-13', '15:32:40', 'Consultorio A', 'Programada', 94, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-29', '10:10:29', 'Consultorio A', 'Programada', 63, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-26', '05:37:18', 'Consultorio A', 'Programada', 60, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-04', '11:23:24', 'Consultorio C', 'Programada', 48, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-27', '05:06:35', 'Consultorio A', 'Programada', 95, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-09', '07:40:02', 'Consultorio A', 'Programada', 86, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-20', '13:45:57', 'Consultorio C', 'Programada', 63, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-10', '09:58:07', 'Consultorio B', 'Programada', 40, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-30', '07:31:22', 'Consultorio B', 'Programada', 40, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-01', '10:16:59', 'Consultorio A', 'Programada', 56, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-16', '09:27:22', 'Consultorio C', 'Programada', 80, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-24', '05:30:51', 'Consultorio B', 'Programada', 95, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-08', '16:00:43', 'Consultorio B', 'Programada', 88, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-05', '12:56:40', 'Consultorio B', 'Programada', 77, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-17', '10:18:34', 'Consultorio A', 'Programada', 77, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-04-26', '17:52:36', 'Consultorio A', 'Programada', 51, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-15', '15:20:33', 'Consultorio A', 'Programada', 56, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-19', '08:42:33', 'Consultorio C', 'Programada', 92, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-05-29', '06:39:11', 'Consultorio B', 'Programada', 54, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-03', '13:27:57', 'Consultorio C', 'Programada', 47, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-02-21', '14:53:53', 'Consultorio B', 'Programada', 41, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-03-05', '06:27:30', 'Consultorio A', 'Programada', 60, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_Mascota, ID_Veterinario) values ('2026-06-15', '07:50:10', 'Consultorio C', 'Programada', 65, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2019-08-13', '15:23:00', 'Consultorio B', 'Completada', 128, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2019-05-19', '11:33:00', 'Consultorio C', 'Completada', 5, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-11-05', '09:35:00', 'Consultorio A', 'Completada', 101, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-03-02', '19:16:00', 'Consultorio C', 'Completada', 115, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-03-24', '06:13:00', 'Consultorio B', 'Completada', 80, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-06-03', '15:03:00', 'Consultorio C', 'Completada', 61, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-12-11', '11:33:00', 'Consultorio A', 'Completada', 31, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-11-28', '19:03:00', 'Consultorio A', 'Completada', 83, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-04-02', '05:30:00', 'Consultorio A', 'Completada', 80, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-02-27', '10:58:00', 'Consultorio C', 'Completada', 64, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2026-04-10', '10:41:00', 'Consultorio A', 'Completada', 58, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-06-04', '13:22:00', 'Consultorio A', 'Completada', 76, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-07-26', '17:40:00', 'Consultorio C', 'Completada', 14, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-04-30', '15:06:00', 'Consultorio B', 'Completada', 44, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-06-25', '18:36:00', 'Consultorio B', 'Completada', 114, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-10-16', '13:48:00', 'Consultorio B', 'Completada', 9, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-10-24', '19:37:00', 'Consultorio B', 'Completada', 129, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-12-12', '07:51:00', 'Consultorio C', 'Completada', 11, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-01-23', '06:11:00', 'Consultorio B', 'Completada', 18, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-10-12', '07:55:00', 'Consultorio C', 'Completada', 52, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-04-23', '19:41:00', 'Consultorio B', 'Completada', 45, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-02-24', '07:46:00', 'Consultorio C', 'Completada', 110, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-10-30', '17:13:00', 'Consultorio A', 'Completada', 33, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-05-18', '18:31:00', 'Consultorio B', 'Completada', 69, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-07-15', '19:59:00', 'Consultorio B', 'Completada', 8, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-07-24', '11:28:00', 'Consultorio B', 'Completada', 64, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-05-27', '08:23:00', 'Consultorio A', 'Completada', 90, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-07-24', '14:05:00', 'Consultorio C', 'Completada', 26, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-01-24', '14:15:00', 'Consultorio C', 'Completada', 95, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-01-05', '10:39:00', 'Consultorio A', 'Completada', 102, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-08-06', '11:59:00', 'Consultorio B', 'Completada', 8, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-08-10', '11:24:00', 'Consultorio C', 'Completada', 114, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2019-02-18', '17:57:00', 'Consultorio B', 'Completada', 50, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-12-02', '11:03:00', 'Consultorio B', 'Completada', 125, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-01-06', '11:12:00', 'Consultorio C', 'Completada', 112, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-03-03', '08:26:00', 'Consultorio B', 'Completada', 136, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-05-09', '12:31:00', 'Consultorio C', 'Completada', 111, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-06-08', '17:54:00', 'Consultorio B', 'Completada', 101, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-01-16', '17:38:00', 'Consultorio C', 'Completada', 29, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-06-06', '09:48:00', 'Consultorio C', 'Completada', 44, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-09-15', '06:11:00', 'Consultorio B', 'Completada', 90, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-03-24', '13:18:00', 'Consultorio A', 'Completada', 94, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-09-15', '06:51:00', 'Consultorio B', 'Completada', 52, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-03-07', '12:47:00', 'Consultorio C', 'Completada', 6, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-05-19', '11:00:00', 'Consultorio B', 'Completada', 55, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-08-27', '07:43:00', 'Consultorio A', 'Completada', 69, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-02-08', '19:16:00', 'Consultorio A', 'Completada', 14, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-05-30', '14:16:00', 'Consultorio B', 'Completada', 45, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-04-18', '12:28:00', 'Consultorio B', 'Completada', 7, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-11-28', '15:27:00', 'Consultorio B', 'Completada', 138, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-07-12', '06:41:00', 'Consultorio C', 'Completada', 35, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-08-21', '09:37:00', 'Consultorio A', 'Completada', 104, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-07-24', '15:09:00', 'Consultorio C', 'Completada', 32, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2026-04-22', '06:35:00', 'Consultorio B', 'Completada', 133, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-05-16', '07:54:00', 'Consultorio A', 'Completada', 64, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-01-08', '19:47:00', 'Consultorio B', 'Completada', 105, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-09-27', '17:48:00', 'Consultorio B', 'Completada', 31, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-05-21', '13:27:00', 'Consultorio C', 'Completada', 66, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-09-14', '11:29:00', 'Consultorio C', 'Completada', 33, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-08-04', '09:27:00', 'Consultorio B', 'Completada', 54, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-11-02', '06:28:00', 'Consultorio C', 'Completada', 59, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-12-12', '15:57:00', 'Consultorio A', 'Completada', 45, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-11-22', '12:52:00', 'Consultorio C', 'Completada', 140, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-09-22', '13:15:00', 'Consultorio C', 'Completada', 123, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-11-05', '19:24:00', 'Consultorio A', 'Completada', 82, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-03-25', '06:48:00', 'Consultorio A', 'Completada', 106, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-08-13', '15:13:00', 'Consultorio A', 'Completada', 88, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-11-15', '07:52:00', 'Consultorio B', 'Completada', 65, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-04-24', '18:58:00', 'Consultorio A', 'Completada', 33, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-05-24', '11:21:00', 'Consultorio C', 'Completada', 45, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-05-21', '14:21:00', 'Consultorio A', 'Completada', 136, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-04-25', '11:28:00', 'Consultorio A', 'Completada', 19, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-02-01', '16:48:00', 'Consultorio C', 'Completada', 38, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-05-19', '18:58:00', 'Consultorio A', 'Completada', 10, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-11-14', '14:29:00', 'Consultorio C', 'Completada', 12, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-09-07', '10:24:00', 'Consultorio C', 'Completada', 60, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-07-21', '05:44:00', 'Consultorio C', 'Completada', 69, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-11-28', '07:06:00', 'Consultorio B', 'Completada', 90, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2018-11-16', '17:43:00', 'Consultorio C', 'Completada', 56, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-08-02', '09:18:00', 'Consultorio A', 'Completada', 83, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-05-31', '15:14:00', 'Consultorio B', 'Completada', 110, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-07-25', '06:19:00', 'Consultorio A', 'Completada', 113, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-01-08', '18:31:00', 'Consultorio B', 'Completada', 14, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-05-19', '12:44:00', 'Consultorio C', 'Completada', 124, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-06-27', '14:42:00', 'Consultorio B', 'Completada', 88, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-12-14', '08:25:00', 'Consultorio B', 'Completada', 114, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-01-05', '07:01:00', 'Consultorio A', 'Completada', 61, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2022-11-12', '16:39:00', 'Consultorio C', 'Completada', 90, 3);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-04-11', '13:18:00', 'Consultorio C', 'Completada', 79, 7);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2025-10-07', '13:32:00', 'Consultorio C', 'Completada', 37, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-07-06', '17:28:00', 'Consultorio B', 'Completada', 123, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-02-08', '11:28:00', 'Consultorio A', 'Completada', 39, 9);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2016-05-03', '05:48:00', 'Consultorio B', 'Completada', 47, 5);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2023-09-10', '18:58:00', 'Consultorio A', 'Completada', 12, 2);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2017-11-11', '14:02:00', 'Consultorio A', 'Completada', 77, 1);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2020-09-09', '06:23:00', 'Consultorio B', 'Completada', 17, 6);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2024-03-31', '16:54:00', 'Consultorio C', 'Completada', 55, 4);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2019-11-27', '15:15:00', 'Consultorio B', 'Completada', 93, 10);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2015-10-11', '09:53:00', 'Consultorio A', 'Completada', 77, 8);
insert into Cita (Fecha, Hora, Consultorio, Estado, ID_mascota, ID_Veterinario) values ('2021-09-21', '06:56:00', 'Consultorio A', 'Completada', 9, 8);


-- select * from cita;




GO

--DIAGNOSTICO
insert into diagnostico (descripcion,id_cita) values ('revision general sin hallazgos relevantes',1);
insert into diagnostico (descripcion,id_cita) values ('dermatitis alergica leve',2);
insert into diagnostico (descripcion,id_cita) values ('otitis externa',3);
insert into diagnostico (descripcion,id_cita) values ('gastroenteritis leve',4);
insert into diagnostico (descripcion,id_cita) values ('parasitosis intestinal',5);
insert into diagnostico (descripcion,id_cita) values ('conjuntivitis bacteriana',6);
insert into diagnostico (descripcion,id_cita) values ('fractura en proceso de recuperacion',7);
insert into diagnostico (descripcion,id_cita) values ('gingivitis moderada',8);
insert into diagnostico (descripcion,id_cita) values ('obesidad grado i',9);
insert into diagnostico (descripcion,id_cita) values ('infeccion respiratoria superior',10);
insert into diagnostico (descripcion,id_cita) values ('deshidratacion leve',13);
insert into diagnostico (descripcion,id_cita) values ('herida superficial en extremidad',14);
insert into diagnostico (descripcion,id_cita) values ('inflamacion articular',15);
insert into diagnostico (descripcion,id_cita) values ('acumulacion de sarro dental',8);
insert into diagnostico (descripcion,id_cita) values ('sobrepeso',9);
insert into diagnostico (descripcion,id_cita) values ('irritacion ocular leve',6);
insert into diagnostico (descripcion,id_cita) values ('dolor muscular',15);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 158);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 151);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 155);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 165);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 173);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 149);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 207);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 163);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 149);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 155);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 228);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 174);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 199);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 218);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 136);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 200);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 184);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 144);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 165);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 214);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 153);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 235);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 234);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 155);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 208);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 171);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 147);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 177);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 200);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 163);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 179);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 208);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 208);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 199);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 197);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 207);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 232);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 174);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 136);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 145);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 213);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 186);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 214);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 165);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 173);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 149);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 140);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 220);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 183);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 226);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 191);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 234);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 202);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 185);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 197);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 215);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 213);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 150);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 198);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 156);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 189);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 178);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 189);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 189);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 138);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 221);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 191);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 211);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 154);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 137);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 177);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 171);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 204);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 235);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 222);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 148);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 209);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 219);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 162);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 227);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 144);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 235);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 203);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 193);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 198);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 171);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 235);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 191);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 188);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 214);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 167);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 173);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 152);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 195);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 146);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 227);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 184);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 187);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 230);
insert into Diagnostico (Descripcion, ID_Cita) values ('parasitosis intestinal', 165);
--select * from diagnostico;




GO

--DIAGNOSTICO-PROCEDIMIENTO
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (10,3);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (11,12);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (22,8);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (22,14);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (29,7);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (33,7);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (34,4);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (34,5);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (35,10);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (35,11);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (32,12);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (28,12);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (29,13);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (35,16);
insert into diagnostico_procedimiento (id_procedimiento,id_diagnostico) values (28,17);
-- Nuevos datos agregados utilizando select
insert into diagnostico_procedimiento (id_diagnostico, id_procedimiento)
select id_diagnostico, 5
from diagnostico
where id_diagnostico between 18 and 118;
--select * from diagnostico_procedimiento;




GO

--TRATAMIENTO
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','250 mg','2026-07-15','control preventivo tras la consulta',1,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','0.1 mg/kg','2026-07-10','reducir la inflamacion cutanea',2,13);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','5 gotas','2026-07-08','tratamiento para la otitis externa',3,15);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','10 mg/kg','2026-07-12','antibiotico para infeccion auditiva',3,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 8 horas','15 mg/kg','2026-07-14','control de gastroenteritis',4,19);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('dosis unica','0.2 mg/kg','2026-06-20','desparasitacion interna',5,16);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','10 mg/kg','2026-07-16','control de infeccion ocular',6,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','2 mg/kg','2026-07-20','analgesico para recuperacion',7,20);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','1 mg/kg','2026-07-18','antiinflamatorio durante recuperacion',7,13);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','10 mg/kg','2026-07-25','tratamiento posterior a limpieza dental',8,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','segun dieta','2026-09-01','plan nutricional y control de peso',9,21);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','10 mg/kg','2026-07-15','tratamiento de infeccion respiratoria',10,17);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','20 mg','2026-07-15','protector gastrico durante tratamiento',10,18);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 8 horas','rehidratacion oral','2026-06-25','recuperacion por deshidratacion',11,21);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','10 mg/kg','2026-07-10','prevencion de infeccion en herida',12,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','0.1 mg/kg','2026-07-10','disminuir inflamacion de la herida',12,13);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','1 mg/kg','2026-07-20','control del dolor articular',13,13);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','10 mg/kg','2026-07-18','profilaxis despues de limpieza dental',14,12);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','segun dieta','2026-09-15','control alimenticio para sobrepeso',15,21);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','2 gotas','2026-07-05','tratamiento para irritacion ocular',16,15);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 12 horas','2 mg/kg','2026-07-12','analgesico para dolor muscular',17,20);
insert into tratamiento (frecuencia,dosis,vigencia,descripcion,id_diagnostico,id_medicamento) values ('cada 24 horas','1 mg/kg','2026-07-12','antiinflamatorio complementario',17,13);
--select * from tratamiento;




GO

--FACTURA
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-10',0,1,1);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-10',0,2,2);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-11',0,3,3);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-11',0,4,4);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-12',0,5,5);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-12',0,6,23);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-13',0,7,6);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-13',0,8,7);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-14',0,9,8);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-14',0,10,9);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-16',0,13,2);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-16',0,14,12);
insert into factura (fecha,monto,id_cita,id_propietario) values ('2026-05-17',0,15,13);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-03-29', 138, 104, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-08-09', 139, 88, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-11-03', 140, 86, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2015-05-31', 141, 95, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-08-15', 142, 12, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-05-29', 143, 114, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2016-07-04', 144, 86, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-03-14', 145, 108, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-12-28', 146, 87, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-05-12', 147, 135, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-04-25', 148, 12, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-03-20', 149, 96, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-08-06', 150, 84, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-01-31', 151, 8, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-05-31', 152, 113, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-02-11', 153, 10, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-01-10', 154, 16, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-06-19', 155, 62, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-08-08', 156, 57, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-12-22', 157, 87, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-07-22', 158, 24, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-09-05', 159, 28, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-12-12', 160, 7, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-10-10', 161, 108, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-03-11', 162, 53, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-06-10', 163, 7, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-08-07', 164, 68, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-04-02', 165, 90, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-04-09', 166, 7, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-03-29', 167, 84, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-11-17', 168, 132, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-09-19', 169, 69, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-10-20', 170, 114, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-02-19', 171, 36, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-03-13', 172, 127, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-12-13', 173, 104, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-06-03', 174, 10, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-03-21', 175, 96, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-04-27', 176, 53, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-11-06', 177, 83, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-08-08', 178, 62, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-06-14', 179, 23, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-01-13', 180, 56, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-03-11', 181, 28, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-10-18', 182, 12, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2016-11-13', 183, 57, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-11-30', 184, 6, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-03-08', 185, 115, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-04-06', 186, 16, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-08-28', 187, 114, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-02-16', 188, 13, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-12-20', 189, 140, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2015-12-26', 190, 108, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-12-12', 191, 134, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-07-03', 192, 12, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-09-06', 193, 96, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-05-18', 194, 24, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-10-12', 195, 102, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-08-11', 196, 71, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2015-08-24', 197, 57, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2026-03-22', 198, 38, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-11-16', 199, 33, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-08-02', 200, 105, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-03-24', 201, 68, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-05-27', 202, 102, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-08-17', 203, 99, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-06-18', 204, 24, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-10-02', 205, 57, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-04-06', 206, 36, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2016-02-15', 207, 3, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-05-23', 208, 19, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-02-03', 209, 9, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2018-09-24', 210, 11, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2017-12-07', 211, 129, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-06-04', 212, 28, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-02-19', 213, 53, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2026-04-04', 214, 107, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-04-14', 215, 114, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-08-06', 216, 87, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-08-06', 217, 131, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-02-26', 218, 12, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2023-04-30', 219, 127, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-03-02', 220, 102, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-09-12', 221, 84, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2016-08-23', 222, 95, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-01-25', 223, 53, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2015-03-25', 224, 79, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-03-21', 225, 22, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2016-04-10', 226, 33, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2022-05-25', 227, 20, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2019-04-24', 228, 94, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2021-01-05', 229, 11, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-10-29', 230, 105, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-02-20', 231, 15, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2025-10-02', 232, 56, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2020-04-05', 233, 74, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2024-04-18', 234, 105, 8);
insert into factura (Fecha, ID_Cita, ID_Propietario, monto) values ('2026-02-04', 235, 8, 8);
-- select * from factura;








GO

--DETALLE FACTURA
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,1,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,2,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (15,1,2,13);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,3,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (22,1,10,10);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (12,1,3,11);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,4,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (220,1,4,34);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (14,1,4,18);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,5,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (10,1,5,15);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,6,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (12,1,6,11);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,7,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (700,1,7,29);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (100,1,7,33);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (16,1,7,20);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,8,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (90,1,8,22);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (12,1,8,11);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,9,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,10,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (45,1,10,35);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (19,1,10,17);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,11,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (120,1,11,32);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (22,1,11,11);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (12,1,11,11);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,12,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (250,1,12,28);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (18,1,12,12);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (20,1,13,1);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (90,1,13,22);
insert into detalle_factura (precio_unitario,cantidad,num_factura,id_item) values (12,1,13,11);
-- Nuevos datos utilizando select
insert into detalle_factura (precio_unitario, cantidad, num_factura, id_item)
select
    8, 1, num_factura, 5
from factura
where num_factura between 14 and 114;
-- select * from detalle_factura;

GO

-- PAGO (poblacion automatica y aleatoria)
-- Se genera primero el numero aleatorio (1-4) UNA sola vez por factura en una tabla temporal.
-- (Usar CHOOSE(... NEWID() ...) directo falla: CHOOSE se expande a CASE y re-evalua NEWID().)
SELECT Num_Factura,
       ABS(CHECKSUM(NEWID())) % 4 + 1 AS n,
       ABS(CHECKSUM(NEWID())) AS r_fecha
INTO   #rnd
FROM   Factura;
GO

INSERT INTO Pago (Monto, Metodo_Pago, Num_Factura)
SELECT f.Monto,
       CHOOSE(r.n, 'Efectivo', 'Transferencia', 'Bitcoin', 'Tarjeta'),
       f.Num_Factura
FROM   Factura f
JOIN   #rnd r ON r.Num_Factura = f.Num_Factura
WHERE  f.Monto > 0
  AND  f.Num_Factura < 14;      -- las facturas 14+ se pagan abajo (con fecha aleatoria)
GO

-- Pago de las facturas 14+ (una sola vez, con metodo y fecha al azar).
-- Nota: el original pagaba estas facturas dos veces; el trigger de sobrepago lo bloquearia.
DECLARE @ini DATE = DATEFROMPARTS(2015, 3, 1);
DECLARE @fin DATE = DATEFROMPARTS(2026, 6, 19);

INSERT INTO Pago (Num_Factura, Monto, Fecha_Pago, Metodo_Pago)
SELECT f.Num_Factura,
       f.Monto,                 -- pago completo: antes era un 2o pago de 8 duplicado
       DATEADD(DAY, r.r_fecha % (DATEDIFF(DAY, @ini, @fin) + 1), @ini),
       CHOOSE((r.r_fecha / 7) % 4 + 1, 'Efectivo', 'Transferencia', 'Bitcoin', 'Tarjeta')
FROM   Factura f
JOIN   #rnd r ON r.Num_Factura = f.Num_Factura
WHERE  f.Num_Factura BETWEEN 14 AND 114;
GO

DROP TABLE #rnd;
GO

-- SELECT * FROM Pago;