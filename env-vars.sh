export app_url="https://app.getskewer.com"
export client_id="xxx"
heroku config:add --app getskewer app_url="$app_url"
heroku config:add --app getskewer client_id="$client_id"

