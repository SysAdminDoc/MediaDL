// ==UserScript==
// @name         MediaDL - Universal Media Downloader
// @namespace    https://github.com/SysAdminDoc/MediaDL
// @version      1.0.0
// @description  Download videos and extract audio from 1800+ sites - powered by yt-dlp
// @author       SysAdminDoc
// @license      MIT
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' rx='20' fill='%2300b894'/%3E%3Ctext x='50' y='68' font-size='50' font-weight='bold' text-anchor='middle' fill='%230a0a0a'%3EM%3C/text%3E%3C/svg%3E
// @homepageURL  https://github.com/SysAdminDoc/MediaDL
// @supportURL   https://github.com/SysAdminDoc/MediaDL/issues
// @updateURL    https://github.com/SysAdminDoc/MediaDL/raw/main/MediaDL.user.js
// @downloadURL  https://github.com/SysAdminDoc/MediaDL/raw/main/MediaDL.user.js
// @grant        GM_addStyle
// @run-at       document-idle
// @noframes
// @match        *://*.youtube.com/*
// @match        *://*.youtu.be/*
// @match        *://*.googlevideo.com/*
// @match        *://*.10play.com.au/*
// @match        *://*.17.live/*
// @match        *://*.1news.co.nz/*
// @match        *://*.1tv.ru/*
// @match        *://*.20min.ch/*
// @match        *://*.247sports.com/*
// @match        *://*.24tv.ua/*
// @match        *://*.3qsdn.com/*
// @match        *://*.3sat.de/*
// @match        *://*.4tube.com/*
// @match        *://*.56.com/*
// @match        *://*.7plus.com.au/*
// @match        *://*.8tracks.com/*
// @match        *://*.9gag.com/*
// @match        *://*.9news.com.au/*
// @match        *://*.9now.com.au/*
// @match        *://*.abc.net.au/*
// @match        *://*.abcnews.go.com/*
// @match        *://*.abcotvs.com/*
// @match        *://*.abema.tv/*
// @match        *://*.academicearth.org/*
// @match        *://*.acast.com/*
// @match        *://*.acfun.cn/*
// @match        *://*.adn.com/*
// @match        *://*.animationdigitalnetwork.fr/*
// @match        *://*.adobeconnect.com/*
// @match        *://*.tv.adobe.com/*
// @match        *://*.adultswim.com/*
// @match        *://*.aetv.com/*
// @match        *://*.history.com/*
// @match        *://*.lifetime.com/*
// @match        *://*.fyi.tv/*
// @match        *://*.historyvault.com/*
// @match        *://*.aeon.co/*
// @match        *://*.airtv.net/*
// @match        *://*.aitube.kz/*
// @match        *://*.alibaba.com/*
// @match        *://*.aliexpress.com/*
// @match        *://*.aljazeera.com/*
// @match        *://*.allocine.fr/*
// @match        *://*.allstar.gg/*
// @match        *://*.alphaporno.com/*
// @match        *://*.alsace20.tv/*
// @match        *://*.altcensored.com/*
// @match        *://*.alura.com.br/*
// @match        *://*.amadeustv.com/*
// @match        *://*.amara.org/*
// @match        *://*.amazon.com/*
// @match        *://*.amazon.in/*
// @match        *://*.amc.com/*
// @match        *://*.americastestkitchen.com/*
// @match        *://*.anchor.fm/*
// @match        *://*.npo.nl/*
// @match        *://*.angel.com/*
// @match        *://*.animalplanet.com/*
// @match        *://*.ant1news.gr/*
// @match        *://*.antenna.gr/*
// @match        *://*.aol.com/*
// @match        *://*.apa.at/*
// @match        *://*.aparat.com/*
// @match        *://*.apple.com/*
// @match        *://*.appledaily.com/*
// @match        *://*.archive.org/*
// @match        *://*.ard.de/*
// @match        *://*.ardmediathek.de/*
// @match        *://*.ardaudiothek.de/*
// @match        *://*.art19.com/*
// @match        *://*.arte.tv/*
// @match        *://*.asobichannel.com/*
// @match        *://*.asobistage.com/*
// @match        *://*.atresplayer.com/*
// @match        *://*.atv.at/*
// @match        *://*.audimedia.tv/*
// @match        *://*.audioboom.com/*
// @match        *://*.audiodraft.com/*
// @match        *://*.audiomack.com/*
// @match        *://*.audius.co/*
// @match        *://*.awaan.ae/*
// @match        *://*.axs.tv/*
// @match        *://*.azmedien.ch/*
// @match        *://*.baidu.com/*
// @match        *://*.banbye.com/*
// @match        *://*.bandcamp.com/*
// @match        *://*.bandlab.com/*
// @match        *://*.banned.video/*
// @match        *://*.bbc.com/*
// @match        *://*.bbc.co.uk/*
// @match        *://*.bbvtv.ch/*
// @match        *://*.beacontv.com/*
// @match        *://*.beatbump.ml/*
// @match        *://*.beatport.com/*
// @match        *://*.beeg.com/*
// @match        *://*.behindkink.com/*
// @match        *://*.berufe.tv/*
// @match        *://*.bet.com/*
// @match        *://*.bfi.org.uk/*
// @match        *://*.bfmtv.com/*
// @match        *://*.bibeltv.de/*
// @match        *://*.bigflix.com/*
// @match        *://*.bigo.tv/*
// @match        *://*.bild.de/*
// @match        *://*.bilibili.com/*
// @match        *://*.biobiochiletv.cl/*
// @match        *://*.biography.com/*
// @match        *://*.bitchute.com/*
// @match        *://*.bitmovin.com/*
// @match        *://*.blackboardcollaborate.com/*
// @match        *://*.bleacherreport.com/*
// @match        *://*.blerp.com/*
// @match        *://*.blogger.com/*
// @match        *://*.blogspot.com/*
// @match        *://*.bloomberg.com/*
// @match        *://*.bluesky.app/*
// @match        *://*.bsky.app/*
// @match        *://*.bokecc.com/*
// @match        *://*.bongacams.com/*
// @match        *://*.boosty.to/*
// @match        *://*.bostonglobe.com/*
// @match        *://*.box.com/*
// @match        *://*.boxcast.tv/*
// @match        *://*.bpb.de/*
// @match        *://*.br.de/*
// @match        *://*.brainpop.com/*
// @match        *://*.bravotv.com/*
// @match        *://*.breitbart.com/*
// @match        *://*.brightcove.com/*
// @match        *://*.brilliantpala.org/*
// @match        *://*.bt.no/*
// @match        *://*.btvplus.bg/*
// @match        *://*.bundesliga.com/*
// @match        *://*.bundestag.de/*
// @match        *://*.bunnycdn.com/*
// @match        *://*.businessinsider.com/*
// @match        *://*.buzzfeed.com/*
// @match        *://*.byutv.org/*
// @match        *://*.caffeine.tv/*
// @match        *://*.callin.com/*
// @match        *://*.caltrans.ca.gov/*
// @match        *://*.cam4.com/*
// @match        *://*.camdemy.com/*
// @match        *://*.camfm.co.uk/*
// @match        *://*.cammodels.com/*
// @match        *://*.camsoda.com/*
// @match        *://*.camtasia.com/*
// @match        *://*.canal1.com.co/*
// @match        *://*.canalalpha.ch/*
// @match        *://*.canalc2.tv/*
// @match        *://*.canalplus.com/*
// @match        *://*.mycanal.fr/*
// @match        *://*.canalsurmas.es/*
// @match        *://*.caracoltv.com/*
// @match        *://*.cbc.ca/*
// @match        *://*.cbsnews.com/*
// @match        *://*.cbs.com/*
// @match        *://*.cbslocal.com/*
// @match        *://*.cbssports.com/*
// @match        *://*.ccma.cat/*
// @match        *://*.tv3.cat/*
// @match        *://*.cctv.com/*
// @match        *://*.cda.pl/*
// @match        *://*.cellebrite.com/*
// @match        *://*.ceskatelevize.cz/*
// @match        *://*.cgtn.com/*
// @match        *://*.charlierose.com/*
// @match        *://*.chaturbate.com/*
// @match        *://*.chilloutzone.net/*
// @match        *://*.chzzk.naver.com/*
// @match        *://*.cielotv.it/*
// @match        *://*.cinemax.com/*
// @match        *://*.cinetecamilano.it/*
// @match        *://*.cineverse.com/*
// @match        *://*.ciscolive.com/*
// @match        *://*.webex.com/*
// @match        *://*.cjsw.com/*
// @match        *://*.clipchamp.com/*
// @match        *://*.clippituser.tv/*
// @match        *://*.cliprs.com/*
// @match        *://*.closertotruth.com/*
// @match        *://*.cloudflarestream.com/*
// @match        *://*.cloudycdn.com/*
// @match        *://*.clubic.com/*
// @match        *://*.clyp.it/*
// @match        *://*.cnbc.com/*
// @match        *://*.cnn.com/*
// @match        *://*.cnnindonesia.com/*
// @match        *://*.cc.com/*
// @match        *://*.comedycentral.com/*
// @match        *://*.condenast.com/*
// @match        *://*.wired.com/*
// @match        *://*.gq.com/*
// @match        *://*.vogue.com/*
// @match        *://*.vanityfair.com/*
// @match        *://*.newyorker.com/*
// @match        *://*.architecturaldigest.com/*
// @match        *://*.bonappetit.com/*
// @match        *://*.glamour.com/*
// @match        *://*.allure.com/*
// @match        *://*.epicurious.com/*
// @match        *://*.self.com/*
// @match        *://*.teenvogue.com/*
// @match        *://*.arstechnica.com/*
// @match        *://*.contv.com/*
// @match        *://*.cookingchanneltv.com/*
// @match        *://*.corusent.com/*
// @match        *://*.coub.com/*
// @match        *://*.cozytv.com/*
// @match        *://*.cp24.com/*
// @match        *://*.cpac.ca/*
// @match        *://*.cracked.com/*
// @match        *://*.craftsy.com/*
// @match        *://*.crooksandliars.com/*
// @match        *://*.crowdbunker.com/*
// @match        *://*.crtvg.es/*
// @match        *://*.c-span.org/*
// @match        *://*.cts.com.tw/*
// @match        *://*.ctvnews.ca/*
// @match        *://*.ntv.co.jp/*
// @match        *://*.cultureunplugged.com/*
// @match        *://*.curiositystream.com/*
// @match        *://*.cybrary.it/*
// @match        *://*.dacast.com/*
// @match        *://*.dagelijksekost.een.be/*
// @match        *://*.dailymail.co.uk/*
// @match        *://*.dailymotion.com/*
// @match        *://*.dailywire.com/*
// @match        *://*.damtomo.jp/*
// @match        *://*.dangalplay.com/*
// @match        *://*.daum.net/*
// @match        *://*.daystar.com/*
// @match        *://*.dbtv.no/*
// @match        *://*.dctp.tv/*
// @match        *://*.democracynow.org/*
// @match        *://*.destinationamerica.com/*
// @match        *://*.detik.com/*
// @match        *://*.2m.ma/*
// @match        *://*.dhm.de/*
// @match        *://*.digitalconcerthall.com/*
// @match        *://*.digitallyspeaking.com/*
// @match        *://*.digiteka.com/*
// @match        *://*.digiview.com/*
// @match        *://*.discogs.com/*
// @match        *://*.discoverylife.com/*
// @match        *://*.discovery.de/*
// @match        *://*.discoveryplus.com/*
// @match        *://*.disney.com/*
// @match        *://*.deutschlandfunk.de/*
// @match        *://*.dlive.tv/*
// @match        *://*.douyin.com/*
// @match        *://*.douyu.com/*
// @match        *://*.dplay.com/*
// @match        *://*.dr.dk/*
// @match        *://*.drooble.com/*
// @match        *://*.dropbox.com/*
// @match        *://*.dropout.tv/*
// @match        *://*.drtalks.com/*
// @match        *://*.drtuber.com/*
// @match        *://*.dtube.video/*
// @match        *://*.duboku.io/*
// @match        *://*.dumpert.nl/*
// @match        *://*.duoplay.ee/*
// @match        *://*.aktualne.cz/*
// @match        *://*.dw.com/*
// @match        *://*.dzen.ru/*
// @match        *://*.ebaumsworld.com/*
// @match        *://*.ebay.com/*
// @match        *://*.egghead.io/*
// @match        *://*.eggs.mu/*
// @match        *://*.1und1.tv/*
// @match        *://*.eitb.tv/*
// @match        *://*.elementor.com/*
// @match        *://*.elonet.fi/*
// @match        *://*.elpais.com/*
// @match        *://*.eltrecetv.com.ar/*
// @match        *://*.embed.ly/*
// @match        *://*.empflix.com/*
// @match        *://*.epicon.in/*
// @match        *://*.epidemicsound.com/*
// @match        *://*.eplus.jp/*
// @match        *://*.epochtimes.com/*
// @match        *://*.eporner.com/*
// @match        *://*.erocast.me/*
// @match        *://*.eroprofile.com/*
// @match        *://*.err.ee/*
// @match        *://*.ertflix.gr/*
// @match        *://*.ert.gr/*
// @match        *://*.espn.com/*
// @match        *://*.espncricinfo.com/*
// @match        *://*.ettu.tv/*
// @match        *://*.europa.eu/*
// @match        *://*.europarl.europa.eu/*
// @match        *://*.europeantour.com/*
// @match        *://*.eurosport.com/*
// @match        *://*.euscreen.eu/*
// @match        *://*.ewe.tv/*
// @match        *://*.expressen.se/*
// @match        *://*.eyedo.tv/*
// @match        *://*.facebook.com/*
// @match        *://*.fb.com/*
// @match        *://*.fb.watch/*
// @match        *://*.fancode.com/*
// @match        *://*.fathom.video/*
// @match        *://*.faulio.com/*
// @match        *://*.faz.net/*
// @match        *://*.fc2.com/*
// @match        *://*.fczenit.com/*
// @match        *://*.fifa.com/*
// @match        *://*.filmon.com/*
// @match        *://*.filmweb.pl/*
// @match        *://*.fivethirtyeight.com/*
// @match        *://*.5-tv.ru/*
// @match        *://*.flickr.com/*
// @match        *://*.floatplane.com/*
// @match        *://*.ft.dk/*
// @match        *://*.foodnetwork.com/*
// @match        *://*.footyroom.com/*
// @match        *://*.formula1.com/*
// @match        *://*.fox.com/*
// @match        *://*.fox9.com/*
// @match        *://*.foxnews.com/*
// @match        *://*.foxsports.com/*
// @match        *://*.fptplay.vn/*
// @match        *://*.francaisfacile.rfi.fr/*
// @match        *://*.franceculture.fr/*
// @match        *://*.franceinter.fr/*
// @match        *://*.france.tv/*
// @match        *://*.francetvinfo.fr/*
// @match        *://*.freesound.org/*
// @match        *://*.freespeech.org/*
// @match        *://*.freetv.com/*
// @match        *://*.frontendmasters.com/*
// @match        *://*.fujitv.co.jp/*
// @match        *://*.funk.net/*
// @match        *://*.funker530.com/*
// @match        *://*.fux.com/*
// @match        *://*.fuyin.tv/*
// @match        *://*.gab.com/*
// @match        *://*.tv.gab.com/*
// @match        *://*.gaia.com/*
// @match        *://*.gamedevtv.com/*
// @match        *://*.gamejolt.com/*
// @match        *://*.gamespot.com/*
// @match        *://*.gamestar.de/*
// @match        *://*.gaskrank.tv/*
// @match        *://*.gazeta.ru/*
// @match        *://*.gbnews.com/*
// @match        *://*.gdcvault.com/*
// @match        *://*.gedidigital.it/*
// @match        *://*.gem.cbc.ca/*
// @match        *://*.genius.com/*
// @match        *://*.germanupa.de/*
// @match        *://*.getcourse.ru/*
// @match        *://*.gettr.com/*
// @match        *://*.giantbomb.com/*
// @match        *://*.glattvision.tv/*
// @match        *://*.glide.me/*
// @match        *://*.globalplayer.com/*
// @match        *://*.globo.com/*
// @match        *://*.glomex.com/*
// @match        *://*.gmanetwork.com/*
// @match        *://*.go.com/*
// @match        *://*.godiscovery.com/*
// @match        *://*.godresource.com/*
// @match        *://*.godtube.com/*
// @match        *://*.gofile.io/*
// @match        *://*.golem.de/*
// @match        *://*.goodgame.ru/*
// @match        *://*.podcasts.google.com/*
// @match        *://*.drive.google.com/*
// @match        *://*.gopro.com/*
// @match        *://*.goshgay.com/*
// @match        *://*.gotostage.com/*
// @match        *://*.nvidia.com/*
// @match        *://*.graspop.be/*
// @match        *://*.gronkh.tv/*
// @match        *://*.groupon.com/*
// @match        *://*.harpodeon.com/*
// @match        *://*.hbo.com/*
// @match        *://*.hearthis.at/*
// @match        *://*.heise.de/*
// @match        *://*.hellporno.com/*
// @match        *://*.hetklokhuis.nl/*
// @match        *://*.hgtv.com/*
// @match        *://*.hidive.com/*
// @match        *://*.historicfilms.com/*
// @match        *://*.hitrecord.org/*
// @match        *://*.hketv.hk/*
// @match        *://*.hollywoodreporter.com/*
// @match        *://*.holodex.net/*
// @match        *://*.hotnewhiphop.com/*
// @match        *://*.hotstar.com/*
// @match        *://*.jiocinema.com/*
// @match        *://*.hr-fernsehen.de/*
// @match        *://*.hrti.hr/*
// @match        *://*.hse.de/*
// @match        *://*.huajiao.com/*
// @match        *://*.huffpost.com/*
// @match        *://*.hungama.com/*
// @match        *://*.huya.com/*
// @match        *://*.hypem.com/*
// @match        *://*.hytale.com/*
// @match        *://*.icareus.com/*
// @match        *://*.idagio.com/*
// @match        *://*.idolplus.com/*
// @match        *://*.iflix.com/*
// @match        *://*.ign.com/*
// @match        *://*.iheart.com/*
// @match        *://*.ilpost.it/*
// @match        *://*.iltalehti.fi/*
// @match        *://*.imdb.com/*
// @match        *://*.imgur.com/*
// @match        *://*.ina.fr/*
// @match        *://*.inc.com/*
// @match        *://*.indavideo.hu/*
// @match        *://*.infoq.com/*
// @match        *://*.instagram.com/*
// @match        *://*.internazionale.it/*
// @match        *://*.internetvideoarchive.com/*
// @match        *://*.investigationdiscovery.com/*
// @match        *://*.iprima.cz/*
// @match        *://*.iq.com/*
// @match        *://*.iqiyi.com/*
// @match        *://*.islamchannel.tv/*
// @match        *://*.israelnationalnews.com/*
// @match        *://*.itprotv.com/*
// @match        *://*.itv.com/*
// @match        *://*.ivi.ru/*
// @match        *://*.ivideon.com/*
// @match        *://*.ivoox.com/*
// @match        *://*.ivxplayer.com/*
// @match        *://*.iwara.tv/*
// @match        *://*.ixigua.com/*
// @match        *://*.izlesene.com/*
// @match        *://*.jamendo.com/*
// @match        *://*.jeuxvideo.com/*
// @match        *://*.jiosaavn.com/*
// @match        *://*.joj.sk/*
// @match        *://*.jove.com/*
// @match        *://*.jstream.jp/*
// @match        *://*.jtbc.co.kr/*
// @match        *://*.jwplatform.com/*
// @match        *://*.kakao.com/*
// @match        *://*.kaltura.com/*
// @match        *://*.kankanews.com/*
// @match        *://*.karaoketv.co.il/*
// @match        *://*.katsomo.fi/*
// @match        *://*.kelbyone.com/*
// @match        *://*.kenh14.vn/*
// @match        *://*.khanacademy.org/*
// @match        *://*.kick.com/*
// @match        *://*.kicker.de/*
// @match        *://*.kickstarter.com/*
// @match        *://*.kika.de/*
// @match        *://*.kinja.com/*
// @match        *://*.kinopoisk.ru/*
// @match        *://*.kommune.tv/*
// @match        *://*.kompas.com/*
// @match        *://*.koo.com/*
// @match        *://*.krasview.ru/*
// @match        *://*.kth.se/*
// @match        *://*.ku6.com/*
// @match        *://*.kukululive.com/*
// @match        *://*.kuwo.cn/*
// @match        *://*.la7.it/*
// @match        *://*.laracasts.com/*
// @match        *://*.last.fm/*
// @match        *://*.laxarxames.cat/*
// @match        *://*.odysee.com/*
// @match        *://*.lci.fr/*
// @match        *://*.lcp.fr/*
// @match        *://*.le.com/*
// @match        *://*.learningonscreen.ac.uk/*
// @match        *://*.lecture2go.de/*
// @match        *://*.lecturio.com/*
// @match        *://*.lecturio.de/*
// @match        *://*.lefigaro.fr/*
// @match        *://*.lego.com/*
// @match        *://*.lemonde.fr/*
// @match        *://*.lenta.ru/*
// @match        *://*.libsyn.com/*
// @match        *://*.life.ru/*
// @match        *://*.likee.video/*
// @match        *://*.linkedin.com/*
// @match        *://*.liputan6.com/*
// @match        *://*.listennotes.com/*
// @match        *://*.litv.tv/*
// @match        *://*.livejournal.com/*
// @match        *://*.livestream.com/*
// @match        *://*.livestreamfails.com/*
// @match        *://*.lnk.lt/*
// @match        *://*.loc.gov/*
// @match        *://*.loco.gg/*
// @match        *://*.loom.com/*
// @match        *://*.lovehomeporn.com/*
// @match        *://*.lrt.lt/*
// @match        *://*.lsm.lv/*
// @match        *://*.lumni.fr/*
// @match        *://*.lynda.com/*
// @match        *://*.maariv.co.il/*
// @match        *://*.magellantv.com/*
// @match        *://*.magentamusik.de/*
// @match        *://*.mail.ru/*
// @match        *://*.mainstreaming.com/*
// @match        *://*.mangomolo.com/*
// @match        *://*.mgtv.com/*
// @match        *://*.manoto.tv/*
// @match        *://*.manyvids.com/*
// @match        *://*.maoritv.com/*
// @match        *://*.markiza.sk/*
// @match        *://*.massengeschmack.tv/*
// @match        *://*.masters.com/*
// @match        *://*.matchtv.ru/*
// @match        *://*.mave.digital/*
// @match        *://*.mbn.co.kr/*
// @match        *://*.mdr.de/*
// @match        *://*.medal.tv/*
// @match        *://*.media.ccc.de/*
// @match        *://*.mediaite.com/*
// @match        *://*.mediaklikk.hu/*
// @match        *://*.medialaan.be/*
// @match        *://*.mediaset.it/*
// @match        *://*.mediasite.com/*
// @match        *://*.mediastream.com/*
// @match        *://*.mediaworks.nz/*
// @match        *://*.medici.tv/*
// @match        *://*.megaphone.fm/*
// @match        *://*.megatv.com/*
// @match        *://*.meipai.com/*
// @match        *://*.melon.com/*
// @match        *://*.metacritic.com/*
// @match        *://*.mewatch.sg/*
// @match        *://*.microsoft.com/*
// @match        *://*.minds.com/*
// @match        *://*.minoto.net/*
// @match        *://*.mir24.tv/*
// @match        *://*.mirrativ.com/*
// @match        *://*.mirror.co.uk/*
// @match        *://*.mixch.tv/*
// @match        *://*.mixcloud.com/*
// @match        *://*.mixlr.com/*
// @match        *://*.mlb.com/*
// @match        *://*.mlssoccer.com/*
// @match        *://*.mnet.tv/*
// @match        *://*.mochavideo.com/*
// @match        *://*.mojevideo.sk/*
// @match        *://*.mojvideo.com/*
// @match        *://*.monstercat.com/*
// @match        *://*.monster-siren.com/*
// @match        *://*.motherless.com/*
// @match        *://*.motorsport.com/*
// @match        *://*.moviefap.com/*
// @match        *://*.moviepilot.de/*
// @match        *://*.movingimage.us/*
// @match        *://*.msn.com/*
// @match        *://*.mtg.com/*
// @match        *://*.mtv.com/*
// @match        *://*.mtv.fi/*
// @match        *://*.muenchen.tv/*
// @match        *://*.mujrozhlas.cz/*
// @match        *://*.murrtube.net/*
// @match        *://*.muse.ai/*
// @match        *://*.musescore.com/*
// @match        *://*.musicdex.org/*
// @match        *://*.mux.com/*
// @match        *://*.mx3.ch/*
// @match        *://*.mxplayer.in/*
// @match        *://*.myspace.com/*
// @match        *://*.myspass.de/*
// @match        *://*.myvideo.ge/*
// @match        *://*.myvidster.com/*
// @match        *://*.mzaalo.com/*
// @match        *://*.n-tv.de/*
// @match        *://*.n1info.com/*
// @match        *://*.nascar.com/*
// @match        *://*.nate.com/*
// @match        *://*.nationalgeographic.com/*
// @match        *://*.naver.com/*
// @match        *://*.nba.com/*
// @match        *://*.nbc.com/*
// @match        *://*.nbcnews.com/*
// @match        *://*.nbcolympics.com/*
// @match        *://*.nbcsports.com/*
// @match        *://*.ndr.de/*
// @match        *://*.ndtv.com/*
// @match        *://*.nebula.tv/*
// @match        *://*.nekohacker.com/*
// @match        *://*.nerdcubed.co.uk/*
// @match        *://*.nest.com/*
// @match        *://*.netapp.com/*
// @match        *://*.163.com/*
// @match        *://*.netplus.tv/*
// @match        *://*.netverse.id/*
// @match        *://*.netzkino.de/*
// @match        *://*.newgrounds.com/*
// @match        *://*.newspicks.com/*
// @match        *://*.newsy.com/*
// @match        *://*.nextmedia.com/*
// @match        *://*.nexttv.com.tw/*
// @match        *://*.nexx.cloud/*
// @match        *://*.nfb.ca/*
// @match        *://*.onf.ca/*
// @match        *://*.nfhsnetwork.com/*
// @match        *://*.nfl.com/*
// @match        *://*.nhk.or.jp/*
// @match        *://*.nhl.com/*
// @match        *://*.nick.com/*
// @match        *://*.nicovideo.jp/*
// @match        *://*.niconico.com/*
// @match        *://*.ninaprotocol.com/*
// @match        *://*.nintendo.com/*
// @match        *://*.nitter.net/*
// @match        *://*.njoy.de/*
// @match        *://*.nobelprize.org/*
// @match        *://*.noice.id/*
// @match        *://*.nonktube.com/*
// @match        *://*.noodlemagazine.com/*
// @match        *://*.nos.nl/*
// @match        *://*.nova.cz/*
// @match        *://*.novaplay.bg/*
// @match        *://*.now.com/*
// @match        *://*.nowness.com/*
// @match        *://*.noz.de/*
// @match        *://*.npr.org/*
// @match        *://*.nrk.no/*
// @match        *://*.nrl.com/*
// @match        *://*.nts.live/*
// @match        *://*.ntv.ru/*
// @match        *://*.nubiles-porn.com/*
// @match        *://*.nuum.ru/*
// @match        *://*.nuvid.com/*
// @match        *://*.nytimes.com/*
// @match        *://*.nzherald.co.nz/*
// @match        *://*.nzonscreen.com/*
// @match        *://*.nzz.ch/*
// @match        *://*.ocw.mit.edu/*
// @match        *://*.ok.ru/*
// @match        *://*.odnoklassniki.ru/*
// @match        *://*.oftv.mx/*
// @match        *://*.oktoberfest-tv.de/*
// @match        *://*.olympics.com/*
// @match        *://*.on24.com/*
// @match        *://*.ondemandchina.com/*
// @match        *://*.ondemandkorea.com/*
// @match        *://*.onefootball.com/*
// @match        *://*.oneplace.com/*
// @match        *://*.onet.pl/*
// @match        *://*.onet.tv/*
// @match        *://*.onionstudios.com/*
// @match        *://*.onsen.ag/*
// @match        *://*.opencast.org/*
// @match        *://*.openrec.tv/*
// @match        *://*.ora.tv/*
// @match        *://*.orf.at/*
// @match        *://*.osnatel.tv/*
// @match        *://*.outsidetv.com/*
// @match        *://*.owncloud.com/*
// @match        *://*.packtpub.com/*
// @match        *://*.palcomp3.com.br/*
// @match        *://*.panopto.com/*
// @match        *://*.paramountpressexpress.com/*
// @match        *://*.parler.com/*
// @match        *://*.parliamentlive.tv/*
// @match        *://*.parlview.aph.gov.au/*
// @match        *://*.parti.com/*
// @match        *://*.patreon.com/*
// @match        *://*.pbs.org/*
// @match        *://*.pbskids.org/*
// @match        *://*.pearvideo.com/*
// @match        *://*.peekvids.com/*
// @match        *://*.peer.tv/*
// @match        *://*.peertube.social/*
// @match        *://*.joinpeertube.org/*
// @match        *://*.onepeloton.com/*
// @match        *://*.performgroup.com/*
// @match        *://*.periscope.tv/*
// @match        *://*.pscp.tv/*
// @match        *://*.pgatour.com/*
// @match        *://*.philharmoniedeparis.fr/*
// @match        *://*.phoenix.de/*
// @match        *://*.photobucket.com/*
// @match        *://*.pialive.jp/*
// @match        *://*.piapro.jp/*
// @match        *://*.picarto.tv/*
// @match        *://*.piksel.com/*
// @match        *://*.pinkbike.com/*
// @match        *://*.pinterest.com/*
// @match        *://*.piramidetv.com/*
// @match        *://*.planetmarathi.com/*
// @match        *://*.platzi.com/*
// @match        *://*.goplay.be/*
// @match        *://*.player.fm/*
// @match        *://*.playeur.com/*
// @match        *://*.playplustv.com/*
// @match        *://*.playsuisse.ch/*
// @match        *://*.playtvak.cz/*
// @match        *://*.idnes.cz/*
// @match        *://*.lidovky.cz/*
// @match        *://*.playvids.com/*
// @match        *://*.playwire.com/*
// @match        *://*.pluralsight.com/*
// @match        *://*.pluto.tv/*
// @match        *://*.plvideo.ru/*
// @match        *://*.plyr.io/*
// @match        *://*.podbay.fm/*
// @match        *://*.podchaser.com/*
// @match        *://*.podomatic.com/*
// @match        *://*.pokergo.com/*
// @match        *://*.polsatgo.pl/*
// @match        *://*.polskieradio.pl/*
// @match        *://*.popcorntimes.tv/*
// @match        *://*.popcorntv.it/*
// @match        *://*.pornbox.com/*
// @match        *://*.pornerbros.com/*
// @match        *://*.pornflip.com/*
// @match        *://*.pornhub.com/*
// @match        *://*.thumbzilla.com/*
// @match        *://*.pornotube.com/*
// @match        *://*.pornovoisines.com/*
// @match        *://*.pornoxo.com/*
// @match        *://*.porntop.com/*
// @match        *://*.porntube.com/*
// @match        *://*.pr0gramm.com/*
// @match        *://*.prankcast.com/*
// @match        *://*.premiershiprugby.com/*
// @match        *://*.presstv.ir/*
// @match        *://*.projectveritas.com/*
// @match        *://*.prosieben.de/*
// @match        *://*.sat1.de/*
// @match        *://*.prx.org/*
// @match        *://*.puhutv.com/*
// @match        *://*.puls4.com/*
// @match        *://*.pyvideo.org/*
// @match        *://*.q-dance.com/*
// @match        *://*.qingting.fm/*
// @match        *://*.qq.com/*
// @match        *://*.quantumtv.com/*
// @match        *://*.r7.com/*
// @match        *://*.radiko.jp/*
// @match        *://*.radio.de/*
// @match        *://*.radio1.be/*
// @match        *://*.radiocanada.ca/*
// @match        *://*.radiocomercial.pt/*
// @match        *://*.radiofrance.fr/*
// @match        *://*.radiojavan.com/*
// @match        *://*.radiokapital.pl/*
// @match        *://*.radioradicale.it/*
// @match        *://*.radiozet.pl/*
// @match        *://*.radlive.com/*
// @match        *://*.rai.it/*
// @match        *://*.raiplay.it/*
// @match        *://*.raywenderlich.com/*
// @match        *://*.rbgtum.de/*
// @match        *://*.rcs.it/*
// @match        *://*.rctiplus.com/*
// @match        *://*.rds.ca/*
// @match        *://*.redbull.com/*
// @match        *://*.redbulltv.com/*
// @match        *://*.reddit.com/*
// @match        *://*.redgifs.com/*
// @match        *://*.redtube.com/*
// @match        *://*.ren.tv/*
// @match        *://*.restudy.dk/*
// @match        *://*.reuters.com/*
// @match        *://*.reverbnation.com/*
// @match        *://*.rheinmaintv.de/*
// @match        *://*.ridehome.info/*
// @match        *://*.rinse.fm/*
// @match        *://*.rmcdecouverte.bfmtv.com/*
// @match        *://*.rockstargames.com/*
// @match        *://*.rokfin.com/*
// @match        *://*.roosterteeth.com/*
// @match        *://*.rottentomatoes.com/*
// @match        *://*.roya.tv/*
// @match        *://*.rozhlas.cz/*
// @match        *://*.rtbf.be/*
// @match        *://*.rt.com/*
// @match        *://*.rte.ie/*
// @match        *://*.rtl.lu/*
// @match        *://*.rtl.nl/*
// @match        *://*.rtlxl.nl/*
// @match        *://*.rtl2.de/*
// @match        *://*.rtnews.com/*
// @match        *://*.rtp.pt/*
// @match        *://*.rtrfm.com.au/*
// @match        *://*.rts.ch/*
// @match        *://*.rtvc.gov.co/*
// @match        *://*.rtve.es/*
// @match        *://*.rtvslo.si/*
// @match        *://*.rudovideo.com/*
// @match        *://*.rule34video.com/*
// @match        *://*.rumble.com/*
// @match        *://*.ruptly.tv/*
// @match        *://*.rutube.ru/*
// @match        *://*.ruutu.fi/*
// @match        *://*.ruv.is/*
// @match        *://*.s4c.cymru/*
// @match        *://*.safaribooksonline.com/*
// @match        *://*.saitosan.net/*
// @match        *://*.sak.tv/*
// @match        *://*.salt.ch/*
// @match        *://*.samplefocus.com/*
// @match        *://*.sangiin.go.jp/*
// @match        *://*.sapo.pt/*
// @match        *://*.sauceplus.com/*
// @match        *://*.sbs.com.au/*
// @match        *://*.sbs.co.kr/*
// @match        *://*.schooltv.nl/*
// @match        *://*.sciencechannel.com/*
// @match        *://*.screen.yahoo.com/*
// @match        *://*.screen9.com/*
// @match        *://*.screencast.com/*
// @match        *://*.screencastify.com/*
// @match        *://*.screencast-o-matic.com/*
// @match        *://*.screenrec.com/*
// @match        *://*.scrippsnetworks.com/*
// @match        *://*.scrolller.com/*
// @match        *://*.scte.org/*
// @match        *://*.sejm.gov.pl/*
// @match        *://*.sen.com/*
// @match        *://*.senalcolombia.tv/*
// @match        *://*.senate.gov/*
// @match        *://*.sendtonews.com/*
// @match        *://*.servustv.com/*
// @match        *://*.sexu.com/*
// @match        *://*.seznamzpravy.cz/*
// @match        *://*.shahid.mbc.net/*
// @match        *://*.sharepoint.com/*
// @match        *://*.sharevideos.com/*
// @match        *://*.shemaroome.com/*
// @match        *://*.shiey.com/*
// @match        *://*.showroom-live.com/*
// @match        *://*.shugiintv.go.jp/*
// @match        *://*.sibnet.ru/*
// @match        *://*.simplecast.com/*
// @match        *://*.sina.com.cn/*
// @match        *://*.skeb.jp/*
// @match        *://*.sky.it/*
// @match        *://*.sky.com/*
// @match        *://*.news.sky.com/*
// @match        *://*.sports.sky.com/*
// @match        *://*.skylinewebcams.com/*
// @match        *://*.skynewsarabia.com/*
// @match        *://*.skynews.com.au/*
// @match        *://*.slideshare.net/*
// @match        *://*.slideslive.com/*
// @match        *://*.slutload.com/*
// @match        *://*.smotrim.ru/*
// @match        *://*.snapchat.com/*
// @match        *://*.snotr.com/*
// @match        *://*.softwhiteunderbelly.com/*
// @match        *://*.sohu.com/*
// @match        *://*.sonyliv.com/*
// @match        *://*.sooplive.co.kr/*
// @match        *://*.afreecatv.com/*
// @match        *://*.soundcloud.com/*
// @match        *://*.soundgasm.net/*
// @match        *://*.southpark.cc.com/*
// @match        *://*.southparkstudios.com/*
// @match        *://*.southpark.de/*
// @match        *://*.southpark.lat/*
// @match        *://*.sovietscloset.com/*
// @match        *://*.spankbang.com/*
// @match        *://*.spiegel.de/*
// @match        *://*.sport5.co.il/*
// @match        *://*.sportbox.ru/*
// @match        *://*.sporteurope.tv/*
// @match        *://*.spreaker.com/*
// @match        *://*.springboardplatform.com/*
// @match        *://*.sproutvideo.com/*
// @match        *://*.sr.de/*
// @match        *://*.srf.ch/*
// @match        *://*.rts.ch/*
// @match        *://*.rsi.ch/*
// @match        *://*.rtr.ch/*
// @match        *://*.swissinfo.ch/*
// @match        *://*.stacommu.jp/*
// @match        *://*.stageplus.io/*
// @match        *://*.stanford.edu/*
// @match        *://*.startrek.com/*
// @match        *://*.startv.com.tr/*
// @match        *://*.steam.com/*
// @match        *://*.steampowered.com/*
// @match        *://*.steamcommunity.com/*
// @match        *://*.stitcher.com/*
// @match        *://*.storyfire.com/*
// @match        *://*.streaks.gg/*
// @match        *://*.streamable.com/*
// @match        *://*.stream.cz/*
// @match        *://*.streetvoice.com/*
// @match        *://*.stretchinternet.com/*
// @match        *://*.stripchat.com/*
// @match        *://*.stv.tv/*
// @match        *://*.rtvs.sk/*
// @match        *://*.subsplash.com/*
// @match        *://*.substack.com/*
// @match        *://*.sunporno.com/*
// @match        *://*.sverigesradio.se/*
// @match        *://*.svt.se/*
// @match        *://*.svtplay.se/*
// @match        *://*.swearnet.com/*
// @match        *://*.syfy.com/*
// @match        *://*.syvdk.dk/*
// @match        *://*.sztv.hu/*
// @match        *://*.t-online.de/*
// @match        *://*.tagesschau.de/*
// @match        *://*.taptap.io/*
// @match        *://*.tass.com/*
// @match        *://*.tbs.com/*
// @match        *://*.tbs.co.jp/*
// @match        *://*.teachable.com/*
// @match        *://*.teachertube.com/*
// @match        *://*.teachingchannel.org/*
// @match        *://*.teamcoco.com/*
// @match        *://*.teamtreehouse.com/*
// @match        *://*.techtv.mit.edu/*
// @match        *://*.ted.com/*
// @match        *://*.tele13.cl/*
// @match        *://*.tele5.de/*
// @match        *://*.telebruxelles.be/*
// @match        *://*.telecaribe.co/*
// @match        *://*.telecinco.es/*
// @match        *://*.cuatro.com/*
// @match        *://*.telegraaf.nl/*
// @match        *://*.telegram.org/*
// @match        *://*.t.me/*
// @match        *://*.telemb.be/*
// @match        *://*.telemundo.com/*
// @match        *://*.telequebec.tv/*
// @match        *://*.teletask.de/*
// @match        *://*.telewebion.com/*
// @match        *://*.tempo.co/*
// @match        *://*.tennistv.com/*
// @match        *://*.tf1.fr/*
// @match        *://*.tfo.org/*
// @match        *://*.theatercomplextown.jp/*
// @match        *://*.thechosen.tv/*
// @match        *://*.theguardian.com/*
// @match        *://*.thehighwire.com/*
// @match        *://*.thehole.tv/*
// @match        *://*.theintercept.com/*
// @match        *://*.theplatform.com/*
// @match        *://*.thestar.com/*
// @match        *://*.thesun.co.uk/*
// @match        *://*.weather.com/*
// @match        *://*.thisamericanlife.org/*
// @match        *://*.thisoldhouse.com/*
// @match        *://*.thisvid.com/*
// @match        *://*.3speak.tv/*
// @match        *://*.tiktok.com/*
// @match        *://*.tlc.com/*
// @match        *://*.tmz.com/*
// @match        *://*.tnaflix.com/*
// @match        *://*.toggle.sg/*
// @match        *://*.toggo.de/*
// @match        *://*.tokfm.pl/*
// @match        *://*.toongoggles.com/*
// @match        *://*.tou.tv/*
// @match        *://*.toutiao.com/*
// @match        *://*.toypics.net/*
// @match        *://*.traileraddict.com/*
// @match        *://*.travelchannel.com/*
// @match        *://*.triller.co/*
// @match        *://*.trovo.live/*
// @match        *://*.trt.net.tr/*
// @match        *://*.trtworld.com/*
// @match        *://*.trueid.net/*
// @match        *://*.trunews.com/*
// @match        *://*.truthsocial.com/*
// @match        *://*.ttinglive.com/*
// @match        *://*.tube8.com/*
// @match        *://*.tube.tugraz.at/*
// @match        *://*.tubitv.com/*
// @match        *://*.tumblr.com/*
// @match        *://*.tunein.com/*
// @match        *://*.tv.dfb.de/*
// @match        *://*.tv2.no/*
// @match        *://*.tv2.dk/*
// @match        *://*.tv2play.hu/*
// @match        *://*.tv4.se/*
// @match        *://*.tv4play.se/*
// @match        *://*.tv5monde.com/*
// @match        *://*.tv5unis.ca/*
// @match        *://*.tv8.it/*
// @match        *://*.tvanouvelles.ca/*
// @match        *://*.tva.ca/*
// @match        *://*.tvc.ru/*
// @match        *://*.tver.jp/*
// @match        *://*.tvigle.ru/*
// @match        *://*.tviplayer.pt/*
// @match        *://*.tvn24.pl/*
// @match        *://*.tvnoe.cz/*
// @match        *://*.tvopen.gr/*
// @match        *://*.ethnos.gr/*
// @match        *://*.tvp.pl/*
// @match        *://*.tvplayer.com/*
// @match        *://*.tvplay.com/*
// @match        *://*.tvw.org/*
// @match        *://*.tweakers.net/*
// @match        *://*.twitcasting.tv/*
// @match        *://*.twitch.tv/*
// @match        *://*.twitter.com/*
// @match        *://*.x.com/*
// @match        *://*.txxx.com/*
// @match        *://*.udemy.com/*
// @match        *://*.udn.com/*
// @match        *://*.ufcarabia.com/*
// @match        *://*.ufctv.com/*
// @match        *://*.ukcolumn.org/*
// @match        *://*.uktvplay.co.uk/*
// @match        *://*.uliza.jp/*
// @match        *://*.universalmusic.de/*
// @match        *://*.unistra.fr/*
// @match        *://*.webtv.un.org/*
// @match        *://*.unity.com/*
// @match        *://*.uol.com.br/*
// @match        *://*.uplynk.com/*
// @match        *://*.urort.no/*
// @match        *://*.urplay.se/*
// @match        *://*.usanetwork.com/*
// @match        *://*.usatoday.com/*
// @match        *://*.ustream.tv/*
// @match        *://*.ustudio.com/*
// @match        *://*.varzesh3.com/*
// @match        *://*.vbox7.com/*
// @match        *://*.veo.co/*
// @match        *://*.vevo.com/*
// @match        *://*.vgtv.no/*
// @match        *://*.vh1.com/*
// @match        *://*.vhx.tv/*
// @match        *://*.vice.com/*
// @match        *://*.viddler.com/*
// @match        *://*.videa.hu/*
// @match        *://*.arnes.si/*
// @match        *://*.videodetective.com/*
// @match        *://*.videofy.me/*
// @match        *://*.videoken.com/*
// @match        *://*.videomore.ru/*
// @match        *://*.videopress.com/*
// @match        *://*.vidflex.com/*
// @match        *://*.vidio.com/*
// @match        *://*.vidlii.com/*
// @match        *://*.vidly.com/*
// @match        *://*.vids.io/*
// @match        *://*.vidyard.com/*
// @match        *://*.viewlift.com/*
// @match        *://*.viidea.net/*
// @match        *://*.vimeo.com/*
// @match        *://*.vimm.tv/*
// @match        *://*.vimp.com/*
// @match        *://*.viously.com/*
// @match        *://*.viqeo.tv/*
// @match        *://*.viu.com/*
// @match        *://*.vk.com/*
// @match        *://*.vkplay.ru/*
// @match        *://*.vocaroo.com/*
// @match        *://*.vod.pl/*
// @match        *://*.vodplatform.com/*
// @match        *://*.voicy.jp/*
// @match        *://*.volej.tv/*
// @match        *://*.voxmedia.com/*
// @match        *://*.vrsquare.jp/*
// @match        *://*.vrt.be/*
// @match        *://*.vrtmax.be/*
// @match        *://*.vtm.be/*
// @match        *://*.vtv.vn/*
// @match        *://*.vtvgo.vn/*
// @match        *://*.vtx.tv/*
// @match        *://*.vuclip.com/*
// @match        *://*.vvvvid.it/*
// @match        *://*.walla.co.il/*
// @match        *://*.waly.tv/*
// @match        *://*.washingtonpost.com/*
// @match        *://*.wat.tv/*
// @match        *://*.watchespn.com/*
// @match        *://*.wdr.de/*
// @match        *://*.web.archive.org/*
// @match        *://*.webcamera.pl/*
// @match        *://*.webcaster.pro/*
// @match        *://*.webofstories.com/*
// @match        *://*.weibo.com/*
// @match        *://*.weiqitv.com/*
// @match        *://*.wetv.vip/*
// @match        *://*.weverse.io/*
// @match        *://*.wevidi.net/*
// @match        *://*.weyyak.com/*
// @match        *://*.whowatch.tv/*
// @match        *://*.whyp.it/*
// @match        *://*.wikimedia.org/*
// @match        *://*.wikipedia.org/*
// @match        *://*.wimbledon.com/*
// @match        *://*.wimtv.it/*
// @match        *://*.winsports.co/*
// @match        *://*.wistia.com/*
// @match        *://*.omroepwnl.nl/*
// @match        *://*.wordpress.com/*
// @match        *://*.worldstarhiphop.com/*
// @match        *://*.wppilot.pl/*
// @match        *://*.wrestle-universe.com/*
// @match        *://*.wsj.com/*
// @match        *://*.wwe.com/*
// @match        *://*.wyborcza.pl/*
// @match        *://*.wykop.pl/*
// @match        *://*.xboxclips.com/*
// @match        *://*.xhamster.com/*
// @match        *://*.xiaohongshu.com/*
// @match        *://*.ximalaya.com/*
// @match        *://*.xinpianchang.com/*
// @match        *://*.xminus.com/*
// @match        *://*.xnxx.com/*
// @match        *://*.xstream.dk/*
// @match        *://*.xvideos.com/*
// @match        *://*.xxxymovies.com/*
// @match        *://*.yahoo.com/*
// @match        *://*.yandex.ru/*
// @match        *://*.music.yandex.ru/*
// @match        *://*.yapfiles.ru/*
// @match        *://*.yappy.media/*
// @match        *://*.yfanefa.com/*
// @match        *://*.yle.fi/*
// @match        *://*.areena.yle.fi/*
// @match        *://*.youjizz.com/*
// @match        *://*.youku.com/*
// @match        *://*.younow.com/*
// @match        *://*.youporn.com/*
// @match        *://*.zaiko.io/*
// @match        *://*.zapiks.fr/*
// @match        *://*.zattoo.com/*
// @match        *://*.zdf.de/*
// @match        *://*.zee5.com/*
// @match        *://*.zeenews.com/*
// @match        *://*.zenporn.com/*
// @match        *://*.zetland.dk/*
// @match        *://*.zhihu.com/*
// @match        *://*.zingmp3.vn/*
// @match        *://*.zoom.us/*
// @match        *://*.zype.com/*
// ==/UserScript==

