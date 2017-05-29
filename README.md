fitocracy-api
=============

Feel free to look me up and follow me on fitocracy as sjoconnor.

# Disclaimer

This is an unofficial API to help you get your lifting data from Fitocracy. I am in no way affiliated with Fitocracy, and do not represent them. 
If you choose to store your password for ongoing synchronization, this system attempts to do so in a secure way and 
does not log it in plain text. However, this system is by definition able to use your password to connect to Fitocracy
and therefore stores it in a decryptable way. Use at your own risk. Changing your password at Fitocracy will forcibly
disable this system's ability to access your account.

# Setup

You should be able to simply clone the project, perform a `bundle install` and then start your Sinatra server with 
`bundle exec rackup -p 4567 -o 0.0.0.0 config.ru`. Or under unicorn with `unicorn` after renaming example-unicorn.rb
to unicorn.rb

In `login.api.rb` you'll need to swap out the Username and Password with your actual credentials, or you can optionally 
set the following environment variables in `user.rb`.

````ruby
class User

  ...

  def initialize(hash={})
    @username = hash[:username] || ENV['fitocracy_api_username']
    @password = hash[:password] || ENV['fitocracy_api_password']
    @agent    = hash[:agent]

    validate_user
  end

  ...

end
````

To configure [vault](https://www.vaultproject.io), which is used for storing secrets follow the following steps:

 1. [Install vault](https://www.vaultproject.io/downloads.html) and put the binary in your system path.
 2. Start the vault server: `sudo vault server -config=/PATH_TO_PROJECT/vault.hcl &` (note, in prod you will want to change the configuration to use TLS)
 3. If you're not using TLS (default) set this environment variable: `export VAULT_ADDR=http://127.0.0.1:8200`
 4. Initialize vault: `vault init` put the 5 keys and the root token in a safe place
 5. Run the command `vault unseal` 3 times in a row, with a different one of the previous 5 keys each time
 6. Authenticate with your root token: `vault auth`
 7. Create a new token for this application to use: `vault token-create`
 8. Paste that token into config.yml in this file under the vault/token key.

# My Lifts

* Hitting `/user/fitocracy/activities` will return JSON with all of your lifts, pulled directly from Fitocracy.
* Hitting `/user/activities/sync` will perform the above action, but persist your lifts to the local database.
* Hitting `/user/activity_log/sync` will iterate through all of your activities and fetch all of the details to the local database.
* Hitting `/user/activities` will return a UI with all of your lifts, pulled from the local database. It's only useful after you've performed the sync operations above.

Sample output from `/user/fitocracy/activities`:

````JSON
[
  {
    "count": 197,
    "id": 2,
    "name": "Barbell Squat"
  },
  {
    "count": 187,
    "id": 1,
    "name": "Barbell Bench Press"
  },
  {
    "count": 175,
    "id": 183,
    "name": "Standing Barbell Shoulder Press (OHP)"
  },
  {
    "count": 116,
    "id": 283,
    "name": "Chin-Up"
  },
  {
    "count": 93,
    "id": 3,
    "name": "Barbell Deadlift"
  },
  {
    "count": 61,
    "id": 425,
    "name": "Romanian Deadlift"
  }
]
````

# Specific Lifts

You can get data regarding a specific link by appending the exercise name, exactly as it comes from Fitocracy, like so: `/user/fitocracy/activity/:activity_name`. Pass the activity name ("Barbell Bench Press") as a param. The lift name must match exactly as it does on Fitocracy.

Sample output:

````JSON
[
  {
    "actions": [
      {
        "effort0_imperial_string": "80 lb",
        "effort0_imperial": 80.0,
        "effort1_imperial_unit": {
          "id": 31,
          "abbr": "reps",
          "name": "Reps"
        },
        "new_quest": null,
        "effort2_metric_unit": null,
        "effort1_metric_string": "6 reps",
        "effort2_string": null,
        "effort3_unit": null,
        "effort4_metric_string": null,
        "effort0_metric": 36.28738963043027,
        "is_pr": false,
        "effort5_imperial_unit": null,
        "effort4_string": null,
        "id": 32349306,
        "effort2_unit": null,
        "actiondate": "2012-02-02",
        "effort5_metric_unit": null,
        "effort0_metric_string": "36.3 kg",
        "effort0_unit": {
          "id": 35,
          "abbr": "lb",
          "name": "Pounds"
        }
     ]
  }
]
````

# Changelog

### January 2016
* Updated with database support, password storage support, and basic UI

### November 22, 2012
* Routes were changed so login validations could be ran before each request.
* All routes are now POSTs, instead of GETs. Doing a GET with usernames/passwords didn't feel right, for obvious reasons.
* Extracted all paths into a separate module to keep them all together.
* Added an additional form, primarily to make testing easier.

# TODO

* ~~Switch to POSTS and set up a form accepting a username/password combination~~
* Should not have to log in for every request
	* Keep user session around
* ~~Actually look up the lifts for a specific exercise~~
* Possibly adding good charts for lifts
* Massive refactor
	* ~~Eliminate login duplication~~
	* ~~Extract pages into objects~~
* Utilized :username param when looking up activites