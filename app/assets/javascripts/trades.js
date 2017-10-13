$(document).ready(function(){
  $('a').on(click, function(e){
    e.preventDefault;
  })
});

// url= https://api.liqui.io
// signature = nonce + command as a string then sign with secret key
// compute the HMAC with hmac, string, secret key
// hex digest?
//
