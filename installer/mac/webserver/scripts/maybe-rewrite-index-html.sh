#! /bin/sh

if [ `md5 -q "$DSTVOLUME/Library/WebServer/Documents/index.html.en"` = 5388f60d7695cb57b87c799ee62d20b2 ] ; then
 cat  > "$DSTVOLUME/Library/WebServer/Documents/index.html.en" <<EOF
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=derbynet"/>
    <title>Redirect</title>
  </head>
  <body>
    <h1>Visit <a href="derbynet">derbynet</a></h1>
  </body>
</html>
EOF
 echo Index file changed
fi