(function() {
    'use strict';

    // =========================================================================
    // CONFIGURATION
    // =========================================================================

    const CONFIG = {
        version: '1.0.0',
        debounceMs: 300,
        protocol: 'ytdl'
    };

    // =========================================================================
    // SITE CONFIGURATIONS
    // =========================================================================

    const SITE_CONFIGS = {
        'youtube.com': {
            name: 'YouTube',
            urlPattern: /youtube\.com\/(watch|shorts|live)/,
            getVideoUrl: () => {
                const urlParams = new URLSearchParams(window.location.search);
                const videoId = urlParams.get('v');
                if (videoId) return `https://www.youtube.com/watch?v=${videoId}`;
                if (location.pathname.includes('/shorts/')) return location.href;
                if (location.pathname.includes('/live/')) return location.href;
                return null;
            },
            getVideoTitle: () => {
                return document.querySelector('h1.ytd-video-primary-info-renderer, h1.ytd-watch-metadata')?.textContent?.trim() 
                    || document.title.replace(' - YouTube', '');
            }
        },
        'youtu.be': { inherit: 'youtube.com' },
        'vimeo.com': {
            name: 'Vimeo',
            urlPattern: /vimeo\.com\/\d+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || document.title
        },
        'twitter.com': {
            name: 'Twitter',
            urlPattern: /twitter\.com\/\w+\/status\/\d+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('article h2')?.textContent?.trim() || 'twitter_video'
        },
        'x.com': { inherit: 'twitter.com', name: 'X' },
        'tiktok.com': {
            name: 'TikTok',
            urlPattern: /tiktok\.com\/@[\w.]+\/video\/\d+|tiktok\.com\/t\/\w+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'tiktok_video'
        },
        'instagram.com': {
            name: 'Instagram',
            urlPattern: /instagram\.com\/(p|reel|tv)\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => 'instagram_video'
        },
        'twitch.tv': {
            name: 'Twitch',
            urlPattern: /twitch\.tv\/videos\/\d+|twitch\.tv\/\w+\/clip\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1, h2[data-a-target="stream-title"]')?.textContent?.trim() || 'twitch_video'
        },
        'reddit.com': {
            name: 'Reddit',
            urlPattern: /reddit\.com\/r\/\w+\/comments\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'reddit_video'
        },
        'dailymotion.com': {
            name: 'Dailymotion',
            urlPattern: /dailymotion\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'dailymotion_video'
        },
        'soundcloud.com': {
            name: 'SoundCloud',
            urlPattern: /soundcloud\.com\/[\w-]+\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'soundcloud_audio',
            audioOnly: true
        },
        'bandcamp.com': {
            name: 'Bandcamp',
            urlPattern: /bandcamp\.com\/(track|album)\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h2.trackTitle, .trackTitle')?.textContent?.trim() || 'bandcamp_audio',
            audioOnly: true
        },
        'rumble.com': {
            name: 'Rumble',
            urlPattern: /rumble\.com\/v[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'rumble_video'
        },
        'odysee.com': {
            name: 'Odysee',
            urlPattern: /odysee\.com\/@[\w-]+:\w\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'odysee_video'
        },
        'bilibili.com': {
            name: 'Bilibili',
            urlPattern: /bilibili\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'bilibili_video'
        },
        'facebook.com': {
            name: 'Facebook',
            urlPattern: /facebook\.com\/.*\/videos\/|facebook\.com\/watch/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => 'facebook_video'
        },
        'streamable.com': {
            name: 'Streamable',
            urlPattern: /streamable\.com\/\w+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('title')?.textContent?.replace(' - Streamable', '') || 'streamable_video'
        },
        'imgur.com': {
            name: 'Imgur',
            urlPattern: /imgur\.com\/(a\/|gallery\/)?[\w]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('.post-title, h1')?.textContent?.trim() || 'imgur'
        },
        'pornhub.com': {
            name: 'PornHub',
            urlPattern: /pornhub\.com\/view_video\.php/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1.title span')?.textContent?.trim() || 'video'
        },
        'xvideos.com': {
            name: 'XVideos',
            urlPattern: /xvideos\.com\/video\d+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h2.page-title')?.textContent?.trim() || 'video'
        },
        'xhamster.com': {
            name: 'xHamster',
            urlPattern: /xhamster\.com\/videos\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'video'
        },
        'mixcloud.com': {
            name: 'Mixcloud',
            urlPattern: /mixcloud\.com\/[\w-]+\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'mixcloud_audio',
            audioOnly: true
        },
        'spotify.com': {
            name: 'Spotify',
            urlPattern: /open\.spotify\.com\/(track|episode)\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'spotify_audio',
            audioOnly: true
        },
        'ted.com': {
            name: 'TED',
            urlPattern: /ted\.com\/talks\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'ted_talk'
        },
        'cnn.com': {
            name: 'CNN',
            urlPattern: /cnn\.com\/videos\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'cnn_video'
        },
        'bbc.com': {
            name: 'BBC',
            urlPattern: /bbc\.com\/.*\/video/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'bbc_video'
        },
        'crunchyroll.com': {
            name: 'Crunchyroll',
            urlPattern: /crunchyroll\.com\/watch\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'crunchyroll_video'
        },
        'kick.com': {
            name: 'Kick',
            urlPattern: /kick\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'kick_video'
        },
        'coub.com': {
            name: 'Coub',
            urlPattern: /coub\.com\/view\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('.coub__title')?.textContent?.trim() || 'coub_video'
        },
        'bitchute.com': {
            name: 'BitChute',
            urlPattern: /bitchute\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'bitchute_video'
        },
        'loom.com': {
            name: 'Loom',
            urlPattern: /loom\.com\/share\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'loom_video'
        },
        'nebula.tv': {
            name: 'Nebula',
            urlPattern: /nebula\.tv\/videos\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'nebula_video'
        },
        'floatplane.com': {
            name: 'Floatplane',
            urlPattern: /floatplane\.com\/post\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'floatplane_video'
        }
    };

    // =========================================================================
    // STYLES
    // =========================================================================

    const STYLES = `
        /* ===== SIDE DRAWER ===== */
        #mediadl-drawer {
            position: fixed;
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            z-index: 2147483647;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            align-items: center;
        }

        #mediadl-drawer .drawer-content {
            display: flex;
            align-items: center;
            background: #1a1a1a;
            border-radius: 8px 0 0 8px;
            overflow: hidden;
            box-shadow: -4px 0 20px rgba(0, 0, 0, 0.4);
            transform: translateX(calc(100% - 8px));
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        #mediadl-drawer:hover .drawer-content,
        #mediadl-drawer.expanded .drawer-content {
            transform: translateX(0);
        }

        #mediadl-drawer .drawer-lip {
            width: 8px;
            height: 80px;
            background: linear-gradient(180deg, #00b894, #00a085);
            cursor: pointer;
            flex-shrink: 0;
            border-radius: 8px 0 0 8px;
        }

        #mediadl-drawer .drawer-lip:hover {
            background: linear-gradient(180deg, #00d4aa, #00b894);
        }

        #mediadl-drawer .drawer-buttons {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 12px 16px 12px 12px;
        }

        #mediadl-drawer .drawer-btn {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            color: white;
            white-space: nowrap;
            transition: all 0.2s ease;
        }

        #mediadl-drawer .drawer-btn:hover {
            transform: scale(1.03);
            filter: brightness(1.15);
        }

        #mediadl-drawer .drawer-btn.video {
            background: linear-gradient(135deg, #00b894, #00a085);
        }

        #mediadl-drawer .drawer-btn.audio {
            background: linear-gradient(135deg, #6c5ce7, #5b4cdb);
        }

        #mediadl-drawer .drawer-btn svg {
            width: 18px;
            height: 18px;
            fill: currentColor;
        }

        /* ===== TOAST NOTIFICATIONS ===== */
        #mediadl-toast {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background: #1a1a2e;
            color: white;
            padding: 14px 20px;
            border-radius: 10px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
            z-index: 2147483647;
            display: flex;
            align-items: center;
            gap: 12px;
            animation: toastSlide 0.3s ease;
            font-size: 14px;
        }

        @keyframes toastSlide {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        #mediadl-toast.success { border-left: 4px solid #00b894; }
        #mediadl-toast.error { border-left: 4px solid #ff7675; }
        #mediadl-toast.info { border-left: 4px solid #0984e3; }
    `;

    // =========================================================================
    // ICONS
    // =========================================================================

    const ICONS = {
        download: '<svg viewBox="0 0 24 24"><path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/></svg>',
        audio: '<svg viewBox="0 0 24 24"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>'
    };

    // =========================================================================
    // UTILITY FUNCTIONS
    // =========================================================================

    function showToast(message, type = 'info', duration = 3000) {
        const existing = document.getElementById('mediadl-toast');
        if (existing) existing.remove();

        const toast = document.createElement('div');
        toast.id = 'mediadl-toast';
        toast.className = type;
        toast.textContent = message;
        document.body.appendChild(toast);

        setTimeout(() => toast.remove(), duration);
    }

    // =========================================================================
    // SITE DETECTION
    // =========================================================================

    function getCurrentSiteConfig() {
        const hostname = location.hostname.replace('www.', '');

        for (const [domain, config] of Object.entries(SITE_CONFIGS)) {
            if (hostname.includes(domain.replace('www.', ''))) {
                if (config.inherit) {
                    const parent = SITE_CONFIGS[config.inherit];
                    return { ...parent, ...config, domain };
                }
                return { ...config, domain };
            }
        }
        
        // Generic fallback for any supported site
        return {
            name: hostname.split('.')[0].charAt(0).toUpperCase() + hostname.split('.')[0].slice(1),
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.title,
            domain: hostname
        };
    }

    function isVideoPage(config) {
        if (!config) return false;
        if (!config.urlPattern) return true;
        return config.urlPattern.test(location.href);
    }

    // =========================================================================
    // DOWNLOAD ACTIONS
    // =========================================================================

    function triggerDownload(action, url, title) {
        if (!url) {
            showToast('No video URL found on this page', 'error');
            return;
        }

        const encodedUrl = encodeURIComponent(url);
        let protocol;

        switch (action) {
            case 'video':
                protocol = `${CONFIG.protocol}://${encodedUrl}`;
                showToast('Starting video download...', 'info');
                break;
            case 'audio':
                protocol = `${CONFIG.protocol}://${encodedUrl}?ytyt_audio_only=1`;
                showToast('Starting audio extraction...', 'info');
                break;
            default:
                return;
        }

        window.location.href = protocol;
    }

    // =========================================================================
    // UI CREATION - SIDE DRAWER
    // =========================================================================

    function createDrawer(config) {
        if (document.getElementById('mediadl-drawer')) return;

        const isAudioSite = config?.audioOnly;
        
        const drawer = document.createElement('div');
        drawer.id = 'mediadl-drawer';

        let buttonsHtml = '';
        
        if (!isAudioSite) {
            buttonsHtml += `
                <button class="drawer-btn video" data-action="video">
                    ${ICONS.download}
                    <span>Video</span>
                </button>
            `;
        }
        
        buttonsHtml += `
            <button class="drawer-btn audio" data-action="audio">
                ${ICONS.audio}
                <span>${isAudioSite ? 'Audio' : 'MP3'}</span>
            </button>
        `;

        drawer.innerHTML = `
            <div class="drawer-content">
                <div class="drawer-lip" title="MediaDL"></div>
                <div class="drawer-buttons">
                    ${buttonsHtml}
                </div>
            </div>
        `;

        document.body.appendChild(drawer);

        // Button click handlers
        drawer.querySelectorAll('.drawer-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                const url = config?.getVideoUrl?.() || location.href;
                const title = config?.getVideoTitle?.() || document.title;
                triggerDownload(action, url, title);
            });
        });
    }

    // =========================================================================
    // INITIALIZATION
    // =========================================================================

    function cleanup() {
        const drawer = document.getElementById('mediadl-drawer');
        if (drawer) drawer.remove();
    }

    function init() {
        cleanup();

        const config = getCurrentSiteConfig();
        
        if (!config || !isVideoPage(config)) {
            return;
        }

        createDrawer(config);
    }

    // Debounced init for SPA navigation
    const debouncedInit = (() => {
        let timeout;
        return () => {
            clearTimeout(timeout);
            timeout = setTimeout(init, CONFIG.debounceMs);
        };
    })();

    // =========================================================================
    // EVENT LISTENERS
    // =========================================================================

    // Inject styles
    GM_addStyle(STYLES);

    // Initial load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Handle SPA navigation (YouTube, Twitter, etc.)
    window.addEventListener('yt-navigate-finish', debouncedInit);
    window.addEventListener('popstate', debouncedInit);
    
    // Watch for URL changes
    let lastUrl = location.href;
    new MutationObserver(() => {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            debouncedInit();
        }
    }).observe(document.body, { childList: true, subtree: true });

    // Also run after full page load
    window.addEventListener('load', () => setTimeout(init, 1000));

    console.log('MediaDL: Universal Media Downloader loaded');
})();
