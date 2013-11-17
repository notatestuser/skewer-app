export app_url="https://app.getskewer.com"
export client_id="3MVG9A2kN3Bn17htvLRrRX6fHQGcufpxe4SHHD9leg4qHNCWK3_enoEMZaUkWUhHIjrBptrLUxtB.LmyjldKu"
heroku config:add --app getskewer app_url="$app_url"
heroku config:add --app getskewer client_id="$client_id"

