# comfortable
user_pref("browser.tabs.loadBookmarksInTabs", true);
user_pref("browser.search.openintab", true);
user_pref("browser.newtab.preload", true);
user_pref("browser.tabs.insertAfterCurrent", true);
user_pref("browser.cache.disk.amount_written", 524288);
user_pref("browser.cache.disk.capacity", 524288);


# dark theme
user_pref("svg.context-properties.content.enabled", true);
# gesturefly
user_pref("privacy.resistFingerprinting", true);

#
user_pref("browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines", "");
user_pref("gecko.handlerService.schemes.mailto.1.uriTemplate", "");

# geo
user_pref("geo.wifi.uri", "");
user_pref("geo.enabled", true);

# data reporting
user_pref("datareporting.policy.dataSubmissionPolicyNotifiedTime", 0);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.healthreport.infoURL", "");


# safe browsing
user_pref("browser.safebrowsing.allowOverride", false);
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.debug", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous_host", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.gethashURL", "");
user_pref("browser.safebrowsing.id", "");
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.malware.reportURL", "");
user_pref("browser.safebrowsing.passwords.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.provider.google.advisoryName", "");
user_pref("browser.safebrowsing.provider.google.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.lists", "");
user_pref("browser.safebrowsing.provider.google.pver", "");
user_pref("browser.safebrowsing.provider.google.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.advisoryName", "");
user_pref("browser.safebrowsing.provider.google4.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharing.enabled", false);
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.lastupdatetime", 0);
user_pref("browser.safebrowsing.provider.google4.lists", "");
user_pref("browser.safebrowsing.provider.google4.nextupdatetime", 0);
user_pref("browser.safebrowsing.provider.google4.pver", 0);
user_pref("browser.safebrowsing.provider.google4.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.reportURL", "");
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.mozilla.gethashURL", "");
user_pref("browser.safebrowsing.provider.mozilla.lastupdatetime", 0);
user_pref("browser.safebrowsing.provider.mozilla.lists", "");
user_pref("browser.safebrowsing.provider.mozilla.lists.base", "");
user_pref("browser.safebrowsing.provider.mozilla.lists.content", "");
user_pref("browser.safebrowsing.provider.mozilla.nextupdatetime", 0);
user_pref("browser.safebrowsing.provider.mozilla.pver", 0);
user_pref("browser.safebrowsing.provider.mozilla.updateURL", "");
user_pref("browser.safebrowsing.reportErrorURL", "");
user_pref("browser.safebrowsing.reportGenericURL", "");
user_pref("browser.safebrowsing.reportMalwareErrorURL", "");
user_pref("browser.safebrowsing.reportMalwareURL", "");
user_pref("browser.safebrowsing.reportPhishURL", "");
user_pref("browser.safebrowsing.reportURL", "");
user_pref("browser.safebrowsing.updateURL", "");
user_pref("services.sync.prefs.sync.browser.safebrowsing.downloads.enabled", false);
user_pref("services.sync.prefs.sync.browser.safebrowsing.malware.enabled", false);
user_pref("services.sync.prefs.sync.browser.safebrowsing.passwords.enabled", false);
user_pref("services.sync.prefs.sync.browser.safebrowsing.phishing.enabled", false);

/*
user_pref("media.autoplay.enabled",false); // Stop autoplay of videos
user_pref("media.directshow.enabled",false); // https://support.mozilla.org/fr/questions/999164
user_pref("media.eme.enabled",false); // https://wiki.mozilla.org/Media/EME
user_pref("media.gmp-eme-adobe.enabled",false); // https://wiki.mozilla.org/Media/EME
user_pref("media.peerconnection.enabled",false); // http://thehackernews.com/2015/02/webrtc-leaks-vpn-ip-address.html https://github.com/diafygi/webrtc-ips
user_pref("media.windows-media-foundation.enabled",false); // https://support.mozilla.org/fr/questions/999164
user_pref("network.dns.disablePrefetch",true);
user_pref("network.http.sendRefererHeader",0); // http://lehollandaisvolant.net/?d=2012/01/17/15/30/15-proteger-votre-vie-privee-sur-le-web-en-masquant-votre-provenance
user_pref("network.http.speculative-parallel-limit",0); // http://news.slashdot.org/story/15/08/14/2321202/how-to-quash-firefoxs-silent-requests
user_pref("network.proxy.socks_remote_dns",true); // http://www.libre-parcours.net/2012/09/eviter-les-fuites-dns-dans-firefox-quand-on-utilise-un-proxy-socks/
user_pref("plugins.click_to_play",true); // http://www.howtogeek.com/123986/how-to-enable-click-to-play-plugins-in-firefox/?PageSpeed=noscript
user_pref("security.tls.version.max",4); // 4 == TLS 1.3 https://www.ghacks.net/2017/06/15/how-to-enable-tls-1-3-support-in-firefox-and-chrome/
user_pref("security.tls.version.min",2); // but some fucking web site use tls < 2 T_T
user_pref("services.sync.prefs.sync.browser.safebrowsing.enabled",false);
user_pref("services.sync.prefs.sync.browser.safebrowsing.malware.enabled",false);
user_pref("toolkit.telemetry.enabled",false); // https://www.mozilla.org/en-US/privacy/firefox/#telemetry
*/
