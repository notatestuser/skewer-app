#clean first
rm -rf www/
mkdir www/

# run code parsers
./node_modules/coffee-script/bin/coffee -c -o public/js src
./node_modules/jade/bin/jade views/partials/components --out www/partials/components
./node_modules/jade/bin/jade views/partials/contact    --out www/partials/contact
./node_modules/jade/bin/jade views/partials/{_about,editor,home,login,logout,share}.jade  --out www/partials/
./node_modules/jade/bin/jade views/index-mobile.jade --out www/
cp -a public/. www/
cp -a mobile-static/sdk/*.js www/js/sdk/
rm www/js/vendor/build.js
cp build/build.js www/js/vendor/spinner.js
cp mobile-static/bootconfig.json www/

#remove old web
rm www/js/sdk/forcetk.ui.js

#Your mobile cordova project directory
rm -rf ../myiosapp/skrewer/skrewer/www/ 
cp -a www/.  ../myiosapp/skrewer/skrewer/www/ 
