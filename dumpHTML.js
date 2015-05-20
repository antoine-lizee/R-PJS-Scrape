var page = require('webpage').create(),
system = require('system'),
fs = require('fs'),
t, address,fileName;

if (system.args.length === 1) {
  console.log('Usage: dumpHTML.js <some URL>');
  phantom.exit();
}

page.settings.userAgent = 'Mozilla/5.0 (X11; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0';
page.customHeaders = { 'Referer':  'http://www.kayak.com/flights'};

t = Date.now();
address = system.args[1];
fileName = address.split("/")[2] + "." + (new Date()).toISOString().slice(0,19) + '.html';
fileName = 'test.html';

page.open(address, function(status) {

  if (status !== 'success') {
    console.log('FAIL to load the address');
    phantom.exit();
  } else {
    t = Date.now() - t;
    console.log('Loading ' + system.args[1]);
    console.log('Loading time ' + t + ' msec');

    window.setTimeout(function () {
      console.log('dumping HTML into ' + fileName);
      try {
        var f = fs.open(fileName, "w");
        f.write(page.content);
        f.close();
      } catch (e) {
        console.log(e);
      }
      console.log("rendering...");
      page.render('test.jpeg', {format: 'jpeg', quality: '100'});
      phantom.exit();
        }, 40000); // Change timeout as required to allow sufficient time
  }
});
